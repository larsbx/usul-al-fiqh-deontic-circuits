import json
import shutil
from pathlib import Path

import pytest

from usul_corpus import fatawa_prolog, fatawa_takhrij

ROOT = Path(__file__).parents[2]
CASE = {"far": "islamqa.4652.f001", "encoder": "trust_loss", "class": "derivable",
        "facts": {"hand": "trustee", "transgressed": False, "negligent": False}, "expected": False}
FACTS = {"islamqa.4652.f001": {"far": "islamqa.4652.f001", "ruling": False,
                               "facts": {"has_legal_value": True, "lawful_authority_act": None, "negligent": None}}}


def test_merge_extends_the_encoder_facts_and_null_drops():
    [r] = fatawa_prolog.merge([CASE], FACTS)
    assert r["encoder_facts"] == CASE["facts"] and r["kernel"] is False
    assert r["facts"] == {"hand": "trustee", "transgressed": False, "has_legal_value": True}


def test_incomplete_encoder_facts_have_no_kernel_value_and_segmentation_errors_are_not_cases():
    gap = CASE | {"class": "missing_fact", "facts": {"hand": "trustee"}}
    assert fatawa_prolog.merge([gap], FACTS)[0]["kernel"] is None
    assert fatawa_prolog.merge([CASE | {"class": "segmentation_error"}], FACTS) == []


def test_check_pairs_cases_with_facts_and_gaps_with_reasons():
    assert fatawa_prolog.check([CASE], FACTS) == []
    assert fatawa_prolog.check([CASE], {}) == ["islamqa.4652.f001: no extended facts"]
    bad = {k: v | {"ruling": None, "oracle_gap": " "} for k, v in FACTS.items()}
    assert fatawa_prolog.check([CASE], bad) == ["islamqa.4652.f001: no ruling", "islamqa.4652.f001: oracle_gap without a reason"]


def test_atoms_are_quoted_unless_plain():
    assert [fatawa_prolog.atom(v) for v in (True, "hold", "islamqa.1.f001", "it's")] == \
        ["true", "hold", "'islamqa.1.f001'", "'it\\'s'"]


def test_vectors_bank_agreement_and_recorded_gaps():
    [r] = fatawa_prolog.merge([CASE], FACTS)
    pl = fatawa_prolog.prolog_file([r])
    c = "'islamqa.4652.f001'"
    assert f"fixture_expectation(bank({c}), query(bank({c}, false)), expect_true)." in pl
    assert f"fixture_expectation(agrees({c}), query(agrees({c})), expect_true)." in pl
    pl = fatawa_prolog.prolog_file([r | {"gap": "a choice the schema cannot hold"}])
    assert f"fixture_expectation(agrees({c}), query(agrees({c})), expect_false)." in pl
    assert f"fixture_premise(agrees({c}), query(text_ruling({c}, _)))." in pl
    assert f"fixture_premise(agrees({c}), query(oracle({c}, _, _)))." in pl


def test_committed_cases_are_generated():
    cases, facts = fatawa_takhrij.load(ROOT / "corpus"), fatawa_prolog.load_facts(ROOT / "corpus")
    assert fatawa_prolog.check(cases, facts) == []
    records = fatawa_prolog.merge(cases, facts)
    assert (ROOT / fatawa_prolog.CASES).read_text(encoding="utf-8") == fatawa_prolog.prolog_file(records)
    if shutil.which("swipl") is None:
        pytest.skip("swipl not installed")
    rep = fatawa_prolog.report(records, fatawa_prolog.run(ROOT))
    assert json.loads((ROOT / "corpus/fatawa/prolog/report.json").read_text()) == rep
