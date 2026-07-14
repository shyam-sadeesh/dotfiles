#!/usr/bin/env bash

set -euo pipefail

dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$HOME/.claude/skills" "$HOME/.agent/skills"
cp -a "$dotfiles_dir/config/skills/." "$HOME/.claude/skills/"
cp -a "$dotfiles_dir/config/skills/." "$HOME/.agent/skills/"

install -D -m 0644 "$dotfiles_dir/config/claude/settings.json" "$HOME/.claude/settings.json"
install -D -m 0644 "$dotfiles_dir/config/codex/config.toml" "$HOME/.codex/config.toml"
install -D -m 0644 "$dotfiles_dir/config/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"

sudo apt-get update
sudo apt-get install -y fd-find pipx ripgrep

npm install -g \
  @anthropic-ai/claude-code \
  @google/gemini-cli \
  @openai/codex \
  pyright \
  typescript \
  typescript-language-server

curl -fsSL https://opencode.ai/install | bash
npx -y skills add antfu/ghfs --agent opencode --yes
npx -y skills add pydantic/skills --agent opencode --yes

git config --global push.autoSetupRemote true
git config --global alias.st 'status --short --branch'
git config --global alias.aa 'add --all'
git config --global alias.cm 'commit -m'
git config --global alias.ca 'commit --amend --no-edit'
git config --global alias.s 'switch'
git config --global alias.sc 'switch --create'
git config --global alias.sp '!f() { git switch "$1" && git pull --ff-only; }; f'
git config --global alias.fp 'push --force-with-lease'
git config --global alias.wta 'worktree add -b'
git config --global alias.acp '!git add --all && git commit --amend --no-edit && git push --force-with-lease'

touch "$HOME/.bash_aliases"
grep -qxF "alias find='fdfind'" "$HOME/.bash_aliases" || echo "alias find='fdfind'" >> "$HOME/.bash_aliases"
grep -qxF "alias grep='rg'" "$HOME/.bash_aliases" || echo "alias grep='rg'" >> "$HOME/.bash_aliases"

claude plugin marketplace add anthropics/claude-plugins-official
claude plugin install pyright-lsp@claude-plugins-official
claude plugin install typescript-lsp@claude-plugins-official

pipx install code-review-graph
: "${REPOSITORY_LOCATION:?REPOSITORY_LOCATION must point to the workspace repository}"
code-review-graph build --repo "$REPOSITORY_LOCATION"

if [ "${EXPORT_LOGS:-0}" = "1" ]; then
  sudo apt-get install -y rclone sqlite3

  install_dir="$HOME/.local/share/dotfiles/agent-logging"
  mkdir -p "$install_dir"
  install -m 0755 "$dotfiles_dir/agent-logging/archiver.sh" "$install_dir/archiver.sh"

  launcher='if [ -n "${AGENT_LOG_REMOTE:-}" ]; then setsid bash "$HOME/.local/share/dotfiles/agent-logging/archiver.sh" run </dev/null >>/tmp/agent-log-archiver.log 2>&1 & fi'
  touch "$HOME/.bashrc"
  for setting in \
    'export RCLONE_CONFIG_R2_TYPE=s3' \
    'export RCLONE_CONFIG_R2_PROVIDER=Cloudflare' \
    'export RCLONE_CONFIG_R2_REGION=auto' \
    'export RCLONE_CONFIG_R2_ENV_AUTH=false' \
    'export RCLONE_CONFIG_R2_NO_CHECK_BUCKET=true' \
    'export RCLONE_CONFIG_R2_NO_HEAD=true'; do
    grep -qxF "$setting" "$HOME/.bashrc" || printf '%s\n' "$setting" >> "$HOME/.bashrc"
  done
  grep -qxF "$launcher" "$HOME/.bashrc" || printf '\n%s\n' "$launcher" >> "$HOME/.bashrc"
fi
