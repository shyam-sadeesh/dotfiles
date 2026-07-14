# Personal workspace setup

## Scope

This repository is only for ephemeral Linux development containers, including GitHub Codespaces and DevPod workspaces. Do not run it on a laptop, desktop, server, or any persistent environment: it installs global tools, replaces AI-tool configuration, adds Git aliases, and may modify `~/.bashrc` when log export is enabled.

The installer expects an Ubuntu/Debian-based image with passwordless `sudo`, Node.js with npm, Git, curl, and Bash. It is intentionally not portable to macOS, Windows, or non-Debian container images.

## Install

Both GitHub Codespaces and DevPod recognize the root [`install.sh`](install.sh) entry point automatically. It is executable in Git and must remain at the repository root.

Set `REPOSITORY_LOCATION` to the repository being developed before the installer runs. The installer uses it to build the `code-review-graph` index.

GitHub Codespaces runs the selected dotfiles repository only for new codespaces. Select this repository and enable automatic installation in [Codespaces settings](https://github.com/settings/codespaces). Use VS Code Settings Sync separately for user-scoped VS Code settings, extensions, keybindings, and UI state.

For DevPod, pass this repository with `--dotfiles`, or set `DOTFILES_URL` and `DOTFILES_SCRIPT=install.sh` on the DevPod context. Provide credentials through the workspace or provider's secret/environment-variable configuration, never through repository files.

## Agent log archiver

Agent-log export is opt-in. Set `EXPORT_LOGS=1` when running the installer to install and configure the archiver. 

Ships Claude Code, Codex, and opencode session logs from a development workspace to Cloudflare R2 as a timestamped change feed via [`archiver.sh`](agent-logging/archiver.sh).

### Layout

Each pass captures only what is new since the last, as per-session objects — never overwritten. Reconstruct a session by concatenating its files in name order.

```text
agent-logs/v1/
├── _MANIFEST.md                        # feed schema
└── host=<id>/                          # AGENT_LOG_HOST_ID / CODESPACE_NAME / DEVPOD_WORKSPACE_UID / DEVPOD_WORKSPACE_ID / uuid
    ├── harness=claude/
    │   └── session=<uuid>/
    │       ├── 20260713T155335Z-root.jsonl        # one pass's new lines
    │       ├── 20260713T161311Z-root.jsonl        # next pass's new lines (append-only)
    │       └── 20260713T161311Z-agent-<id>.jsonl  # subagent stream
    ├── harness=codex/
    │   └── session=<uuid>/20260713T161311Z-rollout.jsonl
    └── harness=opencode/
        └── session=<ses_…>/20260713T161311Z-db.jsonl
```

`<UTC>-<stream>` = capture tick + source stream (`root`/`agent-*`, `rollout`, `db`). Records are each harness's native JSONL — see `_MANIFEST.md`. Idle sources do zero R2 ops.

### Setup (credentials)

Create a scoped R2 API token (**Object Read & Write**, one bucket), then expose the following variables inside the workspace. Credentials remain environment variables and must not be committed.

| Variable | What |
| --- | --- |
| `AGENT_LOG_REMOTE` | Destination, normally `r2:<bucket>` |
| `RCLONE_CONFIG_R2_ENDPOINT` | `https://<account-id>.r2.cloudflarestorage.com` |
| `RCLONE_CONFIG_R2_ACCESS_KEY_ID` | Scoped R2 token's access key id |
| `RCLONE_CONFIG_R2_SECRET_ACCESS_KEY` | That token's secret |

When `EXPORT_LOGS` is not `1`, the installer does not install the export dependencies or configure the archiver. When enabled, the installer supplies the non-secret Cloudflare R2 backend defaults. If `AGENT_LOG_REMOTE` is unset, the installed archiver does not start. Other knobs (interval, opencode queries) are in `archiver.sh`'s header.

### Security

Transcripts contain plaintext secrets typed or echoed in sessions — keep the bucket **private**, scope the token to it alone, and set a short **lifecycle expiry**. Credential *files* are excluded by whitelist and opencode's DB (which holds tokens) is never shipped, only its session tables — but secrets embedded in transcript *text* are not scrubbed.

### Startup

The installer adds a guarded launcher to `~/.bashrc`. It starts after the first interactive shell opens and only when `AGENT_LOG_REMOTE` is set. The archiver's lock prevents later shells from starting duplicate loops.

### Run manually

```bash
# A bare local path works as a remote, so you can test the layout without R2:
AGENT_LOG_REMOTE=/tmp/r2sim bash ~/.local/share/dotfiles/agent-logging/archiver.sh once
```

State (cursors) is namespaced by remote, so a `once` against a scratch remote keeps its own cursors and won't make the live R2 loop skip unshipped data. To point a test at the *same* remote as the running loop without touching its state, set an isolated `AGENT_LOG_STATE_DIR`.

The start-up loop logs to `/tmp/agent-log-archiver.log` and is a singleton: the `run` mode holds an `flock` on `/tmp/agent-log-archiver.lock` for its lifetime, so later interactive shells do not double-spawn it. `once` is unlocked and meant for manual tests.

