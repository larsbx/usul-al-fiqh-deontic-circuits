from usul_corpus.fatawa import normalize
from usul_corpus.fetch import witness_url

ROW = {"Global ID": "G_ID_1", "original_id": "10776", "topic": "Belief",
       "title_ar": "ما هي أسباب زيادة الإيمان ؟", "question_ar": "", "answer_ar": "الحمد لله.للزيادة أسباب",
       "link_ar": "https://islamqa.info/ar/answers/10776/x",
       "title_en": "The best means", "question_en": "q", "answer_en": "Praise be to Allah.",
       "link_en": "https://islamqa.info/en/answers/10776/y"}


def test_huggingface_witness_url_is_pinned_to_a_revision():
    w = {"kind": "huggingface", "repo": "kingkaung/islamqainfo_parallel_corpus", "revision": "abc", "file": "a.parquet"}
    assert witness_url(w) == "https://huggingface.co/datasets/kingkaung/islamqainfo_parallel_corpus/resolve/abc/a.parquet"


def test_normalize_merges_topics_of_duplicate_ids_and_keeps_languages():
    (r,) = normalize([ROW, {**ROW, "Global ID": "G_ID_2", "topic": "Repentance"}], langs=("ar", "en"))
    assert r["id"] == "islamqa.10776"
    assert r["topics"] == ["Belief", "Repentance"]
    assert r["ar"] == {"title": ROW["title_ar"], "question": None, "answer": ROW["answer_ar"], "url": ROW["link_ar"]}
    assert r["en"]["answer"] == "Praise be to Allah."


def test_normalize_drops_languages_without_an_answer_and_rows_without_any():
    blank = {**ROW, "original_id": "2", "answer_ar": " ", "answer_en": None}
    (r,) = normalize([ROW, blank, {**ROW, "answer_ar": ""}], langs=("ar", "fr"))
    assert set(r) == {"id", "topics", "ar"}


def test_normalize_is_sorted_by_numeric_id():
    rows = [{**ROW, "original_id": i} for i in ("100", "9", "20")]
    assert [r["id"] for r in normalize(rows, langs=("ar",))] == ["islamqa.9", "islamqa.20", "islamqa.100"]
