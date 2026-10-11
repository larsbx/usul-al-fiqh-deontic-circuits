import json
from pathlib import Path

import pytest

from usul_corpus import shards, takhrij

ROOT = Path(__file__).resolve().parents[2]


def test_fragments_union_with_the_base_and_name_both_sources_of_a_duplicate(tmp_path):
    base = {"status": "candidate", "entries": [{"id": "a"}]}
    (tmp_path / "s1.json").write_text(json.dumps({"entries": [{"id": "b"}]}))
    merged = shards.with_fragments(base, tmp_path, key="id")
    assert [e["id"] for e in merged["entries"]] == ["a", "b"] and merged["status"] == "candidate"
    (tmp_path / "s2.json").write_text(json.dumps({"entries": [{"id": "a"}]}))
    with pytest.raises(ValueError, match="a: base and s2.json"):
        shards.with_fragments(base, tmp_path, key="id")


def test_no_fragment_directory_leaves_the_base_unchanged(tmp_path):
    base = {"entries": [{"far": "x"}]}
    assert shards.with_fragments(base, tmp_path / "absent", key="far") == base


def test_encoder_shards_merge_without_overwriting():
    assert shards.merge_encoders({"a": {}}, {"s1": {"b": {}}}) == {"a": {}, "b": {}}
    with pytest.raises(ValueError, match="a: core and s1"):
        shards.merge_encoders({"a": {}}, {"s1": {"a": {}}})


def test_the_live_encoder_registry_is_the_core_plus_its_shards():
    assert set(takhrij.ENCODERS) == set(takhrij.CORE) | {n for e in shards.encoder_shards().values() for n in e}


def test_claims_must_be_pending_disjoint_and_pinned():
    pending = {"q1.f001", "q1.f002", "q2.f001"}
    ok = [{"shard": "s1", "base_commit": "a" * 40, "obligations": ["q1.f001"]},
          {"shard": "s2", "base_commit": "a" * 40, "obligations": ["q2.f001"]}]
    assert shards.check_claims(ok, pending) == []
    bad = [{"shard": "s1", "base_commit": "abc", "obligations": ["q1.f001", "q9.f001"]},
           {"shard": "s2", "base_commit": "b" * 40, "obligations": ["q1.f001"]}]
    assert shards.check_claims(bad, pending) == [
        "s1: base_commit is not a full commit sha",
        "s1: q9.f001 is not a pending obligation",
        "q1.f001: claimed by s1 and s2",
    ]


def test_the_readings_index_imports_every_reading_module(tmp_path):
    (tmp_path / "Readings").mkdir()
    for n in ("RajabT11", "FatawaItlaf"):
        (tmp_path / "Readings" / f"{n}.lean").write_text("")
    text = shards.readings_index(tmp_path / "Readings")
    assert text.splitlines()[-2:] == ["import Usul.Readings.FatawaItlaf", "import Usul.Readings.RajabT11"]
    assert "GENERATED" in text


def test_committed_shard_state_is_consistent():
    """The committed readings index is current, and every committed claim is valid."""
    lean = ROOT / "formal/lean/Usul"
    assert (lean / "Readings.lean").read_text(encoding="utf-8") == shards.readings_index(lean / "Readings")
    claims = shards.load_claims(ROOT / "corpus")
    assert shards.check_claims(claims, shards.pending_obligations(ROOT / "corpus")) == []
