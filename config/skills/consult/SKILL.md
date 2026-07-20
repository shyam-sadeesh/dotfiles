---
name: consult
description: Consult a peer frontier model (Claude or Codex) for an independent second opinion on important decisions and reviews.
---

# Consult - AI Brain Trust

Get an independent second opinion from a peer frontier model. You lead: frame the question, query the peer, synthesize both views, and make the final call.

## Pick your peer

Consult the frontier model that is **not** you. Never consult yourself — a model querying itself adds no independent view.

- **If you are Claude** - consult Codex through its CLI:

  ```bash
  codex --yolo exec --skip-git-repo-check "<your prompt here>"
  ```

- **If you are Codex/Opencode** - consult Claude through its CLI:

  ```bash
  claude -p --model claude-opus-4-8 --permission-mode auto "<your prompt here>"
  ```

The peer has full access to the repository and to GitHub through `gh` and `git`, so link to sources instead of pasting them.

Do not consult for trivial decisions; use judgment.

## Process

### 1. Frame and query

Query the peer with a self-contained prompt. Put in it:

- "You are an independent AI advisor. Give your honest, specific recommendation with reasoning, and flag any risks or concerns."
- The full context: the question plus concrete references - file paths, commit IDs, branches, and issue or doc URLs.
- "Answer only. Do not edit or create files."
- "Make good use of web search for prior art, best practices, and documentation."

Do not include your own opinion; it biases the peer. For a **review**, tell the peer to apply the `/design-review` skill and return findings in that template. Both Claude and Codex have `/design-review` installed, so name it explicitly in the prompt. Every review runs on the same rubric.

Allow up to 1200 seconds per peer.

