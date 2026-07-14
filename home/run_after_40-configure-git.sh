#!/usr/bin/env bash

set -euo pipefail

log() { printf '[dotfiles] Git: %s\n' "$*"; }

log "Applying global Git configuration."
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
log "Global Git configuration complete."