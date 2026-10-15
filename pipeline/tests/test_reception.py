import json
from pathlib import Path

from usul_corpus.reception import Cited, authors, citations, matcher, pages, report, spans

ROOT = Path(__file__).resolve().parents[2]

MUGHNI = Cited("ibn_qudama.mughni", ("المغني",), ("الذهبي في المغني",))
MAJMU = Cited("ibn_taymiyya.majmu_fatawa", ("مجموع الفتاوى",))
MUSTADRAK = Cited("ibn_taymiyya.mustadrak", ("المستدرك على مجموع الفتاوى",))
ZAD = Cited("ibn_qayyim.zad_maad", ("زاد المعاد",))
AWSAT = Cited("ibn_mundhir.awsat", ("ابن المنذر في الاوسط",))
MATCH = matcher((MUGHNI, MAJMU, MUSTADRAK, ZAD, AWSAT))


def test_pages_close_on_their_marker_and_drop_markup():
    text = "#META#Header#End#\n# قال في ~~المغني\nPageV01P007\n# وفي «زاد المعاد»\nPageV02P010\n# بلا رقم"
    assert pages(text) == (("PageV01P007", "قال في المغني"), ("PageV02P010", "وفي «زاد المعاد»"), (None, "بلا رقم"))


def test_single_word_titles_need_a_citation_cue():
    assert MATCH("قال في المغني كذا") == ("ibn_qudama.mughni",)
    assert MATCH("وقال صاحب «المغني»: كذا") == ("ibn_qudama.mughni",)
    assert MATCH("الله هو المغني") == ()  # no cue: the divine name, not the book


def test_multi_word_titles_match_literally_after_normalisation():
    assert MATCH("كما في زَادِ المَعَاد وغيره") == ("ibn_qayyim.zad_maad",)
    assert MATCH("انظر مجموع الفتاوي (٢٠/٥٠)") == ("ibn_taymiyya.majmu_fatawa",)  # ى/ي unified


def test_quotes_and_brackets_never_split_a_form():
    assert MATCH("رواه ابن المنذر في «الأوسط» (٢/٣)") == ("ibn_mundhir.awsat",)
    assert MATCH("رواه الطبراني في «الأوسط»") == ()


def test_longest_form_wins_and_each_span_counts_once():
    assert MATCH("في المستدرك على مجموع الفتاوى") == ("ibn_taymiyya.mustadrak",)
    assert MATCH("في مجموع الفتاوى وفي المغني") == ("ibn_taymiyya.majmu_fatawa", "ibn_qudama.mughni")


def test_exclusions_shadow_a_title_they_cover():
    assert MATCH("وذكره الذهبي في المغني في الضعفاء") == ()


def test_citations_locate_each_hit_on_its_page():
    text = "#META#Header#End#\n# في المغني\nPageV01P001\n# في المغني وزاد المعاد\nPageV01P002\n"
    assert citations(text, MATCH) == (("ibn_qudama.mughni", "PageV01P001"), ("ibn_qudama.mughni", "PageV01P002"),
                                      ("ibn_qayyim.zad_maad", "PageV01P002"))


def test_report_aggregates_by_witness_and_scholar():
    hits = {"w1": (("a", "PageV01P001"), ("a", "PageV01P002"), ("b", "PageV01P003")), "w2": (("a", "PageV01P009"),)}
    rep = report(hits, {"w1": "ibn_baz", "w2": "albani"}, samples=1)
    assert rep["a"] == {"total": 3, "by_scholar": {"albani": 1, "ibn_baz": 2}, "by_witness": {"w1": 2, "w2": 1},
                        "sample": ["src:w1/PageV01P001"]}
    assert rep["b"]["total"] == 1


def test_committed_report_agrees_with_the_registry():
    """Every counted work is a registered `cited` work; every citer witness belongs to a registered citer;
    totals are the sums of their parts. Runs against the committed report (no cache needed)."""
    reg = json.loads((ROOT / "corpus/registry.json").read_text(encoding="utf-8"))
    by_role = {r: {w["id"]: w for w in reg["works"] if w.get("reception", {}).get("role") == r} for r in ("cited", "citer")}
    citer_witnesses = {x["id"]: w["reception"]["scholar"] for w in by_role["citer"].values() for x in w["witnesses"]}
    rep = json.loads((ROOT / "corpus/reception/report.json").read_text(encoding="utf-8"))
    assert set(rep["counts"]) == set(by_role["cited"])
    assert set(rep["authors"]) == {a.work for a in authors(ROOT / "corpus/reception/authors.json")}
    assert set(rep["citers"]) <= set(citer_witnesses)
    for wid, c in rep["citers"].items():
        assert c["scholar"] == citer_witnesses[wid]
    for work, c in {**rep["counts"], **rep["authors"]}.items():
        assert c["total"] == sum(c["by_scholar"].values()) == sum(c["by_witness"].values()), work
        assert set(c["by_witness"]) <= set(rep["citers"]), work


def test_cited_works_declare_usable_forms():
    reg = json.loads((ROOT / "corpus/registry.json").read_text(encoding="utf-8"))
    cited = [w for w in reg["works"] if w.get("reception", {}).get("role") == "cited"]
    assert cited and all(w["reception"]["cite_as"] for w in cited)
    forms = [f for w in cited for f in w["reception"]["cite_as"]]
    assert len(forms) == len(set(forms)), "a citation form names one work only"


def test_counts_page_ranks_by_total_and_names_every_scholar_column():
    from usul_corpus.reception import render_counts
    rep = {"citers": {"w1": {"work": "x.a", "scholar": "ibn_baz", "pages": 9}}, "missing": [],
           "counts": {"a.b": {"total": 1, "by_scholar": {"ibn_baz": 1}, "by_witness": {"w1": 1}, "sample": ["src:w1/PageV01P001"]},
                      "c.d": {"total": 5, "by_scholar": {"ibn_baz": 5}, "by_witness": {"w1": 5}, "sample": []}}}
    titles = {"a.b": ("A", "fatawa"), "c.d": ("C", "matn"), "x.a": ("X", "fatawa")}
    page = render_counts(rep, titles)
    assert page.index("| C |") < page.index("| A |")
    assert "Ibn Bāz | Ibn ʿUthaymīn | al-Albānī | al-Saʿdī" in page
    assert "`src:w1/PageV01P001`" in page


TAYMIYYA = Cited("ibn_taymiyya", ("ابن تيمية", "شيخ الإسلام", "شيخ الإسلام ابن تيمية"), ("شيخ الإسلام محمد بن عبد الوهاب", "المجد ابن تيمية"))
MAJD = Cited("majd", ("المجد ابن تيمية",))
NAWAWI = Cited("nawawi", ("النووي",))
AUTHORS = matcher((TAYMIYYA, MAJD, NAWAWI), cue_single=False)


def test_author_forms_need_no_cue_and_count_once():
    assert AUTHORS("قال النووي رحمه الله") == ("nawawi",)
    assert AUTHORS("قال شيخ الإسلام ابن تيمية") == ("ibn_taymiyya",)


def test_a_positive_form_beats_an_exclusion_on_the_same_span():
    assert AUTHORS("واختاره المجد ابن تيمية") == ("majd",)
    assert AUTHORS("قال شيخ الإسلام محمد بن عبد الوهاب") == ()


def test_spans_expose_offsets_into_the_normalised_text():
    t = "وقال في المغني"
    assert spans(t, (MUGHNI,)) == ((8, 14, "ibn_qudama.mughni"),)


def test_author_lexicon_is_keyed_by_cited_work_prefixes():
    reg = json.loads((ROOT / "corpus/registry.json").read_text(encoding="utf-8"))
    prefixes = {w["id"].split(".")[0] for w in reg["works"] if w.get("reception", {}).get("role") == "cited"}
    lex = authors(ROOT / "corpus/reception/authors.json")
    assert {a.work for a in lex} <= prefixes
    forms = [f for a in lex for f in a.cite_as]
    assert len(forms) == len(set(forms)), "an author form names one author only"


def test_exclusions_apply_when_the_lexicon_is_a_one_shot_iterator():
    """Regression: build() passes a generator; compiling forms and exclusions must not exhaust it first."""
    match = matcher(c for c in (MUGHNI,))
    assert match("وقال الذهبي في المغني") == ()
    assert match("وقال في المغني") == ("ibn_qudama.mughni",)


def test_the_grandfather_of_shaykh_al_islam_is_the_majd():
    """«جد شيخ الإسلام ابن تيمية» names Majd al-Dīn; the trailing «ابن تيمية» must not count for the grandson."""
    match = matcher(authors(ROOT / "corpus/reception/authors.json"), cue_single=False)
    assert match("وصرح به المجد جد شيخ الإسلام ابن تيمية") == ("majd",)
    assert match("ومنهم جد شيخ الإسلام ابن تيمية، وهو مجد الدين") == ("majd",)  # bare «مجد الدين» is not a form
