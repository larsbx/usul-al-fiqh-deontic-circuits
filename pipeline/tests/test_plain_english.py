"""Every Lean module has a plain-English companion under docs/plain-english/, and vice versa."""

import re
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
ROOTS = (ROOT / "formal/lean", ROOT / "formal/lean-mathlib")
DOCS = ROOT / "docs/plain-english"

modules = {p.relative_to(r).with_suffix(""): r for r in ROOTS for p in r.rglob("*.lean") if ".lake" not in p.relative_to(r).parts}
lean = set(modules)
docs = {p.relative_to(DOCS).with_suffix("") for p in DOCS.rglob("*.md") if p != DOCS / "README.md"}


def test_companions_biject():
    assert (sorted(map(str, lean - docs)), sorted(map(str, docs - lean))) == ([], [])


@pytest.mark.parametrize("rel", sorted(lean & docs), ids=str)
def test_companion_names_its_source(rel):
    md, src = DOCS / rel.with_suffix(".md"), modules[rel] / f"{rel.as_posix()}.lean"
    lines = md.read_text(encoding="utf-8").splitlines()
    assert lines[0] == f"# {'.'.join(rel.parts)} in Plain English"
    link = re.search(r"^Source: \[`(.+?)`\]\((.+?)\)$", "\n".join(lines), re.M)
    assert link and link[1] == src.relative_to(ROOT).as_posix()
    assert (md.parent / link[2]).resolve() == src


def test_index_lists_every_companion():
    index = (DOCS / "README.md").read_text(encoding="utf-8")
    assert [r for r in sorted(map(Path.as_posix, docs)) if f"]({r}.md)" not in index] == []
