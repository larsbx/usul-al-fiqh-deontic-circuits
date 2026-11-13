#!/usr/bin/env python3
"""Replay ACT-05 with pinned tools, compiled axioms, and independent controls."""

import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile

spec = importlib.util.spec_from_file_location(
    "ida_registry_gate", Path(__file__).with_name("check-ida-act-registry.py"))
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)

ROOT, QUINT = gate.ROOT, gate.QUINT
lake, quint, require = gate.lake, gate.quint, gate.require
FIXTURE = "UsulTest.IDAAdmission"
MODEL = QUINT / "ida-admission.qnt"
OUTPUT = ROOT / ".cache/ida-admission"
TESTS = {"controlsTest", "boundedAuthorityTest", "independentSemanticsTest"}
PROOFS = {"Usul.IDA.Admission." + name for name in (
    "Plan.reconstructed", "Plan.conditional_sound", "replay_changed",
    "reconstruct_preserves_provenance", "authorized_certificate_source", "no_token_reuse",
    "Receipt.destination_grounding", "Receipt.destination_certificates", "Receipt.destination_question",
    "Receipt.conditional_sound", "Receipt.transport_contract",
)} | {FIXTURE + "." + name for name in (
    "nonidentity_admission", "current_receipt_replays", "nonidentity_semantics", "adverse_controls",
)}
MUTATIONS = {
    "ignore_current_snapshot": ("current != Set(submitted)", "false"),
    "ignore_grounded_premise": ("s.certs.foldl(List(), (atoms, c) => atoms.append(c.atom)) != expected.premises", "false"),
    "reuse_signature_token": ("a.signed.filter(other => other.token == c.token) != Set(c)",
                              "a.signed.filter(other => other.token == c.token).size() != 1"),
    "ignore_revoked_source": ("not(a.sources.contains(s.certs[i].sourceId))", "false"),
    "ignore_destination_grant": ("not(a.grants.contains(s))", "false"),
    "ignore_current_evidence": ("not(a.evidence.contains(s.certs[i]))", "false"),
    "ignore_replay_authority_change": ("if (a != issued) 8 else admit(a, d)", "admit(a, d)"),
}


def fingerprint(modules):
    paths = {f"formal/lean/{name.replace('.', '/')}.lean" for name in modules}
    paths.update({
        "Makefile", ".github/workflows/ida-admission.yml",
        "formal/lean/lean-toolchain", "formal/lean/lakefile.toml", "formal/lean/lake-manifest.json",
        "formal/quint/package.json", "formal/quint/package-lock.json",
        "formal/check-ida-admission.py", "formal/check-ida-act-registry.py",
        "formal/ida-act-registry-wire.py", "formal/check-ida.py",
        "formal/check-lean-axioms.py", "formal/lean-axiom-audit.lean",
        str(MODEL.relative_to(ROOT)),
    })
    return {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in sorted(paths)}


def test(model, output, names, *, fail=True):
    result = quint("test", model, "--backend", "typescript", "--max-samples", "1",
                   "--seed", gate.SEED, "--match", "^(?:" + "|".join(sorted(names)) + ")$",
                   "--out", output, fail=fail)
    return result, json.loads(output.read_text())


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    (OUTPUT / "report.json").unlink(missing_ok=True)
    revision = gate.command(["git", "rev-parse", "HEAD"]).stdout.strip()
    modules = gate.lean_closure([FIXTURE])
    hashes = fingerprint(modules)
    lean = lake("env", "lean", "--version").stdout.strip()
    version = quint("--version").stdout.strip()
    require(lean.startswith("Lean (version 4.34.1,") and version == "0.33.1",
            "Lean or Quint version mismatch")
    build = lake("build", FIXTURE)
    require("declaration uses `sorry`" not in build.stdout + build.stderr, "Admitted Lean proof")
    quint("typecheck", MODEL)
    with tempfile.TemporaryDirectory(prefix="ida-admission-", dir=OUTPUT.parent) as directory:
        work = Path(directory)
        source = work / "Audit.lean"
        source.write_text(f"import Lean\nimport {FIXTURE}\n"
                          'private def auditRoots : List String := ["Usul", "UsulTest"]\n'
                          + (ROOT / "formal/lean-axiom-audit.lean").read_text())
        result = lake("env", "lean", source)
        require(not result.stderr.strip(), result.stderr)
        declarations = gate.AUDIT.parse_inventory(result.stdout, modules)
        proofs = [d for d in declarations if d["kind"] == "theorem" and d["name"] in PROOFS]
        require({d["name"] for d in proofs} == PROOFS, "Missing required compiled ACT-05 proof")

        _, tests = test(MODEL, work / "tests.json", TESTS)
        require(tests.get("stage") == "testing" and set(tests.get("passed", [])) == TESTS
                and all(not tests.get(k) for k in ("failed", "ignored", "warnings", "errors")),
                "Incomplete Quint tests")

        source.write_text(f"import {FIXTURE}\n"
                          f"def main : IO Unit := IO.println (repr ((List.range 13).map {FIXTURE}.control))\n")
        lean_cells = json.loads(lake("env", "lean", "--run", source).stdout)
        quint("run", MODEL, "--main", "idaAdmission", "--backend", "typescript",
              "--max-samples", "1", "--max-steps", "0", "--seed", gate.SEED,
              "--out-itf", work / "trace.json", "--verbosity", "0")
        trace = json.loads((work / "trace.json").read_text())
        quint_cells = gate.parse_itf(trace, 13)
        require(lean_cells == quint_cells, f"Lean/Quint disagreement: {lean_cells} vs {quint_cells}")

        original = MODEL.read_text()
        mutants = {}
        for name, (before, after) in MUTATIONS.items():
            require(original.count(before) == 1, f"Nonunique mutation point: {name}")
            changed = work / MODEL.name
            changed.write_text(original.replace(before, after))
            quint("typecheck", changed)
            result, record = test(changed, work / "mutant.json", {"controlsTest"}, fail=False)
            require(result.returncode != 0 and record.get("stage") == "testing"
                    and record.get("failed") == ["controlsTest"],
                    f"Mutation survived or failed outside the expected assertion: {name}")
            mutants[name] = record

    require(hashes == fingerprint(modules)
            and revision == gate.command(["git", "rev-parse", "HEAD"]).stdout.strip(),
            "Verification inputs changed")
    matches = all(hashlib.sha256(gate.command(
        ["git", "show", f"{revision}:{p}"], fail=False).stdout.encode()).hexdigest() == digest
        for p, digest in hashes.items())
    report = {
        "schema": "usul.ida.admission.verification.v1", "status": "passed",
        "revision": revision, "inputs_match_head": matches, "source_sha256": hashes,
        "lean": lean, "quint": version, "control_codes": lean_cells, "authority_cases": 32,
        "audited_declarations": len(declarations), "proofs": proofs, "mutations": sorted(mutants),
    }
    for name, data in (("report", report), ("compiled-axioms", declarations), ("quint-trace", trace),
                       ("quint-tests", tests), ("quint-mutants", mutants)):
        (OUTPUT / (name + ".json")).write_text(json.dumps(data, indent=2) + "\n")
    print(f"ACT-05: {len(lean_cells)} matching controls, {len(proofs)} compiled proofs,"
          f" 32 bounded authority cases, {len(mutants)} rejected mutants.")


if __name__ == "__main__":
    main()
