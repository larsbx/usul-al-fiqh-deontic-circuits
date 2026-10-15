import json
import shutil
from pathlib import Path

import pytest

from usul_corpus import fatawa_prolog

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
    assert fatawa_prolog.check([CASE], bad) == ["islamqa.4652.f001: neither one ruling nor two positions",
                                                 "islamqa.4652.f001: oracle_gap without a reason"]


def test_a_disputed_case_is_held_as_its_positions_not_scored_for_agreement():
    disputed = {k: {"far": k, "facts": {}, "positions": [{"ruling": True, "evidence": "a"}, {"ruling": False, "evidence": "b"}]}
                for k in FACTS}
    assert fatawa_prolog.check([CASE], disputed) == []
    [r] = fatawa_prolog.merge([CASE], disputed)
    pl = fatawa_prolog.prolog_file([r])
    c = "'islamqa.4652.f001'"
    assert f"position({c}, true)." in pl and f"position({c}, false)." in pl
    assert f"fixture_expectation(within_positions({c}), query(within_positions({c})), expect_true)." in pl
    assert "text_ruling" not in pl.split("Do not edit.")[1].replace("text_ruling/2", "") and "agrees(" not in pl
    one = {k: v | {"positions": v["positions"][:1]} for k, v in disputed.items()}
    assert fatawa_prolog.check([CASE], one) == ["islamqa.4652.f001: neither one ruling nor two positions"]


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


def test_first_run_scores_the_earlier_rules_answers_not_todays_winners():
    recs = [{"far": f"islamqa.{i}.f001", "encoder": "trust_loss", "positions": [], "ruling": False, "kernel": False,
             "post_hoc": ph, "gap": None} for i, ph in ((1, []), (2, ["unavoidable"]))]
    now = {f"islamqa.{i}.f001": {"ruling": "false", "rule": "quwwa_qahira"} for i in (1, 2)}
    before = {"islamqa": {"islamqa.1.f001": {"ruling": "false", "rule": "mubashir_liable"},
                          "islamqa.2.f001": {"ruling": "true", "rule": "mubashir_liable"}}}
    rep = fatawa_prolog.report(recs, now, before, frozenset({"quwwa_qahira"}), {"trust_loss": "judgement/wadi:sabab"})
    # a revised rule winning today does not hide an agreement the earlier rules already had
    assert rep["islamqa"]["fit"] == "in_sample"
    assert rep["islamqa"]["total"] == {"decided": 2, "oracle": 2, "first_run": 1, "bank_answers": 2, "bank": 2}
    assert rep["islamqa"]["per_sort"]["judgement/wadi:sabab"]["first_run"] == 1
    assert rep["post_hoc_facts"] == {"islamqa.2.f001": ["unavoidable"]}


def test_every_post_hoc_fact_has_verbatim_evidence_in_its_answer():
    import gzip
    from usul_corpus import fatawa_takhrij
    facts = fatawa_prolog.load_facts(ROOT / "corpus")
    post_hoc = {f: x for f, x in facts.items() if x.get("post_hoc")}
    assert post_hoc and all(set(x["post_hoc"]) == set(x.get("post_hoc_evidence", {})) for x in post_hoc.values())
    path = ROOT / "data/islamqa/answers/islamqa-ar.jsonl.gz"
    if not path.exists():
        pytest.skip("IslamQA answers not fetched")
    need = {f.rsplit(".", 1)[0] for f in post_hoc}
    with gzip.open(path, "rt", encoding="utf-8") as fh:
        answers = {r["id"]: r for r in map(json.loads, fh) if r["id"] in need}
    for f, x in post_hoc.items():
        a = answers[f.rsplit(".", 1)[0]]
        text = fatawa_takhrij._flat(" ".join(a.get(k) or "" for k in ("title", "question", "summary", "answer")))
        for fact, excerpt in x["post_hoc_evidence"].items():
            assert fatawa_takhrij._flat(excerpt) in text, (f, fact)


def test_revised_rules_are_declared_rules():
    import re
    declared = set(re.findall(r"^rule\(\w+, (\w+), C,", (ROOT / fatawa_prolog.RULES).read_text(), re.M))
    assert fatawa_prolog.revised_rules(ROOT) <= declared and "itlaf_bi_haqq" in fatawa_prolog.revised_rules(ROOT)


def test_committed_cases_are_generated():
    facts = fatawa_prolog.load_facts(ROOT / "corpus")
    cases = fatawa_prolog.load_cases(ROOT / "corpus", facts)
    assert fatawa_prolog.check(cases, facts) == []
    records = fatawa_prolog.merge(cases, facts)
    assert (ROOT / fatawa_prolog.CASES).read_text(encoding="utf-8") == fatawa_prolog.prolog_file(records)
    if shutil.which("swipl") is None:
        pytest.skip("swipl not installed")
    rep = fatawa_prolog.report(records, fatawa_prolog.run(ROOT), fatawa_prolog.first_runs(ROOT, records),
                               frozenset(fatawa_prolog.revised_rules(ROOT)), fatawa_prolog.sorts(ROOT / "corpus"))
    # the reconstructed first-run rules reproduce the first run (105/122); the classical held-out run is 24/26
    assert rep["islamqa"]["total"]["first_run"] == 105 and rep["classical"]["total"]["first_run"] == 24
    assert json.loads((ROOT / "corpus/fatawa/prolog/report.json").read_text()) == rep
