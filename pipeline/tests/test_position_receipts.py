"""Evidence associations must fail closed before positional overlays are merged."""
from copy import deepcopy
import json
from pathlib import Path

import pytest

from usul_corpus import reconcile, takhrij, position_receipts as receipts
from usul_corpus import migrate_positions

ROOT = Path(__file__).resolve().parents[2]


@pytest.fixture
def pair():
    case = next(c for c in takhrij.load(ROOT / "corpus") if c["far"].endswith("q043.f005"))
    entry = next(e for e in reconcile.load(ROOT / "corpus")["entries"] if e["far"] == case["far"])
    return deepcopy(case), deepcopy(entry)


@pytest.mark.parametrize("change", ["reverse", "holder", "detail", "type", "case"])
def test_changed_subjects_cannot_reuse_evidence(pair, change):
    case, entry = pair
    if change == "reverse":
        case["positions"].reverse()
    elif change == "holder":
        case["positions"][0]["who"] += " different holder"
    elif change == "detail":
        case["positions"][0]["detail"] = "new qualification"
    elif change == "type":
        case["positions"][0]["ruling"] = 1
    else:
        case["far"] += ".other"
    assert receipts.errors(case, entry)
    assert reconcile.check([case], {"entries": [entry]}, {"entries": []})
    for operation in (reconcile.resolve, reconcile.attribution):
        with pytest.raises(ValueError, match="position"):
            operation(case, entry)


@pytest.mark.parametrize("value", [None, "", "0" * 63, "A" * 64, "0" * 64])
def test_missing_malformed_or_stale_receipt_cannot_resolve(pair, value):
    case, entry = pair
    entry[receipts.FIELD] = value
    assert reconcile.check([case], {"entries": [entry]}, {"entries": []})
    with pytest.raises(ValueError, match="receipt"):
        reconcile.resolve(case, entry)


@pytest.fixture
def corpus(tmp_path, pair):
    case, entry = pair
    (tmp_path / "takhrij").mkdir()
    (tmp_path / "takhrij/cases.json").write_text(json.dumps({"cases": [case]}))
    (tmp_path / "reconciliation/weighing").mkdir(parents=True)
    overlay = {k: entry[k] for k in ("far", receipts.FIELD, *reconcile.WEIGHED) if k in entry}
    base = {k: v for k, v in entry.items() if k not in reconcile.WEIGHED}
    for name, item in (("ledger.json", base), ("weighing/test.json", overlay)):
        (tmp_path / "reconciliation" / name).write_text(json.dumps({"entries": [item]}))
    assert reconcile.load(tmp_path)["entries"][0] == entry
    return tmp_path


@pytest.mark.parametrize("source", ["ledger.json", "weighing/test.json"])
@pytest.mark.parametrize("mutation", ["missing", "stale"])
def test_each_overlay_source_needs_its_own_valid_receipt(corpus, source, mutation):
    path = corpus / "reconciliation" / source
    data = json.loads(path.read_text())
    entry = data["entries"][0]
    if mutation == "missing":
        del entry[receipts.FIELD]
    else:
        entry[receipts.FIELD] = "0" * 64
    path.write_text(json.dumps(data))
    with pytest.raises(ValueError, match="receipt"):
        reconcile.load(corpus)


def test_case_reordering_is_rejected_on_load(corpus):
    path = corpus / "takhrij/cases.json"
    data = json.loads(path.read_text())
    data["cases"][0]["positions"].reverse()
    path.write_text(json.dumps(data))
    with pytest.raises(ValueError, match="receipt mismatch"):
        reconcile.load(corpus)


def test_receipt_is_independent_of_json_key_order_but_binds_the_entire_position(pair):
    case, entry = pair
    case["positions"] = [dict(reversed(list(p.items()))) for p in case["positions"]]
    assert receipts.errors(case, entry) == []
    case["positions"][0]["outside"] = "new range-gap claim"
    assert receipts.errors(case, entry)


def test_pinned_migration_is_idempotent_and_cannot_repin_reordered_cases(monkeypatch):
    corpus = ROOT / "corpus"
    outputs = migrate_positions.outputs(corpus)
    assert len(outputs) == 69
    assert all(path.read_bytes() == raw for path, raw in outputs)
    cases = takhrij.load(corpus)
    next(c for c in cases if c["far"].endswith("q043.f005"))["positions"].reverse()
    monkeypatch.setattr(migrate_positions.takhrij, "load", lambda _: cases)
    with pytest.raises(ValueError, match="pinned migration subjects"):
        migrate_positions.outputs(corpus)


def test_every_active_source_entry_is_bound_before_resolution():
    cases = {c["far"]: c for c in takhrij.load(ROOT / "corpus")}
    count = 0
    for relative in migrate_positions.SOURCES:
        for entry in json.loads((ROOT / "corpus" / relative).read_text())["entries"]:
            assert receipts.errors(cases[entry["far"]], entry) == []
            count += 1
    assert count == 1192


def test_the_audited_reversal_cannot_reach_a_resolution(monkeypatch):
    """Audit PR-37: reversing every two-position case at once changed 224 resolutions, 221 in cases `check`
    accepted. Every ledger and weighing entry now carries its case's ordered-position receipt, so the reversed
    bank does not load at all."""
    cases = takhrij.load(ROOT / "corpus")
    reversed_ = [c for c in cases if len(c.get("positions") or []) == 2]
    assert len(reversed_) > 500
    for c in reversed_:
        c["positions"].reverse()
    monkeypatch.setattr(reconcile.takhrij, "load", lambda _: cases)
    with pytest.raises(ValueError, match="positions receipt mismatch"):
        reconcile.load(ROOT / "corpus")
