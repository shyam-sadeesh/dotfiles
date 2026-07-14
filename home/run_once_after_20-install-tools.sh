#!/usr/bin/env bash

set -euo pipefail

log() { printf '[dotfiles] tools: %s\n' "$*"; }

log "Starting tool installation."
log "Installing APT packages."
sudo apt-get update
sudo apt-get install -y fd-find pipx ripgrep vim

log "Installing pinned npm packages."
npm install -g \
  @anthropic-ai/claude-code@2.1.209 \
  @google/gemini-cli@0.50.0 \
  @openai/codex@0.144.4 \
  pyright@1.1.411 \
  typescript@7.0.2 \
  typescript-language-server@5.3.0

log "Installing opencode."
curl -fsSL https://opencode.ai/install | bash
log "Installing shared opencode skills."
npx -y skills@1.5.17 add antfu/ghfs --agent opencode --yes
npx -y skills@1.5.17 add pydantic/skills --agent opencode --yes

log "Installing code-review-graph."
pipx install code-review-graph==2.3.6
log "Tool installation complete."