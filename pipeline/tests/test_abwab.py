import json
from pathlib import Path

import jsonschema
from usul_corpus.abwab import segment_abwab
from usul_corpus.records import bab_record

ROOT = Path(__file__).resolve().parents[2]

ZAD = """#META#Header#End#
### | مقدمة المحقق
# الحمد لله
PageV01P003
### | كتاب الطهارة
### | مدخل
# وهي ارتفاع الحدث.
### | باب الآنية
# كل إناء طاهر يباح اتخاذه.
PageV01P004
# فصل
# ويجزئ الحجر. وفصلت المسألة هنا.
### | كتاب الصلاة
### | باب الأذان
# هما فرضا كفاية.
PageV01P005
"""

MUQNI = """#META#Header#End#
### ||| CHECK مولده
# ولد سنة 541
### | AUTO كتاب الطهارة
# وهي ارتفاع الحدث.
### || AUTO باب الآنية
# كل إناء طاهر يباح اتخاذه.
### ||| AUTO فصل
# ويجزئ الحجر. وفصلت المسألة هنا.
PageV01P004
"""


def _shape(units):
    return [(u.rank, u.path, u.heading, u.text) for u in units]


def test_units_are_kitab_bab_and_fasl_runs_with_their_path():
    assert _shape(segment_abwab(ZAD)) == [
        ("kitab", (), "كتاب الطهارة", "كتاب الطهارة وهي ارتفاع الحدث."),
        ("bab", ("كتاب الطهارة",), "باب الآنية", "باب الآنية كل إناء طاهر يباح اتخاذه."),
        ("fasl", ("كتاب الطهارة", "باب الآنية"), "فصل", "فصل ويجزئ الحجر. وفصلت المسألة هنا."),
        ("bab", ("كتاب الصلاة",), "باب الأذان", "باب الأذان هما فرضا كفاية."),
    ]


def test_rank_comes_from_the_heading_word_not_the_markdown_level():
    """Zād puts every heading at «|», al-Muqniʿ nests them at «|», «||», «|||»: the units agree."""
    assert _shape(segment_abwab(MUQNI)) == _shape(segment_abwab(ZAD))[:3]


def test_pages_follow_the_openiti_convention():
    units = segment_abwab(ZAD)
    assert [(u.page, u.end_page) for u in units] == [((1, 4), (1, 4)), ((1, 4), (1, 4)), ((1, 5), (1, 5)), ((1, 5), (1, 5))]


def test_bab_records_conform_to_the_schema_and_respect_rights():
    schema = json.loads((ROOT / "schemas/usul_rule.schema.json").read_text())
    u = segment_abwab(ZAD)[2]
    r = bab_record({"id": "a.b", "rights": "public_domain_text"}, "w-x", 3, u)
    jsonschema.validate(r, schema)
    assert (r["id"], r["record_type"], r["rank"], r["path_ar"], r["heading_ar"]) == (
        "a.b.w_x.b00003", "bab", "fasl", ["كتاب الطهارة", "باب الآنية"], "فصل")
    assert r["sha256"] == u.sha256 and r["page_span"] == [5, 5]



def test_a_bare_rank_heading_takes_the_next_heading_as_its_title():
    text = "#META#Header#End#\n### | كتاب الديات\n### | باب \n### | دية الأعضاء ومنافعها\n# في الأنف الدية.\n### | *\n# وفي العينين الدية.\nPageV01P009\n"
    (u,) = segment_abwab(text)
    assert (u.rank, u.heading, u.path) == ("bab", "باب دية الأعضاء ومنافعها", ("كتاب الديات",))
    assert u.text == "باب دية الأعضاء ومنافعها في الأنف الدية. وفي العينين الدية."  # «*» is navigation


def test_the_end_heading_closes_the_matn():
    """The editor's closing matter and bibliography after the matn are not part of its last faṣl."""
    text = MUQNI + "### | CHECK خاتمة الكتاب والتحقيق\n# والحمد لله\n### | AUTO مصادر ومراجع التحقيق\n# 1 - المغني\nPageV01P005\n"
    assert _shape(segment_abwab(text, end="خاتمة الكتاب")) == _shape(segment_abwab(MUQNI))


GHURAR = """#META#Header#End#
# الحمد لله (¬1).
# كتاب الطهارة
# باب المياه
# - الماء طاهر مطهر.
PageV01P001
# فصل
# [في تطهير النجاسات]
# - والنعل بالمسح.
# باب قضاء الحاجة
# - على المتخلي الاستتار.
PageV01P002
# ### |EDITOR|
# ENDNOTES
# (¬1) - هذا الكتاب من أحسن المختصرات.
# باب في الشرح لا يفتح وحدة
PageV01P003
"""


def test_body_rank_lines_open_units_only_when_the_witness_asks():
    """al-Ghurar al-Naqiyya prints «كتاب …», «باب …» as body lines; Zād's body «باب» is prose."""
    assert segment_abwab(GHURAR) == ()
    assert _shape(segment_abwab(GHURAR, end=r"\|EDITOR\|", body_headings=True)) == [
        ("bab", ("كتاب الطهارة",), "باب المياه", "باب المياه - الماء طاهر مطهر."),
        ("fasl", ("كتاب الطهارة", "باب المياه"), "فصل", "فصل [في تطهير النجاسات] - والنعل بالمسح."),
        ("bab", ("كتاب الطهارة",), "باب قضاء الحاجة", "باب قضاء الحاجة - على المتخلي الاستتار."),
    ]


def test_a_long_body_line_beginning_with_a_rank_word_is_prose():
    text = "#META#Header#End#\n# كتاب الطهارة\n# - الماء طاهر.\n# - والنعل بالمسح.\n# باب من أبواب العلم الواسعة يذكر فيه الفقهاء ما يلي\nPageV01P001\n"
    assert [u.rank for u in segment_abwab(text, body_headings=True)] == ["kitab"]


def test_a_heading_the_edition_misranks_can_be_ranked_as_a_kitab():
    """al-Ghurar prints «باب النكاح» where the matn's other witnesses have «كتاب النكاح»: nikāḥ is
    not a bāb of al-Ḥajj."""
    text = ("#META#Header#End#\n# كتاب الحج\n# - يجب على كل مكلف مستطيع.\n# باب النكاح\n# - يشرع لمن استطاع الباءة.\n"
            "# فصل\n# - ولا نكاح إلا بولي.\nPageV01P001\n")
    assert [(u.rank, u.path, u.heading) for u in segment_abwab(text, body_headings=True)][1:] == [
        ("bab", ("كتاب الحج",), "باب النكاح"), ("fasl", ("كتاب الحج", "باب النكاح"), "فصل")]
    assert [(u.rank, u.path, u.heading) for u in segment_abwab(text, body_headings=True, kitab_headings={"باب النكاح"})][1:] == [
        ("kitab", (), "باب النكاح"), ("fasl", ("باب النكاح",), "فصل")]
