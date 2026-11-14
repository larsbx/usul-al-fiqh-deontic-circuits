"""Host boundary tests; real Lean/Quint preparation is checked by the dedicated gate."""

from copy import deepcopy
import importlib.util
import json
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("act_intake_test", ROOT / "formal/ida-act-intake.py")
intake = importlib.util.module_from_spec(spec)
spec.loader.exec_module(intake)


@pytest.fixture(scope="module")
def catalogue():
    return intake.load_catalogue()


@pytest.fixture
def intake_request(catalogue):
    entry = next(e for e in catalogue["entries"]
                 if e["definition"]["key"]["symbol"]["name"] == "transfer.pay_zakat")
    definition = entry["definition"]
    return {"format": intake.FORMAT, "kind": deepcopy(definition["key"]),
            "registrySnapshot": 1, "definitionDigest": definition["digest"].copy(),
            "operands": [{"role": row["role"], "referent": {"kind": row["kind"],
                          "symbol": {"space": "test.person-or-property", "name": row["role"]}}}
                         for row in definition["roles"]],
            "qualifications": [{"predicate": {"space": "test.predicate", "name": "reported"},
                "version": 1, "arguments": [], "polarity": False,
                "mention": {"space": "test.source", "name": "mention-one"}}],
            "context": {"contextId": 1, "timeId": 1, "profile": 1, "profileVersion": 1,
                "interpretationId": 1, "interpretationVersion": 1, "evidenceRevision": 2,
                "clock": {"space": "test.clock", "name": "ticks"}, "effectiveAt": 10, "recordedAt": 20}}


def sample_response(intake_request, catalogue):
    """A host-consistency fixture, not a replacement for Lean resolution."""
    definition = next(e["definition"] for e in catalogue["entries"]
                      if e["definition"]["key"] == intake_request["kind"])
    envelope = {"key": deepcopy(intake_request["kind"]),
                **{key: deepcopy(intake_request[key]) for key in
                   ("definitionDigest", "registrySnapshot", "qualifications", "context")},
                "action": {"operation": {"symbol": deepcopy(definition["key"]["symbol"]),
                                           "parameters": deepcopy(definition["roles"])},
                           "operands": deepcopy(intake_request["operands"])}}
    return {"code": 0, "envelope": envelope, "definition": deepcopy(definition)}


def test_catalogue_preserves_real_candidates_and_does_not_admit_or_verify_source_bytes(catalogue):
    assert catalogue["proposal_counts"] == {"total": 34, "representable": 1, "unresolved": 33}
    assert sum(len(e["unresolved_roles"]) for e in catalogue["entries"]) == 64
    assert all(e["source_loci"] and not e["admitted"] and e["status"] == "candidate"
               for e in catalogue["entries"])
    assert catalogue["source_metadata_checked"] and not catalogue["source_bytes_verified"]
    assert not catalogue["admitted"] and catalogue["ruling"] is None
    assert len(catalogue["provenance"]["input_files"]) >= 10


@pytest.mark.parametrize("field", ["registry", "operation", "signature", "authority", "status", "admitted", "ruling"])
def test_caller_cannot_supply_authority_signature_or_admission(intake_request, field):
    intake_request[field] = {"claimed": True}
    with pytest.raises(ValueError, match="exact fields"):
        intake.decode_request(json.dumps(intake_request).encode())


@pytest.mark.parametrize("path,value", [
    (("registrySnapshot",), True), (("kind", "version"), 1.5),
    (("context", "timeId"), 2**53), (("definitionDigest", 0), True),
    (("operands", 0, "referent", "kind"), "text"),
    (("qualifications", 0, "polarity"), 1),
    (("kind", "symbol", "name"), "\ud800"),
])
def test_request_rejects_noncanonical_semantic_values(intake_request, path, value):
    obj = intake_request
    for key in path[:-1]:
        obj = obj[key]
    obj[path[-1]] = value
    with pytest.raises(ValueError):
        intake.decode_request(json.dumps(intake_request).encode())


def test_json_rejects_duplicate_fields_invalid_utf8_and_nonfinite_values(intake_request):
    data = json.dumps(intake_request).encode()
    duplicate = data.replace(b'"registrySnapshot": 1', b'"registrySnapshot": 1,"registrySnapshot": 2')
    for invalid in (duplicate, b'\xff', data.replace(b'"registrySnapshot": 1', b'"registrySnapshot": NaN')):
        with pytest.raises((ValueError, UnicodeError)):
            intake.decode_request(invalid)


def test_prepare_uses_lean_and_preserves_fields_and_metadata(intake_request, catalogue, monkeypatch):
    original = deepcopy(intake_request)
    calls = []
    def backend(cases, repo):
        calls.append(deepcopy(cases))
        return [sample_response(intake_request, catalogue)]
    monkeypatch.setattr(intake, "lean_prepare", backend)
    result = intake.prepare(intake_request)
    assert len(calls) == 1 and calls[0][0]["input"]["key"] == intake_request["kind"]
    assert "operation" not in calls[0][0]["input"] and "registry" not in intake_request
    assert result["prepared"] and result["outcome"] == "prepared_candidate"
    assert result["status"] == "candidate" and not result["admitted"] and result["ruling"] is None
    assert result["envelope"]["context"] == intake_request["context"]
    assert result["envelope"]["qualifications"] == intake_request["qualifications"]
    assert result["candidate"]["source_loci"] and result["target"]["form"] == "perform"
    assert intake_request == original
    result["request"]["context"]["evidenceRevision"] = 999
    assert intake_request == original


def test_unresolved_and_unknown_results_carry_no_draft(intake_request, catalogue):
    unresolved = next(e for e in catalogue["entries"]
                      if e["definition"]["key"]["symbol"]["name"] == "agency.revoke")
    intake_request["kind"] = deepcopy(unresolved["definition"]["key"])
    blocked = intake.result_for(intake_request, catalogue, {"code": 6, "envelope": None, "definition": None})
    assert blocked["outcome"] == "unresolved_roles" and not blocked["prepared"]
    assert {p["role"] for p in blocked["candidate"]["unresolved_roles"]} == {"mandate_reference", "manifestation"}
    assert blocked["candidate"]["source_loci"] and blocked["target"] is None
    intake_request["kind"]["symbol"]["name"] = "unknown.kind"
    absent = intake.result_for(intake_request, catalogue, {"code": 4, "envelope": None, "definition": None})
    assert absent["outcome"] == "unknown_kind" and absent["candidate"] is None and absent["envelope"] is None


def test_backend_failure_cannot_fall_back_to_python_acceptance(intake_request, monkeypatch):
    def failed(*_):
        raise RuntimeError("Lean unavailable")
    monkeypatch.setattr(intake, "lean_prepare", failed)
    with pytest.raises(RuntimeError, match="Lean unavailable"):
        intake.prepare(intake_request)


@pytest.mark.parametrize("alteration", ["role", "qualification", "definition", "rejected_with_draft"])
def test_changed_backend_payload_is_rejected(intake_request, catalogue, alteration):
    response = sample_response(intake_request, catalogue)
    if alteration == "role": response["envelope"]["action"]["operands"].reverse()
    elif alteration == "qualification": response["envelope"]["qualifications"][0]["polarity"] = True
    elif alteration == "definition": response["definition"]["key"]["version"] += 1
    else: response["code"] = 6
    with pytest.raises(ValueError):
        intake.result_for(intake_request, catalogue, response)


@pytest.mark.parametrize("alteration", ["boolean_version", "float_digest_byte"])
def test_backend_definition_rejects_equal_values_with_wrong_json_types(intake_request, catalogue, alteration):
    response = sample_response(intake_request, catalogue)
    if alteration == "boolean_version":
        response["definition"]["key"]["version"] = True
    else:
        response["definition"]["digest"][0] = float(response["definition"]["digest"][0])
    with pytest.raises(ValueError):
        intake.result_for(intake_request, catalogue, response)


@pytest.mark.parametrize("code", [False, True])
def test_backend_result_code_rejects_booleans(intake_request, catalogue, code):
    response = sample_response(intake_request, catalogue)
    response["code"] = code
    with pytest.raises(ValueError, match="unexpected preparation code"):
        intake.result_for(intake_request, catalogue, response)
