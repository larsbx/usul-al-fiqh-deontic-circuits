"""Shared JSON identity for encoded facts and rulings; no corpus or kernel dependencies.

This is representation identity within a declared encoder, not scholarly equivalence
between interpretations. Public compatibility imports remain in takhrij.
"""
import json


def code(value: object) -> str:
    """Canonical JSON identity, distinguishing false, 0, and the string 'false'."""
    return json.dumps(value, ensure_ascii=False, sort_keys=True, allow_nan=False)


def same(left: object, right: object) -> bool:
    return code(left) == code(right)


def among(value: object, domain) -> bool:
    return any(same(value, item) for item in domain)


def distinct(values) -> list:
    """First occurrence order, without Python's bool/int key collisions."""
    first = {}
    for value in values:
        first.setdefault(code(value), value)
    return list(first.values())
