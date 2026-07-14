#!/usr/bin/env bash

set -euo pipefail

dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v chezmoi >/dev/null 2>&1; then
  bin_dir="$HOME/.local/bin"
  mkdir -p "$bin_dir"
  curl -fsLS https://get.chezmoi.io | sh -s -- -b "$bin_dir"
  export PATH="$bin_dir:$PATH"
fi

chezmoi init "$dotfiles_dir" --apply
