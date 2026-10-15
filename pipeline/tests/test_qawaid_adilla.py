"""The adilla of the qawāʿid: where in the Qurʾān and the Sunna each qāʿida is derived from, by a
source that states the derivation (corpus/dossier/qawaid_adilla.json)."""

import json
from pathlib import Path

from usul_corpus import qawaid_adilla as qa

ROOT = Path(__file__).resolve().parents[2]
RECORDS = {"w.x.q001": {"record_type": "qaida"}, "w.x.q002": {"record_type": "qaida"}}
FOUND = {"Q005:006", "H-niyyat"}
TEXT = {"src-w": "قال المؤلف والدليل على هذه القاعدة قوله تعالى فاتقوا الله ما استطعتم وقوله صلى الله عليه وسلم إنما الأعمال بالنيات"}


def _istidlal(excerpt="والدليل على هذه القاعدة قوله تعالى فاتقوا الله ما استطعتم"):
    return {"witness": "src-w", "ref": "src:src-w", "excerpt_ar": excerpt, "who": "the author"}


def _entry(**kw):
    return {"qaida": "w.x.q001", "adilla": [{"ref": "Q005:006", "relation": "stated", "istidlal": _istidlal()}],
            "searched": ["src-w"], "note": "n", **kw}


def test_a_well_formed_entry_passes():
    assert qa.errors([_entry()], RECORDS, FOUND, TEXT.get) == []


def test_every_ref_is_checked():
    bad = _entry(qaida="w.x.q009", adilla=[{"ref": "Q999:001", "relation": "stated", "istidlal": _istidlal("ليس في النص")}])
    assert qa.errors([bad], RECORDS, FOUND, TEXT.get) == [
        "w.x.q009: not a committed qāʿida record",
        "w.x.q009: Q999:001 is not in the textual foundation",
        "w.x.q009: istidlāl for Q999:001 is not verbatim in src-w"]


def test_none_found_records_where_it_looked():
    assert qa.errors([_entry(adilla=[], searched=[])], RECORDS, FOUND, TEXT.get) == [
        "w.x.q001: no dalīl found must name the works searched"]
    assert qa.errors([_entry(adilla=[])], RECORDS, FOUND, TEXT.get) == []


def test_each_qaida_once():
    assert qa.errors([_entry(), _entry()], RECORDS, FOUND, TEXT.get) == ["w.x.q001: annotated twice"]


def test_the_committed_annotation_is_sound():
    path = ROOT / "corpus" / qa.PATH
    if not path.exists():
        return
    recs = {r["id"]: r for p in (ROOT / "corpus/records").glob("*.jsonl")
            for r in map(json.loads, p.read_text(encoding="utf-8").splitlines())}
    found = qa.foundation_ids(ROOT)
    cache = ROOT / ".cache/corpus"
    text = lambda w: (cache / f"{w}.txt").read_text(encoding="utf-8") if (cache / f"{w}.txt").exists() else None
    assert qa.errors(qa.load(ROOT)["entries"], recs, found, text) == []
