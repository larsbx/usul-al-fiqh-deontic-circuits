"""P0.6, the routing index: which encoder a text is likely to fall under, and which bābs of the mutūn
each encoder's cases sit in (docs/roadmap-parallel-derivation.md, lane B).

Profiles are derived, not written: an encoder's profile is the TF-IDF centroid of its evidence, i.e.
the texts of the records its annotated cases rest on and the text of its own qawāʿid. Its lexicon is
the profile's heaviest words, and its bābs are the matn units nearest the profile (not yet validated:
lane B's share of retrieved units that are real cases measures them). So no agent picks
keywords, and every lexicon word occurs in the encoder's evidence.

Recall is measured, not assumed, under three splits into ``FOLDS``, each fold routed by a model fitted
without it and compared with ranking encoders by case frequency under the same split. The headline,
``by_qaida``, folds whole qawāʿid, so no sibling of a test farʿ trains the model; the formalised qāʿida
statements stay in, as they do when the index is used. ``within_qaida`` folds records, so siblings train
the model (audit PR-38). ``unseen_qaida`` also holds out the qāʿida's statement: routing a farʿ of a
qāʿida the bank has not formalised. The out-of-domain report routes
the IslamQA tranche's questions, modern texts the profiles never saw. The index ranks candidates for
annotation; it decides nothing, and a retrieved unit is a case only once annotated.
"""

from __future__ import annotations

import gzip
import hashlib
import json
import math
from collections import Counter
from dataclasses import dataclass
from pathlib import Path

from . import takhrij
from .arabic import words

INDEX = "routing/index.json"
OOD = "routing/ood.json"
ANSWERS = "data/islamqa/answers/islamqa-ar.jsonl.gz"
TRANCHE = "corpus/fatawa/takhrij/islamqa_tranche1.json"
FOLDS, KS, LEXICON, BABS = 5, (1, 5, 10), 12, 5
STOP_SHARE = 0.1  # a word in more of the evidence documents than this (and in more than two) is a particle or formula

Vector = dict[str, float]


def _norm(v: Vector) -> Vector:
    n = math.sqrt(sum(x * x for x in v.values())) or 1.0
    return {w: x / n for w, x in v.items()}


@dataclass(frozen=True)
class Model:
    idf: dict[str, float]
    profiles: dict[str, Vector]
    vocabulary: dict[str, set[str]]

    @classmethod
    def fit(cls, evidence: list[tuple[str, str]]) -> "Model":
        docs = [(label, words(text)) for label, text in evidence]
        df = Counter(w for _, ws in docs for w in set(ws))
        idf = {w: math.log((len(docs) + 1) / (d + 1)) + 1 for w, d in df.items() if d <= max(STOP_SHARE * len(docs), 2)}
        docs = [(label, [w for w in ws if w in idf]) for label, ws in docs]
        sums: dict[str, Counter] = {}
        for label, ws in docs:
            for w, x in _norm({w: n * idf[w] for w, n in Counter(ws).items()}).items():
                sums.setdefault(label, Counter())[w] += x
        vocab: dict[str, set[str]] = {}
        for label, ws in docs:
            vocab.setdefault(label, set()).update(ws)
        return cls(idf, {label: _norm(dict(v)) for label, v in sums.items()}, vocab)

    def vector(self, text: str) -> Vector:
        return _norm({w: n * self.idf[w] for w, n in Counter(words(text)).items() if w in self.idf})

    def scores(self, text: str) -> dict[str, float]:
        v = self.vector(text)
        return {label: sum(x * p.get(w, 0.0) for w, x in v.items()) for label, p in self.profiles.items()}

    def rank(self, text: str) -> list[str]:
        s = self.scores(text)
        return sorted(s, key=lambda label: (-s[label], label))

    def lexicon(self, label: str, n: int = LEXICON) -> list[str]:
        p = self.profiles[label]
        return sorted(p, key=lambda w: (-p[w], w))[:n]


def _records(corpus: Path, ids: set[str]) -> dict[str, dict]:
    """The committed records with these ids, read only from the witnesses they name."""
    keys = {i.split(".")[2] for i in ids}
    return {r["id"]: r for p in sorted((corpus / "records").glob("*.jsonl")) if p.stem.replace("-", "_") in keys
            for r in map(json.loads, p.read_text(encoding="utf-8").splitlines()) if r["id"] in ids}


def _text(r: dict) -> str:
    return " ".join(r[k] for k in ("heading_ar", "excerpt_ar", "case_ar") if r.get(k))


def cases(corpus: Path) -> list[tuple[str, str, str]]:
    """(id, encoder, text) for annotations usable as whole-case routing labels.

    Gap triage and a component guard need not identify a whole unit's correct encoder.
    Such annotations explicitly set routing_label=false rather than feeding their examined
    proposal back into training or held-out recall as a positive label.
    """
    cs = takhrij.load(corpus)
    recs = _records(corpus, {c["far"] for c in cs})
    return sorted((c["far"], c["encoder"], _text(recs[c["far"]])) for c in cs
                  if c["far"] in recs and c.get("routing_label", True))


def _qawaid(corpus: Path) -> list[tuple[str, str, str]]:
    """(id, encoder, text) for every qāʿida an encoder formalises."""
    enc = sorted(takhrij.ENCODERS.items())
    recs = _records(corpus, {q for _, e in enc for q in e["qawaid"]})
    return [(q, name, _text(recs[q])) for name, e in enc for q in e["qawaid"] if q in recs]


def qawaid(corpus: Path) -> list[tuple[str, str]]:
    """(encoder, text) for every qāʿida an encoder formalises."""
    return [(e, t) for _, e, t in _qawaid(corpus)]


def evidence(corpus: Path) -> list[tuple[str, str]]:
    return qawaid(corpus) + [(e, t) for _, e, t in cases(corpus)]


def _fold(record_id: str) -> int:
    return int(hashlib.sha256(record_id.encode()).hexdigest(), 16) % FOLDS


def _recall(hits: Counter, n: int) -> dict[str, float]:
    return {str(k): round(hits[k] / n, 4) for k in KS}


def _qaida(far: str) -> str:
    """The qāʿida a farʿ's record id names: `….q043.f005` → `….q043`."""
    return far.rsplit(".", 1)[0]


def _split(cs: list[tuple[str, str, str]], qs: list[tuple[str, str, str]], unit, statements: bool) -> dict:
    """Recall@k of each case routed by a model fitted without its fold (cases folded by `unit` of their id;
    the qāʿida statements kept, or folded by their own id), against the frequency prior of the same split."""
    hits, prior = Counter(), Counter()
    for f in range(FOLDS):
        train = [(e, t) for i, e, t in cs if _fold(unit(i)) != f]
        model = Model.fit([(e, t) for i, e, t in qs if statements or _fold(i) != f] + train)
        freq = [e for e, _ in sorted(Counter(e for e, _ in train).items(), key=lambda x: (-x[1], x[0]))]
        for i, e, t in cs:
            if _fold(unit(i)) == f:
                ranked = model.rank(t)
                for k in KS:
                    hits[k] += e in ranked[:k]
                    prior[k] += e in freq[:k]
    return {"recall": _recall(hits, len(cs)), "prior": _recall(prior, len(cs))}


def held_out(corpus: Path) -> dict:
    """Recall under each split; `by_qaida` is the headline (audit PR-38)."""
    cs, qs = cases(corpus), _qawaid(corpus)
    return {"cases": len(cs), "folds": FOLDS,
            "by_qaida": _split(cs, qs, _qaida, True),
            "within_qaida": _split(cs, qs, str, True),
            "unseen_qaida": _split(cs, qs, _qaida, False)}


def _babs(corpus: Path) -> list[dict]:
    return [r for p in sorted((corpus / "records").glob("*.jsonl"))
            for r in map(json.loads, p.read_text(encoding="utf-8").splitlines()) if r["record_type"] == "bab"]


def index(corpus: Path) -> dict:
    model = Model.fit(evidence(corpus))
    babs = [(r, model.vector(" ".join([*r["path_ar"], _text(r)]))) for r in _babs(corpus)]
    support = Counter(e for _, e, _ in cases(corpus))
    out = {}
    for name in sorted(model.profiles):
        p = model.profiles[name]
        scored = sorted(((round(sum(x * p.get(w, 0.0) for w, x in v.items()), 4), r["id"]) for r, v in babs),
                        key=lambda s: (-s[0], s[1]))[:BABS]
        by_id = {r["id"]: r for r, _ in babs}
        out[name] = {"cases": support[name], "lexicon": model.lexicon(name),
                     "babs": [{"id": i, "heading": by_id[i]["heading_ar"], "path": by_id[i]["path_ar"], "score": s}
                              for s, i in scored if s > 0]}
    return {"schema_version": 1, "status": "candidate",
            "method": "TF-IDF centroid of each encoder's evidence (its annotated cases' records and its qawāʿid); "
                      "see pipeline/usul_corpus/routing.py",
            "recall": held_out(corpus), "encoders": out}


def render(corpus: Path) -> str:
    return json.dumps(index(corpus), ensure_ascii=False, indent=2) + "\n"


def ood(root: Path) -> dict:
    """Recall@k routing the IslamQA tranche's questions (title and question) with the full model."""
    corpus = root / "corpus"
    tranche = json.loads((root / TRANCHE).read_text(encoding="utf-8"))["cases"]
    need = {c["far"].rsplit(".", 1)[0] for c in tranche}
    with gzip.open(root / ANSWERS, "rt", encoding="utf-8") as fh:
        asked = {r["id"]: f"{r['title']} {r['question']}" for r in map(json.loads, fh) if r["id"] in need}
    model = Model.fit(evidence(corpus))
    freq = [e for e, _ in sorted(Counter(e for _, e, _ in cases(corpus)).items(), key=lambda x: (-x[1], x[0]))]
    routed = [(c["encoder"], model.rank(asked[a])) for c in tranche if (a := c["far"].rsplit(".", 1)[0]) in asked]
    hits = Counter(k for e, r in routed for k in KS if e in r[:k])
    prior = Counter(k for e, _ in routed for k in KS if e in freq[:k])
    return {"schema_version": 1, "status": "candidate", "set": TRANCHE, "text": "title and question",
            "cases": len(routed), "recall": _recall(hits, len(routed)), "prior": _recall(prior, len(routed))}


def render_ood(root: Path) -> str:
    return json.dumps(ood(root), ensure_ascii=False, indent=2) + "\n"
