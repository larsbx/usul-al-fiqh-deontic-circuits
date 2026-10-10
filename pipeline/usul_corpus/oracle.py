"""Baseline fatwā oracle: question → candidate ḥukm, with the fatwās it rests on.

The oracle reads only the question (title + question text), never the answer, which
states the verdict. Two baselines share one feature set (light stems + bigrams):

- Retriever: TF-IDF cosine over answered questions; the k nearest vote, weighted by
  similarity × label confidence, and each prediction cites them (`evidence`).
- NaiveBayes: multinomial, confidence-weighted.

Both are proposals for review, not rulings; `docs/architecture/fatawa-oracle.md`
reports how weak a surface-text oracle is.
"""

from __future__ import annotations

import math
from collections import Counter, defaultdict
from collections.abc import Mapping, Sequence

from .acts import STOP, stem
from .labels import HUKM, normalize_ar

Doc = tuple[str, str, float, list[str]]  # (id, hukm, weight, features)

_BASIS = {"summary": 1.0, "conclusion": 0.8, "lead": 0.7}
_BANK = {"confirmed": 1.0, "consistent": 0.8, "misread": 0.3}


def confidence(label: Mapping, verdict: Mapping) -> float:
    """Label weight from independent signals: where it was read, the bank's class, the English
    version's vote, and whether its act matches the question. Rejected/conflicting labels weigh 0."""
    w = _BASIS.get(label["basis"], 0.0) * _BANK.get(verdict["class"], 0.0)
    if verdict.get("en"):
        w *= 1.0 if verdict["en"] == label["hukm"] else 0.4
    if label.get("matches_question") is False:
        w *= 0.8
    return w


def features(rec: Mapping) -> list[str]:
    words = [stem(w) for w in normalize_ar(f"{rec.get('title') or ''} {rec.get('question') or ''}").split() if w not in STOP]
    words = [w for w in words if len(w) >= 2]
    return words + [f"{a}_{b}" for a, b in zip(words, words[1:])]


class Retriever:
    def __init__(self, docs: Sequence[Doc]):
        self.docs = list(docs)
        df = Counter(t for *_, f in self.docs for t in set(f))
        self.idf = {t: math.log(len(self.docs) / c) for t, c in df.items()}
        self.index: dict[str, list[tuple[int, float]]] = defaultdict(list)
        for i, (*_, f) in enumerate(self.docs):
            for t, x in self._vector(f).items():
                self.index[t].append((i, x))

    def _vector(self, feats: Sequence[str]) -> dict[str, float]:
        tf = Counter(t for t in feats if t in self.idf)
        v = {t: (1 + math.log(c)) * self.idf[t] for t, c in tf.items()}
        n = math.sqrt(sum(x * x for x in v.values())) or 1.0
        return {t: x / n for t, x in v.items() if x}

    def predict(self, feats: Sequence[str], k: int = 10) -> dict:
        scores: dict[int, float] = defaultdict(float)
        for t, x in self._vector(feats).items():
            for i, y in self.index.get(t, ()):
                scores[i] += x * y
        top = sorted(scores.items(), key=lambda kv: (-kv[1], kv[0]))[:k]
        vote: dict[str, float] = defaultdict(float)
        for i, s in top:
            vote[self.docs[i][1]] += s * self.docs[i][2]
        hukm = max(vote, key=vote.get) if vote and max(vote.values()) > 0 else None
        return {"hukm": hukm, "score": top[0][1] if top else 0.0,
                "evidence": [{"id": self.docs[i][0], "hukm": self.docs[i][1], "sim": round(s, 4)} for i, s in top]}


class NaiveBayes:
    def __init__(self, docs: Sequence[Doc], alpha: float = 0.1):
        self.alpha, prior, self.counts, self.totals = alpha, Counter(), {h: Counter() for h in HUKM}, Counter()
        for _, h, w, f in docs:
            prior[h] += w
            for t in f:
                self.counts[h][t] += w
                self.totals[h] += w
        self.vocab = set().union(*self.counts.values())
        z = sum(prior.values())
        self.log_prior = {h: math.log(prior[h] / z) for h in HUKM if prior[h]}

    def predict(self, feats: Sequence[str]) -> str:
        v, a = len(self.vocab), self.alpha
        score = {h: lp + sum(math.log((self.counts[h][t] + a) / (self.totals[h] + a * v)) for t in feats if t in self.vocab)
                 for h, lp in self.log_prior.items()}
        return max(score, key=score.get)


def evaluate(pred: Sequence[str | None], gold: Sequence[str]) -> dict:
    """Accuracy and F1 over the answered predictions; `coverage` is the share not abstained."""
    pairs = [(p, g) for p, g in zip(pred, gold) if p is not None]
    f1 = {}
    for h in HUKM:
        tp = sum(p == g == h for p, g in pairs)
        fp = sum(p == h != g for p, g in pairs)
        fn = sum(g == h != p for p, g in pairs)
        if tp + fp + fn:
            f1[h] = 2 * tp / (2 * tp + fp + fn)
    return {"n": len(gold), "coverage": len(pairs) / max(1, len(gold)),
            "accuracy": sum(p == g for p, g in pairs) / max(1, len(pairs)),
            "macro_f1": sum(f1.values()) / max(1, len(f1)), "per_class_f1": f1}
