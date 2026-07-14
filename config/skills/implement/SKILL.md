---
name: implement
description: Implement a code change.
---

# Purpose

Implement a code change.

# Process

## 1. Understand the Change

Before writing code:

* Read the relevant documents in full.
* Identify what can be reused, removed, or extended.
* Decide where the change belongs.
* Define or update the relevant types and public contracts.
* Identify where untyped input is validated and where side-effects occur.
* Determine whether any new dependency is genuinely required.
* Understand what tests are needed.

## 2. Implement

Implement the change.

## 3. Verify

Perform the below checks on your changes. Address unmet checks before proceeding.

* [ ] Tests exercise the real implementation path at the appropriate level.
* [ ] Types, validation, architectural boundaries, and public contracts remain sound.
* [ ] Code is placed with the concern that owns it, and shared logic is not duplicated.
* [ ] Effects remain at system boundaries and core logic remains independently testable.
* [ ] Required dependencies are declared.
* [ ] Repeated operations are deterministic and idempotent where required.
* [ ] The change works through its intended user-facing, command-line, or API workflow.
* [ ] Affected fixtures, scripts, snapshots, generated artifacts, and documentation are updated.
* [ ] No suppressions, stubs, silent fallbacks, or workarounds hide an underlying problem.

Run the simplest possible quality gates to verify your changes (formatting/linting/single file tests, etc.)

## 4. Review

Ask me if I want an independent review - if I say yes, run three independent reviews. Otherwise proceed to the next step.

**do not review the change on the originating model yourself.**
**For all reviews, tell the agents to NOT run any quality gates (tests/lints)**

1. **Fresh same-model subagent:** review using `/design-review`.
2. **Peer model:** review using `/consult`, with the peer applying `/design-review`.
3. **Fresh tiny-model (haiku, 5.4-mini) subagent:** check the code for bugs, faulty or missing logic. Do not use the design-review skill. 

Consolidate duplicate findings and present one table:

| ID | Severity                       | Finding           | Why it matters  | Better shape                      |
| -- | ------------------------------ | ----------------- | --------------- | --------------------------------- |
| 1  | Blocker / Warning / Suggestion | What was observed | The consequence | What a stronger design looks like |

Severity definitions:

* **Blocker:** Incorrect behaviour, failing checks, architectural violation, significant technical debt, or an issue that blocks future work. Must be fixed before merge.
* **Warning:** A meaningful deviation from repository conventions or quality standards. Should be fixed.
* **Suggestion:** An optional improvement.

Walk through the findings with me and ask me which ones to address.
Address the agreed items.
Apply the repository quality gates (tests/lints/etc.)
Create a Pull Request, follow the contributing guidance.
