"""Witness texts committed under ``corpus/texts`` (Git LFS).

Only witnesses of works whose rights are in ``PUBLISHABLE`` are committed: public-domain texts, and
texts the owner has cleared for non-commercial study (``noncommercial_text``). Other modern texts stay
in ``.cache/corpus``. Every committed text is byte-identical to its pinned source: ``stage`` copies from
the cache only after checking ``lock.json``, and ``restore`` lets ``fetch`` fill the cache from a
committed text instead of the network when the two agree. An LFS pointer names its content's sha256,
so the check also runs where LFS content was not downloaded (CI).
"""

from __future__ import annotations

import hashlib
import re
import shutil
from pathlib import Path

_POINTER = re.compile(rb"\Aversion https://git-lfs\.github\.com/spec/v1\noid sha256:([0-9a-f]{64})\nsize \d+\n\Z")


PUBLISHABLE = frozenset({"public_domain_text", "noncommercial_text"})


def publishable(registry: dict) -> tuple[str, ...]:
    """Ids of the text witnesses of publishable works, each once, in registry order."""
    return tuple(dict.fromkeys(x["id"] for w in registry["works"] if w["rights"] in PUBLISHABLE
                               for x in w["witnesses"] if x.get("format") != "pdf"))


def _sha256(p: Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def committed_sha256(p: Path) -> str:
    """The content hash of a committed text: an LFS pointer's oid, or the file's own sha256."""
    head = p.read_bytes()[:200] if p.stat().st_size < 200 else b""
    m = _POINTER.match(head)
    return m.group(1).decode() if m else _sha256(p)


def stage(ids: tuple[str, ...], lock: dict, cache: Path, dest: Path) -> dict[str, list[str]]:
    """Copy each verified cached text to ``dest``; never replace a committed text with drifted bytes."""
    out: dict[str, list[str]] = {"copied": [], "unchanged": [], "missing": [], "mismatch": []}
    dest.mkdir(parents=True, exist_ok=True)
    for wid in ids:
        src, dst = cache / f"{wid}.txt", dest / f"{wid}.txt"
        if not src.exists() or wid not in lock:
            out["missing"].append(wid)
        elif _sha256(src) != lock[wid]["sha256"]:
            out["mismatch"].append(wid)
        elif dst.exists() and committed_sha256(dst) == lock[wid]["sha256"]:
            out["unchanged"].append(wid)
        else:
            shutil.copyfile(src, dst)
            out["copied"].append(wid)
    return out


def restore(wid: str, lock: dict, texts: Path, cache: Path) -> bool:
    """Fill the cache from the committed text when it is real content matching the lock."""
    src = texts / f"{wid}.txt"
    if not (src.exists() and wid in lock and _sha256(src) == lock[wid]["sha256"]):
        return False
    cache.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(src, cache / f"{wid}.txt")
    return True
