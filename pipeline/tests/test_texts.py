import copy
import hashlib

import jsonschema
import pytest
import json
from pathlib import Path

from usul_corpus.texts import audit, check_file, committed_sha256, publishable, restore, stage

ROOT = Path(__file__).resolve().parents[2]

REGISTRY = {"works": [
    {"id": "a.old", "rights": "public_domain_text", "witnesses": [{"id": "w-old", "kind": "openiti"}]},
    {"id": "a.scan", "rights": "public_domain_text", "witnesses": [{"id": "w-pdf", "kind": "archive", "format": "pdf"}]},
    {"id": "b.modern", "rights": "modern_cache_only", "witnesses": [{"id": "w-new", "kind": "shamela"}]},
    {"id": "a.part", "rights": "public_domain_text", "witnesses": [{"id": "w-old", "kind": "openiti"}]},
    {"id": "c.study", "rights": "noncommercial_text", "witnesses": [{"id": "w-nc", "kind": "openiti"},
                                                                    {"id": "w-doc", "kind": "url", "format": "doc"}]},
]}


def _lock(**texts: bytes) -> dict:
    return {k: {"witness": k, "bytes": len(v), "sha256": hashlib.sha256(v).hexdigest()} for k, v in texts.items()}


def test_noncommercial_intent_alone_does_not_allow_publication():
    """A pdf or doc witness is pinned as its binary, not as text, so it is never staged."""
    assert publishable(REGISTRY) == ("w-old",)


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


def test_pointer_oid_is_a_declaration_not_complete_byte_verification(tmp_path):
    p = tmp_path / "w.txt"
    p.write_text("version https://git-lfs.github.com/spec/v1\noid sha256:" + "ab" * 32 + "\nsize 4\n")
    assert committed_sha256(p) == "ab" * 32
    p.write_bytes(b"matn")
    assert committed_sha256(p) == hashlib.sha256(b"matn").hexdigest()


def test_committed_texts_are_publishable_and_match_the_lock():
    """Runs in CI on LFS pointers (checkout without lfs) as well as on the real files."""
    registry = json.loads((ROOT / "corpus/registry.json").read_text(encoding="utf-8"))
    lock = json.loads((ROOT / "corpus/lock.json").read_text(encoding="utf-8"))["witnesses"]
    allowed = set(publishable(registry, lock))
    for p in sorted((ROOT / "corpus/texts").glob("*.txt")):
        assert p.stem in allowed, f"{p.name}: not a public-domain text witness"
        assert check_file(p, lock[p.stem]) in {"pointer_only", "bytes_verified"}, f"{p.name}: differs from lock.json"


def _approved(pin):
    # Synthetic permission for testing the gate's structure, not a real grant.
    return {"decision": "redistribute", "scope": "complete_text_public_redistribution",
            "sha256": pin["sha256"], "reviewed_on": "2026-10-15", "basis": "synthetic",
            "authority": "test rights holder", "conditions": "test conditions",
            "attribution": "test attribution", "assessment": "test only",
            "evidence": [{"scope": s, "url": "https://example.invalid/permission",
                          "finding": "synthetic scope grant"} for s in ("work", "edition", "provider")]}


def test_permission_is_specific_to_witness_and_locked_bytes():
    registry = copy.deepcopy(REGISTRY)
    lock = _lock(**{"w-nc": b"study"})
    witness = registry["works"][-1]["witnesses"][0]
    witness["publication"] = _approved(lock["w-nc"])
    assert publishable(registry, lock) == ("w-old", "w-nc")
    assert publishable(registry, _lock(**{"w-nc": b"new edition"})) == ("w-old",)
    assert publishable(registry) == ("w-old",)
    witness["publication"]["evidence"].pop()  # no provider coverage
    assert publishable(registry, lock) == ("w-old",)


@pytest.mark.parametrize("field", ["authority", "assessment", "conditions", "attribution", "reviewed_on"])
def test_missing_permission_fields_fail_closed(field):
    registry = copy.deepcopy(REGISTRY)
    lock = _lock(**{"w-nc": b"study"})
    witness = registry["works"][-1]["witnesses"][0]
    witness["publication"] = _approved(lock["w-nc"])
    witness["publication"][field] = " "
    assert publishable(registry, lock) == ("w-old",)


def test_public_domain_label_and_alias_cannot_override_witness_hold():
    registry = copy.deepcopy(REGISTRY)
    registry["works"][0]["witnesses"][0]["publication"] = {"decision": "cache_only"}
    assert publishable(registry) == ()


def test_pointer_size_mismatch_and_unhydrated_content_are_not_byte_passes(tmp_path):
    pin = _lock(w=b"matn")["w"]
    p = tmp_path / "w.txt"
    p.write_text(f"version https://git-lfs.github.com/spec/v1\noid sha256:{pin['sha256']}\nsize 4\n")
    assert check_file(p, pin) == "pointer_only"
    assert check_file(p, pin, True) == "unhydrated"
    assert restore("w", {"w": pin}, tmp_path, tmp_path / "cache") is False
    p.write_text(p.read_text().replace("size 4", "size 5"))
    assert check_file(p, pin) == "pointer_mismatch"
    p.write_bytes(b"drft")
    assert check_file(p, pin, True) == "bytes_mismatch"
    p.write_bytes(b"matn")
    assert check_file(p, pin, True) == "bytes_verified"
    p.unlink()
    assert check_file(p, pin, True) == "missing"


def test_blocked_committed_file_and_empty_inventory_fail_audit(tmp_path):
    registry = {"works": [{"rights": "noncommercial_text", "witnesses": [{"id": "w"}]}]}
    assert not audit(registry, {}, tmp_path)["ok"]
    (tmp_path / "w.txt").write_bytes(b"matn")
    report = audit(registry, _lock(w=b"matn"), tmp_path, True)
    assert not report["ok"]
    assert report["counts"] == {"publication_blocked": 1}


def test_registry_publication_records_conform_and_bind_to_lock():
    registry = json.loads((ROOT / "corpus/registry.json").read_text())
    schema = json.loads((ROOT / "schemas/corpus_registry.schema.json").read_text())
    lock = json.loads((ROOT / "corpus/lock.json").read_text())["witnesses"]
    jsonschema.validate(registry, schema)
    for work in registry["works"]:
        for witness in work["witnesses"]:
            if "publication" in witness:
                assert witness["publication"]["sha256"] == lock[witness["id"]]["sha256"]
    approved = _approved(_lock(w=b"matn")["w"])
    jsonschema.validate(approved, {"$ref": "#/$defs/publication", "$defs": schema["$defs"]})
    approved["evidence"].pop()
    with pytest.raises(jsonschema.ValidationError):
        jsonschema.validate(approved, {"$ref": "#/$defs/publication", "$defs": schema["$defs"]})


def test_tracked_but_missing_file_cannot_disappear_from_byte_audit(tmp_path):
    registry = {"works": [{"rights": "public_domain_text", "witnesses": [{"id": "w"}]}]}
    report = audit(registry, _lock(w=b"matn"), tmp_path, True, ["w"])
    assert not report["ok"]
    assert report["counts"] == {"missing": 1}
