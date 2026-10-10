from usul_corpus.labels import cues, label, normalize_ar, split_of


def hukms(text):
    return [(c["hukm"], c["polarity"]) for c in cues(text)]


def test_normalize_strips_tashkeel_tatweel_and_unifies_alef():
    assert normalize_ar("يُحَرَّمُ") == "يحرم"
    assert normalize_ar("إأآ ـلا") == "ااا لا"


def test_negated_cue_wins_over_its_positive_substring():
    assert hukms("لا يجوز بيع الخمر") == [("haram", "+")]
    assert hukms("لا حرج عليك") == [("mubah", "+")]


def test_negated_obligation_casts_no_vote():
    (c,) = cues("لا يجب عليه القضاء")
    assert (c["hukm"], c["polarity"]) == ("wajib", "-")


def test_cues_survive_attached_conjunctions_and_diacritics():
    assert hukms("فيَحْرُمُ ذلك، ويُستحب الدعاء") == [("haram", "+"), ("mandub", "+")]


def test_cue_offsets_point_into_the_normalized_text():
    t = "الحمد لله. يجب الوضوء"
    (c,) = cues(t)
    assert normalize_ar(t)[c["start"]:c["end"]] == "يجب"


def test_label_prefers_the_official_summary():
    rec = {"id": "islamqa.1", "topics": [], "answer": "الحمد لله. يجوز ذلك.", "summary": "ملخص الجواب : يحرم ذلك."}
    l = label(rec)
    assert (l["hukm"], l["basis"]) == ("haram", "summary")


def test_label_reads_the_conclusion_then_the_lead():
    concl = {"id": "islamqa.2", "topics": [], "answer": "الحمد لله.\nقال بعضهم يجوز.\nوالحاصل : أنه يكره ذلك."}
    lead = {"id": "islamqa.3", "topics": [], "answer": "الحمد لله.\nيجب عليك الغسل.\nوقيل غير ذلك."}
    assert (label(concl)["hukm"], label(concl)["basis"]) == ("makruh", "conclusion")
    assert (label(lead)["hukm"], label(lead)["basis"]) == ("wajib", "lead")


def test_label_flags_conditional_rulings():
    rec = {"id": "islamqa.4", "topics": [], "answer": "الحمد لله.\nلا حرج في العمل، إلا إذا كان فيه نقل الخمر فيحرم."}
    l = label(rec)
    assert l["hukm"] == "mubah" and l["conditional"] and l["also"] == ["haram"]


def test_label_without_cues_is_unlabelled_and_carries_domain():
    rec = {"id": "islamqa.5", "answer": "الحمد لله.\nهذا من أخبار الأمم السابقة.",
           "topics": [{"ref": 1, "path": ["التاريخ والسيرة", "السيرة النبوية"]}]}
    l = label(rec)
    assert l["hukm"] is None and l["basis"] is None
    assert (l["domain"], l["chapter"]) == ("التاريخ والسيرة", "السيرة النبوية")


def test_wadi_validity_is_a_separate_field():
    rec = {"id": "islamqa.6", "topics": [], "answer": "الحمد لله.\nصلاتك صحيحة، ولا يصح البيع."}
    assert label(rec)["wad"] == ["sahih", "batil"]


def test_split_is_deterministic_and_language_independent():
    assert split_of(115097) == split_of(115097) in {"train", "dev", "test"}
    counts = {s: sum(split_of(i) == s for i in range(10_000)) for s in ("train", "dev", "test")}
    assert 7_700 < counts["train"] < 8_300 and 800 < counts["dev"] < 1_200


def test_audit_regressions():
    assert hukms("هل يجوز له الفطر ؟") == []                        # a question, not a ruling
    assert hukms("لم يلزمه شيء") == [("wajib", "-")]                # لم negates like لا
    assert hukms("فان لم يجز ذلك") == [("haram", "+")]
    assert hukms("من اهل السنة على حرمة قتله") == []                # «من السنة» only as «من السنة أن»
    assert hukms("من السنة ان يرمل") == [("mandub", "+")]
    assert hukms("بالسعر الافضل") == [] and hukms("الافضل ان تصلي") == [("mandub", "+")]
    assert hukms("مكروه المجالسة") == [] and hukms("وهو مكروه") == [("makruh", "+")]


def test_evidence_window_contains_the_cue():
    rec = {"id": "islamqa.7", "topics": [], "answer": "الحمد لله.\n" + "كلام " * 200 + "يحرم ذلك"}
    e = label(rec)["evidence"]
    assert e["cue"] in e["passage"]


def test_makruh_verb_needs_a_ruling_frame():
    assert hukms("يحب له ما يحب لنفسه ويكره له ما يكره لنفسه") == []   # «dislikes», not a ruling
    assert hukms("لا ينبغي له ذلك") == []
    assert hukms("يكره ان يصلي") == [("makruh", "+")]
    assert hukms("كراهة تحريم") == [("haram", "+")] and hukms("كراهة تنزيه") == [("makruh", "+")]


def test_negated_status_nouns_cast_no_vote():
    assert hukms("ليست حراما ولا مكروهة ، فلا حرج") == [("haram", "-"), ("makruh", "-"), ("mubah", "+")]


def _labels():
    return [{"id": f"islamqa.{i}", "hukm": h, "basis": b, "split": split_of(i), "conditional": i % 2 == 0, "wad": [],
             "evidence": h and {"cue": "x", "passage": "p"}}
            for i, (h, b) in enumerate([("haram", "lead")] * 5 + [("wajib", "summary")] * 3 + [(None, None)] * 4)]


def test_report_counts_by_label_basis_and_split():
    from usul_corpus.labels import report
    r = report(_labels())
    assert r["total"] == 12 and r["labelled"] == 8
    assert r["hukm"] == {"haram": 5, "wajib": 3, "unlabelled": 4}
    assert r["hukm_by_basis"]["summary"] == {"wajib": 3}
    assert sum(r["split"].values()) == 12


def test_review_sample_is_stratified_deterministic_and_blank_for_gold():
    from usul_corpus.labels import review_sample
    titles = {f"islamqa.{i}": f"t{i}" for i in range(12)}
    s = review_sample(_labels(), titles, per_class=2)
    assert s == review_sample(list(reversed(_labels())), titles, per_class=2)
    assert [x["candidate"] for x in s].count("haram") == 2 and [x["candidate"] for x in s].count(None) == 2
    assert all(x["gold"] is None and x["title"] == titles[x["id"]] for x in s)


def test_plural_status_nouns_are_not_rulings():
    assert hukms("واجبات الصلاة") == [] and hukms("هذا واجب") == [("wajib", "+")]


def test_ghayr_jaiz_reads_as_prohibition():
    assert hukms("غير جائز") == [("haram", "+")] and hukms("ليس بجائز") == [("haram", "+")]


def test_rerunning_labels_keeps_human_review_fields():
    from usul_corpus.labels import merge_review
    old = [{"id": "islamqa.1", "candidate": "haram", "gold": "mubah", "note": "side issue"},
           {"id": "islamqa.2", "candidate": "wajib", "gold": None, "note": None},
           {"id": "islamqa.3", "candidate": "mandub", "gold": "mandub", "note": None}]
    new = [{"id": "islamqa.1", "candidate": "wajib", "gold": None, "note": None},
           {"id": "islamqa.2", "candidate": "wajib", "gold": None, "note": None}]
    merged = merge_review(new, old)
    assert merged[0] == {"id": "islamqa.1", "candidate": "wajib", "gold": "mubah", "note": "side issue"}
    assert merged[1]["gold"] is None
    assert merged[2] == old[2]                      # a reviewed item is never dropped


def test_wad_comes_from_the_passage_the_ruling_came_from():
    rec = {"id": "islamqa.8", "topics": [], "summary": "صلاتك صحيحة .", "answer": "الحمد لله.\nيحرم البيع ."}
    l = label(rec)
    assert (l["hukm"], l["basis"], l["wad"]) == ("haram", "lead", [])


def test_evidence_records_which_occurrence_of_the_cue_decided():
    rec = {"id": "islamqa.10", "topics": [], "answer": "الحمد لله.\nالتي تجب عليها النفقة ، تجب عليها الصلاة ."}
    assert label(rec)["evidence"]["nth"] == 0
