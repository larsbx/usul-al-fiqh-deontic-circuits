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
def test_rules_never_fabricate(c):
    """D5: without rulings the kernel is mawḍūʿ exactly when there is no isnād (Hadith.judgeH_mawdu_iff);
    a narrated matn reaches the mawḍūʿ branch only through a cited finding."""
    assert (c["kernel"] == "mawdu") == (not c["turuq"])
    assert c.get("kernel_with_rulings") != "mawdu" or any(r["ceiling"] == "mawdu" for r in c["rulings"])


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
        "cases": 45, "coverage": 0.556, "with_isnad": 31, "coverage_with_isnad": 0.355,
        "qarina_share": 0.422, "coverage_with_rulings": 0.978,
        "classes": {"derivable": 25, "missing_rule": 1, "qarina": 19}}


def test_qarina_is_branch_crossing():
    """D5, observed: the rules never miss within the riwāya scale. Every qarīna case is a narrated
    matn that al-Albānī puts on the mawḍūʿ branch, and every such matn but one (#8) is a qarīna case."""
    crossing = {c["n"] for c in CASES if c["turuq"] and c["albani"] == "mawdu"}
    assert {c["n"] for c in CASES if c["class"] == "qarina"} == crossing - {8}


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


def test_irwa_audit_is_reproducible():
    """H0: the committed al-Irwāʾ audit is what the reader derives from the pinned witness."""
    src = CACHE / "shamela-22592.txt"
    if not src.exists():
        pytest.skip("al-Irwāʾ not cached")
    committed = json.loads((ROOT / "corpus/hadith/irwa_audit.json").read_text(encoding="utf-8"))
    assert hadith.irwa_audit(src.read_text(encoding="utf-8")) == committed


def test_longest_increasing_skips_strays():
    assert hadith._longest_increasing([(0, 1), (1, 2), (2, 1650), (3, 3), (4, 7), (5, 8)]) == \
        [(0, 1), (1, 2), (3, 3), (4, 7), (5, 8)]


# --- H8: the al-Irwāʾ join and the seam ------------------------------------------------------

from usul_corpus.__main__ import SEAM_LEAN  # noqa: E402

JOIN = json.loads((ROOT / "corpus/hadith/irwa_join.json").read_text(encoding="utf-8"))["links"]


REVIEW = json.loads((ROOT / "corpus/hadith/irwa_join_review.json").read_text(encoding="utf-8"))["review"]


def _join_inputs():
    src = CACHE / "shamela-22592.txt"
    if not src.exists():
        pytest.skip("al-Irwāʾ not cached")
    records = [json.loads(l) for p in sorted((ROOT / "corpus/records").glob("*.jsonl"))
               for l in p.read_text(encoding="utf-8").splitlines()]
    proposals = json.loads((ROOT / "corpus/proposals/sadi_qawaid.json").read_text(encoding="utf-8"))
    return src.read_text(encoding="utf-8"), records, proposals


def test_every_candidate_is_reviewed():
    """Candidates are proposals: each is accepted or rejected with a reason, none dropped silently,
    and the review holds no entry for a candidate that no longer arises."""
    text, records, _ = _join_inputs()
    keys = {f"{c['irwa']}|{c['record']}" for c in hadith.join_candidates(text, records)}
    assert keys == set(REVIEW)
    assert all(r["why"] for r in REVIEW.values())


def test_join_is_reproducible():
    text, records, proposals = _join_inputs()
    assert hadith.irwa_join(text, records, proposals, REVIEW) == JOIN


def test_seam_lean_is_generated():
    assert SEAM_LEAN.read_text(encoding="utf-8") == hadith.seam_lean(JOIN)


def test_verdict_terms():
    assert [hadith.irwa_verdict(t) for t in ("صحيح", "صحيح , مشهور", "حسن", "ضعيف جدا", "ضعيف", "باطل",
                                             "لم أقف على سنده", None)] == \
        ["sahih", "sahih", "hasan", "daifJiddan", "daif", "mawdu", None, None]


def test_seam_findings():
    """The join's outcome, pinned: every joined qāʿida dalīl passes the seam except Q24's."""
    failing = {q for l in JOIN if l["hujja"] is False for q in l["sadi_qawaid"]}
    passing = {q for l in JOIN if l["hujja"] for q in l["sadi_qawaid"]}
    assert (failing, passing) == ({24}, {22, 47, 57})
    assert not [l["matn_ar"] for l in JOIN if l["hujja"] is False and not l["sadi_qawaid"]]


def test_seam_is_the_only_import_edge():
    """H7: the uṣūl track sees the ḥadīth track only through `Usul.Seam`, and Seam sees only
    `Hadith.Grade` (verdicts and their `grade`), never isnād or turuq internals."""
    lean = ROOT / "formal/lean"
    edges = {(f.relative_to(lean).with_suffix("").as_posix(), line.split()[1])
             for f in [lean / "Usul.lean", *(lean / "Usul").rglob("*.lean")]
             for line in f.read_text(encoding="utf-8").splitlines() if line.startswith("import Hadith")}
    assert edges == {("Usul/Seam", "Hadith.Grade")}
