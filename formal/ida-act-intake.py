#!/usr/bin/env python3
"""Prepare candidate act descriptions through the actual Lean registry resolver.

The request selects a catalogue definition and supplies operands, qualifications,
and context. It cannot supply a registry, operation signature, admission decision,
or ruling. The result is a candidate description, never an admitted premise.
"""

import argparse
from copy import deepcopy
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
FORMAT = "usul.ida.act-intake.request.v1"
RESULT = "usul.ida.act-intake.result.v1"
SCRIPT = "scripts/CheckIDAActIntake.lean"
SNAPSHOT = 1


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


WIRE = module("act_intake_wire", ROOT / "formal/ida-act-registry-wire.py")
REFERENCE = module("act_intake_reference", ROOT / "pipeline/usul_corpus/act_reference.py")
OUTCOMES = ("prepared_candidate", "registry_conflict", "malformed_registry",
            "stale_registry_snapshot", "unknown_kind", "definition_digest_mismatch",
            "unresolved_roles", "declaration_mismatch", "argument_mismatch",
            "malformed_description")


def validate_request(value):
    WIRE.fields(value, ("format", "kind", "registrySnapshot", "definitionDigest",
                        "operands", "qualifications", "context"), "intake request")
    WIRE.require(value["format"] == FORMAT, "unsupported intake format")
    WIRE.kind_key(value["kind"])
    WIRE.nat(value["registrySnapshot"], "registry snapshot")
    WIRE.digest(value["definitionDigest"])
    WIRE.sequence(value["operands"], WIRE.operand, "operands")
    WIRE.sequence(value["qualifications"], WIRE.qualification, "qualifications")
    WIRE.snapshot(value["context"])


def decode_request(data):
    WIRE.require(type(data) is bytes, "request must be UTF-8 bytes")
    value = json.loads(data.decode("utf-8"), object_pairs_hook=WIRE.no_duplicate_keys,
                       parse_constant=lambda _: (_ for _ in ()).throw(ValueError("non-JSON constant")))
    validate_request(value)
    return value


def load_catalogue(repo=ROOT):
    """Validate local source metadata; no full witness bytes or authority are admitted."""
    repo = Path(repo)
    data, inputs = REFERENCE.load_inputs(repo)
    checked = REFERENCE.validate(data)
    reference = data["reference"]
    converted = WIRE.candidate_catalogue(reference)
    registry = {"snapshot": SNAPSHOT, "definitions": converted["definitions"]}
    WIRE.registry(registry)
    entries = []
    for proposal, definition in zip(reference["proposals"], registry["definitions"]):
        legacy = proposal["legacy_concept_ids"]
        entries.append({
            "definition": deepcopy(definition), "label_ar": proposal["label_ar"],
            "label_en": proposal["label_en"], "family_tags": deepcopy(proposal["family_tags"]),
            "status": "candidate", "admitted": False,
            "source_loci": deepcopy(proposal["source_loci"]),
            "legacy_concept_ids": deepcopy(legacy), "legacy_kinds": deepcopy(proposal["legacy_kinds"]),
            "legacy_topic_ids": deepcopy(proposal.get("legacy_topic_ids", [])),
            "subject_binding": proposal["ida_bridge"]["subject_binding"],
            "unresolved_roles": deepcopy([p for p in proposal["ida_bridge"]["parameters"]
                                            if p["ref_kind"] is None]),
            "normalization_cases": deepcopy([case for case in reference["normalization_cases"]
                if case["legacy_concept_id"] in legacy
                or proposal["proposed_kind_id"] in case["proposed_kind_ids"]]),
        })
    inputs["formal/ida-act-intake.py"] = Path(__file__).read_bytes()
    inputs["formal/ida-act-registry-wire.py"] = (ROOT / "formal/ida-act-registry-wire.py").read_bytes()
    provenance = REFERENCE.provenance(repo, inputs)
    return {"format": "usul.ida.act-intake.catalogue.v1", "status": "candidate",
            "admitted": False, "ruling": None, "registry": registry, "entries": entries,
            "inventory_counts": checked["inventory_counts"], "proposal_counts": checked["proposal_counts"],
            "registry_sha256": hashlib.sha256(WIRE.canonical(registry)).hexdigest(),
            "source_pins": deepcopy(reference["source_pins"]),
            "source_metadata_checked": True, "source_bytes_verified": False,
            "provenance": provenance}


def core_case(request, catalogue):
    validate_request(request)
    values = {name: deepcopy(request[name]) for name in
              ("definitionDigest", "registrySnapshot", "qualifications", "context", "operands")}
    values["key"] = deepcopy(request["kind"])
    return {"registry": deepcopy(catalogue["registry"]), "input": values}


def lean_prepare(cases, repo=ROOT):
    """The production path executes Lean; no Python-only acceptance fallback exists."""
    with tempfile.TemporaryDirectory(prefix="ida-act-intake-") as directory:
        path = Path(directory) / "requests.json"
        path.write_bytes(WIRE.canonical(cases))
        command = ["lake", "env", "lean", "--run", SCRIPT, str(path)]
        try:
            result = subprocess.run(command, cwd=Path(repo) / "formal/lean", capture_output=True,
                                    text=True, check=False, timeout=120)
        except (OSError, subprocess.TimeoutExpired) as exc:
            raise RuntimeError(f"Lean preparation unavailable: {exc}") from exc
        if result.returncode != 0 or result.stderr.strip():
            raise RuntimeError("Lean preparation failed: " + (result.stderr or result.stdout).strip()[:2000])
        try:
            values = json.loads(result.stdout, object_pairs_hook=WIRE.no_duplicate_keys)
        except (ValueError, UnicodeError) as exc:
            raise RuntimeError("Lean preparation returned invalid JSON") from exc
        if type(values) is not list or len(values) != len(cases):
            raise RuntimeError("Lean preparation returned incomplete results")
        return values


def result_for(request, catalogue, actual):
    """Retain metadata and check the returned payload; this is not a second resolver."""
    WIRE.fields(actual, ("code", "envelope", "definition"), "Lean preparation result")
    code = actual["code"]
    WIRE.require(type(code) is int and 0 <= code < len(OUTCOMES), "unexpected preparation code")
    found = [entry for entry in catalogue["entries"] if entry["definition"]["key"] == request["kind"]]
    WIRE.require(len(found) <= 1, "ambiguous candidate metadata")
    entry = found[0] if found else None
    if code == 0:
        WIRE.require(entry is not None and not entry["unresolved_roles"], "unexpected prepared candidate")
        WIRE.definition(actual["definition"])
        definition = entry["definition"]
        expected = {"key": deepcopy(request["kind"]),
                    **{name: deepcopy(request[name]) for name in
                       ("definitionDigest", "registrySnapshot", "qualifications", "context")},
                    "action": {"operation": {"symbol": deepcopy(definition["key"]["symbol"]),
                                               "parameters": deepcopy(definition["roles"])},
                               "operands": deepcopy(request["operands"])}}
        WIRE.require(actual["definition"] == definition and actual["envelope"] == expected,
                     "Lean preparation changed the selected definition or request fields")
        WIRE.envelope(actual["envelope"])
    else:
        WIRE.require(actual["envelope"] is None and actual["definition"] is None,
                     "rejected preparation must not contain a draft")
    return {"format": RESULT, "status": "candidate", "admitted": False, "ruling": None,
            "outcome": OUTCOMES[code], "code": code, "prepared": code == 0,
            "request": deepcopy(request), "candidate": deepcopy(entry),
            "definition": deepcopy(actual["definition"]), "envelope": deepcopy(actual["envelope"]),
            "target": WIRE.project(actual["envelope"]) if code == 0 else None,
            "catalogue": {name: deepcopy(catalogue[name]) for name in
                          ("registry_sha256", "source_pins", "source_metadata_checked",
                           "source_bytes_verified", "provenance")},
            "checker": "Usul.IDA.ActIntake.prepare via " + SCRIPT,
            "boundary": "Candidate structural preparation only; no occurrence, qualification truth, "
                        "source interpretation, premise admission, application grant, or ruling is established."}


def prepare(request, repo=ROOT):
    validate_request(request)
    catalogue = load_catalogue(repo)
    case = core_case(request, catalogue)
    actual = lean_prepare([case], repo)[0]
    try:
        return result_for(request, catalogue, actual)
    except (ValueError, KeyError, TypeError) as exc:
        raise RuntimeError(f"Lean preparation output failed consistency checks: {exc}") from exc


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("catalogue", help="show the candidate keys, signatures, digests, source links, and gaps")
    draft = sub.add_parser("prepare", help="prepare one candidate description using the compiled Lean model")
    draft.add_argument("request", type=Path)
    args = parser.parse_args(argv)
    try:
        output = load_catalogue() if args.command == "catalogue" else prepare(decode_request(args.request.read_bytes()))
    except RuntimeError as exc:
        output = {"format": RESULT, "status": "rejected", "admitted": False, "ruling": None,
                  "outcome": "preparation_unavailable", "message": str(exc)}
        print(json.dumps(output, ensure_ascii=False, indent=2))
        return 1
    except (ValueError, OSError, KeyError, TypeError, UnicodeError) as exc:
        output = {"format": RESULT, "status": "rejected", "admitted": False, "ruling": None,
                  "outcome": "invalid_input", "message": str(exc)}
        print(json.dumps(output, ensure_ascii=False, indent=2))
        return 2
    print(json.dumps(output, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
