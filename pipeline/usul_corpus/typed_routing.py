"""T3/T4 of the type system: routing by type, measured on blind-typed test sets.

Each unit of a test set (an IslamQA answer, a classical farʿ) was typed blind (without its labels)
into one or more partial situations: the fields of `Usul.Typing.Qaida` the text settles, each with
a verbatim quote of at most 160 characters (``corpus/typing/<set>_situations.json``; LLM-assisted,
status candidate). They are written out as ``sit/3`` facts (``examples/v41_<set>_situations.pl``) and
routed by the Prolog typing rules (``examples/v41_typing.pl``, exported from Lean): encoders are
ranked by the share of their fields a situation settles (``coverage/4``, relations included), with
ties counted against the true encoder. Each report sets this against the lexical routing index on
the same cases (``corpus/typing/<set>_report.json``).

A proposal set is typed the same way but has no labels: a deterministic sample of the R2 units
awaiting annotation, for which the hybrid's ranking is a routing proposal for lane B
(``corpus/routing/<set>_proposals.json``), not a measurement.
"""

from __future__ import annotations

import hashlib
import json
import subprocess
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Callable

from . import routing
from .fatawa_prolog import atom

TYPING = "examples/v41_typing.pl"
KS = (1, 5, 10)


@dataclass(frozen=True)
class Typed:
    """Units typed blind, their situations committed as ``corpus/typing/<name>_situations.json``."""
    name: str

    @property
    def situations(self) -> str:
        return f"corpus/typing/{self.name}_situations.json"

    @property
    def prolog(self) -> str:
        return f"examples/v41_{self.name}_situations.pl"


@dataclass(frozen=True)
class TestSet(Typed):
    """A labelled test set: its cases as (unit, encoder, needs), and the routing index's ranking of
    the encoders for each unit (the lexical baseline, held out where the index was fitted on the set)."""
    cases: Callable[[Path], list[tuple[str, str, list[str]]]]
    ranker: Callable[[Path], dict[str, list[str]]]

    @property
    def report(self) -> str:
        return f"corpus/typing/{self.name}_report.json"


@dataclass(frozen=True)
class ProposalSet(Typed):
    """An unlabelled sample: per witness, the k records whose ids hash lowest (sha256)."""
    plan: tuple[tuple[str, int], ...]

    def units(self, root: Path) -> list[str]:
        out = []
        for w, k in self.plan:
            raw = (root / "corpus/records" / f"{w}.jsonl").read_text(encoding="utf-8")
            ids = [json.loads(line)["id"] for line in raw.splitlines()]
            out += sorted(sorted(ids, key=lambda i: hashlib.sha256(i.encode()).hexdigest())[:k])
        return out

    @property
    def proposals(self) -> str:
        return f"corpus/routing/{self.name}_proposals.json"


def hybrid(scores: dict[str, float], words: list[str]) -> list[str]:
    """Types first: encoders by the share of their fields a situation settles, then lexical rank."""
    position = {e: i for i, e in enumerate(words)}
    return sorted(words, key=lambda e: (-scores.get(e, 0.0), position[e]))


def shares(cov: dict[str, tuple[int, int]]) -> dict[str, float]:
    return {e: k / n for e, (k, n) in cov.items()}


def _islamqa_cases(root: Path) -> list[tuple[str, str, list[str]]]:
    cases = json.loads((root / "corpus/fatawa/takhrij/islamqa_tranche1.json").read_text(encoding="utf-8"))["cases"]
    return [(c["far"].rsplit(".", 1)[0], c["encoder"], c.get("needs", [])) for c in cases]


def _islamqa_ranker(root: Path) -> dict[str, list[str]]:
    """The full index ranks each answer's title and question, as in ``corpus/routing/ood.json``."""
    import gzip
    corpus, need = root / "corpus", {u for u, _, _ in _islamqa_cases(root)}
    model = routing.Model.fit(routing.evidence(corpus))
    with gzip.open(root / routing.ANSWERS, "rt", encoding="utf-8") as fh:
        return {r["id"]: model.rank(f"{r['title']} {r['question']}") for r in map(json.loads, fh) if r["id"] in need}


FOLD = 0


def _classical_cases(root: Path) -> list[tuple[str, str, list[str]]]:
    from . import takhrij
    needs = {c["far"]: c.get("needs", []) for c in takhrij.load(root / "corpus")}
    return [(far, enc, needs.get(far, [])) for far, enc, _ in routing.cases(root / "corpus") if routing._fold(far) == FOLD]


def _classical_ranker(root: Path) -> dict[str, list[str]]:
    """The index refitted without this fold (qawāʿid kept) ranks each farʿ's text."""
    corpus = root / "corpus"
    cs, qs = routing.cases(corpus), routing.qawaid(corpus)
    model = routing.Model.fit(qs + [(e, t) for i, e, t in cs if routing._fold(i) != FOLD])
    return {i: model.rank(t) for i, _, t in cs if routing._fold(i) == FOLD}


SETS = (TestSet("islamqa_tranche1", _islamqa_cases, _islamqa_ranker),
        TestSet("rajab_fold0", _classical_cases, _classical_ranker))


def sid(answer: str, i: int) -> str:
    return f"s_{answer.replace('.', '_')}_{i}"


def prolog_file(ts: Typed, data: dict) -> str:
    lines = [f"% GENERATED by `python -m usul_corpus typed-routing` from {ts.situations}. Do not edit.",
             ":- encoding(utf8).", ":- multifile([sit/3, situation_of/2]).", ":- discontiguous([sit/3, situation_of/2]).", ""]
    for a in data["answers"]:
        for i, s in enumerate(a["situations"], 1):
            lines.append(f"situation_of({sid(a['answer'], i)}, {atom(a['answer'])}).")
            lines += [f"sit({sid(a['answer'], i)}, {f}, {atom(v)})." for f, v in sorted(s["facts"].items())]
    return "\n".join(lines) + "\n"


def coverage(root: Path, ts: Typed) -> dict[str, dict[str, tuple[int, int]]]:
    """unit ↦ encoder ↦ (fields settled, fields read), best over the unit's situations (needs swipl)."""
    goal = "forall((coverage(E,S,K,N), K > 0, situation_of(S,A)), format('~w\\t~w\\t~w\\t~w~n',[A,E,K,N]))"
    out = subprocess.run(["swipl", "-q", "-g", goal, "-t", "halt", str(root / TYPING), str(root / ts.prolog)],
                         capture_output=True, text=True, check=True).stdout
    best: dict[str, dict[str, tuple[int, int]]] = defaultdict(dict)
    for a, e, k, n in (l.split("\t") for l in out.splitlines()):
        k, n = int(k), int(n)
        if k / n > (lambda p: p[0] / p[1])(best[a].get(e, (0, 1))):
            best[a][e] = (k, n)
    return best


def by_encoder(rows: list[dict]) -> dict[str, dict]:
    """Per true encoder: cases, how many it applies to, ranks in the top 5, and leaves unrouted."""
    out: dict[str, dict] = {}
    for r in rows:
        e = out.setdefault(r["encoder"], {"cases": 0, "applies": 0, "top5": 0, "unrouted": 0})
        e["cases"] += 1
        e["applies"] += r["settled"] == 1.0
        e["top5"] += r["rank"] is not None and r["rank"] <= 5
        e["unrouted"] += r["rank"] is None
    return dict(sorted(out.items()))


def report(root: Path, ts: TestSet, cov: dict[str, dict[str, tuple[int, int]]]) -> dict:
    """Recall against each case's labelled encoder; beside it, recall where routing to a rule the case
    itself named as missing (``needs: rule:E``, E now an encoder) also counts. Labels are not rewritten."""
    from .takhrij import ENCODERS as encoders
    data = json.loads((root / ts.situations).read_text(encoding="utf-8"))
    cases = ts.cases(root)
    typed = {a["answer"] for a in data["answers"]}
    lexical = ts.ranker(root)
    hits, named_hits, lex_hits, hyb_hits, applied, rows = (defaultdict(int), defaultdict(int), defaultdict(int),
                                                          defaultdict(int), 0, [])
    for unit, encoder, needs in cases:
        scores = shares(cov.get(unit, {}))
        words = lexical[unit]
        ranked = hybrid(scores, words)

        def rank_of(e: str) -> int | None:
            s = scores.get(e, 0.0)
            return sum(v >= s for v in scores.values()) if s > 0 else None
        rank, s = rank_of(encoder), scores.get(encoder, 0.0)
        named = sorted({n[5:] for n in needs if n.startswith("rule:") and n[5:] in encoders})
        best = min((r for r in [rank, *map(rank_of, named)] if r is not None), default=None)
        applied += s == 1.0
        for k in KS:
            hits[k] += rank is not None and rank <= k
            named_hits[k] += best is not None and best <= k
            lex_hits[k] += encoder in words[:k]
            hyb_hits[k] += encoder in ranked[:k]
        rows.append({"case": unit, "encoder": encoder, "settled": round(s, 4), "rank": rank,
                     **({"named_rules": named, "best_rank_with_named": best} if named else {})})
    n = len(cases)
    applying = [sum(k == m for k, m in cov.get(a, {}).values()) for a in sorted(typed)]
    touched = [len(cov.get(a, {})) for a in sorted(typed)]
    prior_order = [e for e, _ in sorted(Counter(e for _, e, _ in routing.cases(root / "corpus")).items(), key=lambda x: (-x[1], x[0]))]
    return {"schema_version": 1, "status": "candidate", "set": ts.name,
            "method": "blind typing into Usul.Typing situations; Prolog routing by coverage of each encoder's fields",
            "answers": len(typed), "situations": sum(len(a["situations"]) for a in data["answers"]),
            "fields_stated": sum(len(s["facts"]) for a in data["answers"] for s in a["situations"]),
            "cases": n, "encoders": len(encoders), "applies": round(applied / n, 4),
            "recall": {str(k): round(hits[k] / n, 4) for k in KS},
            "recall_with_named_rules": {str(k): round(named_hits[k] / n, 4) for k in KS},
            "lexical_recall": {str(k): round(lex_hits[k] / n, 4) for k in KS},
            "hybrid_recall": {str(k): round(hyb_hits[k] / n, 4) for k in KS},
            "hybrid": "types first: encoders by the share of their fields the situation settles, lexical rank breaking ties and ordering the rest",
            "prior_recall": {str(k): round(sum(e in prior_order[:k] for _, e, _ in cases) / n, 4) for k in KS},
            "encoders_applying_per_answer": round(sum(applying) / len(applying), 2),
            "encoders_touched_per_answer": round(sum(touched) / len(touched), 2),
            "by_encoder": by_encoder(rows), "cases_detail": rows}


PROPOSALS = (ProposalSet("r2_sample1", (("openiti-abudawud-masailahmad-shamela21487", 10),
                                        ("openiti-harb-masail-shamela12527", 10),
                                        ("openiti-kawsaj-masailahmad-shamela3125", 10),
                                        ("openiti-hajjawi-zadmustaqni-shamela11230", 5),
                                        ("openiti-ibnqudama-umda-shamela11315", 5))),)
PROPOSE = 5


def proposals(root: Path, ps: ProposalSet, cov: dict[str, dict[str, tuple[int, int]]]) -> dict:
    """Per unit, the hybrid's first ``PROPOSE`` encoders, ranking the record's text against the full
    index. A unit no situation of which settles a field gets the lexical order alone."""
    corpus = root / "corpus"
    data = json.loads((root / ps.situations).read_text(encoding="utf-8"))
    recs = routing._records(corpus, {a["answer"] for a in data["answers"]})
    model = routing.Model.fit(routing.evidence(corpus))
    rows = []
    for a in data["answers"]:
        c = cov.get(a["answer"], {})
        words = model.rank(routing._text(recs[a["answer"]]))
        rows.append({"unit": a["answer"], "situations": len(a["situations"]), "typed": bool(c),
                     "proposals": [{"encoder": e, "settled": list(c[e]) if e in c else None,
                                    "lexical_rank": words.index(e) + 1} for e in hybrid(shares(c), words)[:PROPOSE]]})
    return {"schema_version": 1, "status": "candidate", "set": ps.name,
            "method": "blind typing into Usul.Typing situations, Prolog coverage, then the hybrid: types first, "
                      "lexical rank breaking ties and ordering the rest; a proposal for lane B, not a ruling",
            "sample": {w: k for w, k in ps.plan}, "units": len(rows), "typed": sum(r["typed"] for r in rows),
            "encoders_proposed_by_type": len({p["encoder"] for r in rows for p in r["proposals"] if p["settled"]}),
            "units_detail": rows}


def present(root: Path, sets: tuple = SETS) -> list:
    """The sets whose blind-typed situations are committed."""
    return [ts for ts in sets if (root / ts.situations).exists()]
