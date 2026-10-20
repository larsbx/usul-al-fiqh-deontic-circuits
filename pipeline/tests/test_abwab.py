import json
from pathlib import Path

import jsonschema
from usul_corpus.abwab import segment_abwab, split_masail
from usul_corpus.records import bab_record
from usul_corpus.units import unit_records

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


MASAIL = """#META#Header#End#
# كتاب الصلاة
# [1 - باب مواقيت الصلاة]
# - أول وقت الظهر: الزوال.
# - وأوقات الكراهة:
# 1 - بعد الفجر.
# 2 - وعند الزوال.
PageV01P008
# 2 - باب الأذان
# - يشرع لأهل كل بلد:
# 1 - أن يتخذوا مؤذنا.
# - ويشرع للسامع أن يتابع
~~المؤذن.
# 3 - باب
# ويجب على المصلي:
# 1 - تطهير ثوبه.
# 2 - ولا يصلي:
# - في ثوب حرير.
# - ولا مغصوب.
# 3 - وعليه استقبال الكعبة.
# فصل
# [في مبطلات الصلاة]
# - وتبطل بالكلام.
PageV01P009
"""


def test_numbered_body_headings_open_babs_titled_from_the_rank_word():
    """al-Ghurar numbers some bāb headings («2 - باب الأذان», «[1 - باب مواقيت الصلاة]»); the title
    starts at the rank word, as al-Darārī prints them."""
    assert [(u.rank, u.heading, u.path) for u in segment_abwab(MASAIL, body_headings=True)] == [
        ("bab", "باب مواقيت الصلاة", ("كتاب الصلاة",)),
        ("bab", "باب الأذان", ("كتاب الصلاة",)),
        ("bab", "باب", ("كتاب الصلاة",)),
        ("fasl", "فصل", ("كتاب الصلاة", "باب")),
    ]


def test_a_unit_splits_into_masail_with_their_enumerations():
    """«- …» or a plain statement opens a masʾala; «N - …» items belong to it; after an item ending «:»
    its «- …» lines are sub-items; «[…]» is a subtitle; a «~~» line continues the one before."""
    units = segment_abwab(MASAIL, body_headings=True, masail=True)
    assert [[m.text for m in split_masail(u)] for u in units] == [
        ["- أول وقت الظهر: الزوال.", "- وأوقات الكراهة: 1 - بعد الفجر. 2 - وعند الزوال."],
        ["- يشرع لأهل كل بلد: 1 - أن يتخذوا مؤذنا.", "- ويشرع للسامع أن يتابع المؤذن."],
        ["ويجب على المصلي: 1 - تطهير ثوبه. 2 - ولا يصلي: - في ثوب حرير. - ولا مغصوب. 3 - وعليه استقبال الكعبة."],
        ["- وتبطل بالكلام."],
    ]
    assert [(m.page, m.end_page) for m in split_masail(units[0])] == [((1, 8), (1, 8)), ((1, 8), (1, 8))]


def test_masala_records_follow_their_bab_and_conform_to_the_schema():
    schema = json.loads((ROOT / "schemas/usul_rule.schema.json").read_text())
    seg = {"kind": "abwab", "body_headings": True, "masail": True}
    records = unit_records({"id": "a.b", "rights": "public_domain_text"}, "w-x", seg, MASAIL)
    for r in records:
        jsonschema.validate(r, schema)
    assert [(r["id"], r["record_type"]) for r in records[:3]] == [
        ("a.b.w_x.b00001", "bab"), ("a.b.w_x.b00001.m001", "masala"), ("a.b.w_x.b00001.m002", "masala")]
    m = records[1]
    assert (m["path_ar"], m["heading_ar"], m["locator"], m["page_span"]) == (
        ["كتاب الصلاة"], "باب مواقيت الصلاة", "src:w-x/v01:p008#b00001.m001", [8, 8])
    fasl = next(r for r in records if r["id"] == "a.b.w_x.b00004.m001")
    assert (fasl["path_ar"], fasl["heading_ar"]) == (["كتاب الصلاة", "باب"], "فصل")
    assert unit_records({"id": "a.b", "rights": "public_domain_text"}, "w-x", {"kind": "abwab"}, ZAD) == [
        bab_record({"id": "a.b", "rights": "public_domain_text"}, "w-x", i, u) for i, u in enumerate(segment_abwab(ZAD), 1)]


def test_the_audit_counts_units_and_masail_apart():
    from usul_corpus.__main__ import unit_audit
    seg = {"kind": "abwab", "body_headings": True, "masail": True}
    records = unit_records({"id": "a.b", "rights": "public_domain_text"}, "w-x", seg, MASAIL)
    assert unit_audit(records) == {"found": 4, "masail": 6, "ranks": {"bab": 3, "fasl": 1}}
    assert unit_audit([r for r in records if r["record_type"] == "bab"]) == {"ranks": {"bab": 3, "fasl": 1}}


def test_a_wrapped_line_that_opens_a_masala_does_not_continue_the_line_before():
    """OpenITI wraps «# باب حد القذف PageV01P084» and the first masʾala as «~~- من رمى …»: the masʾala
    is not part of the heading."""
    text = ("#META#Header#End#\n# كتاب الحدود\n# باب حد السرقة\n# - وقد ثبت القطع في جحد\n~~العارية.\n"
            "# باب حد القذف PageV01P084\n~~- من رمى غيره وجب عليه الحد.\n# - ويسقط بأربعة شهود.\nPageV01P085\n")
    units = segment_abwab(text, body_headings=True, masail=True)
    assert [u.heading for u in units] == ["باب حد السرقة", "باب حد القذف"]
    assert [[m.text for m in split_masail(u)] for u in units] == [
        ["- وقد ثبت القطع في جحد العارية."], ["- من رمى غيره وجب عليه الحد.", "- ويسقط بأربعة شهود."]]


def test_a_sentence_broken_across_lines_is_one_masala_and_a_bare_title_is_a_subtitle():
    """al-Ghurar's manāsik print one step per line and break a sentence across lines: a plain line
    continues a masʾala whose last line has no sentence end. Before the first masʾala, an unpunctuated
    plain line («مستحبات الوضوء», «في حقوق الراعي والرعية») is a subtitle, as «[…]» is."""
    text = ("#META#Header#End#\n# كتاب الحج\n# فصل\n# [في صفة الحج]\n# - ثم يأتي عرفة صبح يوم عرفة\n# ملبيا مكبرا\n"
            "# ويخطب.\n# ثم يفيض من عرفة\n# ويبيت بها (¬1).\n# - ولا حرج.\n# فصل\n# مستحبات الوضوء\n"
            "# ويستحب: 1 - التثليث.\n# فصل\n# - المهر واجب\n# - وتكره المغالاة فيه\nPageV01P037\n")
    assert [[m.text for m in split_masail(u)] for u in segment_abwab(text, body_headings=True, masail=True)] == [
        ["- ثم يأتي عرفة صبح يوم عرفة ملبيا مكبرا ويخطب.", "ثم يفيض من عرفة ويبيت بها (¬1).", "- ولا حرج."],
        ["ويستحب: 1 - التثليث."],
        ["- المهر واجب", "- وتكره المغالاة فيه"],
    ]


def test_a_numbered_fasl_heading_opens_a_fasl():
    """«5 - فصل» in al-Ghurar's Kitāb al-Ṣalāt is a heading, not the fifth item of a list."""
    text = ("#META#Header#End#\n# كتاب الصلاة\n# 4 - باب كيفية الصلاة\n# - ويكبر.\n# 5 - فصل\n"
            "# [في مبطلات الصلاة]\n# وتبطل الصلاة:\n# 1 - بالكلام.\nPageV01P011\n")
    units = segment_abwab(text, body_headings=True, masail=True)
    assert [(u.rank, u.heading, u.path) for u in units] == [
        ("bab", "باب كيفية الصلاة", ("كتاب الصلاة",)), ("fasl", "فصل", ("كتاب الصلاة", "باب كيفية الصلاة"))]
    assert [[m.text for m in split_masail(u)] for u in units] == [["- ويكبر."], ["وتبطل الصلاة: 1 - بالكلام."]]
