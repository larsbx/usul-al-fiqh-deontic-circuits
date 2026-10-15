import hashlib
import json
from pathlib import Path

from usul_corpus.texts import committed_sha256, publishable, restore, stage

ROOT = Path(__file__).resolve().parents[2]

REGISTRY = {"works": [
    {"id": "a.old", "rights": "public_domain_text", "witnesses": [{"id": "w-old", "kind": "openiti"}]},
    {"id": "a.scan", "rights": "public_domain_text", "witnesses": [{"id": "w-pdf", "kind": "archive", "format": "pdf"}]},
    {"id": "b.modern", "rights": "modern_cache_only", "witnesses": [{"id": "w-new", "kind": "shamela"}]},
    {"id": "a.part", "rights": "public_domain_text", "witnesses": [{"id": "w-old", "kind": "openiti"}]},
    {"id": "c.study", "rights": "noncommercial_text", "witnesses": [{"id": "w-nc", "kind": "openiti"}]},
]}


def _lock(**texts: bytes) -> dict:
    return {k: {"witness": k, "bytes": len(v), "sha256": hashlib.sha256(v).hexdigest()} for k, v in texts.items()}


def test_only_public_domain_and_noncommercial_text_witnesses_are_publishable_once_each():
    assert publishable(REGISTRY) == ("w-old", "w-nc")


def test_stage_copies_verified_texts_and_refuses_drifted_ones(tmp_path):
    cache, dest = tmp_path / "cache", tmp_path / "texts"
    cache.mkdir()
    (cache / "w-old.txt").write_bytes(b"matn")
    lock = _lock(**{"w-old": b"matn"})
    assert stage(("w-old",), lock, cache, dest) == {"copied": ["w-old"], "unchanged": [], "missing": [], "mismatch": []}
    assert (dest / "w-old.txt").read_bytes() == b"matn"
    assert stage(("w-old",), lock, cache, dest)["unchanged"] == ["w-old"]
    (cache / "w-old.txt").write_bytes(b"drifted")
    assert stage(("w-old",), lock, cache, dest)["mismatch"] == ["w-old"]
    assert (dest / "w-old.txt").read_bytes() == b"matn"  # the verified copy is kept


def test_restore_fills_the_cache_from_a_verified_committed_text(tmp_path):
    texts, cache = tmp_path / "texts", tmp_path / "cache"
    texts.mkdir()
    (texts / "w-old.txt").write_bytes(b"matn")
    assert restore("w-old", _lock(**{"w-old": b"matn"}), texts, cache) is True
    assert (cache / "w-old.txt").read_bytes() == b"matn"
    assert restore("w-old", _lock(**{"w-old": b"other"}), texts, tmp_path / "c2") is False


def test_an_lfs_pointer_is_verified_by_its_oid_without_the_content(tmp_path):
    p = tmp_path / "w.txt"
    p.write_text("version https://git-lfs.github.com/spec/v1\noid sha256:" + "ab" * 32 + "\nsize 4\n")
    assert committed_sha256(p) == "ab" * 32
    p.write_bytes(b"matn")
    assert committed_sha256(p) == hashlib.sha256(b"matn").hexdigest()


def test_committed_texts_are_publishable_and_match_the_lock():
    """Runs in CI on LFS pointers (checkout without lfs) as well as on the real files."""
    registry = json.loads((ROOT / "corpus/registry.json").read_text(encoding="utf-8"))
    lock = json.loads((ROOT / "corpus/lock.json").read_text(encoding="utf-8"))["witnesses"]
    allowed = set(publishable(registry))
    for p in sorted((ROOT / "corpus/texts").glob("*.txt")):
        assert p.stem in allowed, f"{p.name}: not a public-domain text witness"
        assert committed_sha256(p) == lock[p.stem]["sha256"], f"{p.name}: differs from lock.json"
