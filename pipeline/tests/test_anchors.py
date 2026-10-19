"""PR-48: every fact a qāʿida type declares is defined by a verbatim phrase of its own source."""

from pathlib import Path

import pytest

from usul_corpus import anchors
from witnesses import cached

ROOT = Path(__file__).resolve().parents[2]
EXPORT = (ROOT / "examples/v41_types.pl").read_text(encoding="utf-8")
ENTRIES = anchors.load(ROOT / "corpus")


def test_anchor_entries_are_well_formed():
    assert anchors.check(ENTRIES, EXPORT) == []


def test_every_declared_field_has_an_anchor_or_a_reason():
    assert anchors.missing(ENTRIES, EXPORT) == []


@pytest.mark.parametrize("entry", [e for e in ENTRIES if "anchor" in e], ids=lambda e: f"{e['type']}.{e['field']}")
def test_anchors_are_verbatim_where_their_ref_says(entry):
    wid = anchors.REF.fullmatch(entry["anchor"]["ref"])[1]
    assert anchors.verify(entry["anchor"], cached(wid).read_text(encoding="utf-8")) is None


def test_the_gate_rejects_a_wrong_page_a_cut_word_and_a_missing_negation():
    text = "PageV01P010 من حرم عليه الامتناع من بدل شيء سئله فامتنع فهل يسقط إذنه بالكلية PageV01P011 ثم"
    ok = {"ref": "src:w/v01:p011", "excerpt_ar": "من حرم عليه الامتناع"}
    assert anchors.verify(ok, text) is None
    assert anchors.verify({**ok, "ref": "src:w/v01:p012"}, text)
    assert anchors.verify({**ok, "excerpt_ar": "من حرم عليه الامتنا"}, text)
    assert anchors.check([{"type": "x", "field": "y", "gloss": "g"}], "type_field(x, y, 'Option Bool').") \
        == ["x.y: needs exactly one of anchor and unanchored"]
