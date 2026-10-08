from usul_corpus.fatawa import answer_record, fold, html_text, snapshot_witnesses
from usul_corpus.fetch import witness_url

ANSWER = {
    "type": "answer", "id": 115097, "reference": 115097, "lang": "ar",
    "createdAt": "2008-03-26T00:00:00.000Z", "updatedAt": "2020-02-11T06:17:41.000Z",
    "title": "اكتتب في عدة شركات", "question": "<p>فهل تجب الزكاة ؟</p>\n",
    "body": "<p>أولا : يجوز &quot;الاكتتاب&quot;</p><p>ثانيا : <strong>لا</strong></p>",
    "source": {"reference": 5, "title": "الإسلام سؤال وجواب"}, "contentLangs": ["ar", "en"],
    "topics": [{"reference": 150, "title": "الاستثمار",
                "ancestors": [{"reference": 56, "title": "الفقه"}, {"reference": 146, "title": "البيوع"}]}],
    "subsites": [{"reference": 47, "title": "الاختلاط", "ancestors": []}],
    "fatawas": [{"reference": 7535, "title": "x", "question": "<p>y</p>"}],
}


def ev(op, data, serial="1"):
    return {"serial": serial, "op": op, "type": data["type"], "data": data}


def test_dump_witness_url_is_pinned_to_a_snapshot_folder():
    w = {"kind": "zadapps", "base": "https://files.zadapps.info/m.islamqa.info", "folder": "dumps/2026-10-04-220000/ar", "file": "data.ndjson.gz"}
    assert witness_url(w) == "https://files.zadapps.info/m.islamqa.info/dumps/2026-10-04-220000/ar/data.ndjson.gz"


def test_snapshot_witnesses_one_per_pinned_language():
    dump = {"base": "B", "snapshot": "dumps/S", "file": "data.ndjson.gz", "langs": {"ar": {"sha256": "h"}}}
    (w,) = snapshot_witnesses(dump)
    assert w == {"id": "islamqa-ar", "kind": "zadapps", "base": "B", "folder": "dumps/S/ar", "file": "data.ndjson.gz",
                 "format": "ndjson.gz", "lang": "ar", "sha256": "h"}


def test_html_text_keeps_paragraphs_and_unescapes():
    assert html_text(ANSWER["body"]) == 'أولا : يجوز "الاكتتاب"\nثانيا : لا'
    assert html_text(None) is None and html_text("<p> </p>") is None


def test_fold_applies_created_updated_deleted_in_order():
    other = {**ANSWER, "reference": 2, "id": 2}
    events = [ev("created", ANSWER), ev("created", other), ev("updated", {**ANSWER, "title": "new"}), ev("deleted", other)]
    assert fold(events) == {("answer", 115097): {**ANSWER, "title": "new"}}


def test_answer_record_flattens_topic_paths_and_cross_references():
    r = answer_record(ANSWER)
    assert r["id"] == "islamqa.115097" and r["lang"] == "ar"
    assert r["url"] == "https://islamqa.info/ar/answers/115097"
    assert r["question"] == "فهل تجب الزكاة ؟"
    assert r["answer"].endswith("ثانيا : لا")
    assert r["source"] == {"ref": 5, "title": "الإسلام سؤال وجواب"}
    assert r["topics"] == [{"ref": 150, "path": ["الفقه", "البيوع", "الاستثمار"]}]
    assert r["subsites"] == [{"ref": 47, "path": ["الاختلاط"]}]
    assert r["see_also"] == ["islamqa.7535"]
    assert r["langs"] == ["ar", "en"] and r["created"] == "2008-03-26" and r["updated"] == "2020-02-11"
