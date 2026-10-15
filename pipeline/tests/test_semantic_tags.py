import pytest

from usul_corpus import semantic_tags as tags, takhrij


def test_arabic_offsets_pin_exact_text_and_source():
    text = "هل يجوز إذا لم يعرف؟"
    record = tags.propose("q", text)
    assert {t["role"] for t in record["tags"]} == {"condition", "negation"}
    for t in record["tags"]:
        tags.validate_span(t["evidence"], "q", text)
        with pytest.raises(ValueError):
            tags.validate_span(t["evidence"], "other", text)
        with pytest.raises(ValueError):
            tags.validate_span(t["evidence"], "q", text + " ")
    assert all(v["status"] == "unknown" for v in record["semantic_roles"].values())
    assert record["encoder_facts"] == []


def observation(value=False, status="reviewed"):
    return {"field": "lapsed", "value": value, "status": status,
            "evidence": tags.span("q", "دليل", 0, 4), "review_locator": "fixture:review"}


def test_candidate_or_unknown_facts_hold_without_calling_kernel(monkeypatch):
    monkeypatch.setitem(takhrij.ENCODERS["doubled"], "py", lambda _: pytest.fail("kernel called"))
    assert tags.admit("doubled", [], "q", "دليل")["status"] == "hold"
    assert tags.admit("doubled", [observation(status="candidate")], "q", "دليل")["output"] is None
    assert tags.admit("doubled", [{"field": "lapsed", "status": "unknown", "value": None}], "q", "دليل")["output"] is None


def test_complete_reviewed_map_executes_strictly_typed_mirror():
    result = tags.admit("doubled", [observation()], "q", "دليل")
    assert result["status"] == "candidate_kernel_result"
    assert result["output"] == 1
    for value in (0, 1, "false", None):
        with pytest.raises(ValueError, match="typed domain"):
            tags.admit("doubled", [observation(value)], "q", "دليل")


def test_forged_duplicate_and_unreviewed_evidence_is_rejected():
    bad = observation(); bad["evidence"]["quote"] = "مزور"
    with pytest.raises(ValueError):
        tags.admit("doubled", [bad], "q", "دليل")
    with pytest.raises(ValueError, match="duplicate"):
        tags.admit("doubled", [observation(), observation()], "q", "دليل")
    bad = observation(); bad.pop("review_locator")
    with pytest.raises(ValueError, match="locator"):
        tags.admit("doubled", [bad], "q", "دليل")


def test_markers_do_not_match_inside_words():
    assert tags.propose("q", "بعدها لامرأة")['tags'] == []
