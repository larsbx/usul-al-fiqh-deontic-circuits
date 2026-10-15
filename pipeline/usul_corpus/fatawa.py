"""IslamQA.info (al-Munajjid) fatāwā → normalised JSONL for the oracle.

Source: the site's own offline dumps — the per-language ``data.ndjson.gz`` files
the IslamQA app and website download for offline reading, listed in
``{base}/dumps/manifest.json``. Each line is an event ``{op, type, data}``; a
snapshot is all ``created``, later deltas also ``updated``/``deleted``. Folding
the events gives the current database; answers are then flattened to records.
Dumps and records are committed under ``data/islamqa`` (Git LFS; private repo).
"""

from __future__ import annotations

import gzip
import html
import json
import re
from collections.abc import Iterable, Mapping
from pathlib import Path

SITE = "https://islamqa.info"
_BREAK = re.compile(r"</p>|<br\s*/?>|</li>|</h\d>", re.I)
_TAG = re.compile(r"<[^>]+>")

Key = tuple[str, int]


def html_text(s: str | None) -> str | None:
    """HTML → plain text, one line per paragraph."""
    if not s:
        return None
    lines = (" ".join(l.split()) for l in html.unescape(_TAG.sub("", _BREAK.sub("\n", s))).splitlines())
    return "\n".join(l for l in lines if l) or None


def snapshot_witnesses(dump: Mapping) -> list[dict]:
    """Pinned snapshot → one fetchable witness per language."""
    return [
        {"id": f"islamqa-{lang}", "kind": "zadapps", "base": dump["base"], "folder": f"{dump['snapshot']}/{lang}",
         "file": dump["file"], "format": "ndjson.gz", "lang": lang, "sha256": pin["sha256"]}
        for lang, pin in dump["langs"].items()
    ]


def fold(events: Iterable[Mapping]) -> dict[Key, dict]:
    """Apply created/updated/deleted events in order; keyed by (type, reference)."""
    db: dict[Key, dict] = {}
    for e in events:
        key = (e["type"], int(e["data"]["reference"]))
        if e["op"] == "deleted":
            db.pop(key, None)
        else:
            db[key] = e["data"]
    return db


def _path(node: Mapping) -> dict:
    return {"ref": node["reference"], "path": [a["title"] for a in node.get("ancestors") or []] + [node["title"]]}


def answer_record(d: Mapping) -> dict:
    ref, src = d["reference"], d.get("source") or {}
    return {
        "id": f"islamqa.{ref}",
        "lang": d["lang"],
        "url": f"{SITE}/{d['lang']}/answers/{ref}",
        "title": d["title"],
        "question": html_text(d.get("question")),
        "answer": html_text(d.get("body")),
        "summary": html_text(d.get("description")),
        "source": src and {"ref": src["reference"], "title": src["title"]},
        "topics": [_path(t) for t in d.get("topics") or []],
        "subsites": [_path(t) for t in d.get("subsites") or []],
        "see_also": [f"islamqa.{f['reference']}" for f in d.get("fatawas") or []],
        "langs": d.get("contentLangs") or [d["lang"]],
        "created": (d.get("createdAt") or "")[:10] or None,
        "updated": (d.get("updatedAt") or "")[:10] or None,
    }


def answers(db: Mapping[Key, dict]) -> list[dict]:
    return [answer_record(d) for (t, _), d in sorted(db.items(), key=lambda kv: kv[0][1]) if t == "answer"]


def write_jsonl_gz(path: Path, records: Iterable[Mapping]) -> None:
    """Byte-deterministic gzip (no name, mtime 0): regenerating leaves no diff."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "wb") as raw, gzip.GzipFile(filename="", mode="wb", fileobj=raw, mtime=0) as gz:
        gz.writelines((json.dumps(r, ensure_ascii=False) + "\n").encode() for r in records)
