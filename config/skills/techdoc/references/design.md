# The visual system

The template implements one look so every techdoc reads as part of the same set. This page records the decisions so they are not re-made per document, and lists the knobs that exist.

## Reference

Zensical (the Material for MkDocs successor) documentation pages: sticky accent header, left contents column, measured article, admonitions with a coloured left rule, tabbed code, titled code blocks. The template reproduces that layout for a single page, with one contents pane on the left (H2 sections, H3 entries nested under the section in view) instead of separate site-nav and on-this-page columns.

## Tokens

| Role | Light | Dark |
|---|---|---|
| Accent | `#3f51b5` indigo (front-matter `accent` overrides) | same hue lifted 55% toward white |
| Ground / surface | `#ffffff` / `#f6f7fb` (indigo-biased greys) | `#1a1c26` / `#21242f` |
| Text / muted | `#1f2330` / `#5d6275` | `#e7e9f2` / `#a3a8bd` |
| Good / warn / bad | `#2e7d32` / `#b26a00` / `#c62828` with soft fills | lifted variants with dark soft fills |

Good, warn and bad are reserved for diff state and admonition types, so green always means added and red always means removed, on every page.

The bare `:root` holds the full light set; `prefers-color-scheme: dark` guarded by `:root:not([data-theme="light"])` and `:root[data-theme="dark"]` redefine tokens only. Components never use a literal colour.

## Type

- Body: Roboto 400/500/700 from Google Fonts, 16px, line-height 1.6, measure 46rem.
- Code: Roboto Mono. Code cards at 0.82rem, inspector tables at 0.8rem.
- Headings: Roboto 500 with slight negative tracking. H1 is 400 weight at 2.1rem; H2 carries a hairline rule; H4 is an uppercase eyebrow.
- Labels (contents, code-card headers, pane labels, status chips): 0.7 to 0.78rem uppercase with letter-spacing.
- Tabular numerals on every table.

## Layout

- Header 3rem, accent background, doc title left, author · date and the Document / Slides toggle right.
- Two columns: contents 15rem, article up to 46rem. The contents pane becomes a drawer below 820px.
- Every diagram and screenshot has an Expand control on hover that opens it in a modal at up to 96% of the viewport with zoom and scrolling. Flow inspectors keep working inside the modal.
- Figures are numbered and captioned; captions are claims. Wide content scrolls inside its own container.
- Slides: one H2 section per slide, 64rem card on the surface ground, progress bar at the bottom, counter bottom-right, hash-addressable.

## Diagram vocabulary

- Node shapes encode kind: rounded = process, header band = table, cylinder = store, accent bar = API/service, diamond = decision, dashed = external.
- Strokes and text use `currentColor` so diagrams follow the theme. The accent marks only the selected node and its edges.
- Edges are cubic curves with one arrowhead marker and labels centred on the edge in the muted colour.
- Diff state: added green, removed red dashed, relabelled amber. A legend appears under any diff.

## Knobs

- `accent` in front matter. Use one hue per team so docs still cluster.
- `mode` in front matter, the initial mode only.
- Raw HTML `<div class="grid"><div class="card">…</div></div>` for side-by-side cards.

Nothing else. A document that needs a different type scale or palette is not a techdoc.

## What the template does not do

- Hero sections, big-number tiles, gradients, emoji section markers.
- Per-document fonts or colours beyond the accent.
- Animation beyond a progress bar and a details toggle. `prefers-reduced-motion` disables transitions.
