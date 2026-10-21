"""M14 source receipts, partial situations and all three unselected stances."""
import copy
import json
from functools import lru_cache
from pathlib import Path

import pytest

from usul_corpus import deduction, istislah_cases as m14, takhrij

ROOT = Path(__file__).parents[2]


@lru_cache(maxsize=1)
def inputs():
    corpus = ROOT / "corpus"
    receipt = json.loads((corpus / m14.RECEIPT).read_text())
    lock = json.loads((corpus / "lock.json").read_text())["witnesses"][m14.WITNESS]
    # Required source: artifacts() restores committed LFS bytes and fails if unavailable.
    outputs = m14.artifacts(ROOT)
    text = (ROOT / ".cache/corpus" / f"{m14.WITNESS}.txt").read_text()
    return receipt, lock, text, outputs


def test_five_cases_replay_exactly_without_source_skips():
    receipt, lock, text, outputs = inputs()
    assert len(receipt["cases"]) == 5
    for path, rendered in outputs.items():
        assert path.read_text() == rendered, path
    assert [r["source_span"]["page_span"] for r in receipt["cases"]] == [
        [174, 174], [175, 176], [176, 176], [176, 176], [176, 176]]
    records = m14.replay(receipt, text, lock, lock["url"])
    assert all(r["status"] == "candidate" for r in records)
    cases = m14.annotations(receipt)["cases"]
    assert takhrij.annotation_errors(cases, records) == []
    assert all(takhrij.check_case(c) == [] and c["routing_label"] is False for c in cases)
    assert sum(len(takhrij.case_completions(c)) for c in cases) == 31


@pytest.mark.parametrize("mutation", ["source", "bytes", "span", "page", "quote", "locator", "review", "duplicate"])
def test_source_replay_rejects_corrupt_receipts(mutation):
    receipt, lock, text, _ = inputs()
    receipt = copy.deepcopy(receipt)
    row = receipt["cases"][0]
    if mutation == "source":
        text += "x"
    elif mutation == "bytes":
        receipt["source"]["bytes"] += 1
    elif mutation == "span":
        row["source_span"]["start"] += 1
    elif mutation == "page":
        row["source_span"]["page_span"] = [173, 173]
    elif mutation == "quote":
        row["evidence"][0]["excerpt_ar"] = "هذا كلام لم يرد في النص"
    elif mutation == "locator":
        row["evidence"][0]["ref"] = f"src:{m14.WITNESS}/v01:p173"
    elif mutation == "review":
        row["review"]["status"] = "reviewed"
    else:
        receipt["cases"][1]["id"] = row["id"]
    with pytest.raises(ValueError):
        m14.replay(receipt, text, lock, lock["url"])


def test_author_conditional_results_and_competing_stances_remain_distinct():
    receipt, _, _, _ = inputs()
    cases = m14.annotations(receipt)["cases"]
    report = m14.coverage(receipt, cases, (ROOT / "examples/v41_types.pl").read_text())
    rows = {r["label"]: r for r in report["cases"]}
    assert report["reviewed_cases"] == 0
    assert rows["tatarrus"]["reachable_by_stance"] == {"rawda": [False], "mustasfa": [True], "malik": [True]}
    assert rows["king_fast"]["reachable_by_stance"] == dict.fromkeys(("rawda", "mustasfa", "malik"), [False])
    for label in ("fortress", "ship", "famine"):
        assert rows[label]["reachable_by_stance"] == {"rawda": [False], "mustasfa": [False], "malik": [False, True]}
    # Source qualifiers and non-modelled objections cannot vanish from the evidence layer.
    assert "إذ لا ضرورة" in receipt["cases"][2]["evidence"][0]["excerpt_ar"]
    assert "ولا أصل لها" in receipt["cases"][3]["evidence"][0]["excerpt_ar"]
    assert any("ولا يبعد المنع" in ev["excerpt_ar"] for ev in receipt["cases"][1]["evidence"])
    assert all(c["facts"]["istislah_stance"] == "mustasfa" for c in cases)
    assert all("istislah_stance" not in r["interpretation"]["facts"] for r in receipt["cases"])


def test_partial_cases_use_exported_typing_and_existing_deduction():
    receipt, _, _, _ = inputs()
    read = deduction.reads((ROOT / "examples/v41_types.pl").read_text())["istislah"]
    names = deduction.names("istislah")
    assert len(read) == len(names) == 5
    for c in m14.annotations(receipt)["cases"]:
        settled = {field: c["facts"][name] for field, name in zip(read, names) if name in c["facts"]}
        assert deduction.reach("istislah", settled, read) == {c["expected"]}
        guards = takhrij.lean_file([c])
        assert guards.count("#guard") == len(takhrij.case_completions(c))


def test_quantification_never_silently_fills_or_selects_facts():
    c = {"far": "x.m00001", "encoder": "istislah", "class": "derivable", "expected": False,
         "facts": {"maslaha_shahada": "ilgha", "istislah_stance": "mustasfa"}, "note": "test"}
    assert takhrij.check_case(c) == ["facts do not match the encoder"]
    c["quantified_facts"] = ["maslaha_rutba", "maslaha_qatiyya", "maslaha_kulliyya"]
    assert takhrij.check_case(c) == []
    assert len(takhrij.case_completions(c)) == 12
    # Existential agreement is insufficient: one disagreeing completion rejects the annotation.
    assert takhrij.check_case({**c, "facts": {**c["facts"], "maslaha_shahada": "irsal"}}) == [
        "class contradicts the kernel's output"]
    for changed in (["maslaha_rutba"], c["quantified_facts"] + ["maslaha_qatiyya"],
                    c["quantified_facts"] + ["istislah_stance"], c["quantified_facts"] + ["unknown"]):
        assert takhrij.check_case({**c, "quantified_facts": changed})
    assert takhrij.check_case({**c, "class": "missing_fact"})
    assert takhrij.check_case({**c, "facts": {**c["facts"], "maslaha_qatiyya": 1},
                              "quantified_facts": ["maslaha_rutba", "maslaha_kulliyya"]})
