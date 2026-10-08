"""Source receipts for additive opening-example segmentation; no fiqh annotations."""

from __future__ import annotations

import hashlib
import json
import re
from collections import Counter

from .fetch import witness_url
from .records import qaida_records, unit_tags
from .segment import Unit

FORMAT = "opening-furu/v1"
_RECOVERED = re.compile(r"\.f000(?:_(?:[2-9]|[1-9][0-9]+))?$")


def is_recovered(record: dict) -> bool:
    return record["record_type"] == "far" and bool(_RECOVERED.search(record["id"]))


def legacy_commitment(records: list[dict]) -> dict:
    """All prior fields are immutable except the parent's corrected furu_count."""
    legacy = [{k: v for k, v in r.items() if k != "furu_count" or r["record_type"] != "qaida"}
              for r in records if not is_recovered(r)]
    payload = json.dumps(legacy, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()
    return {"records": len(legacy),
            "far_records": sum(r["record_type"] == "far" for r in legacy),
            "records_except_furu_count_sha256": hashlib.sha256(payload).hexdigest()}


def validate_receipt(saved: dict, records: list[dict], lock: dict) -> None:
    """Offline gate: no fabricated exemptions, drifted legacy data, or promotions."""
    if saved.get("format") != FORMAT or saved.get("status") != "candidate":
        raise ValueError("unsupported opening receipt or non-candidate status")
    if saved["source"]["sha256"] != lock["sha256"] or saved["source"]["bytes"] != lock["bytes"]:
        raise ValueError("opening receipt does not match the locked source")
    if legacy_commitment(records) != saved["legacy"]:
        raise ValueError("legacy record commitment drifted")
    recovered = [r for r in records if is_recovered(r)]
    if recovered != saved["records"] or any(r["status"] != "candidate" for r in recovered):
        raise ValueError("opening receipt records drifted or were promoted")
    if saved["summary"]["recovered"] != len(recovered):
        raise ValueError("opening receipt count drifted")


def receipt(work: dict, witness: dict, source: bytes, units: tuple[Unit, ...],
            baseline: dict) -> dict:
    records = [r for tag, unit in zip(unit_tags(units), units)
               for r in qaida_records(work, witness["id"], "headed", tag, unit)]
    if legacy_commitment(records) != baseline:
        raise ValueError("opening recovery changed a legacy record (apart from furu_count)")
    recovered = [r for r in records if is_recovered(r)]
    by_method = Counter(r["extraction"]["method"].split("+", 1)[1] for r in recovered)
    return {
        "format": FORMAT,
        "status": "candidate",
        "source": {"witness": witness["id"], "url": witness_url(witness),
                   "bytes": len(source), "sha256": hashlib.sha256(source).hexdigest()},
        "span_basis": "Unicode code-point offsets, end exclusive, in the full headed unit body: "
                      "OpenITI parse_markdown section texts joined by newline, as in segment_headed. "
                      "Hash UTF-8 bytes. Locators retain the parent qāʿida's page anchor.",
        "legacy": baseline,
        "summary": {"recovered": len(recovered),
                    "qawaid": len({r["qaida"] for r in recovered}),
                    "by_method": dict(sorted(by_method.items())),
                    "legacy_far": baseline["far_records"],
                    "revised_far": baseline["far_records"] + len(recovered)},
        "records": recovered,
        "review": "Source segmentation candidates only. No encoder facts, positions, rulings, "
                  "or review approvals are inferred. Review.tla still governs promotion; "
                  "unannotated recovered records remain in the coverage denominator.",
        "boundary": "This is a conservative structural profile, not an exhaustive semantic "
                    "case census. Bare pronouns, generic comparisons and ruling alternatives "
                    "are not example introducers. Other unlabeled cases still require source review.",
    }
