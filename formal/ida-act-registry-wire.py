#!/usr/bin/env python3
"""Canonical ACT-01 data boundary; structural resolution never admits a ruling.

Definition SHA-256 is recomputed here. Lean and Quint check exact definition
payloads and supplied digest pins; neither assumes hash injectivity. This
adapter does not create the trusted envelope/source bindings used by their
source-admission gate.
"""

from copy import deepcopy
import hashlib
import json
from pathlib import Path
import sys

FORMAT = "usul.ida.act-registry.v1"
KINDS = ("person", "asset", "obligation", "occurrence", "proposition")
MAX_NAT = 2**53 - 1
SNAPSHOT_FIELDS = (
    "contextId", "timeId", "profile", "profileVersion", "interpretationId",
    "interpretationVersion", "evidenceRevision", "clock", "effectiveAt", "recordedAt",
)


def require(condition, message):
    if not condition:
        raise ValueError(message)


def fields(value, names, label):
    require(type(value) is dict and set(value) == set(names), f"{label}: exact fields required")


def nat(value, label):
    require(type(value) is int and 0 <= value <= MAX_NAT, f"{label}: safe natural required")


def string(value, label):
    require(type(value) is str and not any(0xD800 <= ord(c) <= 0xDFFF for c in value),
            f"{label}: Unicode scalar string required")


def sequence(value, check, label):
    require(type(value) is list, f"{label}: list required")
    for item in value:
        check(item)


def symbol(value):
    fields(value, ("space", "name"), "symbol")
    for key in ("space", "name"):
        string(value[key], "symbol." + key)


def kind_key(value):
    fields(value, ("symbol", "version"), "kind key")
    symbol(value["symbol"])
    nat(value["version"], "kind version")


def digest(value):
    require(type(value) is list and len(value) == 32
            and all(type(x) is int and 0 <= x < 256 for x in value),
            "digest: exactly 32 bytes required")


def role(value):
    fields(value, ("role", "kind"), "role")
    string(value["role"], "role name")
    require(value["kind"] is None or value["kind"] in KINDS, "unsupported reference sort")


def entity(value):
    fields(value, ("kind", "symbol"), "reference")
    require(value["kind"] in KINDS, "unsupported reference sort")
    symbol(value["symbol"])


def parameter(value):
    role(value)
    require(value["kind"] is not None, "operation parameter cannot be unresolved")


def operand(value):
    fields(value, ("role", "referent"), "operand")
    string(value["role"], "operand role")
    entity(value["referent"])


def action(value):
    fields(value, ("operation", "operands"), "action")
    fields(value["operation"], ("symbol", "parameters"), "operation")
    symbol(value["operation"]["symbol"])
    sequence(value["operation"]["parameters"], parameter, "parameters")
    sequence(value["operands"], operand, "operands")


def qualification(value):
    fields(value, ("predicate", "version", "arguments", "polarity", "mention"), "qualification")
    symbol(value["predicate"])
    nat(value["version"], "predicate version")
    sequence(value["arguments"], entity, "predicate arguments")
    require(type(value["polarity"]) is bool, "qualification polarity: Boolean required")
    symbol(value["mention"])


def snapshot(value):
    fields(value, SNAPSHOT_FIELDS, "context snapshot")
    for key in SNAPSHOT_FIELDS:
        if key == "clock":
            symbol(value[key])
        else:
            nat(value[key], "snapshot." + key)


def envelope(value):
    fields(value, ("key", "definitionDigest", "registrySnapshot", "qualifications", "context", "action"),
           "description envelope")
    kind_key(value["key"])
    digest(value["definitionDigest"])
    nat(value["registrySnapshot"], "registry snapshot")
    sequence(value["qualifications"], qualification, "qualifications")
    snapshot(value["context"])
    action(value["action"])


def canonical(value):
    """ASCII escapes make the UTF-8 byte representation independent of locale."""
    return json.dumps(value, ensure_ascii=True, allow_nan=False, sort_keys=True,
                      separators=(",", ":")).encode("utf-8")


def definition_payload(value):
    fields(value, ("key", "digest", "roles"), "definition")
    kind_key(value["key"])
    sequence(value["roles"], role, "definition roles")
    return {"key": value["key"], "roles": value["roles"]}


def definition_digest(value):
    return list(hashlib.sha256(canonical(definition_payload(value))).digest())


def definition(value):
    definition_payload(value)
    digest(value["digest"])
    require(value["digest"] == definition_digest(value), "definition SHA-256 does not match canonical payload")


def registry(value):
    fields(value, ("snapshot", "definitions"), "registry")
    nat(value["snapshot"], "registry snapshot")
    sequence(value["definitions"], definition, "registry definitions")


def no_duplicate_keys(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, "duplicate JSON object key")
        result[key] = value
    return result


def decode(data):
    require(type(data) is bytes, "wire input must be bytes")
    value = json.loads(data.decode("utf-8"), object_pairs_hook=no_duplicate_keys,
                       parse_constant=lambda _: (_ for _ in ()).throw(ValueError("non-JSON constant")))
    fields(value, ("format", "registry", "envelope"), "wire bundle")
    require(value["format"] == FORMAT, "unsupported wire format")
    registry(value["registry"])
    envelope(value["envelope"])
    require(canonical(value) == data, "noncanonical wire bytes")
    return value


def encode(value):
    data = canonical(value)
    decode(data)
    return data


def project(value):
    """A lossy projection; the caller must retain the whole bound envelope."""
    envelope(value)
    return {"form": "perform", "action": deepcopy(value["action"])}


def candidate_catalogue(reference):
    """Preserve every source candidate and unresolved role without inventing sorts."""
    rows = []
    worklist = []
    definitions = []
    for item in reference["proposals"]:
        bridge = item["ida_bridge"]
        require(item["status"] == "candidate" and item["admitted"] is False
                and bridge["profile_admitted"] is False, "catalogue admission status changed")
        value = {"key": {"symbol": deepcopy(bridge["operation_symbol"]),
                         "version": item["proposed_definition_version"]},
                 "roles": [{"role": p["role"], "kind": p["ref_kind"]} for p in bridge["parameters"]],
                 "digest": []}
        value["digest"] = definition_digest(value)
        definition(value)
        definitions.append(value)
        unresolved = []
        for p in bridge["parameters"]:
            if p["ref_kind"] is None:
                require(bool(p.get("unresolved_reason")), "unresolved role has no explanation")
                unresolved.append(p["role"])
                worklist.append({"kind": deepcopy(value["key"]), "role": p["role"],
                                 "reason": p["unresolved_reason"],
                                 "source_loci": deepcopy(item["source_loci"])})
        rows.append({"kind": deepcopy(value["key"]), "definition_digest": value["digest"],
                     "outcome": "unresolved_roles" if unresolved else "representable_candidate",
                     "unresolved_roles": unresolved, "status": "candidate", "admitted": False,
                     "legacy_concept_ids": item["legacy_concept_ids"],
                     "source_loci": deepcopy(item["source_loci"]),
                     "subject_binding": bridge["subject_binding"]})
    return {"definitions": definitions, "candidates": rows, "unresolved_role_worklist": worklist,
            "identity_layers": deepcopy(reference["identity_layers"]),
            "normalization_cases": deepcopy(reference["normalization_cases"])}


def negative_controls(baseline):
    """Exercise the actual strict decoder and digest verifier with hostile bytes."""
    good = encode(baseline)
    rejected = []

    def reject(name, data):
        try:
            decode(data)
        except (ValueError, UnicodeError, TypeError, KeyError):
            rejected.append(name)
        else:
            raise ValueError("wire control accepted: " + name)

    reject("trailing_whitespace", good + b"\n")
    reject("trailing_json", good + b"{}")
    reject("invalid_utf8", b"\xff" + good)
    reject("duplicate_key", b'{"format":"ignored",' + good[1:])
    reordered = dict(reversed(list(baseline.items())))
    reject("noncanonical_key_order", json.dumps(reordered, separators=(",", ":")).encode())

    def change(name, fn):
        value = deepcopy(baseline)
        fn(value)
        reject(name, canonical(value))

    change("unknown_field", lambda x: x.__setitem__("admitted", True))
    change("wrong_version", lambda x: x.__setitem__("format", "usul.ida.act-registry.v0"))
    change("boolean_natural", lambda x: x["envelope"].__setitem__("registrySnapshot", True))
    change("negative_natural", lambda x: x["envelope"]["context"].__setitem__("timeId", -1))
    change("unsafe_natural", lambda x: x["envelope"]["context"].__setitem__("timeId", MAX_NAT + 1))
    change("fractional_natural", lambda x: x["envelope"]["context"].__setitem__("timeId", 0.5))
    change("missing_snapshot_field", lambda x: x["envelope"]["context"].pop("clock"))
    change("unknown_sort", lambda x: x["envelope"]["action"]["operands"][0]["referent"].__setitem__("kind", "mandate"))
    change("surrogate_identifier", lambda x: x["envelope"]["key"]["symbol"].__setitem__("name", "\ud800"))
    change("non_boolean_polarity", lambda x: x["envelope"]["qualifications"][0].__setitem__("polarity", 1))
    change("short_digest", lambda x: x["envelope"]["definitionDigest"].pop())
    change("oversized_digest_byte", lambda x: x["registry"]["definitions"][0]["digest"].__setitem__(0, 256))
    change("signature_changed_under_old_digest", lambda x: x["registry"]["definitions"][0]["roles"][0].__setitem__("role", "other"))
    change("version_changed_under_old_digest", lambda x: x["registry"]["definitions"][0]["key"].__setitem__("version", 2))
    change("role_order_changed_under_old_digest", lambda x: x["registry"]["definitions"][0]["roles"].reverse())
    require(decode(good) == baseline and encode(decode(good)) == good, "canonical roundtrip failed")
    return rejected


def main():
    require(len(sys.argv) == 2, "usage: ida-act-registry-wire.py CANONICAL_BUNDLE.json")
    bundle = decode(Path(sys.argv[1]).read_bytes())
    print(json.dumps({"format": FORMAT, "canonical_bytes": True,
                      "definition_digests_verified": len(bundle["registry"]["definitions"]),
                      "admitted": False, "envelope": bundle["envelope"]}, sort_keys=True))


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, UnicodeError) as exc:
        raise SystemExit(str(exc)) from exc
