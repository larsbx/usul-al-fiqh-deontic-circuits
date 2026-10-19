"""PR-51: each case's maḥall, defined by a canonical text, and the label graph to its qāʿida."""

import json
from pathlib import Path

import pytest

from usul_corpus import mahall
from witnesses import cached

ROOT = Path(__file__).resolve().parents[2]
CORPUS = ROOT / "corpus"
ABWAB, LABELS, ENTRIES = mahall.load(CORPUS)
GRAPH = mahall.export(CORPUS)


def test_every_case_has_one_mahall_named_in_its_own_words_under_a_rooted_defined_label():
    assert mahall.check(CORPUS) == []


@pytest.mark.parametrize("nass", [dict(n, label=l["id"]) for l in LABELS for n in l.get("nass", [])],
                         ids=lambda n: f"{n['label']}:{n['ref'].split(':', 1)[1]}")
def test_each_nass_is_verbatim_in_its_witness(nass):
    wid = mahall.REF.fullmatch(nass["ref"])[1]
    assert mahall.verify(nass, cached(wid).parent) is None


def test_the_gate_rejects_a_misplaced_aya_and_an_unstated_ijma(tmp_path):
    (tmp_path / "tanzil-quran-simple.txt").write_text("2|275|وَأَحَلَّ اللَّهُ الْبَيْعَ وَحَرَّمَ الرِّبَا\n", encoding="utf-8")
    ok = {"kind": "quran", "ref": "src:tanzil-quran-simple#Q002:275", "excerpt_ar": "وأحل الله البيع"}
    assert mahall.verify(ok, tmp_path) is None
    assert mahall.verify({**ok, "ref": "src:tanzil-quran-simple#Q002:276"}, tmp_path)
    assert mahall.verify({**ok, "excerpt_ar": "وأحل الله النكاح"}, tmp_path)
    assert not mahall.IJMA_MARK.search("قال أبو حنيفة يجوز")


def test_the_footprint_is_the_up_closure_of_the_qaidas_furu_mahalls():
    up = mahall.parents(ABWAB, LABELS)
    for q, fp in GRAPH["footprint"].items():
        own = {l for f in GRAPH["furu"] if f["qaida"] == q for l in f["labels"]}
        assert own <= set(fp)
        assert all(up[l] is None or up[l] in fp for l in fp)        # up-closed
        assert all(any(mahall.root(up, m) == mahall.root(up, l) for m in own) for l in fp)


def test_the_generated_graph_and_lean_guards_are_up_to_date():
    assert json.loads((CORPUS / mahall.GRAPH).read_text(encoding="utf-8")) == GRAPH
    assert (ROOT / "formal/lean/UsulTest" / mahall.LEAN).read_text(encoding="utf-8") == mahall.lean_file(GRAPH)
