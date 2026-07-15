#!/usr/bin/env bash

set -euo pipefail

log() { printf '[dotfiles] %s\n' "$*"; }

dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v chezmoi >/dev/null 2>&1; then
  log "Installing chezmoi."
  bin_dir="$HOME/.local/bin"
  mkdir -p "$bin_dir"
  curl -fsLS https://get.chezmoi.io | sh -s -- -b "$bin_dir"
  export PATH="$bin_dir:$PATH"
else
  log "Using installed chezmoi."
fi

log "Applying chezmoi source state."
upstream_url="$(git -C "$dotfiles_dir" remote get-url origin)"
chezmoi init "$dotfiles_dir" --apply
git -C "$(chezmoi source-path)/.." remote set-url origin "$upstream_url"
log "Dotfiles setup complete."
