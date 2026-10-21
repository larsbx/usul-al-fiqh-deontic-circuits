"""RQ-05: distinguish a textual variant from a legal position or a Lean proof.

The immutable research URLs and hashes live in the existing question register.
`make source-verify-fetch` provisions and verifies all five receipts, including
external witnesses, before CI runs these tests. Missing bytes fail; tests do not
fetch evidence or accept schema validity as a substitute for receipt replay.
"""

import copy
import hashlib
import json
import re
from pathlib import Path

import jsonschema
import pytest

from usul_corpus import source_verify, takhrij
from usul_corpus.arabic import letters, locate
from usul_corpus.reception import pages

ROOT = Path(__file__).resolve().parents[2]
REGISTER = json.loads((ROOT / "corpus/review/research_questions.json").read_text())
QUESTION = next(q for q in REGISTER["questions"] if q["id"] == "RQ-05")
SCHEMA = json.loads((ROOT / "schemas/research_question.schema.json").read_text())
WITNESSES = QUESTION["collation"]["witnesses"]


def test_required_source_gate_replays_all_five_rq05_receipts():
    checks = [c for c in source_verify.verify_collations(ROOT / "corpus", ROOT / ".cache/corpus")
              if c["question"] == "RQ-05"]
    assert len(checks) == len(WITNESSES) == 5
    assert {c["witness"] for c in checks} == {w["id"] for w in WITNESSES}
    assert all(c["status"] == "verified" for c in checks), checks


@pytest.mark.parametrize("source", QUESTION["sources"], ids=lambda s: s["ref"])
def test_rq05_registered_sources_match_the_exact_pinned_page(source):
    wid, vol, page = re.fullmatch(r"src:([a-z0-9-]+)/v(\d+):p(\d+)", source["ref"]).groups()
    cached = ROOT / ".cache/corpus" / f"{wid}.txt"
    if not cached.exists():
        pytest.skip(f"{wid} not cached")
    data = cached.read_bytes()
    lock = json.loads((ROOT / "corpus/lock.json").read_text())["witnesses"][wid]
    assert hashlib.sha256(data).hexdigest() == lock["sha256"]
    body = dict(pages(data.decode("utf-8")))[f"PageV{int(vol):02d}P{int(page):03d}"]
    assert source["excerpt_ar"] in body


def test_collation_receipts_are_candidate_and_schema_valid():
    jsonschema.validate(REGISTER, SCHEMA)
    assert QUESTION["status"] == "open-research"
    assert "decision" not in QUESTION
    assert len({w["id"] for w in WITNESSES}) == len(WITNESSES)
    assert {w["has_negation"] for w in WITNESSES} == {True, False}
    primary = next(w for w in WITNESSES if w["id"] == "openiti-rajab-shamela21730")
    lock = json.loads((ROOT / "corpus/lock.json").read_text())["witnesses"][primary["id"]]
    assert all(primary[k] == lock[k] for k in ("url", "sha256", "bytes"))
    assert primary["has_negation"]


@pytest.mark.parametrize("w", WITNESSES, ids=lambda w: w["id"])
def test_collation_quote_retains_its_declared_polarity(w):
    # A copied quote cannot silently lose its لا while its receipt still says negative.
    text = letters(w["excerpt_ar"])
    assert (letters("أنه لا يضمنه بألفين") in text) == w["has_negation"]
    assert (letters("أنه يضمنه بألفين") in text) == (not w["has_negation"])


@pytest.mark.parametrize("w", WITNESSES, ids=lambda w: w["id"])
def test_cached_collation_receipt_and_negation_mutation(w):
    cached = ROOT / ".cache" / w["cache_group"] / w["cache_file"]
    assert cached.is_file(), f"{w['id']} unavailable; run make source-verify-fetch"
    data = cached.read_bytes()
    assert len(data) == w["bytes"]
    assert hashlib.sha256(data).hexdigest() == w["sha256"]
    text = data.decode("utf-8")
    assert locate(text, w["excerpt_ar"]) == w["locator"]
    before, after = ("أنه لا يضمنه", "أنه يضمنه") if w["has_negation"] else ("أنه يضمنه", "أنه لا يضمنه")
    mutated = w["excerpt_ar"].replace(before, after)
    assert mutated != w["excerpt_ar"]
    assert locate(text, mutated) != w["locator"]


def test_case_guard_checks_the_annotated_reading_not_a_textual_emendation():
    suite = json.loads((ROOT / "corpus/takhrij/rajab_m8_rajab_a15_furu.json").read_text())
    case = next(c for c in suite["cases"] if c["far"].endswith("q128.f003"))
    assert takhrij.check_case(case) == []
    assert case["class"] == "derivable" and case["expected"] is True
    assert takhrij.lean_expr(case["encoder"], case["facts"]) == "Usul.Readings.RajabA15.measuredAtInjury true true"
    # A literal-negative reannotation cannot be made derivable by changing only expected.
    negative = copy.deepcopy(case)
    negative["expected"] = False
    assert "class contradicts the kernel's output" in takhrij.check_case(negative)
    # Two digital readings do not by themselves supply two attributed legal positions.
    invented_disagreement = copy.deepcopy(case)
    invented_disagreement["class"] = "genuine_ikhtilaf"
    invented_disagreement.pop("positions", None)
    assert "ikhtilāf needs at least two positions" in takhrij.check_case(invented_disagreement)


@pytest.mark.parametrize("field,value", [("sha256", "unpinned"), ("url", "https://example.org/latest"), ("excerpt_ar", "")])
def test_collation_schema_rejects_unreplayable_receipts(field, value):
    bad = copy.deepcopy(REGISTER)
    question = next(q for q in bad["questions"] if q["id"] == "RQ-05")
    question["collation"]["witnesses"][0][field] = value
    with pytest.raises(jsonschema.ValidationError):
        jsonschema.validate(bad, SCHEMA)

