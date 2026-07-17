---
name: update-dotfiles
description: Change this user's chezmoi-managed dotfiles repository and apply the change locally. Use from any repo when asked to modify the dotfiles.
---

# Update dotfiles

The user's environment comes from a [chezmoi](https://chezmoi.io)-managed dotfiles repository (`github.com/shyam-sadeesh/dotfiles`). Use this skill to change that repo and apply the change in the current, live workspace. Do not edit files under `~` directly: edit the chezmoi source and let chezmoi apply. The change is not done until you commit and push it to GitHub.

## 1. Locate the source

Run:

```bash
SRC="$(chezmoi source-path)"   # e.g. ~/.local/share/chezmoi/home  — the source-state root
REPO="$(dirname "$SRC")"       # repo root: install.sh, config/, agent-logging/, README.md
```

If `chezmoi` is missing or `source-path` fails, tell the user - this should not happen if the repo was provisioned correctly.

## 2. The two edit zones

`.chezmoiroot` is `home`, so the repo splits in two:

- **`$SRC` (the `home/` source state)** deploys files under `~`. chezmoi rewrites `dot_` to `.`, so `$SRC/dot_claude/settings.json` deploys to `~/.claude/settings.json` and `$SRC/dot_config/opencode/opencode.json` to `~/.config/opencode/opencode.json`. A `.tmpl` suffix marks a Go template. A `symlink_<name>.tmpl` file becomes a symlink whose target is the rendered template body.
- **`$REPO` (repo root, not under `~`)** holds skill bodies in `config/skills/`, `install.sh`, the `run_*` provisioning scripts, `agent-logging/`, and `README.md`.

Match the surrounding conventions, and run `chezmoi diff` (step 4) to confirm a change lands where you intend before applying.

## 3. Common changes

**Change an agent/tool setting:** edit the file under `$SRC`, such as `$SRC/dot_claude/settings.json`, `$SRC/dot_config/opencode/opencode.json`, or `$SRC/dot_codex/config.toml`.

**Add or edit a skill** (one source, shared across clients):

1. Create `$REPO/config/skills/<name>/SKILL.md` (frontmatter `name` and `description`, then the instructions). Add any helper files alongside it.
2. Register it for each client with a one-line symlink template, exactly:

   ```text
   {{ .chezmoi.sourceDir }}/../config/skills/<name>
   ```

   Place it at `$SRC/dot_claude/skills/symlink_<name>.tmpl` (Claude reads `~/.claude/skills`) and `$SRC/dot_agents/skills/symlink_<name>.tmpl` (Codex reads `~/.agents/skills`).
3. To change an existing skill, edit its `config/skills/<name>/SKILL.md`. The symlinks already point at it.

**Change provisioning, install, or log-export behavior:** understand which class of script you need.

- `install.sh` and `run_once_*` scripts run exactly once per machine (once per chezmoi state dir). They have already run here and will **not** re-run on this workspace. Editing them affects only future fresh containers, not the current one. Do not force them to re-run (e.g. `chezmoi state delete-bucket`) to apply a change to a live machine: they are written to run once and re-running can break idempotency.
- To change how the **current** machine is set up, add a new `run_after_<NN>-<name>.sh` script under `$REPO/home/`. `run_after_*` scripts run on every `chezmoi apply`, so write them to be idempotent — safe to run repeatedly, checking for the desired state before acting.

Reserve `install.sh` / `run_once_*` edits for behavior that only needs to take effect on the next fresh container. These scripts mutate the machine, so read the file and run `chezmoi diff` before applying.

## 4. Apply locally and verify

```bash
chezmoi diff     # preview what changes under ~ (or: chezmoi diff ~/.claude/settings.json)
chezmoi apply    # apply; add -v to see each operation
```

Confirm the deployed file changed by reading the real destination path. For a new skill, check that the symlink resolves to `config/skills/<name>/SKILL.md`. Only `run_after_*` scripts run on this apply; `install.sh` and `run_once_*` scripts have already run and stay dormant, so a new provisioning step must be a `run_after_*` script (see step 3).

## 5. Persist to GitHub (required)

The container is disposable, so an unpushed change is lost on rebuild.

```bash
chezmoi git -- add -A
chezmoi git -- status
chezmoi git -- commit -m "<what changed and why>"
```

Then push to GitHub. The source checkout's `origin` may be a local Codespaces mirror rather than GitHub, so check first:

```bash
chezmoi git -- remote -v
```

- If `origin` is `github.com/shyam-sadeesh/dotfiles`, `chezmoi git -- push` is enough.
- If `origin` is a local path (Codespaces mirror), the commit will not reach GitHub from here. Apply the same edit in a GitHub-tracked checkout and push there. Look for one already on disk (under `/workspaces`, with `git -C <dir> remote -v` showing the GitHub URL), or clone `https://github.com/shyam-sadeesh/dotfiles`, replay the edit, commit, and push.

Follow the user's usual git conventions (branch vs. direct-to-main, commit message style). If you are unsure whether to push straight to `main` or open a pull request, ask.
