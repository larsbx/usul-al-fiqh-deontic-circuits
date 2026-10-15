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
    expected = sorted((x["id"], f"records/{x['id']}{suffix}.jsonl") for w in reg["works"]
                      if w.get("segmenter", {}).get("kind") in units.UNIT_SEGMENTERS for x in w["witnesses"]
                      for suffix in ["", ".masail"][:1 + bool(x.get("segmenter", w["segmenter"]).get("paragraphs"))])
    rows = _committed()["witnesses"]
    assert [(r["witness"], r["records"]) for r in rows] == expected  # a matn's masāʾil are a row of their own
    assert {r["kind"] for r in rows if r["records"].endswith(".masail.jsonl")} == {units.PARAGRAPHS}
    assert _committed()["summary"]["witnesses"] == len({r["witness"] for r in rows})
    for r in rows:
        lines = (CORPUS / r["records"]).read_text(encoding="utf-8").splitlines()
        assert r["units"] == len(lines) and r["pending"] == r["units"] - len(r["annotated_ids"])
    assert _committed()["summary"]["units"] == sum(r["units"] for r in rows)


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
