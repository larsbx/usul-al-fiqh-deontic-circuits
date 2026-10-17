"""Versioned receipts for the subjects of legacy positional evidence references.

A receipt freezes the ordered reported positions, including their holder and
interpretation metadata, within one case. It does not attest scholarly truth.
Changing position order or content requires explicit evidence revalidation.
"""
from hashlib import sha256

from .values import code

FIELD = "positions_sha256"


def digest(case: dict) -> str:
    payload = {"schema": "usul.positions.v1", "far": case["far"],
               "positions": case["positions"]}
    return sha256(code(payload).encode("utf-8")).hexdigest()


def errors(case: dict, entry: dict) -> list[str]:
    if entry.get("far") != case.get("far"):
        return ["positions receipt belongs to a different case"]
    receipt = entry.get(FIELD)
    if not isinstance(receipt, str) or len(receipt) != 64 or any(c not in "0123456789abcdef" for c in receipt):
        return ["positions receipt missing or malformed; revalidate evidence associations"]
    if receipt != digest(case):
        return ["positions receipt mismatch; revalidate evidence associations before re-pinning"]
    return []
