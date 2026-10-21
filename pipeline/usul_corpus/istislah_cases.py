"""M14's five selected al-Mustaṣfā examples: fail-closed source replay and candidates.

Run ``python -m usul_corpus.istislah_cases [--write]`` before ``takhrij``.
This does not register a whole-book segmenter, choose a stance, or confer review.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path

from . import deduction, fetch, source_verify, takhrij

WITNESS = "openiti-mustasfa-shamela5459"
RECEIPT = Path(f"segmentation/{WITNESS}-istislah.json")
RECORDS = Path(f"records/{WITNESS}.jsonl")
CASES = Path("takhrij/istislah_furu.json")
REPORT = Path("typing/istislah-cases.json")


def digest(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def plain(text: str) -> str:
    """Remove only OpenITI layout markers, joining line wraps with spaces."""
    return " ".join(re.sub(r"PageV\d+P\d+|ms\d+|(?m:^[#~]+)", "", text).split())


def page_at(text: str, offset: int) -> int:
    match = re.search(r"PageV01P(\d+)", text[offset:])
    if not match:
        raise ValueError("source span lacks its closing volume-1 page marker")
    return int(match[1])


def replay(receipt: dict, text: str, lock: dict, url: str) -> list[dict]:
    """Byte pin, exact spans, closing-page locations and quotation qualifiers all checked."""
    if (receipt["format"] != "istislah-cases/v1" or receipt["status"] != "candidate"
            or receipt["source"] != lock or lock["url"] != url
            or lock["bytes"] != len(text.encode("utf-8")) or lock["sha256"] != digest(text)):
        raise ValueError("istiṣlāḥ witness does not match registered URL and source lock")
    out, ids, spans = [], set(), []
    for i, row in enumerate(receipt["cases"], 1):
        span = row["source_span"]
        a, b = span["start"], span["end"]
        if type(a) is not int or type(b) is not int or not 0 <= a < b <= len(text):
            raise ValueError("invalid source span")
        raw = text[a:b]
        if span["sha256"] != digest(raw) or span["page_span"] != [page_at(text, a), page_at(text, b - 1)]:
            raise ValueError("source span hash or page mismatch")
        if any(a < end and start < b for start, end in spans):
            raise ValueError("overlapping source cases")
        spans.append((a, b))
        if row["id"] in ids or row["id"] != f"ghazali.mustasfa.{WITNESS.replace('-', '_')}.m{i:05d}":
            raise ValueError("duplicate or unstable editorial case id")
        ids.add(row["id"])
        if row["interpretation"]["status"] != "candidate" or row["review"] != {"status": "pending", "conclusion": None}:
            raise ValueError("source replay cannot promote a candidate")
        for ev in row["evidence"]:
            ref = source_verify.REF.fullmatch(ev["ref"])
            if not ref or ref[1] != WITNESS:
                raise ValueError("evidence must name the pinned witness and precise page")
            if error := source_verify.check_quote(text, ev["excerpt_ar"], ref[2]):
                raise ValueError(f"{row['label']}: {error}")
        body = plain(raw)
        out.append({"id": row["id"], "work": "ghazali.mustasfa", "witness": WITNESS,
                    "record_type": "masala", "locator": f"src:{WITNESS}/v01:p{span['page_span'][0]:03d}#m{i:05d}",
                    "heading_ar": row["heading_ar"], "excerpt_ar": body[:400], "sha256": digest(body),
                    "page_span": span["page_span"], "status": "candidate",
                    "extraction": {"pipeline": "usul_corpus/istislah-cases-v1", "method": "selected_source_spans",
                                   "receipt": str(RECEIPT), "source_span": span}})
    return out


def annotations(receipt: dict) -> dict:
    enc = takhrij.ENCODERS["istislah"]
    cases = []
    for row in receipt["cases"]:
        interpretation = row["interpretation"]
        if interpretation["encoder"] != "istislah" or "istislah_stance" in interpretation["facts"]:
            raise ValueError("the author stance is a scope, not a scenario fact")
        facts = {**interpretation["facts"], "istislah_stance": "mustasfa"}
        quantified = [k for k in enc["facts"] if k not in facts]
        case = {"far": row["id"], "encoder": "istislah", "class": "derivable", "facts": facts,
                "expected": interpretation["expected_under_mustasfa"], "routing_label": False,
                "quote": row["evidence"][0]["excerpt_ar"],
                "note": "Candidate source-author reading only, not a reviewed ruling or normative stance selection. "
                        + row["stated_scenario"] + " " + " ".join(row["uncertainty"])
                        + f" Source receipt: corpus/{RECEIPT} ({row['label']}); existing theorem: {interpretation['theorem']}."}
        if quantified:
            case["quantified_facts"] = quantified
        if errors := takhrij.check_case(case):
            raise ValueError(f"{row['label']}: {errors}")
        cases.append(case)
    return {"suite": "istislah", "status": "candidate",
            "provenance": "Five selected al-Ghazālī examples, replayed from the pinned al-Mustaṣfā v01 p174–177. "
                          "Derivable means the conditional mustasfa reading agrees with the annotated conclusion. "
                          "Unsettled fields are universally quantified, never filled as facts. rawda/mustasfa/malik "
                          "remain unresolved; corpus/typing/istislah-cases.json compares all three. Review pending. "
                          "Scoped component checks are excluded from whole-unit routing labels.", "cases": cases}


def coverage(receipt: dict, cases: list[dict], export: str) -> dict:
    read = deduction.reads(export)["istislah"]
    names = deduction.names("istislah")
    rows = []
    for row, case in zip(receipt["cases"], cases):
        reached = {}
        for stance in takhrij.ENCODERS["istislah"]["facts"]["istislah_stance"]:
            facts = {**case["facts"], "istislah_stance": stance}
            settled = {f: facts[n] for f, n in zip(read, names) if n in facts}
            reached[stance] = sorted(deduction.reach("istislah", settled, read))
        rows.append({"far": case["far"], "label": row["label"], "sort": "epistemic",
                     "author_stance": "mustasfa", "stated_fields": list(row["interpretation"]["facts"]),
                     "quantified_fields": case.get("quantified_facts", []),
                     "author_completions": len(takhrij.case_completions(case)),
                     "reachable_by_stance": reached, "review_status": "pending"})
    return {"status": "candidate", "source_cases": len(cases), "reviewed_cases": 0,
            "scope": "Reachability of the hujja question under three existing modeled stances, not historical "
                     "attributions of every concrete ruling. malik means Mālik as the Rawḍa reports him. "
                     "A two-valued set records unresolved attributes; no default fills them.",
            "author_completion_checks": sum(r["author_completions"] for r in rows), "cases": rows}


def artifacts(root: Path) -> dict[Path, str]:
    corpus = root / "corpus"
    receipt = json.loads((corpus / RECEIPT).read_text())
    lock = json.loads((corpus / "lock.json").read_text())["witnesses"][WITNESS]
    witness = next(w for work in json.loads((corpus / "registry.json").read_text())["works"]
                   for w in work["witnesses"] if w["id"] == WITNESS)
    # Same locked restore as the corpus gate: missing bytes fail, never skip or re-pin.
    text = source_verify.locked_text(WITNESS, witness, lock, corpus, root / ".cache/corpus", False)
    records = replay(receipt, text, lock, fetch.witness_url(witness))
    suite = annotations(receipt)
    report = coverage(receipt, suite["cases"], (root / "examples/v41_types.pl").read_text())
    dump = lambda obj: json.dumps(obj, ensure_ascii=False, indent=2) + "\n"
    return {corpus / RECORDS: "".join(json.dumps(r, ensure_ascii=False) + "\n" for r in records),
            corpus / CASES: dump(suite), corpus / REPORT: dump(report)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    outputs = artifacts(root)
    if args.write:
        for path, body in outputs.items():
            path.write_text(body, encoding="utf-8")
    elif stale := [str(p.relative_to(root)) for p, body in outputs.items() if not p.exists() or p.read_text() != body]:
        raise SystemExit("stale istiṣlāḥ artifacts: " + ", ".join(stale))
    report = json.loads(outputs[root / "corpus" / REPORT])
    print(f"ok: {report['source_cases']} source cases; {report['author_completion_checks']} author completions; "
          f"all three stances retained; {report['reviewed_cases']} reviewed conclusions")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
