#!/usr/bin/env python3
"""Build a techdoc HTML page from a markdown source.

Usage:
    python3 ~/.claude/skills/techdoc/build.py doc.md [-o out.html] [--standalone] [--check]

Standard library only. The markdown is embedded verbatim into template.html and rendered
client-side, so the output is a single self-contained file: local images are inlined as
data URIs. `--standalone` adds the mermaid CDN script for viewing outside Artifacts
(Artifacts render `<pre class="mermaid">` natively). `--check` validates without writing.
"""
from __future__ import annotations

import argparse
import base64
import json
import mimetypes
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
TEMPLATE = HERE / "template.html"
STANDALONE_SCRIPTS = '<script src="https://cdnjs.cloudflare.com/ajax/libs/mermaid/11.6.0/mermaid.min.js"></script>'
DEFAULT_ACCENT = "#3f51b5"
FENCE_RE = re.compile(r"^(`{3,}|~{3,})\s*([\w-]+)?(.*)$")
IMG_MD_RE = re.compile(r"(!\[[^\]]*\]\()([^)\s]+)((?:\s+\"[^\"]*\")?\))")
IMG_HTML_RE = re.compile(r"(<img\b[^>]*\bsrc=\")([^\"]+)(\")")


def parse_front_matter(text: str) -> tuple[dict, str]:
    if not text.startswith("---\n"):
        return {}, text
    end = text.find("\n---\n", 4)
    if end < 0:
        return {}, text
    front: dict = {}
    for line in text[4:end].splitlines():
        if ":" not in line or line.lstrip().startswith("#"):
            continue
        key, _, value = line.partition(":")
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        front[key.strip()] = value
    return front, text[end + 5 :]


def data_uri(path: Path) -> str:
    mime = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
    return f"data:{mime};base64,{base64.b64encode(path.read_bytes()).decode()}"


def inline_images(md: str, base: Path, problems: list[str]) -> str:
    def swap(match: re.Match) -> str:
        src = match.group(2)
        if re.match(r"^(https?:|data:|#)", src):
            return match.group(0)
        path = (base / src).resolve()
        if not path.is_file():
            problems.append(f"image not found: {src}")
            return match.group(0)
        return f"{match.group(1)}{data_uri(path)}{match.group(3)}"

    return IMG_HTML_RE.sub(swap, IMG_MD_RE.sub(swap, md))


def iter_fences(md: str):
    """Yield (line_no, lang, body) for every fenced block, ignoring fences nested in indented blocks."""
    lines = md.splitlines()
    i = 0
    while i < len(lines):
        m = FENCE_RE.match(lines[i])
        if m and not lines[i].startswith("    "):
            fence, lang = m.group(1), (m.group(2) or "")
            start = i
            i += 1
            body: list[str] = []
            while i < len(lines) and not lines[i].startswith(fence[0] * len(fence)):
                body.append(lines[i])
                i += 1
            yield start + 1, lang, "\n".join(body)
        i += 1


def check_flow(graph: dict, where: str, problems: list[str]) -> None:
    nodes = graph.get("nodes")
    if not isinstance(nodes, list) or not nodes:
        problems.append(f"{where}: 'nodes' must be a non-empty list")
        return
    ids = set()
    for n in nodes:
        nid = n.get("id") if isinstance(n, dict) else None
        if not nid:
            problems.append(f"{where}: every node needs an 'id'")
            continue
        if nid in ids:
            problems.append(f"{where}: duplicate node id {nid!r}")
        ids.add(nid)
        for side in ("input", "output"):
            table = n.get(side)
            if table is None:
                continue
            cols, rows = table.get("columns"), table.get("rows", [])
            if not isinstance(cols, list):
                problems.append(f"{where}: node {nid!r} {side} needs 'columns'")
                continue
            for r in rows:
                if len(r) != len(cols):
                    problems.append(f"{where}: node {nid!r} {side} row {r!r} has {len(r)} cells for {len(cols)} columns")
                    break
    for e in graph.get("edges", []):
        for end in ("from", "to"):
            if e.get(end) not in ids:
                problems.append(f"{where}: edge {end}={e.get(end)!r} does not name a node")


def check_table(table: dict, where: str, problems: list[str]) -> None:
    cols, rows = table.get("columns"), table.get("rows", [])
    if not isinstance(cols, list):
        problems.append(f"{where}: needs 'columns'")
        return
    for r in rows:
        if len(r) != len(cols):
            problems.append(f"{where}: row {r!r} has {len(r)} cells for {len(cols)} columns")
            break


def check_blocks(md: str, problems: list[str]) -> dict:
    counts: dict[str, int] = {}
    for line_no, lang, body in iter_fences(md):
        counts[lang or "(plain)"] = counts.get(lang or "(plain)", 0) + 1
        if lang not in {"flow", "graph-diff", "table-diff"}:
            continue
        where = f"line {line_no} ```{lang}"
        try:
            data = json.loads(body)
        except json.JSONDecodeError as exc:
            problems.append(f"{where}: invalid JSON ({exc.msg} at line {exc.lineno})")
            continue
        if lang == "flow":
            check_flow(data, where, problems)
        elif lang == "graph-diff":
            for side in ("before", "after"):
                if side not in data:
                    problems.append(f"{where}: missing '{side}'")
                else:
                    check_flow(data[side], f"{where} {side}", problems)
        else:
            for side in ("before", "after"):
                if side not in data:
                    problems.append(f"{where}: missing '{side}'")
                else:
                    check_table(data[side], f"{where} {side}", problems)
    return counts


def build(source: Path, out: Path | None, standalone: bool, check_only: bool) -> int:
    text = source.read_text(encoding="utf-8")
    front, md = parse_front_matter(text)
    problems: list[str] = []
    md = inline_images(md, source.parent, problems)
    counts = check_blocks(md, problems)
    title = front.get("title")
    if not title:
        h1 = re.search(r"^#\s+(.+)$", md, re.M)
        title = h1.group(1).strip() if h1 else source.stem.replace("_", " ").title()
        front["title"] = title
    if not re.search(r"^##\s+", md, re.M):
        problems.append("no '## ' headings: the document has no sections, so slides mode has one slide")
    if problems:
        print("techdoc: problems found", file=sys.stderr)
        for p in problems:
            print(f"  - {p}", file=sys.stderr)
    summary = ", ".join(f"{k}×{v}" for k, v in sorted(counts.items()))
    print(f"techdoc: {source.name}: title={title!r} blocks: {summary or 'none'}")
    if problems and any("invalid JSON" in p or "does not name a node" in p for p in problems):
        return 1
    if check_only:
        return 0
    accent = front.get("accent", DEFAULT_ACCENT)
    if not re.fullmatch(r"#[0-9a-fA-F]{6}", accent):
        print(f"techdoc: accent {accent!r} is not a 6-digit hex colour, using {DEFAULT_ACCENT}", file=sys.stderr)
        accent = DEFAULT_ACCENT
    html = TEMPLATE.read_text(encoding="utf-8")
    html = html.replace("__TECHDOC_TITLE__", title.replace("<", "&lt;"))
    html = html.replace("__TECHDOC_ACCENT__", accent)
    html = html.replace("__TECHDOC_FRONT__", json.dumps(front))
    html = html.replace("__TECHDOC_STANDALONE_SCRIPTS__", STANDALONE_SCRIPTS if standalone else "")
    html = html.replace("__TECHDOC_MARKDOWN__", md.replace("</script", "<\\/script"))
    out = out or source.with_suffix(".html")
    out.write_text(html, encoding="utf-8")
    size = out.stat().st_size
    print(f"techdoc: wrote {out} ({size / 1024:.0f} KB{' — over the 16 MB artifact limit' if size > 16 * 1024 * 1024 else ''})")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("source", type=Path)
    ap.add_argument("-o", "--out", type=Path)
    ap.add_argument("--standalone", action="store_true", help="add the mermaid CDN script for viewing outside Artifacts")
    ap.add_argument("--check", action="store_true", help="validate front matter, images and diagram JSON without writing")
    args = ap.parse_args()
    return build(args.source, args.out, args.standalone, args.check)


if __name__ == "__main__":
    sys.exit(main())
