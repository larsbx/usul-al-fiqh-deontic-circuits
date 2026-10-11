import json
from pathlib import Path

import pytest

from usul_corpus.mentions import (NONE, Task, candidates, choices, heads, merge_gold, review_queue, split_of,
                                summary, with_gold)
from usul_corpus.reception import Cited

ROOT = Path(__file__).resolve().parents[2]

MUGHNI = Cited("ibn_qudama.mughni", ("المغني",), ("الذهبي في المغني",))
AWSAT = Cited("ibn_mundhir.awsat", ("ابن المنذر في الاوسط", "الاوسط لابن المنذر"), ("الطبراني في الاوسط",))
FURU = Cited("ibn_muflih.furu", ("قال في الفروع", "صاحب الفروع"))
WORKS = Task("work", (MUGHNI, AWSAT, FURU), cue_single=True)

PAGE = ("#META#Header#End#\n# قال في المغني كذا. والله هو المغني. رواه الطبراني في الأوسط. "
        "وذكره ابن المنذر في «الأوسط».\nPageV01P007\n")


def test_heads_strip_the_cue_from_a_cued_form():
    assert heads(FURU) == ("الفروع",)
    assert heads(AWSAT) == ("الاوسط", "الاوسط لابن المنذر")
    assert heads(MUGHNI) == ("المغني",)


def test_candidates_are_every_head_occurrence_with_rule_labels_where_the_matcher_is_sure():
    rows = candidates(WORKS, "w", PAGE, window=12)
    assert [(r["surface"], r["label"], r["label_source"]) for r in rows] == [
        ("المغني", "ibn_qudama.mughni", "rule"),  # cued
        ("المغني", None, None),                   # uncued: left for review, not guessed
        ("الاوسط", NONE, "rule"),                 # al-Ṭabarānī's, shadowed
        ("الاوسط", "ibn_mundhir.awsat", "rule"),
    ]
    first = rows[0]
    assert first["id"] == f"work:w/PageV01P007@{first['start']}"
    assert first["left"].endswith("قال في ") and first["right"].startswith(" كذا")
    assert len(first["left"]) <= 12 and len(first["right"]) <= 12


def test_splits_are_grouped_by_page_and_deterministic():
    assert split_of("w", "PageV01P007") == split_of("w", "PageV01P007")
    rows = candidates(WORKS, "w", PAGE)
    assert len({r["split"] for r in rows}) == 1
    tally = {s: sum(split_of("w", f"PageV01P{i:03d}") == s for i in range(1000)) for s in ("train", "dev", "test")}
    assert 700 < tally["train"] < 900 and 50 < tally["dev"] < 150 and 50 < tally["test"] < 150


def test_choices_are_the_works_sharing_a_surface_plus_none():
    assert choices(WORKS, "الاوسط") == ("ibn_mundhir.awsat", NONE)
    assert choices(WORKS, "المغني") == ("ibn_qudama.mughni", NONE)


def test_gold_overrides_rules_and_fills_gaps():
    rows = candidates(WORKS, "w", PAGE)
    gold = {rows[1]["id"]: NONE, rows[3]["id"]: "ibn_mundhir.awsat"}
    out = with_gold(rows, gold)
    assert [(r["label"], r["label_source"]) for r in out] == [
        ("ibn_qudama.mughni", "rule"), (NONE, "gold"), (NONE, "rule"), ("ibn_mundhir.awsat", "gold")]
    assert out[3]["rule_label"] == "ibn_mundhir.awsat"


def test_review_queue_takes_unlabelled_rows_round_robin_by_surface():
    rows = [{"id": f"r{i}", "surface": s, "label": None} for i, s in enumerate("aaab")] + [{"id": "x", "surface": "a", "label": "k"}]
    assert [r["id"] for r in review_queue(rows, 3)] == ["r0", "r3", "r1"]


def test_merge_gold_validates_labels_against_the_rows_choices():
    rows = candidates(WORKS, "w", PAGE)
    review = [{**rows[1], "label": NONE}]
    assert merge_gold({}, review, WORKS) == {rows[1]["id"]: NONE}
    with pytest.raises(ValueError, match="not a choice"):
        merge_gold({}, [{**rows[1], "label": "ibn_mundhir.awsat"}], WORKS)


def test_summary_carries_no_text_and_measures_rules_against_gold():
    rows = with_gold(candidates(WORKS, "w", PAGE), {})
    rows[3] = {**rows[3], "label": NONE, "label_source": "gold"}  # a reviewer overruled the rule
    s = summary({"work": rows})
    assert s["work"]["candidates"] == 4
    assert s["work"]["by_source"] == {"gold": 1, "rule": 2, "unlabelled": 1}
    assert s["work"]["rule_vs_gold"] == {"compared": 1, "agree": 0}
    assert "left" not in json.dumps(s) and "المغني" not in json.dumps(s)


def test_committed_gold_labels_are_well_formed():
    path = ROOT / "corpus/mentions/gold.jsonl"
    rows = [json.loads(l) for l in path.read_text(encoding="utf-8").splitlines()] if path.exists() else []
    assert all(set(r) <= {"id", "label", "note"} and r["id"].split(":")[0] in {"work", "author"} for r in rows)
    assert len({r["id"] for r in rows}) == len(rows)


def test_rows_conform_to_the_published_schema():
    import jsonschema
    schema = json.loads((ROOT / "schemas/citation_mention.schema.json").read_text(encoding="utf-8"))
    rows = with_gold(candidates(WORKS, "w", PAGE), {})
    for r in rows:
        jsonschema.validate({**r, "text": "", "choices": list(choices(WORKS, r["surface"]))}, schema)


def test_a_candidate_overlapping_one_precise_span_takes_its_label():
    """Regression (Codex on #55): the precise matcher resolves «النووي في المجموع» while candidate
    resolution keeps the longer head «المجموع شرح المهذب»; containment lost the label, overlap keeps it."""
    majmu = Cited("nawawi.majmu", ("المجموع شرح المهذب", "النووي في المجموع"))
    rows = candidates(Task("work", (majmu,), cue_single=True), "w", "#META#Header#End#\n# قال النووي في المجموع شرح المهذب\nPageV01P001\n")
    assert [(r["surface"], r["label"]) for r in rows] == [("المجموع شرح المهذب", "nawawi.majmu")]


def test_a_candidate_spanning_two_disagreeing_precise_spans_stays_unlabelled():
    a, b = Cited("x.a", ("قال في الف",)), Cited("x.b", ("باء جيم",), )
    both = Cited("x.c", ("الف باء",))
    task = Task("work", (a, b, both), cue_single=True)
    rows = candidates(task, "w", "#META#Header#End#\n# قال في الف باء جيم\nPageV01P001\n")
    assert [r["label"] for r in rows if r["surface"] == "الف باء"] == [None]
