"""Every Lean module has a plain-English companion under docs/plain-english/, and vice versa."""

import re
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
LEAN = ROOT / "formal/lean"
DOCS = ROOT / "docs/plain-english"

lean = {p.relative_to(LEAN).with_suffix("") for p in LEAN.rglob("*.lean") if ".lake" not in p.parts}
docs = {p.relative_to(DOCS).with_suffix("") for p in DOCS.rglob("*.md") if p != DOCS / "README.md"}


def test_companions_biject():
    assert (sorted(map(str, lean - docs)), sorted(map(str, docs - lean))) == ([], [])


@pytest.mark.parametrize("rel", sorted(lean & docs), ids=str)
def test_companion_names_its_source(rel):
    md = DOCS / rel.with_suffix(".md")
    lines = md.read_text(encoding="utf-8").splitlines()
    assert lines[0] == f"# {'.'.join(rel.parts)} in Plain English"
    link = re.search(r"^Source: \[`formal/lean/(.+?)`\]\((.+?)\)$", "\n".join(lines), re.M)
    assert link and link[1] == f"{rel.as_posix()}.lean"
    assert (md.parent / link[2]).resolve() == LEAN / f"{rel.as_posix()}.lean"


def test_index_lists_every_companion():
    index = (DOCS / "README.md").read_text(encoding="utf-8")
    assert [r for r in sorted(map(Path.as_posix, docs)) if f"]({r}.md)" not in index] == []
