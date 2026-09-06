---
name: techdoc
description: Write a shareable technical document or slide deck as a Claude Artifact from a single markdown file, rendered through a fixed Zensical-style template with interactive data-flow diagrams (click a node to see input rows become output rows), before/after graph and table diffs, mermaid ERDs and sequence diagrams, code with captured output (showboat), and framed screenshots. Use whenever the user asks for a design note, architecture doc, walkthrough, migration write-up, runbook, or deck to share with colleagues, or says "techdoc", "write this up as a doc/deck", "make an artifact for the team". Not for ad-hoc one-off pages that need a bespoke visual identity.
---

# techdoc

One markdown file in, one self-contained HTML page out, published as an Artifact. Every document uses the same template, so a team's docs share chrome, type, palette, diagram vocabulary and both themes. Author content, not CSS.

## Workflow

1. Pin the subject. One page, one job: what should a colleague decide or do after reading it? Write that as the front-matter `description`. Use `mode: doc` for something read top to bottom and `mode: slides` for something presented; the viewer can switch either way.
2. Choose the diagrams before the prose. Pick a block per question the page answers, using `references/diagrams.md`: data moving through steps is a `flow`, two states of a system is a `graph-diff`, two states of a table is a `table-diff`, entities and keys is a mermaid `erDiagram`, who calls whom over time is a mermaid `sequenceDiagram`, a claim about code is a code block with a real `output`.
3. Write the markdown following `references/authoring.md`. Every H2 is a section and a slide. Keep each section to one idea; a slide that scrolls is two slides.
4. Gather evidence. Rows in a `flow` or `table-diff` come from a fixture, a query or a showboat run. Code outputs come from running the code; the showboat skill produces ```` ```python ```` + ```` ```output ```` pairs that render as one card. Screenshots come from the running app. Say "example rows" in the caption when data is illustrative.
5. Build and check.
   ```
   python3 ~/.claude/skills/techdoc/build.py <doc>.md --check        # validates JSON blocks, images, sections
   python3 ~/.claude/skills/techdoc/build.py <doc>.md -o <out>.html  # for the Artifact tool
   python3 ~/.claude/skills/techdoc/build.py <doc>.md --standalone   # only for opening the file locally (adds the mermaid CDN script)
   ```
   Write the HTML to the scratchpad unless the user wants it kept. Keep the `.md` with related docs in the project (for example `docs/`, or `demos/` for showboat-backed walkthroughs) so it can be edited and rebuilt.
6. Publish with the Artifact tool: `file_path` is the built HTML (not `--standalone`; Artifacts render mermaid natively), `favicon` chosen once per doc, `description` from the front matter. Give the user the link. Redeploy to the same file path to update.

Do not restyle the template per document. A document that needs a different look is not a techdoc.

## Front matter

```
---
title: Order Enrichment Service        # page name; short noun phrase, no explainer after a dash
short_title: Overview                  # label of the first nav entry (default "Overview")
description: One sentence saying what the page is for.
author: Data Platform
date: 2026-09-05
status: Draft for review               # optional byline chip
eyebrow: Design note                   # optional small label above the title
mode: doc                              # doc | slides (initial mode; viewer can toggle)
accent: "#3f51b5"                      # optional 6-digit hex; default is the shared indigo
---
```

## Block vocabulary

Syntax and JSON schemas are in `references/authoring.md`.

| Block | Shows | Interactive |
|---|---|---|
| ```` ```flow ```` JSON | Layered DAG of tables, processes, APIs, stores, decisions | Click a node: note, SQL/code, input rows vs output rows with changed cells and added/dropped columns highlighted |
| ```` ```graph-diff ```` JSON | Two DAGs side by side with added, removed and relabelled nodes and edges coloured, plus counts | No |
| ```` ```table-diff ```` JSON | One merged table keyed by a column; rows marked added, removed or changed, old→new in cells | No |
| ```` ```mermaid ```` | ERD, sequence, state, class, gantt, flowchart | Native in Artifacts |
| ```` ```python ```` then ```` ```output ```` | Code card with its captured result attached (showboat format) | Copy button |
| `![screenshot: alt](img.png "https://url Caption")` | Screenshot in a browser frame with the URL in the bar | No |
| `!!! note "Title"` / `??? question "Title"` | Admonition / collapsible admonition | Toggle |
| `=== "Tab"` | Content tabs (SQL / Python / SAS variants of one idea) | Tabs |
| ```` ```notes ```` | Speaker notes, hidden in doc mode, `n` toggles in slides | Keyboard |

Every diagram and screenshot has an Expand control on hover that opens it full-screen with zoom, so draw at the detail the mechanism needs and let article width be the overview.

## Rules of thumb

- Lead with the diagram that carries the decision, then explain it. The first section after the title is the one people paste into Slack.
- Label edges. `1 row / order`, `nightly`, `lookup` are information; a bare arrow means "related somehow".
- Show the delta. For before/after use `graph-diff` or `table-diff` so the reader can point at what changed.
- Keep samples small. Two to four rows per node show a transformation; the inspector caps at 25.
- Every code block that makes a claim has an output block. Without one it is a listing.
- Captions state the claim ("Prices lag by a day because the join reads a snapshot"), not the object ("Diagram of the pipeline").
- One H2 per idea: three to six sections for a note, eight to fifteen for a deck.
- Repo prose rules apply: no hard-wrapped paragraphs, plain sentences, no decoration.

## Files

- `template.html`: the shared page. Light and dark tokens, layout (header, contents pane, article), renderer for the block vocabulary, figure lightbox, slides mode.
- `build.py`: stdlib-only builder and validator. Embeds the markdown and inlines images.
- `references/authoring.md`: syntax and JSON schemas for every block.
- `references/diagrams.md`: which diagram answers which question.
- `references/design.md`: the visual system the template implements and its two knobs.
