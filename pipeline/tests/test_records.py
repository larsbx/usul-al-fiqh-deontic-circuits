import json
from pathlib import Path

import jsonschema

from usul_corpus.records import qaida_records, unit_tags
from usul_corpus.segment import Unit

SCHEMA = json.loads((Path(__file__).parents[2] / "schemas" / "usul_rule.schema.json").read_text())
WORK = {"id": "ibn_lahham.qawaid_fawaid", "rights": "public_domain_text"}


def test_qaida_records_emit_parent_then_furu_and_validate():
    u = Unit(3, "القاعدة 3", "لا تكليف على الناسي", (1, 37), ("إذا نسي الماء وتيمم", "إذا تكلم في الصلاة ناسيا"), False)
    q, f1, f2 = qaida_records(WORK, "openiti-x", "headed", "q003", u)
    assert q["furu_count"] == 2 and q["locator"] == "src:openiti-x/v01:p037#q003"
    assert f1["qaida"] == q["id"] and f1["id"] == q["id"] + ".f001"
    assert f2["case_ar"] == "إذا تكلم في الصلاة ناسيا"
    for r in (q, f1, f2):
        jsonschema.validate(r, SCHEMA)


def test_modern_rights_cap_excerpts():
    u = Unit(1, "القاعدة الأولى", "ا" * 1000, None, ("ب" * 1000,), False)
    q, f = qaida_records({"id": "sadi.qawaid_jamia", "rights": "modern_cache_only"}, "archive-x", "lines", "q001", u)
    assert len(q["excerpt_ar"]) == 160 and len(f["case_ar"]) == 160


def test_unit_tags_disambiguate_repeats_and_unparsed():
    us = tuple(Unit(n, "", "", None, (), False) for n in (1, 15, None, 15, 1, 15))
    assert unit_tags(us) == ["q001", "q015", "u003", "q015_2", "q001_2", "q015_3"]
