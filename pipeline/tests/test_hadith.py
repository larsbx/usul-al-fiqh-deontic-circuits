"""al-Albānī track, H0: each kernel scale has the recalled number of rungs, numbered 1…n, every
rung verbatim in its pinned witness (where cached), within that witness's rights, and every
Lean link #check-ed by the generated HadithTest/ScaleMap.lean."""

import json
from pathlib import Path

import jsonschema
import pytest

from usul_corpus.__main__ import CACHE, SCALE_LEAN, hadith_lean_names, signature_lean
from usul_corpus.arabic import letters, locate
from usul_corpus.records import EXCERPT_LEN

ROOT = Path(__file__).parents[2]
SCALES = json.loads((ROOT / "corpus/hadith/kernel_scales.json").read_text(encoding="utf-8"))
REGISTRY = json.loads((ROOT / "corpus/registry.json").read_text(encoding="utf-8"))["works"]
WORKS = {w["id"]: w for w in REGISTRY}
ITEMS = [(s, i) for s in SCALES["scales"] for i in s["items"]]


def _witness(ref):
    return ref[4:].split("/")


def test_schema():
    jsonschema.validate(SCALES, json.loads((ROOT / "schemas/hadith_scales.schema.json").read_text()))


@pytest.mark.parametrize("scale", SCALES["scales"], ids=lambda s: s["id"])
def test_counts_match_the_claim(scale):
    assert [i["n"] for i in scale["items"]] == list(range(1, scale["claim"] + 1))


@pytest.mark.parametrize("scale,item", ITEMS, ids=lambda x: x.get("id") or str(x.get("n")))
def test_refs_within_the_work_and_its_rights(scale, item):
    work = WORKS[scale["work"]]
    w, _ = _witness(item["ref"])
    assert w in {x["id"] for x in work["witnesses"]} and work.get("track") == "albani_hadith"
    assert len(item["excerpt_ar"]) <= EXCERPT_LEN[work["rights"]]


@pytest.mark.parametrize("scale,item", ITEMS, ids=lambda x: x.get("id") or str(x.get("n")))
def test_excerpts_are_verbatim(scale, item):
    w, loc = _witness(item["ref"])
    src = CACHE / f"{w}.txt"
    if not src.exists():
        pytest.skip(f"{w} not cached")
    assert locate(src.read_text(encoding="utf-8"), item["excerpt_ar"]) == loc


def test_scale_map_is_generated():
    assert SCALE_LEAN.read_text(encoding="utf-8") == signature_lean(hadith_lean_names(), "Hadith")


# --- H4: al-Ḍaʿīfa tranches -------------------------------------------------------------

from usul_corpus import hadith  # noqa: E402
from usul_corpus.__main__ import CORPUS, DAIFA_LEAN  # noqa: E402

TRANCHES = hadith.tranches(CORPUS)
CASES = [c for t in TRANCHES for c in t["cases"]]
DAIFA_RIGHTS = EXCERPT_LEN[WORKS["albani.daifa"]["rights"]]


def test_tranche_schema():
    schema = json.loads((ROOT / "schemas/daifa_tranche.schema.json").read_text())
    for t in TRANCHES:
        jsonschema.validate(t, schema)


def test_tranches_are_consecutive():
    """No cherry-picking: a tranche covers a run of entries with none skipped."""
    for t in TRANCHES:
        ns = [c["n"] for c in t["cases"]]
        assert ns == list(range(ns[0], ns[0] + len(ns)))


@pytest.mark.parametrize("c", CASES, ids=lambda c: f"daifa-{c['n']}")
def test_class_matches_kernel(c):
    """`derivable` exactly when the kernel (as #guard-ed in Lean) agrees with al-Albānī."""
    assert (c["class"] == "derivable") == (c["kernel"] == c["albani"])
    assert len(c["excerpt_ar"]) <= DAIFA_RIGHTS
    assert all(len(l.get("said_ar", "")) <= DAIFA_RIGHTS for t in c["turuq"] for l in t["links"])


@pytest.mark.parametrize("c", CASES, ids=lambda c: f"daifa-{c['n']}")
def test_daifa_excerpts_are_verbatim(c):
    w, loc = _witness(c["ref"])
    src = CACHE / f"{w}.txt"
    if not src.exists():
        pytest.skip(f"{w} not cached")
    assert locate(src.read_text(encoding="utf-8"), c["excerpt_ar"]) == loc


def test_daifa_lean_is_generated():
    assert DAIFA_LEAN.read_text(encoding="utf-8") == hadith.daifa_lean(CORPUS)


def test_coverage_report():
    """The H4 metric, pinned so a change to the kernel or the data shows up in review."""
    assert hadith.coverage(CASES) == {
        "cases": 25, "coverage": 0.72, "with_isnad": 17, "coverage_with_isnad": 0.588,
        "qarina_share": 0.24, "coverage_with_rulings": 0.96,
        "classes": {"derivable": 18, "missing_rule": 1, "qarina": 6}}


@pytest.mark.parametrize("c", CASES, ids=lambda c: f"daifa-{c['n']}")
def test_rulings_only_on_qarina_cases(c):
    """D2: a critic's ruling is evidence only where the rules fall short; rule-derived cases carry
    none, so the qarīna share is not absorbed into the coverage."""
    assert ("rulings" in c) == (c["class"] == "qarina") == ("kernel_with_rulings" in c)
    assert all(len(r["said_ar"]) <= DAIFA_RIGHTS for r in c.get("rulings", []))


@pytest.mark.parametrize("c", [c for c in CASES if "rulings" in c], ids=lambda c: f"daifa-{c['n']}")
def test_rulings_are_quoted_verbatim(c):
    src = CACHE / "shamela-12762.txt"
    if not src.exists():
        pytest.skip("al-Ḍaʿīfa not cached")
    text = letters(src.read_text(encoding="utf-8"))
    assert all(letters(r["said_ar"]) in text for r in c["rulings"])


def test_tranches_are_contiguous():
    """Tranches continue one another: entries 1…n with no gap between tranches."""
    ns = [c["n"] for c in CASES]
    assert ns == list(range(1, len(ns) + 1))
