---
name: brainstorm
description: Research, refine, and file well-formed GitHub issue(s) for a feature or bug.
---

# Purpose

Turn a raw requirement into clear GitHub issue(s) - a bug or an enhancement - filed with `gh`. Research the problem hard, grill me until the ask is sharp, then draft against the repo's issue template, confirm, and file.

If the requirement contains several separable pieces, say so and ask whether I want one issue or several (one run each). Do not cram unrelated work into one ticket.

## Principles

These drive every step. When a specific instruction seems to fight one of these, follow the principle and say why.

- **Plain professional English, terse.** Short sentences, common words, no filler.
- **Research, refine, draft, confirm, file.** In that order.
- **A ticket is a current view, never a history.** Describe what is wanted *now*. Never write changelogs, "Update:", "Scope correction (date)", "originally this said...", or any narration of how the ticket evolved. If the ask changes mid-run, rewrite the section - do not append a correction.
- **Enhancements state WHAT, never HOW.** Capture what I want and what I explicitly do NOT want. No implementation, no file names, no function names, no design. The HOW is decided later, in a design document.
- **Bugs state what is broken and how to reproduce it.** Observed vs. expected behavior, plus minimal repro steps.

## Process

### 1. Understand the requirement

Take my initial ask. Decide the type:

- **Bug** - something behaves wrong. Uses `.github/ISSUE_TEMPLATE/bug.md`.
- **Enhancement** - something new or improved is wanted. Uses `.github/ISSUE_TEMPLATE/issue.md`.

If the type is ambiguous, ask. If the ask is thin, note the gaps - the next two steps will fill them.

### 2. Refine the ask

To sharpen the requirement with me, interview me relentlessly about every aspect of this requirement until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.
Ask the questions one at a time, waiting for feedback on each question before continuing . Asking multiple questions at once is bewildering. Provide examples to frame the question.
If a question can be answered by exploring the codebase, explore the codebase instead.
Drive the questions from what step 2 surfaced. For an enhancement, resolve:

- The problem or use case in one or two sentences.
- What is explicitly **out of scope** - the things this will NOT do. Every edge case research surfaced that I have not ruled in, ask about here.
- Acceptance criteria: observable, checkable outcomes. Include cases that confirm out-of-scope things correctly do nothing / fail.

For a bug, resolve: exact observed behavior, expected behavior, and the minimal steps to reproduce.

Keep grilling to WHAT, not HOW. If I start designing a solution, note it for the Notes section and steer back to the requirement.

### 3. Research the problem

**This step is mandatory.**

Research two ways at once, on the originating model - do not spawn a fresh subagent for this:

- **You** research the codebase for existing behavior, related code, and conventions the ask must respect.
- **The peer model**, via the `/consult` skill: frame the question around my requirement and tell the peer to make heavy use of web search for prior art, best practices, existing conventions, and edge cases.

Consolidate both before the grilling.

The goal of this step is to surface: edge cases I have not considered, scope boundaries, and whether the thing already partly exists. Ask follow up clarifying questions.

### 4. Draft the issue

Draft the body against the chosen template, following each field's own `description` for what belongs there. Fill every section; write "N/A" for a section that genuinely does not apply rather than dropping it.

#### Title

- Lead with the core noun or symptom in the first few words. "Export button does nothing on Safari," not "There is an issue where...".
- Aim for ~50 characters. Drop qualifiers and restated context until only the core remains.
- Plain words, no trailing period, a leading conventional-commit prefix (`fix:` for bugs, `feat:` for enhancements).
- Be specific: "Slice returns 409 before targets are set" beats "Fix backend bug."

### 5. Preview and file

- Show the final title and body, plus the label you intend to attach (`enhancement` or `bug`). Ask for a yes or edits. Loop until approved.
- File with `gh`, writing the body to a temp file and passing `--body-file` - issue bodies contain backticks and `$` that an inline `--body "..."` will mangle:

  ```bash
  gh issue create \
    --title "feat: <title>" \
    --body-file /tmp/issue-body.md \
    --label enhancement
  ```

- Report the issue URL `gh` returns.
