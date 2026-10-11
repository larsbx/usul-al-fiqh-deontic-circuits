"""Candidate retrieval from fact-field relevance; never infer values or execute a ruling.

Run: python -m usul_corpus.typed_routing ROOT [--check]
Only classical case annotations train the field detector. Modern labels are test-only.
"""
from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import math
from collections import Counter
from dataclasses import dataclass
from pathlib import Path

from . import routing, takhrij

OUTPUT = "corpus/routing/type-aware.json"
WEIGHTS = (0.0, 0.25, 0.5, 1.0)
ANSWERS_SHA256 = "621fcd30c854a45407a5c303de8656c402eab4c59abde884a06038348ffbb205"


def questions(root: Path, need: set[str]) -> dict[str, str]:
    path = root / routing.ANSWERS
    with path.open("rb") as fh:
        digest = hashlib.file_digest(fh, "sha256").hexdigest()
    if digest != ANSWERS_SHA256:
        raise ValueError("Original OOD answers missing or not the pinned SHA-256 witness")
    with gzip.open(path, "rt", encoding="utf-8") as fh:
        selected = [r for r in map(json.loads, fh) if r["id"] in need]
    asked = {r["id"]: f"{r['title']} {r['question']}" for r in selected}
    if set(asked) != need or len(selected) != len(asked):
        raise ValueError("Missing or duplicated original OOD questions")
    return asked


def signatures() -> dict[str, dict]:
    return {name: {key: list(domain) for key, domain in sorted(e["facts"].items())}
            for name, e in sorted(takhrij.ENCODERS.items())}


def compatible(observed: dict, signature: dict) -> bool:
    """Partial, explicitly supplied observations; Python bool/int equality is insufficient.

    Missing facts stay unknown. Extra fields mean this encoder does not consume that
    observation, not that its legal reading is false.
    """
    return all(key in signature and any(type(value) is type(v) and value == v
               for v in signature[key]) for key, value in observed.items())


@dataclass
class Model:
    lexical: routing.Model
    fields: routing.Model
    schemas: dict[str, dict]
    field_idf: dict[str, float]

    @classmethod
    def fit(cls, corpus: Path, train: list[tuple[str, str, str]]) -> "Model":
        annotations = {}
        for c in takhrij.load(corpus):
            annotations.setdefault((c["far"], c["encoder"]), set()).update((c.get("facts") or {}).keys())
        evidence = [(key, text) for rid, label, text in train
                    for key in sorted(annotations.get((rid, label), set()))]
        schemas = signatures()
        df = Counter(key for schema in schemas.values() for key in schema)
        return cls(routing.Model.fit(routing.qawaid(corpus) + [(e, t) for _, e, t in train]),
                   routing.Model.fit(evidence), schemas,
                   {k: math.log((len(schemas) + 1) / (n + 1)) + 1 for k, n in df.items()})

    def scores(self, text: str, weight: float) -> dict[str, float]:
        lexical = self.lexical.scores(text)
        # Cosine between a soft field-relevance vector and each declared signature.
        # This is a learned text proxy for structure, not verified fact extraction.
        f = {k: s * self.field_idf[k] for k, s in self.fields.scores(text).items()}
        norm = math.sqrt(sum(v*v for v in f.values())) or 1.0
        result = {}
        for label, score in lexical.items():
            keys = self.schemas[label]
            denom = math.sqrt(sum(self.field_idf[k]**2 for k in keys)) or 1.0
            structural = sum(f.get(k, 0)*self.field_idf[k] for k in keys) / (norm*denom)
            result[label] = (1-weight)*score + weight*structural
        return result

    def rank(self, text: str, weight: float, observed: dict | None = None) -> list[str]:
        scores = self.scores(text, weight)
        return sorted((label for label in scores if observed is None or compatible(observed, self.schemas[label])),
                      key=lambda label: (-scores[label], label))


def _metrics(rows: list[dict], method: str) -> dict:
    n = len(rows)
    return {str(k): round(sum(r["encoder"] in r[method][:k] for r in rows)/n, 4)
            for k in routing.KS} if n else {}


def select_weight(corpus: Path, train: list[tuple[str, str, str]]) -> float:
    """Inner grouped folds; maximize recall@5, then @1, then prefer less structure."""
    hits = {w: Counter() for w in WEIGHTS}
    for fold in range(routing.FOLDS):
        fit = [c for c in train if routing._fold(c[0]) != fold]
        test = [c for c in train if routing._fold(c[0]) == fold]
        if not test:
            continue
        model = Model.fit(corpus, fit)
        for _, label, text in test:
            for w in WEIGHTS:
                ranked = model.rank(text, w)
                for k in routing.KS:
                    hits[w][k] += label in ranked[:k]
    return max(WEIGHTS, key=lambda w: (hits[w][5], hits[w][1], -w))


def evaluate(root: Path, classical_only: bool = False) -> dict:
    corpus = root / "corpus"
    cases = routing.cases(corpus)
    rows, folds = [], []
    ablations = {w: Counter() for w in WEIGHTS}
    for fold in range(routing.FOLDS):
        train = [c for c in cases if routing._fold(c[0]) != fold]
        weight = select_weight(corpus, train)
        folds.append({"fold": fold, "weight": weight})
        model = Model.fit(corpus, train)
        for rid, label, text in cases:
            if routing._fold(rid) == fold:
                for w in WEIGHTS:
                    ranked = model.rank(text, w)
                    for k in routing.KS:
                        ablations[w][k] += label in ranked[:k]
                rows.append({"record_id": rid, "encoder": label,
                             **{m: model.rank(text, w)[:10] for m, w in
                                (("lexical", 0), ("structural", 1), ("hybrid", weight))}})
    weight = select_weight(corpus, cases)
    model = Model.fit(corpus, cases)
    modern, asked = [], {}
    original = json.loads((corpus / routing.OOD).read_text())
    if not classical_only:
        tranche = json.loads((root / routing.TRANCHE).read_text())["cases"]
        need = {c["far"].rsplit(".", 1)[0] for c in tranche}
        asked = questions(root, need)
        if set(asked) != need:
            raise ValueError("Missing original OOD questions; refuse a changed denominator")
        modern = [{"record_id": c["far"], "encoder": c["encoder"],
                   **{m: model.rank(asked[c["far"].rsplit(".", 1)[0]], w)[:10] for m, w in
                      (("lexical", 0), ("structural", 1), ("hybrid", weight))}} for c in tranche]
        # All committed original metrics must replay before comparing new results.
        original = json.loads((corpus / routing.OOD).read_text())
        if _metrics(modern, "lexical") != original["recall"] or len(modern) != original["cases"]:
            raise ValueError("Original OOD baseline did not replay")
    # Bāb assignments have no reviewed gold labels: measure churn, not correctness.
    babs = routing._babs(corpus)
    texts = {r["id"]: " ".join([*r["path_ar"], routing._text(r)]) for r in babs}
    scores = {rid: {m: model.scores(text, w) for m, w in (("lexical", 0), ("hybrid", weight))}
              for rid, text in texts.items()}
    changes = []
    for label in sorted(model.lexical.profiles):
        top = {m: sorted(texts, key=lambda rid: (-scores[rid][m][label], rid))[:routing.BABS]
               for m in ("lexical", "hybrid")}
        changes.append({"encoder": label, **top,
                        "shared": len(set(top["lexical"]) & set(top["hybrid"]))})
    source_paths = sorted({routing.TRANCHE, "corpus/routing/ood.json", "corpus/lock.json",
                           *[str(p.relative_to(root)) for p in (corpus / "takhrij").glob("*.json")],
                           *[str(p.relative_to(root)) for p in (corpus / "records").glob("*.jsonl")],
                           *[str(p.relative_to(root)) for p in (root / "pipeline/usul_corpus/encoders").glob("*.py")],
                           "pipeline/usul_corpus/takhrij.py", "pipeline/usul_corpus/routing.py",
                           "pipeline/usul_corpus/arabic.py", "pipeline/usul_corpus/typed_routing.py"})
    return {"schema_version": 1, "status": "candidate", "method": "classical-only field relevance and signature cosine",
            "warnings": ["No fact values inferred; no kernel invoked; no legal ruling established",
                         "Field relevance is a lexical proxy, not verified structural extraction",
                         "Original OOD was already published; this is not a fresh blind test",
                         "No modern training/tuning annotations added; reviewed bab accuracy unavailable"],
            "selection": {"weights": list(WEIGHTS), "objective": "recall@5, recall@1, lower weight",
                          "outer_folds": folds, "full_classical_weight": weight},
            "schemas": signatures(),
            "coverage": {"registry_encoders": len(model.schemas), "ranked_encoders": len(model.lexical.profiles),
                         "without_lexical_evidence": sorted(set(model.schemas)-set(model.lexical.profiles)),
                         "learned_fields": sorted(model.fields.profiles),
                         "undetected_fields": sorted(set(model.field_idf)-set(model.fields.profiles))},
            "classical": {"cases": len(rows),
                          "fixed_weight_recall": {str(w): routing._recall(h, len(rows)) for w, h in ablations.items()}, "recall": {m: _metrics(rows, m) for m in ("lexical", "structural", "hybrid")},
                          "rows": sorted(rows, key=lambda r: (r["record_id"], r["encoder"]))},
            "ood": {"cases": len(modern), "questions": len(asked), "text": "title and question",
                    "evaluation_status": "blocked_missing_questions" if classical_only else "evaluated",
                    "original_lexical": original,
                    "recall": {m: _metrics(modern, m) for m in ("lexical", "structural", "hybrid")}, "rows": modern},
            "bab": {"status": "unvalidated", "accuracy": None, "assignments": changes},
            "inputs_sha256": {p: hashlib.sha256((root/p).read_bytes()).hexdigest() for p in source_paths},
            "questions_sha256": hashlib.sha256(json.dumps(asked, ensure_ascii=False, sort_keys=True).encode()).hexdigest()}


def render(root: Path, classical_only: bool = False) -> str:
    return json.dumps(evaluate(root, classical_only), ensure_ascii=False, indent=2) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", type=Path)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--classical-only", action="store_true", help="explicit partial report; OOD remains blocked")
    args = parser.parse_args()
    text = render(args.root, args.classical_only)
    output = args.root / OUTPUT
    if args.check:
        if output.read_text() != text:
            raise SystemExit("type-aware artifact is stale")
    else:
        output.write_text(text, encoding="utf-8")


if __name__ == "__main__":
    main()
