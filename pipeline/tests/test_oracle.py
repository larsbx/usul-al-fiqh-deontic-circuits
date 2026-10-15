from usul_corpus.oracle import NaiveBayes, Retriever, confidence, evaluate, features


def test_confidence_multiplies_independent_signals():
    l = {"hukm": "haram", "basis": "summary", "matches_question": True}
    assert confidence(l, {"class": "confirmed", "en": "haram"}) == 1.0
    assert confidence(l | {"basis": "lead"}, {"class": "confirmed", "en": None}) == 0.7
    assert confidence(l, {"class": "misread", "en": "mubah"}) == 0.3 * 0.4
    assert confidence(l, {"class": "conflict", "en": "haram"}) == 0.0
    assert confidence(l | {"matches_question": False}, {"class": "consistent", "en": None}) == 0.8 * 0.8


def test_features_read_the_question_only_with_stems_and_bigrams():
    f = features({"title": "حكم بيع الخمر", "question": None, "answer": "لا يجوز"})
    assert "بيع" in f and "خمر" in f and "بيع_خمر" in f and not any("جوز" in t for t in f)


DOCS = [("a", "haram", 1.0, ["خمر", "بيع"]), ("b", "haram", 1.0, ["خمر", "شرب"]),
        ("c", "mubah", 1.0, ["ماء", "شرب"]), ("d", "mubah", 1.0, ["ماء", "بيع"])]


def test_retriever_votes_by_similarity_and_cites_its_neighbours():
    r = Retriever(DOCS)
    p = r.predict(["خمر", "بيع"], k=2)
    assert p["hukm"] == "haram" and p["evidence"][0]["id"] == "a" and p["evidence"][0]["sim"] > p["evidence"][1]["sim"]
    assert Retriever(DOCS).predict(["غير", "معروف"])["hukm"] is None      # nothing similar: abstain


def test_naive_bayes_learns_the_obvious():
    assert NaiveBayes(DOCS).predict(["خمر"]) == "haram" and NaiveBayes(DOCS).predict(["ماء"]) == "mubah"


def test_evaluate_reports_accuracy_macro_f1_and_coverage():
    m = evaluate(["haram", "mubah", None, "haram"], ["haram", "haram", "mubah", "haram"])
    assert m["n"] == 4 and m["coverage"] == 0.75 and m["accuracy"] == 2 / 3
    assert m["per_class_f1"]["haram"] == 0.8 and m["per_class_f1"]["mubah"] == 0.0
