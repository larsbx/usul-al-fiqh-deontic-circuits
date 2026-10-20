"""The unit inventory: every line-segmented witness's records are obligations, annotated exactly once
(derivation-method §3 S0, §4 invariant 5). Pending ids are derived from the pinned records file, never
listed, and a records file that drifted from the inventory is refused."""

import json
import shutil
from pathlib import Path

import pytest

from usul_corpus import shards, takhrij, units

ROOT = Path(__file__).resolve().parents[2]
CORPUS = ROOT / "corpus"


def _committed() -> dict:
    return json.loads((CORPUS / units.INVENTORY).read_text(encoding="utf-8"))


def test_the_committed_unit_inventory_is_current():
    annotated = {c["far"] for c in takhrij.load(CORPUS)}
    assert units.render(CORPUS, annotated) == (CORPUS / units.INVENTORY).read_text(encoding="utf-8")


def test_the_inventory_covers_every_unit_witness_exactly_once():
    reg = json.loads((CORPUS / "registry.json").read_text(encoding="utf-8"))
    expected = sorted(x["id"] for w in reg["works"] for x in w["witnesses"]
                      if (units.segmenter_of(w, x) or {}).get("kind") in units.UNIT_SEGMENTERS)
    rows = _committed()["witnesses"]
    assert [r["witness"] for r in rows] == expected
    for r in rows:
        lines = (CORPUS / r["records"]).read_text(encoding="utf-8").splitlines()
        assert r["units"] == len(lines) and r["pending"] == r["units"] - len(r["annotated_ids"])
    assert _committed()["summary"]["units"] == sum(r["units"] for r in rows)


def test_a_witness_segmenter_overrides_the_work_and_may_stand_alone():
    """A work's witnesses share its segmenter unless one names its own; a work with none segments only
    the witnesses that do (al-Durar: the Ghurar witness is cut, the bare matn 34280 is not)."""
    work = {"segmenter": {"kind": "abwab"}, "witnesses": [{"id": "a"}, {"id": "b", "segmenter": {"kind": "qa"}}]}
    assert [units.segmenter_of(work, x)["kind"] for x in work["witnesses"]] == ["abwab", "qa"]
    bare = {"witnesses": [{"id": "c"}, {"id": "d", "segmenter": {"kind": "abwab"}}]}
    assert [units.segmenter_of(bare, x) for x in bare["witnesses"]] == [None, {"kind": "abwab"}]


def test_unit_records_are_pending_obligations_a_shard_can_claim():
    first = json.loads((CORPUS / "records/openiti-kawsaj-masailahmad-shamela3125.jsonl").read_text(encoding="utf-8").split("\n", 1)[0])["id"]
    pending = shards.pending_obligations(CORPUS)
    assert first in pending
    claim = {"shard": "s", "lane": "B", "base_commit": "0" * 40, "obligations": [first]}
    assert shards.check_claims([claim], pending) == []


def test_a_records_file_that_drifted_from_the_inventory_is_refused(tmp_path):
    (tmp_path / "worklists").mkdir()
    shutil.copy(CORPUS / units.INVENTORY, tmp_path / units.INVENTORY)
    row = _committed()["witnesses"][0]
    (tmp_path / row["records"]).parent.mkdir(parents=True, exist_ok=True)
    (tmp_path / row["records"]).write_text("{}\n", encoding="utf-8")
    with pytest.raises(ValueError, match="drifted"):
        units.pending(tmp_path)
