#!/usr/bin/env bash
#
# Ship coding-agent session logs from a workspace to object storage (R2) as an
# immutable, timestamped change feed (CDC). Each pass captures only what is new
# since the last pass and writes it under a common per-session layout:
#
#   <prefix>/v1/host=<id>/harness=<claude|codex|opencode>/session=<sid>/<UTC>-<stream>.jsonl
#
# Objects are never overwritten (unique tick timestamp); reconstruct a session by
# concatenating its objects in name order. See _MANIFEST.md at the feed root.
#
#   archiver.sh once   # one pass, then exit
#   archiver.sh run    # loop every $AGENT_LOG_INTERVAL (postStart)
#
# Config (env):
#   R2_BUCKET            Cloudflare R2 bucket name. REQUIRED.
#   R2_ACCOUNT_ID        Cloudflare account id. REQUIRED.
#   R2_ACCESS_KEY_ID     R2 API token access key id. REQUIRED.
#   R2_SECRET_ACCESS_KEY R2 API token secret access key. REQUIRED.
#   AGENT_LOG_PREFIX     key prefix under the remote. Default "agent-logs".
#   AGENT_LOG_INTERVAL   seconds between passes in `run`. Default 60.
#   AGENT_LOG_HOST_ID    per-container id. Auto-derived if unset.
#   AGENT_LOG_STATE_DIR  cursor/state dir. Default namespaces state by remote.
#   OPENCODE_DELTA_SQL / OPENCODE_CURSOR_SQL   opencode queries; pinned defaults below.

set -euo pipefail

MODE="${1:-run}"

AGENT_LOG_PREFIX="${AGENT_LOG_PREFIX:-agent-logs}"
AGENT_LOG_INTERVAL="${AGENT_LOG_INTERVAL:-60}"
LOCKFILE="${AGENT_LOG_LOCKFILE:-/tmp/agent-log-archiver.lock}"

log() { printf '%s agent-log-archiver: %s\n' "$(date -u +%FT%TZ)" "$*" >&2; }

R2_BUCKET="${R2_BUCKET:-}"
R2_ACCOUNT_ID="${R2_ACCOUNT_ID:-}"
R2_ACCESS_KEY_ID="${R2_ACCESS_KEY_ID:-}"
R2_SECRET_ACCESS_KEY="${R2_SECRET_ACCESS_KEY:-}"

if [ -z "$R2_BUCKET" ] || [ -z "$R2_ACCOUNT_ID" ] || [ -z "$R2_ACCESS_KEY_ID" ] || [ -z "$R2_SECRET_ACCESS_KEY" ]; then
  log "R2_* vars missing; set R2_BUCKET, R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY."
  exit 0
fi

AGENT_LOG_REMOTE="r2:${R2_BUCKET}"
export RCLONE_CONFIG_R2_ENDPOINT="https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com"
export RCLONE_CONFIG_R2_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID"
export RCLONE_CONFIG_R2_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"

# Cursors are namespaced by remote so a manual `once` against a scratch remote
# (see README) can't advance the live loop's cursors and make production skip
# unshipped data. Override wholesale with AGENT_LOG_STATE_DIR.
_state_slug="$(printf '%s' "${AGENT_LOG_REMOTE}" | tr -c 'A-Za-z0-9._-' '-')"
STATE_DIR="${AGENT_LOG_STATE_DIR:-$HOME/.agent-log-archiver/state/$_state_slug}"

# R2 settings all come from RCLONE_CONFIG_R2_* env vars, so there is no config
# file. Point rclone at /dev/null so it stops logging a "config file not found"
# NOTICE on every pass. Overridable if a caller has a real config.
export RCLONE_CONFIG="${RCLONE_CONFIG:-/dev/null}"

# Stable per-container id so concurrent containers don't collide under host=<id>/.
derive_host_id() {
  # DevPod: prefer WORKSPACE_UID (unique per instance) over WORKSPACE_ID (the
  # source-derived name), so two workspaces from the same repo don't collide
  # under one host= prefix.
  local id="${AGENT_LOG_HOST_ID:-${CODESPACE_NAME:-${DEVPOD_WORKSPACE_UID:-${DEVPOD_WORKSPACE_ID:-}}}}"
  if [ -z "$id" ]; then
    local idfile="$HOME/.agent-log-archiver/host-id"
    if [ ! -s "$idfile" ]; then
      mkdir -p "$(dirname "$idfile")"
      cat /proc/sys/kernel/random/uuid >"$idfile"
    fi
    id="$(cat "$idfile")"
  fi
  printf '%s' "$id" | tr -c 'A-Za-z0-9._-' '-'
}

HOST_ID="$(derive_host_id)"
DEST_ROOT="${AGENT_LOG_REMOTE%/}/${AGENT_LOG_PREFIX}/v1"
DEST_BASE="${DEST_ROOT}/host=${HOST_ID}"

# Delta objects have unique names, so upload unconditionally: --no-check-dest
# means no destination LIST/HEAD, just one PUT per new object.
DELTA_FLAGS=(copy --no-check-dest --transfers 4)
if [ -n "${AGENT_LOG_RCLONE_EXTRA:-}" ]; then
  # shellcheck disable=SC2206
  DELTA_FLAGS+=(${AGENT_LOG_RCLONE_EXTRA})
fi

sanitize() { printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '-'; }

# ─────────────────────────────────────────────
# File-based harnesses (claude, codex): append-only JSONL, one file per session
# stream. We track a per-file complete-line cursor and ship only newly appended
# lines each pass. wc -l counts complete lines only, so a half-written trailing
# line is left for the next pass rather than shipped partial.
# ─────────────────────────────────────────────
collect_filelog() {
  local h="$1" src="$2" findroot="$3"
  [ -d "$src" ] || { log "$h: no $src, skip"; return 0; }

  local statef="$STATE_DIR/$h.lines"
  declare -A L=()
  if [ -f "$statef" ]; then
    while IFS=$'\t' read -r k v; do [ -n "$k" ] && L["$k"]="$v"; done <"$statef"
  fi

  local stage changed=0 f rel sid stream prev total out
  stage="$(mktemp -d)"
  while IFS= read -r f; do
    rel="${f#"$src"/}"
    case "$h" in
      claude)
        if [[ "$rel" == */subagents/* ]]; then
          sid="${rel%/subagents/*}"; sid="${sid##*/}"; stream="$(basename "$f" .jsonl)"
        else
          sid="$(basename "$f" .jsonl)"; stream="root"
        fi ;;
      codex)
        sid="$(basename "$f" | grep -oiE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -n1)"
        [ -n "$sid" ] || sid="$(basename "$f" .jsonl)"; stream="rollout" ;;
    esac
    sid="$(sanitize "$sid")"; stream="$(sanitize "$stream")"

    prev="${L[$rel]:-0}"
    total=$(wc -l <"$f" 2>/dev/null || echo 0)
    [ "$total" -lt "$prev" ] && prev=0   # file truncated/replaced -> reship whole
    if [ "$total" -gt "$prev" ]; then
      out="$stage/session=$sid"; mkdir -p "$out"
      awk -v s="$((prev + 1))" -v e="$total" 'NR >= s && NR <= e' "$f" >>"$out/${TICK}-${stream}.jsonl"
      L["$rel"]="$total"; changed=1
    fi
  done < <(find "$findroot" -type f -name '*.jsonl' 2>/dev/null)

  if [ "$changed" -eq 0 ]; then rm -rf "$stage"; log "$h: unchanged, skip"; return 0; fi
  log "$h: shipping deltas"
  if rclone "${DELTA_FLAGS[@]}" "$stage" "${DEST_BASE}/harness=$h"; then
    mkdir -p "$STATE_DIR"; : >"$statef"
    for k in "${!L[@]}"; do printf '%s\t%s\n' "$k" "${L[$k]}" >>"$statef"; done
  else
    log "$h: rclone copy failed (nonfatal)"
  fi
  rm -rf "$stage"
}

collect_claude() { collect_filelog claude "$HOME/.claude" "$HOME/.claude/projects"; }
collect_codex()  { collect_filelog codex  "$HOME/.codex"  "$HOME/.codex/sessions"; }

# ─────────────────────────────────────────────
# opencode: transcript is in opencode.db (SQLite), which also holds account /
# credential tokens — so we export only the session tables, never the file.
# CURSOR_SQL yields the high-water mark (MAX time_updated); DELTA_SQL emits rows
# newer than the cursor as `session_id <TAB> json`. Pinned to the current schema;
# override via env if it changes. __CURSOR__ is substituted with the last mark.
# ─────────────────────────────────────────────
OPENCODE_CURSOR_SQL="${OPENCODE_CURSOR_SQL:-SELECT max(t) FROM (SELECT max(time_updated) t FROM session UNION ALL SELECT max(time_updated) FROM message UNION ALL SELECT max(time_updated) FROM part UNION ALL SELECT max(time_updated) FROM session_message)}"

OPENCODE_DELTA_SQL="${OPENCODE_DELTA_SQL:-SELECT line FROM (
  SELECT id AS sid, time_updated AS tu, id || char(9) || json_object('_t','session','id',id,'time_created',time_created,'time_updated',time_updated,'title',title,'directory',directory,'agent',agent,'model',model) AS line FROM session WHERE time_updated > __CURSOR__
  UNION ALL SELECT session_id, time_updated, session_id || char(9) || json_object('_t','message','id',id,'session_id',session_id,'time_created',time_created,'time_updated',time_updated,'data',CASE WHEN json_valid(data) THEN json(data) ELSE data END) FROM message WHERE time_updated > __CURSOR__
  UNION ALL SELECT session_id, time_updated, session_id || char(9) || json_object('_t','part','id',id,'message_id',message_id,'session_id',session_id,'time_created',time_created,'time_updated',time_updated,'data',CASE WHEN json_valid(data) THEN json(data) ELSE data END) FROM part WHERE time_updated > __CURSOR__
  UNION ALL SELECT session_id, time_updated, session_id || char(9) || json_object('_t','session_message','id',id,'session_id',session_id,'type',type,'seq',seq,'time_created',time_created,'time_updated',time_updated,'data',CASE WHEN json_valid(data) THEN json(data) ELSE data END) FROM session_message WHERE time_updated > __CURSOR__
) ORDER BY tu, sid}"

collect_opencode() {
  local base="$HOME/.local/share/opencode"
  local db="$base/opencode.db"
  [ -e "$db" ] || { log "opencode: no $db, skip"; return 0; }

  local cursf="$STATE_DIR/opencode.cursor" cursor=0
  [ -s "$cursf" ] && cursor="$(cat "$cursf")"
  [ -n "$cursor" ] || cursor=0

  local newmax; newmax="$(sqlite3 -readonly "$db" "$OPENCODE_CURSOR_SQL" 2>/dev/null || true)"
  [ -n "$newmax" ] || { log "opencode: no rows, skip"; return 0; }
  if [ "$newmax" = "$cursor" ]; then log "opencode: unchanged, skip"; return 0; fi

  local stage; stage="$(mktemp -d)"
  trap 'rm -rf "$stage"' RETURN

  if ! sqlite3 -readonly "$db" "${OPENCODE_DELTA_SQL//__CURSOR__/$cursor}" >"$stage/rows.tsv" 2>/dev/null \
     || [ ! -s "$stage/rows.tsv" ]; then
    log "opencode: delta empty/failed (schema drift?); skipping — will NOT ship raw DB (holds secrets)"
    return 0
  fi

  # Partition `sid <TAB> json` rows into per-session delta objects. Sanitize the
  # session id (as sanitize() does elsewhere) before it reaches the shell in
  # system() and the object path.
  awk -F'\t' -v base="$stage" -v tick="$TICK" '
    { sid = $1; gsub(/[^A-Za-z0-9._-]/, "-", sid)
      dir = base "/session=" sid
      if (!(dir in seen)) { system("mkdir -p \"" dir "\""); seen[dir] = 1 }
      line = $0; sub(/^[^\t]*\t/, "", line)
      print line >> (dir "/" tick "-db.jsonl") }' "$stage/rows.tsv"
  rm -f "$stage/rows.tsv"

  log "opencode: shipping deltas ($(find "$stage" -name '*.jsonl' | wc -l) sessions, cursor $cursor -> $newmax)"
  if rclone "${DELTA_FLAGS[@]}" "$stage" "${DEST_BASE}/harness=opencode"; then
    mkdir -p "$STATE_DIR"; printf '%s\n' "$newmax" >"$cursf"
  else
    log "opencode: rclone copy failed (nonfatal)"
  fi
}

ship_manifest() {
  [ -f "$STATE_DIR/.manifest" ] && return 0
  local tmp; tmp="$(mktemp)"
  cat >"$tmp" <<'MD'
# Agent session-log feed (v1)

Immutable, timestamped change feed. Layout:

    host=<id>/harness=<claude|codex|opencode>/session=<sid>/<UTC>-<stream>.jsonl

- Each object holds the JSONL records appended to that session since the prior
  pass. Objects are never rewritten; reconstruct a session by concatenating its
  files in filename (time) order.
- `<UTC>` is the capture tick, e.g. `20260713T151230Z`. `<stream>` distinguishes
  sources within a session: `root` / `agent-*` (claude), `rollout` (codex),
  `db` (opencode).

Record formats are each harness's native JSONL (not normalized):
- claude   — Claude Code transcript lines from ~/.claude/projects/**.
- codex    — Codex rollout lines from ~/.codex/sessions/**.
- opencode — rows exported from opencode.db, each `{"_t":"session|message|part|
  session_message", ...}` with the original `data` nested as JSON. Secret tables
  (account/credential) are never exported.
MD
  if rclone copyto "$tmp" "${DEST_ROOT}/_MANIFEST.md" --no-check-dest 2>/dev/null; then
    mkdir -p "$STATE_DIR"; touch "$STATE_DIR/.manifest"
  fi
  rm -f "$tmp"
}

archive_all() {
  TICK="$(date -u +%Y%m%dT%H%M%SZ)"
  log "pass start ($TICK) -> ${DEST_BASE}"
  # No agent dirs under $HOME almost always means the wrong user (root, HOME=/root).
  if [ ! -d "$HOME/.claude" ] && [ ! -d "$HOME/.codex" ] \
     && [ ! -e "$HOME/.local/share/opencode/opencode.db" ]; then
    log "WARNING: no agent dirs under HOME=$HOME (user=$(id -un)). Wrong user? Pin remoteUser=vscode."
  fi
  ship_manifest
  collect_claude
  collect_codex
  collect_opencode
  log "pass done"
}

case "$MODE" in
  once)
    archive_all
    ;;
  run)
    # Singleton: hold the lock for the process lifetime so a resume (postStart
    # re-fires) never spawns a second loop.
    exec 9>"$LOCKFILE"
    if ! flock -n 9; then
      log "another archiver holds $LOCKFILE; exiting"
      exit 0
    fi

    # Best-effort final flush on stop; the interval already bounds loss to one tick.
    trap 'log "SIGTERM: final flush"; archive_all || true; exit 0' TERM INT

    log "run loop every ${AGENT_LOG_INTERVAL}s (host=${HOST_ID})"
    while true; do
      archive_all || log "pass errored (nonfatal)"
      sleep "$AGENT_LOG_INTERVAL" &
      wait $! || true
    done
    ;;
  *)
    log "usage: $0 {once|run}"
    exit 2
    ;;
esac
