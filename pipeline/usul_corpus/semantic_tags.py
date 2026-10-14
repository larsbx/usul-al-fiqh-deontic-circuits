"""Evidence-linked candidate tagging; surface cues never become bank facts.

Run ``python -m usul_corpus.semantic_tags ROOT OUTPUT [--check]``.
The published IslamQA tranche is development material, not a blind test.
"""
from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import re
from pathlib import Path

from . import routing, takhrij

ANSWERS_SHA256 = "621fcd30c854a45407a5c303de8656c402eab4c59abde884a06038348ffbb205"
ANSWERS_BYTES = 54803328

ROLES = ("act", "actor", "object", "affected_party", "condition", "exception",
         "negation", "omission", "time", "scope")
# Locate literal discourse markers in the ORIGINAL text; these do not resolve scope.
MARKERS = {
    "condition": r"إذا|اذا|إن كان|ان كان|بشرط",
    "exception": r"إلا|الا|ما عدا",
    "negation": r"لا|لم|لن|ليس",
    "omission": r"ترك|التفريط|التهاون",
    "time": r"قبل|بعد|حين|عندما",
}


def digest(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def span(source_id: str, text: str, start: int, end: int) -> dict:
    if type(start) is not int or type(end) is not int or not 0 <= start < end <= len(text):
        raise ValueError("Invalid Unicode character offsets")
    return {"source_id": source_id, "text_sha256": digest(text), "start": start,
            "end": end, "quote": text[start:end]}


def validate_span(evidence: dict, source_id: str, text: str) -> None:
    expected = span(source_id, text, evidence["start"], evidence["end"])
    if evidence != expected:
        raise ValueError("Evidence does not match the pinned source text")


def propose(source_id: str, text: str) -> dict:
    tags = []
    for role, pattern in MARKERS.items():
        for m in re.finditer(r"(?<!\w)(?:" + pattern + r")(?!\w)", text):
            tags.append({"role": role, "status": "candidate", "method": "literal_marker",
                         "evidence": span(source_id, text, m.start(), m.end()),
                         "scope": None, "meaning": None})
    return {"source_id": source_id, "text_sha256": digest(text), "text": text,
            "status": "candidate", "tags": sorted(tags, key=lambda t: (t["evidence"]["start"], t["role"])),
            "semantic_roles": {role: {"status": "unknown", "value": None} for role in ROLES},
            "encoder_facts": [], "kernel_output": None}


def admit(encoder: str, observations: list[dict], source_id: str, text: str) -> dict:
    """Execute the Python mirror only for a complete, explicitly reviewed fact map.

    Evidence integrity is checked here. Semantic entailment must be reviewed upstream;
    a valid quote alone cannot establish that its proposed fact value is true.
    This is not proof acceptance or a fatwa. No tagger calls this automatically.
    """
    schema = takhrij.ENCODERS[encoder]["facts"]
    facts, pending = {}, []
    seen = set()
    for observation in observations:
        key = observation["field"]
        if key not in schema or key in seen:
            raise ValueError("Unknown or duplicate fact field")
        seen.add(key)
        state = observation["status"]
        if state not in ("unknown", "candidate", "reviewed"):
            raise ValueError("Unknown observation status")
        if state == "unknown":
            if observation.get("value") is not None:
                raise ValueError("Unknown facts must not carry a value")
            pending.append(key)
            continue
        value = observation["value"]
        if not any(type(value) is type(v) and value == v for v in schema[key]):
            raise ValueError("Fact value outside the strict typed domain")
        evidence = observation["evidence"]
        validate_span(evidence, source_id, text)
        if state != "reviewed":
            pending.append(key)
            continue
        if not isinstance(observation.get("review_locator"), str) or not observation["review_locator"].strip():
            raise ValueError("Reviewed fact requires a review evidence locator")
        facts[key] = value
    missing = sorted(set(schema) - set(facts))
    if missing:
        return {"status": "hold", "missing_facts": missing, "pending_review": sorted(pending),
                "output": None}
    return {"status": "candidate_kernel_result", "missing_facts": [], "pending_review": [],
            "output": takhrij.ENCODERS[encoder]["py"](facts),
            "lean_expression": takhrij.lean_expr(encoder, facts)}


def build(root: Path) -> dict:
    tranche = json.loads((root / routing.TRANCHE).read_text())["cases"]
    need = {c["far"].rsplit(".", 1)[0] for c in tranche}
    archive = root / routing.ANSWERS
    with archive.open("rb") as fh:
        archive_digest = hashlib.file_digest(fh, "sha256").hexdigest()
    if archive.stat().st_size != ANSWERS_BYTES or archive_digest != ANSWERS_SHA256:
        raise ValueError("Original Arabic archive is not the pinned witness")
    with gzip.open(archive, "rt", encoding="utf-8") as fh:
        selected = [r for r in map(json.loads, fh) if r["id"] in need]
    questions = {r["id"]: f"{r['title']} {r['question']}" for r in selected}
    if set(questions) != need or len(selected) != len(questions):
        raise ValueError("Missing or duplicate development questions")
    records = [propose(rid, text) for rid, text in sorted(questions.items())]
    return {"schema_version": 1, "status": "candidate", "purpose": "semantic annotation development scaffold",
            "source_sha256": ANSWERS_SHA256,
            "offset_unit": "Unicode code points in exact title-space-question text",
            "records": records,
            "development_references": [{"case_id": c["far"], "question_id": c["far"].rsplit(".", 1)[0],
                                        "existing_candidate_encoder": c["encoder"]} for c in tranche],
            "evaluation": {"questions": len(records), "existing_cases": len(tranche),
                           "literal_marker_candidates": sum(len(r["tags"]) for r in records),
                           "semantic_tag_accuracy": None, "fact_accuracy": None,
                           "encoder_accuracy": None, "new_kernel_executions": 0},
            "limitations": ["Literal markers are annotation aids, not semantic extraction",
                            "No facts inferred; all semantic roles remain unknown",
                            "Existing case encoders are separate development references, never tagger inputs",
                            "Published cases are not a blind test; no retrieval improvement measured",
                            "Reviewed observation status is caller-attested; a locator is not authentication"]}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    text = json.dumps(build(args.root), ensure_ascii=False, indent=2) + "\n"
    if args.check:
        if args.output.read_text() != text:
            raise SystemExit("semantic-tag artifact is stale")
    else:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text, encoding="utf-8")


if __name__ == "__main__":
    main()
