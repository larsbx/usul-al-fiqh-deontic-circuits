"""Validate authored candidate propositions against pinned question-body spans.

This validates structure and source integrity, not the truth of interpretations.
Run: python -m usul_corpus.semantic_propositions ROOT [--check]
"""
from __future__ import annotations

import argparse
import hashlib
import json
from collections import Counter
from pathlib import Path

from . import semantic_tags as tags, takhrij

ANNOTATIONS = "corpus/fatawa/semantic-propositions-development.json"
REPORT = "corpus/fatawa/semantic-propositions-report.json"
ROLES = ("actor", "act", "object", "affected_party", "condition", "time")
MODALITIES = {"asserted", "hypothetical", "questioned", "uncertain"}


def validate_record(record: dict, sources: dict[str, dict]) -> dict:
    """One act per proposition; candidates cannot promote themselves to reviewed."""
    rid = record["source_id"]
    source = sources[rid]
    text, body_start = source["text"], source["body_start"]
    if record["status"] != "candidate" or record["text_sha256"] != tags.digest(text):
        raise ValueError("Candidate status or text pin mismatch")

    def evidence(ev):
        tags.validate_span(ev, rid, text)
        if ev["start"] < body_start:
            raise ValueError("Editorial title cannot supply question-body facts")

    propositions = {}
    for p in record["propositions"]:
        pid = p["id"]
        if not isinstance(pid, str) or not pid or pid in propositions:
            raise ValueError("Missing or duplicate proposition ID")
        if p["status"] != "candidate" or p["modality"] not in MODALITIES:
            raise ValueError("Invalid proposition state")
        if p["polarity"] not in ("positive", "negative", "unknown"):
            raise ValueError("Invalid polarity")
        evidence(p["scope"])
        if set(p["roles"]) != set(ROLES):
            raise ValueError("Incomplete role schema")
        for role in p["roles"].values():
            if role["status"] == "unknown":
                if role["value"] is not None or role["evidence"]:
                    raise ValueError("Unknown role carries unsupported content")
            elif role["status"] == "candidate":
                if not isinstance(role["value"], str) or not role["value"].strip() or not role["evidence"]:
                    raise ValueError("Candidate role requires meaning and evidence")
                for ev in role["evidence"]:
                    evidence(ev)
                    if not p["scope"]["start"] <= ev["start"] < ev["end"] <= p["scope"]["end"]:
                        raise ValueError("Role evidence crosses proposition scope")
            else:
                raise ValueError("Roles must remain candidate or unknown")
        if p["roles"]["act"]["status"] != "candidate":
            raise ValueError("Proposition needs an evidenced act")
        propositions[pid] = p

    mappings, seen = [], set()
    for mapping in record["bank_mappings"]:
        pid, encoder = mapping["proposition_id"], mapping["encoder"]
        if (pid, encoder) in seen or pid not in propositions:
            raise ValueError("Unknown or duplicate mapping target")
        seen.add((pid, encoder))
        p = propositions[pid]
        schema = takhrij.ENCODERS[encoder]["facts"]
        if set(mapping["facts"]) != set(schema):
            raise ValueError("Mapping must name every required field, including unknowns")
        observations = []
        for field, fact in mapping["facts"].items():
            if fact["proposition_id"] != pid:
                raise ValueError("Cannot pool facts from different propositions")
            if fact["status"] not in ("candidate", "unknown"):
                raise ValueError("Development facts cannot assert review")
            if fact["status"] == "unknown":
                if fact["value"] is not None or fact["evidence"] is not None:
                    raise ValueError("Unknown fact carries unsupported content")
            else:
                if p["modality"] != "asserted" or p["polarity"] != "positive":
                    raise ValueError("Non-asserted propositions cannot supply factual bindings")
                evidence(fact["evidence"])
                ev = fact["evidence"]
                if not p["scope"]["start"] <= ev["start"] < ev["end"] <= p["scope"]["end"]:
                    raise ValueError("Fact evidence crosses proposition scope")
                if not isinstance(fact["rationale"], str) or not fact["rationale"].strip():
                    raise ValueError("Candidate mapping needs an entailment rationale")
            observations.append({"field": field, **fact})
        result = tags.admit(encoder, observations, rid, text)
        if result["status"] != "hold":
            raise ValueError("Development mapping unexpectedly executed a kernel")
        mappings.append({"proposition_id": pid, "encoder": encoder, **result})
    return {"source_id": rid, "propositions": len(propositions), "mappings": mappings}


def evaluate(root: Path) -> dict:
    path = root / ANNOTATIONS
    data = json.loads(path.read_text())
    if data["status"] != "candidate" or data["source_sha256"] != tags.ANSWERS_SHA256:
        raise ValueError("Annotation provenance mismatch")
    sources = tags.question_sources(root)
    records = data["records"]
    if len({r["source_id"] for r in records}) != len(records):
        raise ValueError("Duplicate annotation source")
    results = [validate_record(r, sources) for r in records]
    props = [p for r in records for p in r["propositions"]]
    return {"status": "candidate", "source_sha256": tags.ANSWERS_SHA256,
            "annotations_sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "annotated_questions": len(records), "available_questions": len(sources),
            "propositions": len(props), "modalities": dict(sorted(Counter(p["modality"] for p in props).items())),
            "candidate_roles": sum(v["status"] == "candidate" for p in props for v in p["roles"].values()),
            "candidate_fact_bindings": sum(f["status"] == "candidate" for r in records for m in r["bank_mappings"] for f in m["facts"].values()),
            "new_kernel_executions": 0, "semantic_accuracy": None, "retrieval_improvement": None,
            "records": results,
            "limitations": ["LLM-authored purposive development annotations, not independent gold",
                            "Only source integrity, structure and conservative admission are validated",
                            "Interpretations and proposed field entailments remain unreviewed",
                            "Editorial titles excluded from factual evidence; answers unused"]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", type=Path)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    rendered = json.dumps(evaluate(args.root), ensure_ascii=False, indent=2) + "\n"
    output = args.root / REPORT
    if args.check:
        if output.read_text() != rendered:
            raise SystemExit("semantic proposition report is stale")
    else:
        output.write_text(rendered, encoding="utf-8")


if __name__ == "__main__":
    main()
