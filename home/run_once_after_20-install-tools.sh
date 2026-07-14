#!/usr/bin/env bash

set -euo pipefail

sudo apt-get update
sudo apt-get install -y fd-find pipx ripgrep

npm install -g \
  @anthropic-ai/claude-code@2.1.209 \
  @google/gemini-cli@0.50.0 \
  @openai/codex@0.144.4 \
  pyright@1.1.411 \
  typescript@7.0.2 \
  typescript-language-server@5.3.0

curl -fsSL https://opencode.ai/install | bash
npx -y skills@1.5.17 add antfu/ghfs --agent opencode --yes
npx -y skills@1.5.17 add pydantic/skills --agent opencode --yes

pipx install code-review-graph==2.3.6