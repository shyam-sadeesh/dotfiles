# Choosing the diagram

A diagram earns its place when a cold reader sees a mechanism they would otherwise assemble from prose. Draw the mechanism, not its name. Label the arrows. Match complexity to what the decision turns on.

| Question the reader has | Block | Why |
|---|---|---|
| What happens to a record as it passes through this API, job or pipeline? | `flow` with `input`/`output` on each node | The reader clicks a step and sees the rows change; column adds, drops and value edits are highlighted. |
| Which tables feed which, in what order? | `flow` with `table` and `process` nodes, no data | Layered DAG, edges labelled with grain (`1 row / order`) or cadence (`hourly`). |
| What did the migration or refactor change in the lineage? | `graph-diff` | Only the delta is coloured and the summary line gives counts. Two separate diagrams make the reader diff by eye. |
| Which rows differ after the change, and how? | `table-diff` | Keyed merge shows added, removed and changed rows in one table with old→new. |
| What are the entities, keys and cardinalities? | `mermaid erDiagram` | Standard ERD notation with PK/FK marks. |
| Who calls whom, in what order, and what comes back? | `mermaid sequenceDiagram` | Lifelines carry time; `alt`/`loop` blocks show branches and retries. |
| What states can a batch, job or record be in? | `mermaid stateDiagram-v2` | Transitions with guards, terminal states explicit. |
| How is the run scheduled and how long do stages take? | `mermaid gantt` | Only if durations matter; otherwise a table. |
| Does this code do what I claim? | code block + `output` | Real output beats a prose assertion. |
| What does the operator or user see? | `screenshot` image | Framed with the URL so the reader knows where to go. |
| Which option are we choosing between? | `graph-diff` with `before_label`/`after_label` set to the option names | A comparison is a picture of the difference, not two labelled boxes. |

## Patterns that work

- API processing data: one `flow` from source table through each processing node with `input`/`output` samples to the sink tables. Set `select` to the node the doc is about so it opens expanded, and put that node's SQL or code on it so rows and logic sit together. Keep samples to two to four rows, with row *i* the same entity before and after; the inspector diff depends on it.
- Before/after lineage: one `graph-diff`, then one paragraph on why the removed edge was wrong and what the added node guarantees. Follow with a `table-diff` of a replayed batch when you can produce one; it is the strongest evidence a change did what it claims.
- Contract table: a markdown table with Field / Type / Source / Notes after the flow. Source is the node id or table; Notes is where nulls and grain live.
- Run this yourself: a showboat code + output pair, then `=== "SQL"` / `=== "Python"` / `=== "SAS"` tabs when the same check exists in several languages.
- Operational view: one screenshot in a browser frame with the real URL, captioned with what to look at.

## Patterns to avoid

- A mermaid flowchart and a `flow` of the same pipeline. Pick `flow` if the reader needs data, mermaid if they need a shape the `flow` layout cannot make.
- A `flow` whose nodes have no `note`, `input` or `output`. The click hint only appears when some node has data; if nothing is inspectable, use mermaid.
- Placeholder rows (`foo`, `123`). Use rows from a fixture or query, and say "example rows" in the caption when they are illustrative.
- A `graph-diff` between unrelated systems. Diff means shared ids; with no matches everything is red and green and the picture says nothing.
- Twenty-node diagrams. Cut to the part the decision hinges on and link to the full lineage elsewhere.

## Mermaid snippets to copy

```
erDiagram
    DIM_CUSTOMER ||--o{ FACT_ORDER_LINE : segments
    FACT_ORDER_LINE {
        string order_id PK
        string sku PK
        decimal line_total
    }
```

```
sequenceDiagram
    participant S as Scheduler
    participant A as API
    S->>A: POST /batches
    alt gate passes
        A-->>S: 200
    else
        A-->>S: 422
    end
```

```
stateDiagram-v2
    [*] --> landed
    landed --> enriched: join ok
    enriched --> published: gate pass
    enriched --> quarantined: gate fail
    published --> [*]
```
