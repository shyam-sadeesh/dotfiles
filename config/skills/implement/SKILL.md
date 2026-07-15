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

Apply the repository quality gates (tests/lints/etc.), then create a Pull Request, follow the contributing guidance. I
