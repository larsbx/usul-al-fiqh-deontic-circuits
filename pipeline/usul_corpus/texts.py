"""Publication eligibility and pointer/byte checks are separate claims.

Witness publication provenance lives in registry.json, identity in lock.json.
Legacy public_domain_text entries remain eligible unless a witness-level hold
exists; this compatibility rule is not a new rights audit of the legacy corpus.
Noncommercial intent alone never authorizes redistribution.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
from collections import Counter
from pathlib import Path

_POINTER = re.compile(rb"\Aversion https://git-lfs\.github\.com/spec/v1\noid sha256:([0-9a-f]{64})\nsize (\d+)\n\Z")
PUBLISHABLE = frozenset({"public_domain_text", "noncommercial_text"})


def publication_approved(witness: dict, lock: dict) -> bool:
    """Check the documented decision's structure and byte binding, not its legal truth."""
    p = witness.get("publication", {})
    return (p.get("decision") == "redistribute"
            and p.get("scope") == "complete_text_public_redistribution"
            and bool(lock.get(witness["id"], {}).get("sha256"))
            and p.get("sha256") == lock[witness["id"]]["sha256"]
            and all(isinstance(p.get(k), str) and p[k].strip()
                    for k in ("authority", "basis", "reviewed_on", "assessment", "conditions", "attribution"))
            and {"work", "edition", "provider"} <= {
                e.get("scope") for e in p.get("evidence", [])
                if e.get("url", "").startswith("https://") and e.get("finding", "").strip()})


def publishable(registry: dict, lock: dict | None = None) -> tuple[str, ...]:
    """All occurrences must allow publication; an alias cannot override a hold."""
    allowed: dict[str, bool] = {}
    for work in registry["works"]:
        for witness in work["witnesses"]:
            wid = witness["id"]
            ok = work["rights"] in PUBLISHABLE and witness.get("format", "text") == "text"
            if "publication" in witness or work["rights"] == "noncommercial_text":
                ok = ok and publication_approved(witness, lock or {})
            allowed[wid] = allowed.get(wid, True) and ok
    return tuple(wid for wid, ok in allowed.items() if ok)


def _sha256(p: Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def _pointer(p: Path):
    return _POINTER.fullmatch(p.read_bytes()) if p.stat().st_size < 200 else None


def committed_sha256(p: Path) -> str:
    """Declared oid for a pointer, computed digest for bytes; never conflate them."""
    m = _pointer(p)
    return m[1].decode() if m else _sha256(p)


def check_file(p: Path, pin: dict, require_bytes: bool = False) -> str:
    if not p.is_file():
        return "missing"
    m = _pointer(p)
    if m:
        if m[1].decode() != pin.get("sha256") or int(m[2]) != pin.get("bytes"):
            return "pointer_mismatch"
        return "unhydrated" if require_bytes else "pointer_only"
    if p.stat().st_size != pin.get("bytes") or _sha256(p) != pin.get("sha256"):
        return "bytes_mismatch"
    return "bytes_verified"


def audit(registry: dict, lock: dict, texts: Path, require_bytes: bool = False,
          inventory: list[str] | None = None) -> dict:
    allowed = set(publishable(registry, lock))
    rows = []
    paths = sorted(texts.glob("*.txt")) if inventory is None else [texts / f"{wid}.txt" for wid in inventory]
    for p in paths:
        status = ("publication_blocked" if p.stem not in allowed else
                  "unlocked" if p.stem not in lock else check_file(p, lock[p.stem], require_bytes))
        rows.append({"witness": p.stem, "status": status})
    good = {"bytes_verified"} if require_bytes else {"bytes_verified", "pointer_only"}
    return {"mode": "complete_bytes" if require_bytes else "pointer_or_bytes",
            "ok": bool(rows) and all(r["status"] in good for r in rows),
            "counts": dict(Counter(r["status"] for r in rows)), "witnesses": rows}


def stage(ids: tuple[str, ...], lock: dict, cache: Path, dest: Path) -> dict[str, list[str]]:
    """Copy eligible ids selected by publishable; never copy pointers or drifted bytes."""
    out: dict[str, list[str]] = {"copied": [], "unchanged": [], "missing": [], "mismatch": []}
    dest.mkdir(parents=True, exist_ok=True)
    for wid in ids:
        src, dst = cache / f"{wid}.txt", dest / f"{wid}.txt"
        if not src.exists() or wid not in lock:
            out["missing"].append(wid)
        elif check_file(src, lock[wid], True) != "bytes_verified":
            out["mismatch"].append(wid)
        elif dst.exists() and check_file(dst, lock[wid]) in {"pointer_only", "bytes_verified"}:
            out["unchanged"].append(wid)
        else:
            shutil.copyfile(src, dst)
            out["copied"].append(wid)
    return out


def restore(wid: str, lock: dict, texts: Path, cache: Path) -> bool:
    """Only actual bytes, never a pointer, may populate the local study cache."""
    src = texts / f"{wid}.txt"
    if wid not in lock or check_file(src, lock[wid], True) != "bytes_verified":
        return False
    cache.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(src, cache / f"{wid}.txt")
    return True


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--require-bytes", action="store_true")
    parser.add_argument("--report", type=Path)
    parser.add_argument("--inventory", type=Path, help="git ls-files corpus/texts/*.txt output before hydration")
    args = parser.parse_args(argv)
    corpus = args.root / "corpus"
    inventory = None
    if args.inventory:
        paths = args.inventory.read_text().splitlines()
        if any(not re.fullmatch(r"corpus/texts/[a-z0-9-]+\.txt", p) for p in paths):
            parser.error("invalid committed text inventory")
        inventory = [Path(p).stem for p in paths]
    report = audit(json.loads((corpus / "registry.json").read_text()),
                   json.loads((corpus / "lock.json").read_text())["witnesses"],
                   corpus / "texts", args.require_bytes, inventory)
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({k: v for k, v in report.items() if k != "witnesses"}))
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
