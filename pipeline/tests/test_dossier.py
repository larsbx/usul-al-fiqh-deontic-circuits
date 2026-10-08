"""The dossier of adopted principles and the glossary: every closure cited, every citation
resolvable and verbatim, every constant checked, every page generated."""

import json
from pathlib import Path

import jsonschema
import pytest

from usul_corpus import takhrij
from usul_corpus.arabic import locate
from usul_corpus.__main__ import CACHE, DOSSIER, GLOSSARY, docs_pages
from usul_corpus.records import EXCERPT_LEN

ROOT = Path(__file__).parents[2]


def _json(p):
    return json.loads(p.read_text(encoding="utf-8"))


DOSS, GLOSS = _json(DOSSIER), _json(GLOSSARY)
RECORDS = {r["id"] for f in (ROOT / "corpus/records").glob("*.jsonl") for r in map(json.loads, f.read_text().splitlines())}
RIGHTS = {w["id"]: work["rights"] for work in _json(ROOT / "corpus/registry.json")["works"] for w in work["witnesses"]}
REFS = [r for e in DOSS["entries"] for r in (e["statement"], *e["refs"])] + [r for t in GLOSS["terms"] for r in t["refs"]]


def test_schemas():
    jsonschema.validate(DOSS, _json(ROOT / "schemas/dossier.schema.json"))
    jsonschema.validate(GLOSS, _json(ROOT / "schemas/glossary.schema.json"))
    for xs, k in ((DOSS["entries"], "id"), (GLOSS["terms"], "key")):
        assert len({x[k] for x in xs}) == len(xs)


def test_refs_resolve_within_their_limits():
    """A ref is a committed record (which carries its own excerpt) or a locator into a registered
    witness, with an inline excerpt no longer than that witness's rights allow."""
    for r in REFS:
        if r["ref"].startswith("src:"):
            w = r["ref"][4:].split("/")[0]
            assert w in RIGHTS and "excerpt_ar" in r, r["ref"]
            assert len(r["excerpt_ar"]) <= EXCERPT_LEN[RIGHTS[w]], r["ref"]
        else:
            assert r["ref"] in RECORDS and "excerpt_ar" not in r, r["ref"]


@pytest.mark.parametrize("ref", [r for r in REFS if "excerpt_ar" in r], ids=lambda r: r["ref"])
def test_excerpts_are_verbatim(ref):
    """Letters-only comparison against the cached witness, and the page is the one the excerpt
    ends on (the next page marker). Skipped where the witness is not cached (CI)."""
    w, loc = ref["ref"][4:].split("/")
    src = CACHE / f"{w}.txt"
    if not src.exists():
        pytest.skip(f"{w} not cached")
    assert locate(src.read_text(encoding="utf-8"), ref["excerpt_ar"]) == loc, ref["ref"]


def test_every_closure_is_cited():
    """No gap closes without a cited rationale: each revisit's `closed_by` is some entry's
    `closes`, and an entry closes only what the bank provides."""
    closes = {t for e in DOSS["entries"] for t in e["closes"]}
    closed = {t for c in takhrij.load(ROOT / "corpus") if c.get("revisit") for t in c["revisit"]["closed_by"]}
    assert closed <= closes, closed - closes
    assert closes <= takhrij.provides(), closes - takhrij.provides()


def test_entries_are_linked():
    """Terms are glossary keys, the conservativity theorem is among the entry's constants,
    register questions exist, and every constant is #check-ed."""
    keys = {t["key"] for t in GLOSS["terms"]}
    iqs = {q["id"] for q in _json(ROOT / "corpus/review/sadi_interpretive_questions.json")["questions"]}
    checked = (ROOT / "formal/lean/UsulTest/SignatureMap.lean").read_text()
    for e in DOSS["entries"]:
        assert set(e["terms"]) <= keys, (e["id"], set(e["terms"]) - keys)
        assert e["conservative"] in (None, *e["lean"]), e["id"]
        assert set(e["iq"]) <= iqs, e["id"]
    for t in GLOSS["terms"]:
        assert set(t.get("related", [])) <= keys, t["key"]
    lean = [n for e in DOSS["entries"] for n in e["lean"]] + [n for t in GLOSS["terms"] for n in t.get("lean", [])]
    assert all(f"#check @{n}\n" in checked for n in lean), [n for n in lean if f"#check @{n}\n" not in checked]


def test_refinement_closures_are_conservative():
    """A closure that refines the case's own earlier reading (closed under the encoder it had)
    names a conservativity theorem; a new encoder beside the old ones changes no earlier result."""
    refined = {t for c in takhrij.load(ROOT / "corpus") if (r := c.get("revisit")) and r.get("from_encoder", c["encoder"]) == c["encoder"]
               for t in r["closed_by"]}
    for e in DOSS["entries"]:
        if set(e["closes"]) & refined:
            assert e["conservative"], e["id"]
    assert refined, "no in-place refinement found: the check would be vacuous"


def test_docs_are_generated():
    for path, text in docs_pages().items():
        assert path.read_text(encoding="utf-8") == text, f"{path} stale: run `python -m usul_corpus docs`"
