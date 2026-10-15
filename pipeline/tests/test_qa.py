import hashlib
import json
from pathlib import Path

import jsonschema
import pytest

from usul_corpus.qa import segment_entries, segment_qa
from usul_corpus.records import fatwa_record, masala_record
from usul_corpus.units import UNIT_SEGMENTERS

ROOT = Path(__file__).resolve().parents[2]

KUBRA = """#META#Header#End#
# مقدمة المحقق لا تعد سؤالا
PageV01P001
### | [مسألة جندي قلع بياض لحيته]
### | 3 -
# مسألة:
# في رجل جندي قلع بياض لحيته، فهل عليه في ذلك إثم؟ وإذا دعا الإمام
~~والمأموم عقيب صلاة الفرض، جائز أم لا؟
# الجواب: الحمد لله رب العالمين. نتف الشيب مكروه
PageV01P002
# للجندي وغيره.
# مسألة:
# في رجل نذر صوما ولم يجب عنه هنا
PageV01P003
"""
Q, A = r"(?:\[?مسألة)", r"(?:الجواب)"


def test_units_run_from_question_marker_to_the_next_and_split_at_the_answer():
    units = segment_qa(KUBRA, Q, A)
    assert len(units) == 2
    first = units[0]
    assert first.question.startswith("[مسألة جندي") and "عقيب صلاة الفرض" in first.question
    assert "~~" not in first.question and "#" not in first.question
    assert first.answer.startswith("الجواب: الحمد لله") and first.answer.endswith("للجندي وغيره.")
    assert (first.page, first.end_page) == ((1, 2), (1, 3))  # OpenITI: a marker closes its page
    assert units[1].answer is None


def test_the_receipt_is_the_sha256_of_the_unit_text():
    u = segment_qa(KUBRA, Q, A)[0]
    assert u.sha256 == hashlib.sha256(u.text.encode()).hexdigest()
    assert u.text == f"{u.question} {u.answer}"


def test_numbered_lajna_style_markers_and_html_wrappers():
    text = ("#META#Header#End#\n# السؤال الثالث من الفتوى رقم (782) :\n# س3: <span>هل يجوز كذا؟</span>\n"
            "# ج3: لا يجوز.\n# عضو ... عبد الله\nPageV01P058\n# س4: نصه كذا؟\n# ج4: نعم.\nPageV01P059\n")
    units = segment_qa(text, r"(?:السؤال|س\d*\s*:)", r"(?:ج\d*\s*:)")
    assert [u.number for u in units] == [3, 4]
    assert units[0].question == "السؤال الثالث من الفتوى رقم (782) : س3: هل يجوز كذا؟"
    assert units[0].answer == "ج3: لا يجوز. عضو ... عبد الله"


def test_a_marker_mid_line_does_not_start_a_unit():
    text = "#META#Header#End#\n# وسئل: عن رجل؟\n# فأجاب: وسئل مالك عن مثله فقال: لا.\nPageV01P001\n"
    units = segment_qa(text, r"(?:و?سئل)", r"(?:فأجاب)")
    assert len(units) == 1 and "وسئل مالك" in units[0].answer


def test_fatwa_records_conform_to_the_schema_and_respect_rights():
    schema = json.loads((ROOT / "schemas/usul_rule.schema.json").read_text())
    u = segment_qa(KUBRA, Q, A)[0]
    for rights, cap in (("public_domain_text", 400), ("modern_cache_only", 160)):
        r = fatwa_record({"id": "a.b", "rights": rights}, "w-x", 1, u)
        jsonschema.validate(r, schema)
        assert r["id"] == "a.b.w_x.qa00001" and r["record_type"] == "fatwa" and r["sha256"] == u.sha256
        assert len(r["question_ar"]) <= cap and len(r["answer_ar"]) <= cap
        assert r["locator"] == "src:w-x/v01:p002#qa00001" and r["page_span"] == [2, 3]


def test_a_section_heading_after_the_answer_ends_the_unit():
    """A treatise between fatāwā is not part of the last answer before it."""
    text = ("#META#Header#End#\n# وسئل: عن رجل؟\n# فأجاب: لا.\n### | رسالة في السماع\n# الحمد لله، أما بعد فهذه رسالة طويلة\n"
            "PageV01P001\n# وسئل: عن آخر؟\n# فأجاب: نعم.\nPageV01P002\n")
    units = segment_qa(text, r"(?:و?سئل)", r"(?:فأجاب)")
    assert [u.answer for u in units] == ["فأجاب: لا.", "فأجاب: نعم."]


def test_an_unanswered_unit_keeps_only_its_question_header():
    """A question marker with no answer before the next unit does not absorb the text after it."""
    body = "".join(f"# سطر سرد {i}\n" for i in range(20))
    text = f"#META#Header#End#\n# وسئل: عن رجل؟\n{body}PageV01P001\n# وسئل: عن آخر؟\n# فأجاب: نعم.\nPageV01P002\n"
    first = segment_qa(text, r"(?:و?سئل)", r"(?:فأجاب)")[0]
    assert first.answer is None and first.question.count("سطر سرد") == 3  # the header's lines, no more


def _unit_witnesses():
    reg = json.loads((ROOT / "corpus/registry.json").read_text(encoding="utf-8"))
    return [(w, x) for w in reg["works"] if w.get("segmenter", {}).get("kind") in UNIT_SEGMENTERS for x in w["witnesses"]]


@pytest.mark.parametrize("work,witness", _unit_witnesses(), ids=lambda v: v["id"] if isinstance(v, dict) else v)
def test_committed_unit_records_replay_from_the_pinned_witness(work, witness):
    """Stability replay: re-segmenting the cached witness reproduces every committed id and receipt."""
    cached = ROOT / ".cache/corpus" / f"{witness['id']}.txt"
    if not cached.exists():
        pytest.skip("witness not cached")
    seg = witness.get("segmenter", work["segmenter"])
    cut, record = UNIT_SEGMENTERS[seg["kind"]]
    replay = [(record(work, witness["id"], i, u)["id"], u.sha256) for i, u in enumerate(cut(cached.read_text(encoding="utf-8"), seg), 1)]
    committed = [(r["id"], r["sha256"]) for r in map(json.loads, (ROOT / "corpus/records" / f"{witness['id']}.jsonl").read_text(encoding="utf-8").splitlines())]
    assert replay == committed


KAWSAJ = """#META#Header#End#
# مقدمة المحقق
### | [1103-1] قلت: إذا أمر الرجل ابنه أن يطلق امرأته؟
# قال: يطيع أباه إذا كان الأب رجلا صالحا. PageV04P1728
### | [1104-] قلت: فأمه؟
# قال: لا يطيعها في هذا.
# قال إسحاق: إن فعل ما قال أبوه وأمه كان قد أخذ بالفضيلة.
PageV04P1729
"""

HARB = """#META#Header#End#
### $ 19- باب: النظر إلى المرأة التي يريد أن يتزوجها.
# قلت لأحمد: الرجل يريد أن يتزوج المرأة, هل ينظر إليها؟
# قال: إذا خاف ريبة.
# حدثنا يحيى بن عبد الحميد، قال: حدثنا شريك
PageV01P215
### $ 20- باب: من فجر بأخت امرأته.
# سألت أحمد, قلت: رجل تزوج أخت امرأته؟
PageV01P218
"""


def test_entries_run_from_one_opening_formula_to_the_next_and_take_the_printed_number():
    units = segment_entries(KAWSAJ, r"\[\s*(?P<n>\d+)\s*-")
    assert [u.number for u in units] == [1103, 1104]
    assert units[0].text == "[1103-1] قلت: إذا أمر الرجل ابنه أن يطلق امرأته؟ قال: يطيع أباه إذا كان الأب رجلا صالحا."
    assert "قال إسحاق" in units[1].text and units[1].page == (4, 1729)


def test_a_section_heading_that_is_not_an_opening_ends_the_entry():
    units = segment_entries(HARB, r"(?:قلت لأحمد|و?سألت أحمد)")
    assert len(units) == 2
    assert units[0].text.endswith("حدثنا شريك") and "باب" not in units[0].text
    assert units[1].text.startswith("سألت أحمد") and units[0].number is None


def test_masala_records_conform_to_the_schema():
    schema = json.loads((ROOT / "schemas/usul_rule.schema.json").read_text())
    u = segment_entries(KAWSAJ, r"\[\s*(?P<n>\d+)\s*-")[0]
    r = masala_record({"id": "a.b", "rights": "public_domain_text"}, "w-x", 1, u)
    jsonschema.validate(r, schema)
    assert (r["id"], r["record_type"], r["number"], r["sha256"]) == ("a.b.w_x.m00001", "masala", 1103, u.sha256)


def test_the_placeholder_page_marker_closes_no_page():
    """OpenITI's PageV00P000 marks a page the source did not number: its lines are on no known page."""
    text = "#META#Header#End#\n# قلت لأحمد: كذا؟ قال: لا.\nPageV00P000\n# قلت لأحمد: آخر؟ قال: نعم.\nPageV01P007\n"
    first, second = segment_entries(text, r"(?:قلت لأحمد)")
    assert (first.page, first.end_page, second.page) == (None, None, (1, 7))
    assert masala_record({"id": "a.b", "rights": "public_domain_text"}, "w-x", 1, first)["page_span"] is None


def test_a_heading_can_be_the_question():
    """Nūr ʿalā al-Darb (Ibn ʿUthaymīn): the question is the section heading, with no marker word."""
    text = ("#META#Header#End#\n# ***\n### | السائل أحمد يقول: ما حكم كذا؟\n# فأجاب رحمه الله تعالى: لا يجوز.\n# ***\nPageV04P002\n"
            "### | وهذه سائلة تقول: وما حكم كذا؟\n# فأجاب رحمه الله تعالى: يجوز.\nPageV04P003\n")
    units = segment_qa(text, None, r"(?:فأجاب)", question_heading=True)
    assert [(u.question, u.answer) for u in units] == [
        ("السائل أحمد يقول: ما حكم كذا؟", "فأجاب رحمه الله تعالى: لا يجوز. ***"),
        ("وهذه سائلة تقول: وما حكم كذا؟", "فأجاب رحمه الله تعالى: يجوز.")]


MBI = r"(?:\((?=\d)|(?=\d+\s*-\s*$))(?P<n>\d+)\s*[-_]?\s*(?:$|(?=[^\W\d_]|\())"  # as in corpus/registry.json


def test_ordered_entries_keep_only_the_increasing_run_of_numbers():
    """Fatāwā Muḥammad b. Ibrāhīm: a letter's own enumeration «(1- …)» and references «(20547 وتاريخ …)»
    look like openings; only the collection's increasing numbering opens entries."""
    text = ("#META#Header#End#\n# (1002 كذا) نص\n# (1003- كذا) نص\n# (1004- أخذ الزكاة) من محمد بن إبراهيم إلى فلان\n# (1- أولا كذا)\n### | 2- \n# ثانيا كذا\n"
            "# (20547 وتاريخ 3-4-1375ه)\n### | 1005 - \n# ما يفعله بعض القبائل\n# (1006 الثالثة) والجواب: لا.\nPageV01P001\n")
    units = segment_entries(text, MBI, ordered=True)
    assert [u.number for u in units] == [1002, 1003, 1004, 1005, 1006]
    assert "2- ثانيا كذا (20547 وتاريخ" in units[2].text and units[3].text == "1005 - ما يفعله بعض القبائل"
    assert [u.number for u in segment_entries(text, MBI)] == [1002, 1003, 1004, 1, 2, 20547, 1005, 1006]
