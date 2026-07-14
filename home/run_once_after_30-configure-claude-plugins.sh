#!/usr/bin/env bash

set -euo pipefail

log() { printf '[dotfiles] Claude plugins: %s\n' "$*"; }

log "Starting plugin setup."
claude plugin marketplace add anthropics/claude-plugins-official
claude plugin install pyright-lsp@claude-plugins-official
claude plugin install typescript-lsp@claude-plugins-official
log "Plugin setup complete."