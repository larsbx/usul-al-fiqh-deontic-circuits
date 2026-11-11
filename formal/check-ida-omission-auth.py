#!/usr/bin/env python3
"""Replay authenticated omission observations and audit the compiled scope checks."""

import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile

spec = importlib.util.spec_from_file_location(
    "ida_registry_gate", Path(__file__).with_name("check-ida-act-registry.py"))
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)

ROOT = gate.ROOT
WIRE = "Usul.Typing.IDAOmissionWire"
FIXTURE = "UsulTest.IDAPilot"
OUTPUT = ROOT / ".cache/ida-omission-auth"
PROOFS = {"Usul.IDA.Omission.Wire." + name for name in (
    "scope_roundtrip", "scope_injective", "decodeView_exact", "review_exact",
)}


def fingerprint(modules):
    paths = {f"formal/lean/{name.replace('.', '/')}.lean" for name in modules}
    paths.update({
        "Makefile", ".github/workflows/ida-omission-auth.yml",
        "formal/lean/lean-toolchain", "formal/lean/lakefile.toml", "formal/lean/lake-manifest.json",
        "formal/lean/scripts/CheckIDAOmissionWire.lean", "formal/check-ida-omission-auth.py",
        "formal/check-ida-omission-auth.mjs", "formal/ida-omission-auth.mjs",
        "formal/ida-source-auth.mjs", "formal/check-ida-act-registry.py",
        "formal/ida-act-registry-wire.py", "formal/check-ida.py",
        "formal/check-lean-axioms.py", "formal/lean-axiom-audit.lean",
    })
    paths.update(str(p.relative_to(ROOT)) for p in
                 (ROOT / "formal/fixtures/ida-source-auth").glob("test-only-*.pem"))
    return {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in sorted(paths)}


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    (OUTPUT / "report.json").unlink(missing_ok=True)
    revision = gate.command(["git", "rev-parse", "HEAD"]).stdout.strip()
    modules = gate.lean_closure([WIRE, FIXTURE])
    hashes = fingerprint(modules)
    overrides = gate.COMMON.runtime_overrides()
    lean = gate.lake("env", "lean", "--version").stdout.strip()
    gate.require(lean.startswith("Lean (version 4.34.1,"), "Lean version mismatch")
    build = gate.lake("build", WIRE, FIXTURE)
    gate.require("declaration uses `sorry`" not in build.stdout + build.stderr, "Admitted Lean proof")
    with tempfile.TemporaryDirectory(prefix="ida-omission-auth-") as directory:
        audit = Path(directory) / "Audit.lean"
        audit.write_text(f"import Lean\nimport {WIRE}\nimport {FIXTURE}\n"
                         'private def auditRoots : List String := ["Usul", "UsulTest"]\n'
                         + (ROOT / "formal/lean-axiom-audit.lean").read_text())
        declarations = gate.AUDIT.parse_inventory(gate.lake("env", "lean", audit).stdout, modules)
        proofs = [d for d in declarations if d["kind"] == "theorem" and d["name"] in PROOFS]
        gate.require({d["name"] for d in proofs} == PROOFS, "Missing compiled omission binding proof")

    replay = json.loads(gate.command(["node", "formal/check-ida-omission-auth.mjs"]).stdout)
    gate.require(hashes == fingerprint(modules) and overrides == gate.COMMON.runtime_overrides()
                 and revision == gate.command(["git", "rev-parse", "HEAD"]).stdout.strip(),
                 "Verification inputs changed during replay")
    matches = all(blob.returncode == 0 and hashlib.sha256(blob.stdout).hexdigest() == digest
                  for path, digest in hashes.items()
                  for blob in [subprocess.run(["git", "show", f"{revision}:{path}"], cwd=ROOT,
                                              capture_output=True)])
    report = {
        "schema": "usul.ida.omission-auth.verification.v1", "status": "passed",
        "revision": revision, "inputs_match_head": matches, "source_sha256": hashes,
        "lean": lean, "node": replay["node"], "runtime_overrides": overrides,
        "audited_declarations": len(declarations), "proofs": proofs, "cases": replay["cases"],
        "boundary": "Signed synthetic observation bytes and exact current scope only.",
    }
    for name, data in (("compiled-axioms", declarations), ("report", report)):
        (OUTPUT / (name + ".json")).write_text(json.dumps(data, indent=2) + "\n")
    print(f"ACT-08 omission authentication: {len(proofs)} compiled proofs,"
          f" {len(replay['cases'])} host controls; inputs_match_head={matches}.")


if __name__ == "__main__":
    main()
