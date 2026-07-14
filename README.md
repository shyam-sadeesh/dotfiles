# Personal workspace setup

## Scope

This repository is only for ephemeral Linux development containers, including GitHub Codespaces and DevPod workspaces. Do not run it on a laptop, desktop, server, or any persistent environment: it installs global tools, replaces AI-tool configuration, adds Git aliases, and may modify `~/.bashrc` when log export is enabled.

The installer expects an Ubuntu/Debian-based image with passwordless `sudo`, Node.js with npm, Git, curl, and Bash. It is intentionally not portable to macOS, Windows, or non-Debian container images.

Chezmoi manages the home-directory configuration in [`home/`](home/). [`.chezmoiroot`](.chezmoiroot) makes it the source state while leaving the installer, documentation, skills, and agent-log implementation at the repository root. Each supported client receives per-skill symlinks to the shared source under [`config/skills/`](config/skills/).

## Install

Both GitHub Codespaces and DevPod recognize the root [`install.sh`](install.sh) entry point automatically. It is executable in Git and must remain at the repository root. It installs chezmoi to `~/.local/bin` when needed, initializes it from this checkout, and applies the source state.

The installer builds the `code-review-graph` index for `GITHUB_WORKSPACE` or `CODESPACE_VSCODE_FOLDER` when either is a Git worktree. Otherwise, it selects the only Git worktree immediately below `/workspaces`. Set `REPOSITORY_LOCATION` only when more than one worktree is present or the repository is elsewhere.

GitHub Codespaces runs the selected dotfiles repository only for new codespaces. Select this repository and enable automatic installation in [Codespaces settings](https://github.com/settings/codespaces). Use VS Code Settings Sync separately for user-scoped VS Code settings, extensions, keybindings, and UI state.

For DevPod, pass this repository with `--dotfiles`, or set `DOTFILES_URL` and `DOTFILES_SCRIPT=install.sh` on the DevPod context. Provide credentials through the workspace or provider's secret/environment-variable configuration, never through repository files.

## Updating configuration

Edit files below [`home/`](home/) when changing a managed destination file. Chezmoi maps `dot_` path components to leading dots; for example, [`home/dot_claude/settings.json`](home/dot_claude/settings.json) is deployed as `~/.claude/settings.json`.

Scripts prefixed `run_once_after_` run once per chezmoi state directory, so they install the base toolchain and build the initial graph index. Scripts prefixed `run_after_` run on every apply and are used for idempotent configuration and opt-in log-export setup. Run `chezmoi diff` before applying manual changes to inspect the managed-file delta.

### Adding a skill

1. Under [`config/skills/`](config/skills/), create `<name>/SKILL.md` with the skill's frontmatter and instructions.
2. Add a `symlink_<name>.tmpl` file under each client directory: [`home/dot_claude/skills/`](home/dot_claude/skills/), [`home/dot_codex/skills/`](home/dot_codex/skills/), and [`home/dot_agents/skills/`](home/dot_agents/skills/). Its content must be:

    ```text
    {{ .chezmoi.sourceDir }}/../config/skills/<name>
    ```

3. Run `chezmoi apply` and confirm each client can discover the new skill.

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
| `R2_BUCKET` | Destination bucket name |
| `R2_ACCOUNT_ID` | Cloudflare account id |
| `R2_ACCESS_KEY_ID` | Scoped R2 token's access key id |
| `R2_SECRET_ACCESS_KEY` | That token's secret |

When `EXPORT_LOGS` is not `1`, the installer does not install the export dependencies or configure the archiver. When enabled, the installer supplies the non-secret Cloudflare R2 backend defaults. The installed archiver runs only when `R2_BUCKET` is set, and it exports only when all required R2 credentials are present (`R2_BUCKET`, `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`). Other knobs (interval, opencode queries) are in `archiver.sh`'s header.

### Security

 Credential *files* are excluded by whitelist and opencode's DB (which holds tokens) is never shipped, only its session tables — but secrets embedded in transcript *text* are not scrubbed.

### Startup

The installer adds a guarded launcher to `~/.bashrc`. It starts after the first interactive shell opens when `R2_BUCKET` is set; the archiver then checks for all required R2 variables (`R2_BUCKET`, `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`) before exporting. The archiver's lock prevents later shells from starting duplicate loops.

State (cursors) is namespaced by remote, so changing `R2_BUCKET` keeps separate cursors and won't make the live loop skip unshipped data. To point a test at the same bucket without touching live cursor state, set an isolated `AGENT_LOG_STATE_DIR`.

The start-up loop logs to `/tmp/agent-log-archiver.log` and is a singleton: the `run` mode holds an `flock` on `/tmp/agent-log-archiver.lock` for its lifetime, so later interactive shells do not double-spawn it. `once` is unlocked and meant for manual tests.

