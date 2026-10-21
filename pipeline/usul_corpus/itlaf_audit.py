"""Replay the source-receipted, UNBLINDED itlaf audit without editing blind inputs.

Run from pipeline: python -m usul_corpus.itlaf_audit [--check].
The correction manifest is candidate editorial evidence, never router training data.
"""
from __future__ import annotations

import argparse
import copy
import gzip
import hashlib
import json
import tempfile
from collections import Counter
from pathlib import Path

from . import routing, typed_routing as tr
from .signature_routing import ANSWERS_SHA256

MANIFEST = "corpus/typing/islamqa_itlaf_corrections.json"
REPORT = "corpus/typing/islamqa_itlaf_audit.json"


def load_sources(root: Path, ids: set[str]) -> dict[str, dict]:
    archive = root / routing.ANSWERS
    with archive.open("rb") as fh:
        if hashlib.file_digest(fh, "sha256").hexdigest() != ANSWERS_SHA256:
            raise ValueError("IslamQA archive does not match the canonical pin")
    with gzip.open(archive, "rt", encoding="utf-8") as fh:
        sources = {r["id"]: r for r in map(json.loads, fh) if r["id"] in ids}
    if set(sources) != ids:
        raise ValueError("Missing canonical source records")
    return sources


def corrected(data: dict, manifest: dict, sources: dict[str, dict]) -> dict:
    """Withdraw only the exact receipted assignment; fail closed on stale input."""
    out = copy.deepcopy(data)
    answers = {a["answer"]: a for a in out["answers"]}
    seen = set()
    for e in manifest["corrections"]:
        key = e["answer"], e["situation"], e["field"]
        if key in seen or e["action"] != "withdraw" or e["situation"] < 1:
            raise ValueError(f"Invalid or duplicate withdrawal: {key}")
        seen.add(key)
        s = answers[e["answer"]]["situations"][e["situation"] - 1]
        field = e["field"]
        source = sources[e["answer"]]
        if (field not in s["facts"] or s["facts"][field] != e["old_value"]
                or s["evidence"].get(field) != e["evidence"]
                or not 0 < len(e["evidence"]) <= 160
                or e["evidence"] not in source["question"] + "\n" + source["answer"]):
            raise ValueError(f"Stale or unsupported withdrawal: {key}")
        del s["facts"][field]
        del s["evidence"][field]
    out["provenance"] = manifest["evaluation_status"] + "; " + manifest["method"]
    return out


def build(root: Path) -> dict:
    ts = tr.by_name("islamqa_tranche1")
    data = json.loads((root / ts.situations).read_text(encoding="utf-8"))
    manifest = json.loads((root / MANIFEST).read_text(encoding="utf-8"))
    source_cases = json.loads((root / routing.TRANCHE).read_text(encoding="utf-8"))["cases"]
    itlaf = {c["far"]: c for c in source_cases if c["encoder"] == "itlaf"}
    decisions = {c["case_id"]: c for c in manifest["cases"]}
    if len(decisions) != len(manifest["cases"]) or set(decisions) != set(itlaf):
        raise ValueError("Audit must cover every itlaf case exactly once")
    sources = load_sources(root, {c["far"].rsplit(".", 1)[0] for c in itlaf.values()})
    revised = corrected(data, manifest, sources)
    before_cov = tr.coverage(root, ts)
    before = tr.report(root, ts, before_cov)
    with tempfile.TemporaryDirectory(prefix="itlaf-audit-") as temp:
        prolog = Path(temp) / "situations.pl"
        prolog.write_text(tr.prolog_file(ts, revised), encoding="utf-8")
        after_cov = tr.coverage(root, ts, prolog=prolog)
        after = tr.report(root, ts, after_cov, data=revised)
    old = {r["case_id"]: r for r in before["cases_detail"]}
    new = {r["case_id"]: r for r in after["cases_detail"]}
    revised_answers = {a["answer"]: a for a in revised["answers"]}
    rows = []
    for cid, c in itlaf.items():
        unit = cid.rsplit(".", 1)[0]
        record = sources[unit]
        decision = decisions[cid]
        quote = decision["source_excerpt"]
        if not 0 < len(quote) <= 160 or quote not in record["answer"]:
            raise ValueError(f"Source receipt does not replay: {cid}")
        if decision["remaining_need"] != c["needs"]:
            raise ValueError(f"Stale case need: {cid}")
        rows.append({**decision, "unit": unit, "source_url": f"https://islamqa.info/ar/answers/{unit.split('.')[1]}",
                     "source_sha256": hashlib.sha256(json.dumps(record, ensure_ascii=False, sort_keys=True).encode()).hexdigest(),
                     "baseline_unrouted": old[cid]["rank"] is None,
                     "annotation_class": c["class"],
                     "before": old[cid], "after": new[cid],
                     "itlaf_missing_stated_fields_by_situation": [[f for f in ("purpose", "mental") if f not in s["facts"]]
                         for s in revised_answers[unit]["situations"]],
                     "correction_indices": [i for i, e in enumerate(manifest["corrections"]) if e["answer"] == unit]})
    families = sorted({r["encoder"] for r in before["cases_detail"]})
    family_metrics = {e: {"before": tr.summarize_ranks([r for r in before["cases_detail"] if r["encoder"] == e]),
                          "after": tr.summarize_ranks([r for r in after["cases_detail"] if r["encoder"] == e])}
                      for e in families}
    metrics = ("applies", "recall", "recall_with_named_rules", "lexical_recall",
               "hybrid_recall", "hybrid_recall_by_qaida", "by_encoder", "by_annotation_class")
    changed = [{"case_id": cid, "encoder": old[cid]["encoder"],
                "before": old[cid], "after": new[cid]}
               for cid in old if old[cid] != new[cid]]
    inputs = [MANIFEST, ts.situations, ts.prolog, routing.TRANCHE, tr.TYPING, "examples/v41_types.pl",
              *manifest["scope_authority"]]
    return {"schema_version": 1, "status": "candidate", "human_reviewed": False,
            "evaluation_status": manifest["evaluation_status"],
            "baseline_commit": manifest["baseline_commit"],
            "source_archive_sha256": ANSWERS_SHA256,
            "input_sha256": {p: hashlib.sha256((root / p).read_bytes()).hexdigest() for p in inputs},
            "limits": ["The original blind benchmark, labels, needs, bindings and ranker are unchanged.",
                       "Corrections were selected after inspecting failures: after is an unblinded development diagnostic.",
                       "Legacy metrics score gap labels too; no itlaf case here is a successful encoder application.",
                       "Type coverage and qawāʿida retrieval are not correctness of a ruling.",
                       "The 25 null ranks are type-only ranks. Hybrid always has a separate rank.",
                       "No new human review or independently measured accuracy gain is asserted."],
            "counts": {"itlaf_cases": len(rows), "itlaf_answers": len(sources),
                       "baseline_unrouted_cases": sum(r["baseline_unrouted"] for r in rows),
                       "primary_diagnoses_unrouted": dict(Counter(r["primary"] for r in rows if r["baseline_unrouted"])),
                       "withdrawals": len(manifest["corrections"])},
            "before": {k: before[k] for k in metrics}, "after": {k: after[k] for k in metrics},
            "by_encoder": family_metrics, "changed_cases_all_families": changed, "cases": rows}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    content = json.dumps(build(root), ensure_ascii=False, indent=2) + "\n"
    path = root / REPORT
    if args.check:
        if not path.exists() or path.read_text(encoding="utf-8") != content:
            raise SystemExit("itlaf audit stale: run python -m usul_corpus.itlaf_audit")
    else:
        path.write_text(content, encoding="utf-8")
    print("itlaf candidate audit current")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
