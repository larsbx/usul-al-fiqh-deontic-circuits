"""The owner's decisions on the weighers' review items (corpus/reconciliation/revisions.json).

Annotations are superseded, never silently rewritten: each revision keeps the value it replaced, its
reason, and the verbatim passages it rests on (checked with every other excerpt by `make
source-verify`), and must still describe the live record.
"""
import json
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
REVISIONS = json.loads((ROOT / "corpus/reconciliation/revisions.json").read_text(encoding="utf-8"))["revisions"]


def _record(rev: dict) -> dict:
    data = json.loads((ROOT / rev["file"]).read_text(encoding="utf-8"))
    [rec] = [r for r in data.get("cases", data.get("entries", [])) if r["far"] == rev["far"]]
    return rec


def _step(node, key: str):
    if isinstance(node, list):
        if key.startswith("«"):
            [hit] = [x for x in node if key.strip("«»") in x.get("excerpt_ar", "")]
            return hit
        return node[int(key)]
    return node[key]


@pytest.mark.parametrize("rev", REVISIONS, ids=lambda r: f"{r['item']}:{r['far'][-9:]}:{r['field']}")
def test_revision_describes_the_live_record(rev):
    *path, last = rev["field"].split("/")
    node = _record(rev)
    for k in path:
        node = _step(node, k)
    assert rev["reason"].strip()
    if rev.get("removed"):
        assert rev["from"] not in node, "a removed value is back"
    elif last == "+":
        assert rev["to"] in node and rev["from"] is None
    else:
        assert node[last] == rev["to"] != rev["from"]
