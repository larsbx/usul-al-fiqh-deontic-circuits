"""The masāʾil of a matn: each abwab unit split into its paragraphs (docs/architecture/mutun-masail.md).

A paragraph is a ``# `` body line and the ``~~`` lines continuing it; every paragraph sits in exactly
one unit, and the unit's text is its opening line, its loose lines and its paragraphs, in order.
A paragraph becomes a masʾala record, a child of its bāb record, unless the audit reports it: a
title printed as a body line, or
a paragraph without Arabic letters. The committed records replay from the pinned witness bytes."""

import hashlib
import json
from pathlib import Path

import jsonschema
import pytest

from usul_corpus import units
from usul_corpus.abwab import segment_abwab, segment_masail
from usul_corpus.arabic import letters
from usul_corpus.records import bab_record

ROOT = Path(__file__).resolve().parents[2]
CORPUS = ROOT / "corpus"
SCHEMA = json.loads((ROOT / "schemas/usul_rule.schema.json").read_text(encoding="utf-8"))
WORK = {"id": "a.b", "rights": "public_domain_text"}

MATN = """#META#Header#End#
### | مقدمة المحقق
# الحمد لله
### | كتاب الطهارة
### | مدخل
# وهي ارتفاع الحدث.
### | باب المياه
# الماء طهور PageV01P002
~~يرفع الحدث
# ويزيل النجس.
# فصل
# والقليل ينجس بالملاقاة
PageV01P003
# إذا تغير.
### | باب الآنية
~~بقية من الصفحة
# كل إناء طاهر يباح.
# الماء طهور
~~يرفع الحدث
# باب الآنية
# 1
PageV01P004
"""


def _shape(text: str):
    return [(u.bab.heading, [(p.text, p.page, p.end_page) for p in u.paragraphs], u.loose) for u in segment_masail(text)]


def test_a_paragraph_is_a_hash_line_and_its_continuations_and_the_opening_line_is_not_one():
    assert _shape(MATN) == [
        ("كتاب الطهارة", [("وهي ارتفاع الحدث.", (1, 2), (1, 2))], ()),
        ("باب المياه", [("الماء طهور يرفع الحدث", (1, 2), (1, 3)), ("ويزيل النجس.", (1, 3), (1, 3))], ()),
        ("فصل", [("والقليل ينجس بالملاقاة", (1, 3), (1, 3)), ("إذا تغير.", (1, 4), (1, 4))], ()),
        ("باب الآنية", [("كل إناء طاهر يباح.", (1, 4), (1, 4)), ("الماء طهور يرفع الحدث", (1, 4), (1, 4)),
                        ("باب الآنية", (1, 4), (1, 4)), ("1", (1, 4), (1, 4))], ("بقية من الصفحة",)),
    ]


def test_the_units_are_those_of_segment_abwab_and_their_text_is_covered_exactly():
    """Front matter stays out, a body «فصل» line opens its own unit, and nothing of a unit is lost."""
    split = segment_masail(MATN)
    assert tuple(u.bab for u in split) == segment_abwab(MATN)
    assert [u.opening for u in split] == ["كتاب الطهارة", "باب المياه", "فصل", "باب الآنية"]
    for u in split:
        assert " ".join([u.opening, *u.loose, *(p.text for p in u.paragraphs)]) == u.bab.text


def test_records_are_children_of_their_bab_numbered_in_text_order():
    records, audit = units.paragraph_records(WORK, "w-x", MATN, {"kind": "abwab", "paragraphs": True})
    assert [r["id"] for r in records] == ["a.b.w_x.b00001.p01", "a.b.w_x.b00002.p01", "a.b.w_x.b00002.p02",
                                          "a.b.w_x.b00003.p01", "a.b.w_x.b00003.p02", "a.b.w_x.b00004.p01", "a.b.w_x.b00004.p02"]
    babs = [bab_record(WORK, "w-x", i, u) for i, u in enumerate(segment_abwab(MATN), 1)]
    r = records[1]
    assert (r["bab"], r["heading_ar"], r["path_ar"]) == (babs[1]["id"], "باب المياه", ["كتاب الطهارة"])
    assert (r["locator"], r["page_span"], r["record_type"]) == ("src:w-x/v01:p002#b00002.p01", [2, 3], "masala")
    assert r["sha256"] == hashlib.sha256("الماء طهور يرفع الحدث".encode()).hexdigest()
    for r in records:
        jsonschema.validate(r, SCHEMA)


def test_the_audit_reports_every_paragraph_that_is_not_a_record():
    _, audit = units.paragraph_records(WORK, "w-x", MATN, {"kind": "abwab", "paragraphs": True})
    assert (audit["units"], audit["paragraphs"], audit["masail"]) == (4, 9, 7)
    assert audit["duplicates"] == []
    assert audit["titles"] == [{"bab": "a.b.w_x.b00004", "paragraph": 3, "text_ar": "باب الآنية"}]
    assert audit["no_letters"] == [{"bab": "a.b.w_x.b00004", "paragraph": 4, "text_ar": "1"}]
    assert audit["loose"] == [{"bab": "a.b.w_x.b00004", "text_ar": "بقية من الصفحة"}]
    # «إذا تغير.» opens a page after an unpunctuated paragraph: perhaps one sentence split by the page.
    assert audit["page_break_candidates"] == ["a.b.w_x.b00003.p02"]


def test_rights_cap_the_excerpt_not_the_receipt():
    long = "#META#Header#End#\n### | باب الآنية\n# " + "ا " * 300 + "\nPageV01P001\n"
    (r,), _ = units.paragraph_records({"id": "a.b", "rights": "modern_cache_only"}, "w-x", long, {"kind": "abwab"})
    assert len(r["excerpt_ar"]) == 160 and r["sha256"] == segment_masail(long)[0].paragraphs[0].sha256


# The committed masāʾil of the opted-in mutūn.

def _opted_in():
    reg = json.loads((CORPUS / "registry.json").read_text(encoding="utf-8"))
    return [(w, x) for w in reg["works"] for x in w["witnesses"]
            if x.get("segmenter", w.get("segmenter", {})).get("paragraphs")]


def _committed(path: str) -> list[dict]:
    return [json.loads(line) for line in (CORPUS / path).read_text(encoding="utf-8").splitlines()]


def _source(witness: dict) -> str:
    cached = ROOT / ".cache/corpus" / f"{witness['id']}.txt"
    if not cached.exists():
        pytest.skip("witness not cached: the replay needs the pinned witness bytes")
    lock = json.loads((CORPUS / "lock.json").read_text(encoding="utf-8"))["witnesses"][witness["id"]]
    if hashlib.sha256(cached.read_bytes()).hexdigest() != lock["sha256"]:
        pytest.skip("cached witness is not the locked bytes")
    return cached.read_text(encoding="utf-8")


def test_the_two_mutun_are_opted_in():
    assert sorted(x["id"] for _, x in _opted_in()) == ["openiti-hajjawi-zadmustaqni-shamela11230",
                                                       "openiti-ibnqudama-umda-shamela11315"]


@pytest.mark.parametrize("work,witness", _opted_in(), ids=lambda v: v["id"] if isinstance(v, dict) else v)
def test_every_masala_has_its_parent_bab_and_a_unique_receipt(work, witness):
    babs = {r["id"]: r for r in _committed(f"records/{witness['id']}.jsonl")}
    masail = _committed(units.masail_path(witness["id"]))
    assert masail and all(r["bab"] in babs and r["id"].startswith(r["bab"] + ".p") for r in masail)
    assert all((r["heading_ar"], r["path_ar"]) == (babs[r["bab"]]["heading_ar"], babs[r["bab"]]["path_ar"]) for r in masail)
    assert len({r["id"] for r in masail}) == len(masail)
    for bab in babs:  # numbered from .p01 within each bāb, in order, without gaps
        ids = [r["id"] for r in masail if r["bab"] == bab]
        assert ids == [f"{bab}.p{n:02d}" for n in range(1, len(ids) + 1)]


@pytest.mark.parametrize("work,witness", _opted_in(), ids=lambda v: v["id"] if isinstance(v, dict) else v)
def test_committed_masail_replay_from_the_pinned_witness(work, witness):
    """Stability replay: re-splitting the cached witness reproduces the masāʾil file byte for byte,
    and its audit entry in corpus/audit.json."""
    text = _source(witness)
    records, audit = units.paragraph_records(work, witness["id"], text, witness.get("segmenter", work["segmenter"]))
    raw = "".join(json.dumps(r, ensure_ascii=False) + "\n" for r in records)
    assert raw == (CORPUS / units.masail_path(witness["id"])).read_text(encoding="utf-8")
    committed = json.loads((CORPUS / "audit.json").read_text(encoding="utf-8"))[f"{witness['id']}#masail"]
    assert committed == {"work": work["id"], **audit}


@pytest.mark.parametrize("work,witness", _opted_in(), ids=lambda v: v["id"] if isinstance(v, dict) else v)
def test_every_source_occurrence_is_covered_once_with_audited_reattribution(work, witness):
    text = _source(witness)
    seg = witness.get("segmenter", work["segmenter"])
    split = segment_masail(text, seg.get("end"))
    by_id = {r["id"]: r for r in _committed(units.masail_path(witness["id"]))}
    audit = json.loads((CORPUS / "audit.json").read_text(encoding="utf-8"))[f"{witness['id']}#masail"]
    reported = {(e["bab"], e["paragraph"]) for k in ("duplicates", "titles", "no_letters") for e in audit[k]}
    loose = {}
    for e in audit["loose"]:
        loose.setdefault(e["bab"], []).append(e["text_ar"])
    counts = {}
    covered = set()
    moved = {(x["bab"], x["paragraph"]): x for x in audit["reattributions"]}
    for i, u in enumerate(split, 1):
        bab = bab_record(work, witness["id"], i, u.bab)["id"]
        for k, p in enumerate(u.paragraphs, 1):
            if (bab, k) in reported:
                continue
            target = moved.get((bab, k), {}).get("bab_to", bab)
            counts[target] = counts.get(target, 0) + 1
            rid = f"{target}.p{counts[target]:02d}"
            assert rid not in covered
            covered.add(rid)
            assert by_id[rid]["sha256"] == p.sha256
            if (bab, k) in moved:
                assert moved[bab, k]["record"] == rid
        assert list(u.loose) == loose.get(bab, [])
        assert letters(u.bab.text) == letters(" ".join([u.opening, *u.loose, *(p.text for p in u.paragraphs)]))
    assert covered == set(by_id)
    assert len(covered) == audit["masail"]
