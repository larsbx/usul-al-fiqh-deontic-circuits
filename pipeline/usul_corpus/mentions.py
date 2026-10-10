"""Labelled mentions for training a citation classifier.

The reception matcher is precise but deliberately narrow (a bare «المغني» needs a cue; «في الأوسط»
counts for nobody). This module turns it into a weak labeller over a high-recall candidate set:

* **candidates**: every occurrence of a *head* (a citation form with its cue stripped:
  «قال في الفروع» → «الفروع») in a citer's page, with its normalised context;
* **rule labels**: where the precise matcher resolves a span covering the candidate, its work
  (or ``none`` when a shadowing phrase covers it: الطبراني في الأوسط); otherwise unlabelled;
* **gold labels** (``corpus/mentions/gold.jsonl``, ids and labels only) override rules; the
  rule-vs-gold agreement on reviewed rows estimates the counts' precision;
* **splits** are by page hash (80/10/10), so no context crosses train and test.

Two tasks share the machinery: ``work`` (title lexicon) and ``author`` (author lexicon).
Contexts come from modern texts and stay in ``.cache/mentions``; only gold ids and the summary
are committed.
"""

from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass
from itertools import chain, zip_longest
from pathlib import Path
from typing import Iterable

from .arabic import normalize
from .reception import Cited, _pattern, _spans, _compile, pages, plain, resolve

NONE = "none"
WINDOW = 200
_CUE_HEADS = frozenset(map(normalize, ("صاحب", "كتاب", "كتابه")))


@dataclass(frozen=True)
class Task:
    name: str
    lexicon: tuple[Cited, ...]
    cue_single: bool


def heads(c: Cited) -> tuple[str, ...]:
    """Each form with its cue stripped: the text after its last «في», or after a leading صاحب/كتاب."""
    def head(form: str) -> str:
        toks = normalize(form).split()
        if normalize("في") in toks[:-1]:
            toks = toks[len(toks) - toks[::-1].index(normalize("في")):]
        elif len(toks) > 1 and toks[0] in _CUE_HEADS:
            toks = toks[1:]
        return " ".join(toks)
    return tuple(dict.fromkeys(map(head, c.cite_as)))


def split_of(witness: str, locator: str | None) -> str:
    h = int(hashlib.sha256(f"{witness}/{locator}".encode()).hexdigest(), 16) % 10
    return "test" if h == 0 else "dev" if h == 1 else "train"


def candidates(task: Task, witness: str, text: str, window: int = WINDOW) -> list[dict]:
    """Every head occurrence in ``text``, rule-labelled where the precise matcher is sure."""
    head_pats = [(h, _pattern(h, False)) for h in dict.fromkeys(chain.from_iterable(map(heads, task.lexicon)))]
    precise = _compile(task.lexicon, task.cue_single)
    rows = []
    for loc, body in pages(text):
        t = plain(body)
        sure = _spans(t, precise)
        for s, e, _ in resolve((m.start("t"), m.end("t"), h) for h, p in head_pats for m in p.finditer(t)):
            label = next((w if w is not None else NONE for ks, ke, w in sure if ks <= s and e <= ke), None)
            rows.append({"id": f"{task.name}:{witness}/{loc}@{s}", "task": task.name, "witness": witness, "locator": loc,
                         "start": s, "end": e, "surface": t[s:e], "left": t[max(0, s - window):s], "right": t[e:e + window],
                         "label": label, "label_source": "rule" if label else None, "split": split_of(witness, loc)})
    return rows


def choices(task: Task, surface: str) -> tuple[str, ...]:
    """The labels a reviewer may give a mention: the entries one of whose heads it is, and none."""
    return (*(c.work for c in task.lexicon if surface in heads(c)), NONE)


def with_gold(rows: Iterable[dict], gold: dict[str, str]) -> list[dict]:
    """Gold labels override rule labels; ``rule_label`` keeps the rule's verdict for agreement."""
    return [{**r, "rule_label": r["label"] if r.get("label_source") == "rule" else None,
             **({"label": gold[r["id"]], "label_source": "gold"} if r["id"] in gold else {})} for r in rows]


def review_queue(rows: Iterable[dict], n: int) -> list[dict]:
    """``n`` unlabelled rows, round-robin over surfaces so rare titles are not drowned by common ones."""
    by_surface: dict[str, list[dict]] = {}
    for r in rows:
        if r["label"] is None:
            by_surface.setdefault(r["surface"], []).append(r)
    return [r for r in chain.from_iterable(zip_longest(*by_surface.values())) if r is not None][:n]


def merge_gold(gold: dict[str, str], reviewed: Iterable[dict], task: Task) -> dict[str, str]:
    """Gold with every labelled reviewed row added; a label outside the row's choices is an error."""
    out = dict(gold)
    for r in reviewed:
        if r.get("label") is None:
            continue
        if r["label"] not in choices(task, r["surface"]):
            raise ValueError(f"{r['id']}: {r['label']!r} is not a choice for this surface")
        out[r["id"]] = r["label"]
    return out


def summary(rows_by_task: dict[str, list[dict]]) -> dict[str, dict]:
    """Counts only (no text): sources, labels, labelled rows per split, rule-vs-gold agreement."""
    def tally(xs: Iterable[str]) -> dict[str, int]:
        out: dict[str, int] = {}
        for x in xs:
            out[x] = out.get(x, 0) + 1
        return dict(sorted(out.items()))

    def one(rows: list[dict]) -> dict:
        labelled = [r for r in rows if r["label"] is not None]
        reviewed = [r for r in rows if r["label_source"] == "gold" and r.get("rule_label") is not None]
        return {"candidates": len(rows),
                "by_source": tally(r["label_source"] or "unlabelled" for r in rows),
                "labels": tally(r["label"] for r in labelled),
                "splits": tally(r["split"] for r in labelled),
                "rule_vs_gold": {"compared": len(reviewed), "agree": sum(r["label"] == r["rule_label"] for r in reviewed)}}
    return {task: one(rows) for task, rows in sorted(rows_by_task.items())}


def read_gold(path: Path) -> dict[str, str]:
    return {r["id"]: r["label"] for r in map(json.loads, path.read_text(encoding="utf-8").splitlines())} if path.exists() else {}


def write_gold(path: Path, gold: dict[str, str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("".join(json.dumps({"id": i, "label": l}, ensure_ascii=False) + "\n" for i, l in sorted(gold.items())),
                    encoding="utf-8")


def write_jsonl(path: Path, rows: Iterable[dict]) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)
    rows = list(rows)
    path.write_text("".join(json.dumps(r, ensure_ascii=False) + "\n" for r in rows), encoding="utf-8")
    return len(rows)
