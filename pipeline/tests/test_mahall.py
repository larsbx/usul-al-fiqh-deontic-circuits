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


def test_the_footprint_is_the_up_closure_of_the_maḥalls_of_the_furu_tied_to_it():
    up = mahall.parents(ABWAB, LABELS)
    for q, fp in GRAPH["footprint"].items():
        own = {l for f in GRAPH["furu"] if q in f["qawaid"] for l in f["labels"]}
        assert own <= set(fp)
        assert all(set(up[l]) <= set(fp) for l in fp)                          # up-closed
        assert set(fp) == set().union(*(mahall.ancestors(up, m) for m in own))  # and least


def test_relations_are_many_to_many_as_in_the_bank():
    """A farʿ may be tied to several qawāʿid, a label may sit under several labels and be defined
    by several nuṣūṣ, and a naṣṣ may define several labels: none is forced to be single."""
    furu = GRAPH["furu"]
    assert all(f["links"]["placed"][0] in f["qawaid"] for f in furu)
    assert sum(len(f["qawaid"]) > 1 for f in furu) >= 280
    assert sum(len(l["broader"]) > 1 for l in LABELS) >= 40
    per_nass = {}
    for n, l in GRAPH["defines"]:
        per_nass.setdefault(n, set()).add(l)
    assert any(len(v) > 1 for v in per_nass.values())
    assert any(len(l.get("nass", [])) > 1 for l in LABELS)


def test_the_generated_graph_and_lean_guards_are_up_to_date():
    assert json.loads((CORPUS / mahall.GRAPH).read_text(encoding="utf-8")) == GRAPH
    assert (ROOT / "formal/lean/UsulTest" / mahall.LEAN).read_text(encoding="utf-8") == mahall.lean_file(GRAPH)
