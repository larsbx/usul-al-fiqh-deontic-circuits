#!/usr/bin/env python3
"""Audit and compare the shared synthetic ACT-08 application trace."""

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

ROOT, require = gate.ROOT, gate.require
FIXTURE = "UsulTest.IDAPilot"
MODEL = gate.QUINT / "ida-pilot-trace.qnt"
OUTPUT = ROOT / ".cache/ida-pilot-trace"
ROWS, CELLS = 16 * 4 * 6, 4
PROOFS = {"Usul.IDA.Pilot." + name for name in (
    "Receipt.explicit_guard", "Receipt.compatible_history", "Receipt.conditional_sound", "guard_frame",
)} | {FIXTURE + "." + name for name in (
    "nonidentity_admitted", "exact_application_controls", "same_snapshot_omission_controls",
    "irrelevant_frame", "hidden_exception_changes_guard",
)}
MUTANTS = {
    "absence_as_exclusion": ("and has(rows, bob, 2, false) and", "and"),
    "ignore_support_conflict": ("and not(has(rows, alice, 1, false))", ""),
    "vacuous_history": ("else if (compatible == Set()) 1", "else if (false) 1"),
    "ignore_destination_evidence": (
        "not(supplied.indices().forall(i => supported.contains(supplied[i])))", "false"),
    "ignore_omission_occurrence": ("batchOccurrence != expectedOccurrence", "false"),
}


def fingerprint(modules):
    paths = {f"formal/lean/{name.replace('.', '/')}.lean" for name in modules}
    paths.update({
        "Makefile", ".github/workflows/ida-pilot.yml", "formal/check-ida-pilot-trace.py",
        "formal/check-ida-act-registry.py", "formal/ida-act-registry-wire.py", "formal/check-ida.py",
        "formal/check-lean-axioms.py", "formal/lean-axiom-audit.lean",
        "formal/lean/lean-toolchain", "formal/lean/lakefile.toml", "formal/lean/lake-manifest.json",
        "formal/quint/package.json", "formal/quint/package-lock.json", str(MODEL.relative_to(ROOT)),
    })
    return {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in sorted(paths)}


def controls(model, out, *, fail=True):
    result = gate.quint("test", model, "--main", "idaPilotTrace", "--backend", "typescript",
                        "--seed", gate.SEED, "--max-samples", "1", "--match", "^controlsTest$",
                        "--out", out, fail=fail)
    raw = json.loads(out.read_text())
    return result, {k: raw.get(k) for k in ("stage", "passed", "failed", "ignored", "warnings", "errors")}


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    (OUTPUT / "report.json").unlink(missing_ok=True)
    revision = gate.command(["git", "rev-parse", "HEAD"]).stdout.strip()
    modules = gate.lean_closure([FIXTURE])
    hashes = fingerprint(modules)
    overrides = gate.COMMON.runtime_overrides()
    lean = gate.lake("env", "lean", "--version").stdout.strip()
    quint = gate.quint("--version").stdout.strip()
    require(lean.startswith("Lean (version 4.34.1,") and quint == "0.33.1",
            "Unexpected Lean or Quint version")
    built = gate.lake("build", FIXTURE)
    require("declaration uses `sorry`" not in built.stdout + built.stderr, "Admitted Lean proof")
    gate.quint("typecheck", MODEL)

    with tempfile.TemporaryDirectory(prefix="ida-pilot-trace-") as directory:
        work = Path(directory)
        audit = work / "Audit.lean"
        audit.write_text(f"import Lean\nimport {FIXTURE}\n"
                         'private def auditRoots : List String := ["Usul", "UsulTest"]\n'
                         + (ROOT / "formal/lean-axiom-audit.lean").read_text())
        inventory = gate.AUDIT.parse_inventory(gate.lake("env", "lean", audit).stdout, modules)
        proofs = [d for d in inventory if d["kind"] == "theorem" and d["name"] in PROOFS]
        require({d["name"] for d in proofs} == PROOFS, "Missing compiled ACT-08 trace proof")

        export = work / "Export.lean"
        export.write_text(f"""import {FIXTURE}
open {FIXTURE}
def main : IO Unit :=
  let table := (List.range 16).flatMap fun mask => (List.range 4).flatMap fun population =>
    (List.range 6).flatMap (cells mask population)
  IO.println (repr (table ++ (List.range 4).map omissionCell))
""")
        values = json.loads(gate.lake("env", "lean", "--run", export).stdout)
        gate.quint("run", MODEL, "--main", "idaPilotTrace", "--backend", "typescript",
                   "--max-samples", "1", "--max-steps", "0", "--seed", gate.SEED,
                   "--out-itf", work / "trace.json", "--verbosity", "0")
        trace = json.loads((work / "trace.json").read_text())
        other = gate.parse_itf(trace, ROWS * CELLS + 4)
        require(len(values) == len(other) and 99 not in values, "Invalid Lean trace output")
        for i, (left, right) in enumerate(zip(values, other)):
            require(left == right, f"Lean/Quint disagreement at cell {i}: {left} vs {right}")

        _, tests = controls(MODEL, work / "tests.json")
        require(tests["stage"] == "testing" and tests["passed"] == ["controlsTest"]
                and all(not tests[k] for k in ("failed", "ignored", "warnings", "errors")),
                "Incomplete Quint control check")
        weakened = {}
        original = MODEL.read_text()
        mutant = work / MODEL.name
        for name, (before, after) in MUTANTS.items():
            require(original.count(before) == 1, f"Ambiguous mutation point: {name}")
            mutant.write_text(original.replace(before, after))
            gate.quint("typecheck", mutant)
            result, record = controls(mutant, work / "mutant.json", fail=False)
            require(result.returncode != 0 and record["stage"] == "testing"
                    and record["failed"] == ["controlsTest"], f"Invalid mutation result: {name}")
            weakened[name] = record

    require(hashes == fingerprint(modules) and overrides == gate.COMMON.runtime_overrides()
            and revision == gate.command(["git", "rev-parse", "HEAD"]).stdout.strip(),
            "Verification inputs changed during replay")
    matches = all(blob.returncode == 0 and hashlib.sha256(blob.stdout).hexdigest() == digest
                  for path, digest in hashes.items()
                  for blob in [subprocess.run(["git", "show", f"{revision}:{path}"], cwd=ROOT,
                                              capture_output=True)])
    report = {
        "schema": "usul.ida.pilot-trace.verification.v1", "status": "passed", "revision": revision,
        "inputs_match_head": matches, "source_sha256": hashes, "runtime_overrides": overrides,
        "lean": lean, "quint": quint, "rows": ROWS, "comparison_cells": len(values),
        "proofs": proofs, "rejected_mutants": sorted(weakened),
        "boundary": "Synthetic guarded repayment and omission; separate report, history, and authority inputs.",
    }
    for name, data in (("lean-cells", values), ("quint-trace", trace), ("quint-controls", tests),
                       ("mutants", weakened), ("compiled-axioms", inventory), ("report", report)):
        (OUTPUT / (name + ".json")).write_text(json.dumps(data, indent=2) + "\n")
    print(f"ACT-08 shared trace: {len(values)} matching cells, {len(proofs)} proofs,"
          f" {len(weakened)} rejected mutants; inputs_match_head={matches}.")


if __name__ == "__main__":
    main()
