"""Deterministic Ibn Rajab M8 inventory from committed records and annotations.

The unit is an existing far record, not an inferred count of distinct legal examples.
No segmented far record is different from no example in the full source. The latter
requires source review and is never inferred here from furu_count == 0.
"""

from __future__ import annotations

import hashlib
import json
from collections import Counter, defaultdict
from pathlib import Path

from . import takhrij
from .fetch import witness_url

WORK = "ibn_rajab.taqrir_qawaid"
WITNESS = "openiti-rajab-shamela21730"
RECORDS = f"records/{WITNESS}.jsonl"
OUTPUT = "worklists/rajab_m8.json"
SCOPE_DOCS = ("docs/architecture/takhrij.md", "docs/roadmap-hanbali-usul-formalization.md")
BEGIN = "<!-- BEGIN GENERATED M8 SCOPE -->"
END = "<!-- END GENERATED M8 SCOPE -->"


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def reconcile(records: list[dict], cases: list[dict]) -> tuple[list[dict], dict]:
    """Check the parent/child counts and partition IDs independently of estimates."""
    ids = [r["id"] for r in records]
    if len(ids) != len(set(ids)):
        raise ValueError("duplicate corpus record id")
    case_ids = [c["far"] for c in cases]
    if len(case_ids) != len(set(case_ids)):
        raise ValueError("duplicate annotation id")
    parents = {r["id"]: r for r in records if r["record_type"] == "qaida"}
    children = defaultdict(list)
    for r in records:
        if r["record_type"] == "far":
            if r["qaida"] not in parents:
                raise ValueError(f"orphan far record: {r['id']}")
            children[r["qaida"]].append(r["id"])
    source_ids = {i for group in children.values() for i in group}
    prefix = f"{WORK}.{WITNESS.replace('-', '_')}."
    annotated = {i for i in case_ids if i.startswith(prefix)}
    if annotated - source_ids:
        raise ValueError("annotation id absent from pinned Ibn Rajab records")
    rows = []
    for q in sorted(parents.values(), key=lambda r: (r["number"], r["id"])):
        fars = sorted(children[q["id"]])
        if len(fars) != q["furu_count"]:
            raise ValueError(f"furu_count disagrees with children: {q['id']}")
        pending = sorted(set(fars) - annotated)
        state = "needs_source_segmentation" if not fars else "awaiting_annotation" if pending else "annotated"
        rows.append({"qaida": q["id"], "number": q["number"], "locator": q["locator"],
                     "state": state, "segmented_furu": len(fars),
                     "annotated_furu": len(fars) - len(pending), "pending_furu": pending,
                     "home_encoders": sorted(n for n, e in takhrij.ENCODERS.items() if q["id"] in e["qawaid"])})
    states = Counter(r["state"] for r in rows)
    summary = {"qawaid": len(rows), "qawaid_with_segmented_furu": sum(bool(r["segmented_furu"]) for r in rows),
               "qawaid_needing_source_segmentation": states["needs_source_segmentation"],
               "qawaid_annotated": states["annotated"], "qawaid_awaiting_annotation": states["awaiting_annotation"],
               "segmented_furu": len(source_ids), "annotated_furu": len(annotated),
               "pending_furu": len(source_ids - annotated)}
    return rows, summary


def build(corpus: Path) -> dict:
    registry = json.loads((corpus / "registry.json").read_text(encoding="utf-8"))
    work = next(w for w in registry["works"] if w["id"] == WORK)
    witness = next(w for w in work["witnesses"] if w["id"] == WITNESS)
    lock = json.loads((corpus / "lock.json").read_text(encoding="utf-8"))["witnesses"][WITNESS]
    if lock["url"] != witness_url(witness):
        raise ValueError("source lock URL differs from registered witness")
    raw = (corpus / RECORDS).read_bytes()
    records = [json.loads(line) for line in raw.decode("utf-8").splitlines()]
    if any(r["work"] != WORK or r["witness"] != WITNESS for r in records):
        raise ValueError("mixed witness in Ibn Rajab records")
    cases = takhrij.load(corpus)
    rows, summary = reconcile(records, cases)
    files = sorted(p for p in (corpus / "takhrij").glob("*.json") if p.name != "report.json")
    inputs = [corpus / "registry.json", corpus / "lock.json", corpus / RECORDS, *files]
    suites = {}
    for p in files:
        data = json.loads(p.read_text(encoding="utf-8"))
        subset = [c for c in data["cases"] if c["far"].startswith(f"{WORK}.")]
        if subset:
            suites[data["suite"]] = {"annotated_furu": len(subset),
                                    "qawaid": sorted({int(c["far"].rsplit(".", 2)[1][1:]) for c in subset})}
    aggregate = takhrij.report(cases)
    tranche3 = next(json.loads(p.read_text(encoding="utf-8"))["cases"] for p in files
                    if p.name == "rajab_m8_tranche3_furu.json")
    return {"schema_version": 1, "status": "candidate",
            "unit": "committed far record; a record may contain more than one example",
            "scope": "Only this registered Ibn Rajab witness; no Ibn al-Lahham or inferred missing examples",
            "source": {"witness": WITNESS, "url": lock["url"], "commit": witness["commit"],
                       "sha256": lock["sha256"], "bytes": lock["bytes"]},
            "input_sha256": {str(p.relative_to(corpus)): sha256(p.read_bytes()) for p in inputs},
            "summary": summary, "suites": suites,
            "aggregate_report": {k: aggregate[k] for k in (
                "total", "classes", "coverage", "madhhab_coverage", "encoding_error",
                "ikhtilaf_matching_madhhab", "gaps_open", "revisited")},
            "tranche3_report": takhrij.report(tranche3),
            "unsegmented_scope": "No segmented far is an extraction backlog, not proof of no examples; no case count is imputed",
            "annotation_scope": "Annotated includes recorded gaps and disagreements; all readings remain candidate, not adopted",
            "qawaid": rows}


def render(corpus: Path) -> str:
    return json.dumps(build(corpus), ensure_ascii=False, indent=2) + "\n"


def scope_block(inventory: dict) -> str:
    s = inventory["summary"]
    def row(label: str, report: dict) -> str:
        return (f"| {label} | {report['total']} | {report['coverage']:.3f} | "
                f"{report['madhhab_coverage']:.3f} | {report['encoding_error']} | {report['gaps_open']} |\n")
    return (f"{BEGIN}\n"
            f"**Current M8 inventory (generated).** {s['segmented_furu']:,} segmented Ibn Rajab furūʿ records = "
            f"{s['annotated_furu']:,} annotated + **{s['pending_furu']:,} awaiting annotation**. "
            f"Of {s['qawaid']} qawāʿid, {s['qawaid_with_segmented_furu']} have segmented records: "
            f"{s['qawaid_annotated']} are fully annotated and **{s['qawaid_awaiting_annotation']} await annotation**. "
            f"The other **{s['qawaid_needing_source_segmentation']} need source segmentation review**; "
            "zero emitted records does not establish zero examples in the text.\n\n"
            "The unit is a committed farʿ record, which can contain multiple examples. Annotated gaps and "
            "disagreements are already counted as annotated; annotation does not mean independently reviewed or "
            "scholarly accepted. No count is imputed for unsegmented examples. The exact ID worklist and input "
            "hashes are in `corpus/worklists/rajab_m8.json`; rebuild with `python -m usul_corpus m8-worklist`.\n\n"
            "| Current scope (generated) | Cases | Coverage | Madhhab coverage | Encoding errors | Open gaps |\n"
            "|---|---|---|---|---|---|\n"
            + row("Combined M8 tranche 3", inventory["tranche3_report"])
            + row("All annotation suites", inventory["aggregate_report"])
            + "\nCoverage counts derivability under the candidate encoding. Madhhab coverage uses candidate "
            "source attributions; neither metric establishes scholarly acceptance.\n"
            f"{END}")


def scoped_documents(root: Path, inventory: dict) -> dict[Path, str]:
    block = scope_block(inventory)
    result = {}
    for relative in SCOPE_DOCS:
        path = root / relative
        old = path.read_text(encoding="utf-8")
        if old.count(BEGIN) != 1 or old.count(END) != 1 or old.index(BEGIN) > old.index(END):
            raise ValueError(f"missing or repeated M8 scope markers: {relative}")
        result[path] = old[:old.index(BEGIN)] + block + old[old.index(END) + len(END):]
    return result
