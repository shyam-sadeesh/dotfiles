---
name: code-review-graph
description: Explain and call the code-review-graph MCP API for codebase navigation and exploration, including graph queries, search, execution flows, communities, architecture, and size reports. Use when a task asks what a code-review-graph tool accepts, returns, or means for exploring a repository, or needs a concrete API call.
---

# Code-review-graph API

Use this skill as an API reference for navigating and exploring a codebase. Describe what each tool returns without recommending code-review-graph or any other tool for review, debugging, refactoring, or similar workflows.

Tool names may appear with a server-generated `_tool` suffix in some clients. The examples use the shorter registered names.

## Conventions

- Omit `repo_root` to use the current repository. Pass it to select another indexed repository.
- Pass repository-relative paths in `changed_files`.
- Where supported, `detail_level="minimal"` returns compact summaries and key entities; `detail_level="standard"` returns structured node, edge, file, or source detail.
- Identify graph nodes with qualified names such as `backend/app/main.py::create_app`. Identify files with repository-relative paths.
- `semantic_search_nodes` uses hybrid keyword/vector search when embeddings exist and falls back to keyword/FTS search otherwise. Results expose qualified identifiers for other calls.
- Common responses contain `status` and `summary`. Some also contain `_hints` or `context_savings`; these are metadata, not graph facts.

## Change exploration

### `get_minimal_context`

Arguments: `task=""`, `changed_files=None`, `repo_root=None`, `base="HEAD~1"`.

Provides an approximately 100-token snapshot of repository or change context: graph node, edge, and file counts; risk and risk score when changes exist; top affected entities; test-gap count; largest communities; critical flows; and server-generated next-tool suggestions.

```text
get_minimal_context(task="summarize the graph", base="main")
```

### `detect_changes`

Arguments: `base="HEAD~1"`, `changed_files=None`, `include_source=False`, `max_depth=2`, `repo_root=None`, `detail_level="standard"`.

Provides git-diff-aware changed functions, affected flows and communities, test gaps, priorities, and an aggregate risk score. Minimal detail provides counts, the risk score, test-gap count, and top priority text. `include_source=True` adds source snippets for changed functions.

```text
detect_changes(base="main", detail_level="minimal")
detect_changes(changed_files=["backend/app/main.py"], include_source=True)
```

### `get_impact_radius`

Arguments: `changed_files=None`, `max_depth=2`, `max_results=500`, `repo_root=None`, `base="HEAD~1"`, `detail_level="standard"`.

Provides directly changed nodes, transitively impacted nodes and files, connecting edges, the total impacted count, and whether results were truncated. Minimal detail provides an impact-derived risk band, impacted-file count, and key entities.

```text
get_impact_radius(changed_files=["backend/app/orchestrator.py"], max_depth=3, detail_level="minimal")
```

### `get_affected_flows`

Arguments: `changed_files=None`, `base="HEAD~1"`, `repo_root=None`.

Provides execution flows that pass through nodes in changed files, sorted by criticality, including flow step details and a total count.

```text
get_affected_flows(changed_files=["backend/app/orchestrator.py"])
```

## Nodes and relationships

### `semantic_search_nodes`

Arguments: `query`, `kind=None`, `limit=20`, `repo_root=None`, `context_files=None`, `model=None`, `provider=None`, `detail_level="standard"`.

Provides ranked matching nodes and the search mode. Filters accept node kinds such as `File`, `Class`, `Function`, `Type`, and `Test`. Minimal results contain up to five names, kinds, file paths, and scores; standard results include qualified names and fuller node metadata.

```text
semantic_search_nodes(query="pipeline", kind="Function", limit=10, detail_level="minimal")
semantic_search_nodes(query="resolve macro", context_files=["backend/app/core/resolve/"])
```

### `query_graph`

Arguments: `pattern`, `target`, `repo_root=None`, `detail_level="standard"`.

Provides nodes and edges matching one predefined relationship query.

| Pattern | Information returned |
| --- | --- |
| `callers_of` | Functions that call the target function |
| `callees_of` | Functions called by the target function |
| `imports_of` | Imports made by the target file or module |
| `importers_of` | Files that import the target file or module |
| `children_of` | Nodes contained in the target file or class |
| `tests_for` | Tests connected to the target function or class |
| `inheritors_of` | Classes that inherit from the target class |
| `file_summary` | Nodes contained in the target file |

Bare names can return `status="ambiguous"` with candidates. Repeat the call with a candidate's qualified name.

```text
query_graph(pattern="callees_of", target="backend/app/main.py::create_app", detail_level="minimal")
query_graph(pattern="file_summary", target="backend/app/orchestrator.py")
```

### `list_graph_stats`

Arguments: `repo_root=None`.

Provides total nodes and edges, counts by node and edge kind, languages, indexed-file count, last update time, and embedding count.

```text
list_graph_stats()
```

### `find_large_functions`

Arguments: `min_lines=50`, `kind=None`, `file_path_pattern=None`, `limit=50`, `repo_root=None`.

Provides functions, classes, files, or tests at or above the line threshold, ordered largest first, with locations and line counts.

```text
find_large_functions(min_lines=100, kind="Function", file_path_pattern="backend/")
```

## Execution flows

### `list_flows`

Arguments: `repo_root=None`, `sort_by="criticality"`, `limit=50`, `kind=None`, `detail_level="standard"`.

Provides stored call chains starting at entry points. Sort values are `criticality`, `depth`, `node_count`, `file_count`, and `name`; `kind` filters by entry-point node kind. Minimal detail contains each flow's name, criticality, and node count.

```text
list_flows(sort_by="depth", limit=10, detail_level="minimal")
```

### `get_flow`

Arguments: `flow_id=None`, `flow_name=None`, `include_source=False`, `repo_root=None`.

Provides one flow's ordered steps, with function names, files, and line numbers. Select by the ID returned from `list_flows` or by a partial name; `flow_id` takes precedence. `include_source=True` adds source snippets for steps.

```text
get_flow(flow_id=12, include_source=False)
get_flow(flow_name="analysis pipeline")
```

## Communities and architecture

### `list_communities`

Arguments: `repo_root=None`, `sort_by="size"`, `min_size=0`, `detail_level="standard"`.

Provides detected clusters of related code entities with size and cohesion. Sort values are `size`, `cohesion`, and `name`. Minimal detail contains name, size, and cohesion.

```text
list_communities(sort_by="cohesion", min_size=5, detail_level="minimal")
```

### `get_community`

Arguments: `community_name=None`, `community_id=None`, `include_members=False`, `repo_root=None`.

Provides one community's metrics and metadata. Select by ID or partial name; `community_id` takes precedence. `include_members=True` adds full member-node details.

```text
get_community(community_name="parsing", include_members=True)
```

### `get_architecture_overview`

Arguments: `repo_root=None`, `detail_level="minimal"`.

Provides communities, cross-community relationships, and coupling warnings. Minimal detail aggregates edges by community pair; standard detail includes member lists and individual cross-community edges.

```text
get_architecture_overview(detail_level="minimal")
```

