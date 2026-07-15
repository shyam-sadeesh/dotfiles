---
name: design-review
description: Produce a critique of an architecture document, design document, or code change. Use when asked to review designs or code.
---

# Design Review

## When to Use

Use when asked to review either:
- architecture docs, design documents, or written specifications of system structure, or
- code, such as a pull request.

Produce a review using the template below.

## Philosophy

Channel Raymond Hettinger's recurring themes. These are design instincts, not language trivia; they apply to Python, Go, Rust, and box-and-arrow service diagrams.

- "There must be a better way" - Flag problems and describe the better shape. Prefer changes that delete concepts, branches, helper layers, modes, or special cases rather than rearranging the same complexity.
- Behavior passing is not enough - If the implementation works but makes the system harder to reason about, treat that as a design regression.
- Common case fast, rare case possible - Check whether primary flows are clean and direct, or buried under edge-case abstractions.
- Flat is better than nested - Look for unnecessary layers, over-abstracted hierarchies, and dependency graphs that need a map.
- Name things well - If a component is hard to explain in one sentence, the abstraction is probably wrong. Naming fog is a design smell.
- Separate concerns, not just diagrams - Check whether boundaries sit where change is likely, or whether the pieces all change together.
- Place code where its siblings live - Decide each component's physical home, not just its name. The Nth stage, route, adapter, or DTO belongs with the existing N-1; a stage floating in the package root beside shared-kernel code is a placement smell. Group by concept, keep shared kernel and composition at the root, and flag naming collisions between neighbors, such as `symbols` vs `order_symbols`.
- YAGNI - Call out speculative abstractions, extension points, and config knobs.
- Testability reveals design quality - If something is hard to test, that is a design problem.
- Functional core, imperative shell - Push decisions into a pure core and keep I/O, mutation, and network work at the edges. Mixing pure logic and side effects hurts testing and reasoning.
- Get the data shape right first - Judge whether the design nails its core data shapes before control flow, and whether it makes illegal states unrepresentable instead of relying on runtime invariants the types cannot capture.
- Validate at boundaries; avoid speculative defense - Validation, narrowing, and error handling belong at system edges, with a trusted typed core inside. Flag defensive checks, persistence, retry, recovery, or schema-migration machinery the spec does not require.
- Use the toolkit - Flag custom machinery where the language or platform already has a standard solution.

## Procedure

### 1. Inventory and Context

- Read the target architecture or design documents.
- Identify the intended patterns, conventions, and component boundaries.
- Note the target language, platform, or domain; it determines which idiom-specific lenses apply.
- Know the goal of the design before critiquing how it achieves it.

### 2. External Benchmarking (when it earns its place)

Use this step to catch cases where the community has already converged on a better pattern than the design uses, such as reaching for `pkgutil` package-walking when entry points exist, or building a choreography saga without a transactional outbox. Searching for a standard shape you already know, such as a cache-aside read path or base62 short code, is busywork.

Benchmark when the design leans on a pattern with established prior art and you are not certain the chosen approach is idiomatic. Use web search to find how the relevant community solves this class of problem. Skip it for well-trodden shapes where you already know the standard answer, and do not pad the review with a search that taught you nothing.

### 3. The Critique

Evaluate the design against these lenses while following Raymond's Philosophy. Use tables to organize findings. Use a Mermaid or ASCII diagram for the one or two highest-impact structural findings when layering or call path is clearer as a picture than a table row. Do not diagram for its own sake; if a table says it clearly, leave it as a table.


- Completeness and correctness of vision
  - Does the design or implementation actually solve the problem, or does it solve a different problem?
  - Has the design or code accounted for how the change moves through the codebase, such as how a change to the first step of a multi-step pipeline affects later steps?

- Boundary quality - Are boundaries drawn where change is likely? Do things that change together live together?
  - Is I/O (file upload read, clipboard, `localStorage`, clock, randomness) happening inside logic that could be pure? Can it move to the boundary (event handler or effect)?
  - Is module-level mutable state being read or written? Is that unavoidable, or should it live in the store?

- Coupling and cohesion - Do components know too much about each other's internals? Are unrelated responsibilities bundled?
  - Is this function/component doing two things that should be separated, or two things that always happen together and should be one?
  - How many call sites or components must change if this function's signature or a shared type changes?
  - Is this module importing from another module it should not know about, such as a `lib/` helper importing a React component or `components/` reaching into `lineage/` internals?
  - Does a new component live with its siblings, or float loose, such as the Nth pipeline stage, route, adapter, or DTO in the package root while the other N-1 sit in a concept subpackage? Group by concept; keep only shared kernel and composition at the root.
  - When the layout changes, do the structure docs (`AGENTS.md`, package `__init__` docstrings) still describe reality, or reference moved or deleted dirs?
  - Does changing this behavior require understanding its callers first?
  - Is a broadly-used component or helper being asked to handle a special case only one caller needs?
  - For a shared type, helper, or component change, is "the callers are unaffected" backed by concrete proof, such as every call site listed by `file:line` or the `verify` flow exercising them?

- Abstraction fitness - Are abstractions earning their complexity? Is there a simpler shape underneath?
  - Does this helper exist only because the caller is too complex? Would simplifying the caller remove it?
  - Does this abstraction reduce total complexity, or does it only add indirection?
  - Could a different framing remove this abstraction, branch, mode, or helper entirely?
  - Is this wrapper, dispatcher, or generic mechanism earning its keep, or just moving complexity somewhere else?
  - Is this a special case of something more general that would be simpler?
  - Is this generic when it only needs to support one current scenario?

- Name things well - Can every component, boundary, and concept be explained in one sentence?
  - Is it clear what a function/component does from its name, signature, and prop types alone, without reading the body?
  - Is it clear from a function's name and signature that a side effect occurs, or does the name imply a pure computation?
  - Can you describe what this function/component does in one sentence? If not, is that the code's problem?
  - Do variable names describe what a thing is rather than what it does? (`columnsById` rather than `columnData`)
  - Do sibling file/module names collide or blur, such as two names differing only by a qualifier (`symbols` vs `order_symbols`) where the relationship is not obvious? Rename or co-locate so proximity explains the pairing.
- Flow directness - Do primary flows read top-to-bottom, or zigzag through layers?
  - Did the change add ad-hoc conditionals, one-off flags, nullable modes, or scattered special cases to an existing flow?

- Use the toolkit - Does the design work with the grain of its language, framework, or platform instead of reinventing what the platform provides? Apply this to the target stack. If the design is language-agnostic, judge it against domain idioms such as messaging, storage, or distributed coordination.
  - Could a standard library or language feature replace this (`Array`/`Map`/`Set` methods, `Object` helpers, optional chaining, etc.)?
  - Could an existing project dependency replace this (zustand, dagre, papaparse, lucide-react, react-select, react-window, `@xyflow/react`)?
  - Does an existing function or component in this codebase already do this?
  - Does the data structure fit the access pattern, such as a `Map`/`Set` instead of a scanned array, or a typed interface instead of a loose object?

- YAGNI - Are extension points, config knobs, or abstractions built for futures that do not exist?
  - Are there props, parameters, or branches that no current caller uses?
  - Does a prop, flag, or config option exist for flexibility but have only one value today?
  - Does an abstraction layer exist for an expected second implementation rather than a current need?
  - Are there comments like "we might want to extend this later" attached to complexity added now?
  - Is the type/data model richer than the current feature requires?
  - Is a `try/catch`, `?.`/`??` fallback, default value, or `if (!x) return` guarding a case that cannot occur given the types and data flow? Delete it.
  - Does a guard catch a failure that can occur but has no defined handling, swallowing it and returning a plausible default instead of surfacing it? Prefer throwing to a visible boundary over hiding it.
  - Was a guard added to silence a crash or console error without diagnosing the cause? That is a symptom fix. The finding is the missing root-cause analysis.
  - Does out-of-spec machinery, such as persistence, retry, restart recovery, or schema migration, exist only to be defended? Delete the feature to delete the defensive code it requires.

- Reader load - Count the layers a reader must trace and the state they must hold. Flag indirection that pays for nothing: wrappers with one caller, adapters with one implementation, and state synced where it could be derived. Any proposed layer or state must reduce reader load elsewhere by at least as much as it adds.
  - Would a prop/argument be simpler than reading from the store or module scope?
  - Would data be clearer than code here, such as a config object or lookup map instead of `if`/`else` chains or switch dispatch?
  - Could a runtime check be removed by making the illegal state unrepresentable, such as using a discriminated `kind` union instead of an optional-field bag?
  - Does the change preserve incidental complexity where a simpler model would delete whole branches or states?
  - Is the reason for any non-obvious decision captured: why this approach was chosen, not what the code does?
  - Is there clever code where straightforward code would work just as well?

- Design-space coverage - For a genuinely open decision, such as a novel interaction or an architectural fork with several viable approaches, did the design compare 2-3 alternatives or commit to the first idea? Skip this for mechanical or constraint-forced choices where only one shape works.

- Get the data shape right first - If the design adds a requirement to an existing structure, is it bolted on, or designed as if the requirement had been there from the start? Adapter layers, escape-hatch types, and append-only shape are smells. Ask what the shape would be if built from scratch with this requirement known, and how far the proposal is from that.
  - When this adds another member to a series (core stage, handler, DTO, enum branch), does it match the existing shape: argument order, return style, and field meaning? Flag avoidable drift, such as a bare `tuple`/`dict` where siblings return named results, or a hand-wired multi-call stage where peer stages use one call.
  - Is a `dict[str, Any]`, `object`, or open bag standing in for a fixed shape, such as a one-key options dict, `metadata` bag, or untyped store value? The keys are part of the contract. Prefer a typed field or model.
  - Does a field's meaning depend on a sibling enum/tag, with one attribute carrying several meanings by `kind`/`call_type`? That is a flattened tagged union. Prefer a typed payload per variant.
  - Is the same field protected with `assert x is not None` or non-null `!` at multiple call sites? The type is too loose for all but one variant. Tighten it or split the variant.

- Testability - Can each component be verified in isolation? Are the seams in the right places? Logic that can only be tested by standing up side effects usually means the functional core should move out and side effects should move to the shell.
  - Is the complexity in the right place: pure logic in `lib`/`store`, rendering in components?

- Contract integrity - Are preconditions, return values, mutation, and failure modes explicit in the type or signature?
  - Are there implicit preconditions that are neither checked nor encoded in the types?
  - Can this return `undefined`/`null` unexpectedly? Does the caller handle it without leaning on `!`?
  - Are casts, loose object shapes, optional fields, or fallback branches hiding an invariant that should be explicit at the boundary?
  - Are exceptions used to control normal flow rather than to signal genuinely unexpected conditions?
  - Does this mutate state, props, or caller-owned values in a way the caller would not expect? Zustand state must be updated immutably.
  - Are there silent failure modes, such as a swallowed `catch` that returns a default and hides the problem?
  - Is the same value validated or null-checked repeatedly down a call chain after the boundary narrowed it? Validate once at the edge; trust it after.

- Imperative Shell - Are effects visible, contained, cleaned up, and consistent if they fail?
  - Are side effects (subscriptions, timers, listeners) set up in `useEffect` with correct cleanup, not during render?
  - Is independent work serialized for no design reason?
  - Can related updates leave state half-applied when a clearer atomic update shape is available?
  - If this fails halfway through, does it leave state consistent, or is partial mutation possible?

- Edge-case behavior - Does the design or tests define behavior for empty, large, degenerate, and unusual inputs?
  - What happens with empty input: no rows, empty form fields, or an empty uploaded file? Is that intended?
  - What happens with large input?
  - What happens if a parsing or layout step fails or produces a degenerate result?
  - Are there numeric or string edge cases, such as zero, negative values, very large values, or special characters in user input, that would produce wrong results silently?

### 4. Resolve Open Questions

Before writing findings, identify anything that cannot be determined from the documents alone. Ask me directly; do not park questions in the review.

### 5. Self-Review

Before delivering findings, check:

- Is every critique explained, not just asserted? "This is wrong" is not a finding. "This couples X to Y because..." is.
- Are you reviewing the design, not the designer? Keep the tone constructive.
- Did you acknowledge what is good? A review that is all critique is incomplete.
- Are the findings architectural? Drop purely presentational findings (diagram style, formatting).
- Did you apply idiom-specific lenses only where they fit, rather than forcing a language's conventions onto a design that doesn't use it?
- Could someone act on this without reading the source documents?

# Review Template

<!--
Blocker => incorrect behaviour, broken build, failing tests, architectural violation, significant technical debt, obvious structural regression, spaghetti branching, or unnecessary complexity that blocks future functionality. Must fix before merge.
Warning => deviation from conventions or quality standards. Should be fixed.
Suggestion => optional improvement. Take it or leave it.

Where possible use examples to demonstrate the issue.
-->

Lead with structural regressions and missed simplifications before naming, style, or local cleanup.

| ID  | Severity                       | Finding             | Why it matters | Recommendation                                             |
| --- | ------------------------------ | ------------------- | -------------- | -------------------------------------------------------- |
| 1   | Blocker / Warning / Suggestion | [what you observed] | [consequence]  | [Recommended design or fix] |
