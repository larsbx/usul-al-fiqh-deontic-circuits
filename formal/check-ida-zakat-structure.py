#!/usr/bin/env python3
"""Check the exact candidate signature and compare structural Lean and Quint outcomes."""

import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile

spec = importlib.util.spec_from_file_location(
    "ida_registry_gate", Path(__file__).with_name("check-ida-act-registry.py"))
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)

ROOT = gate.ROOT
FIXTURE = "UsulTest.IDAZakatStructure"
PROPOSALS = "corpus/proposals/fiqh-acts/reference.json"
MODEL = "formal/quint/ida-zakat-structure.qnt"
OUTPUT = ROOT / ".cache/ida-zakat-structure/report.json"


def fingerprint(revision):
    paths = {f"formal/lean/{name.replace('.', '/')}.lean" for name in gate.lean_closure([FIXTURE])}
    paths.update({PROPOSALS, MODEL, "Makefile", ".github/workflows/ida-pilot.yml",
                  "formal/check-ida-zakat-structure.py", "formal/check-ida-act-registry.py",
                  "formal/check-ida.py", "formal/check-lean-axioms.py",
                  "formal/ida-act-registry-wire.py", "formal/quint/package-lock.json",
                  "formal/quint/package.json", "formal/lean/lean-toolchain",
                  "formal/lean/lakefile.toml", "formal/lean/lake-manifest.json"})
    result = {}
    for path in sorted(paths):
        digest = hashlib.sha256((ROOT / path).read_bytes()).hexdigest()
        committed = gate.command(["git", "show", f"{revision}:{path}"]).stdout
        gate.require(hashlib.sha256(committed.encode()).hexdigest() == digest, f"Input differs from HEAD: {path}")
        result[path] = digest
    return result


def check_candidate(signature):
    space, name, version, *roles = signature
    catalog = json.loads((ROOT / PROPOSALS).read_bytes())
    candidates = [p for p in catalog["proposals"] if p["proposed_kind_id"] == name]
    gate.require(len(candidates) == 1, "Expected one exact candidate")
    candidate, = candidates
    bridge = candidate["ida_bridge"]
    expected_roles = [value for row in bridge["parameters"] for value in (row["role"], row["ref_kind"])]
    gate.require(bridge["operation_symbol"] == {"space": space, "name": name}
                 and candidate["proposed_definition_version"] == int(version)
                 and roles == expected_roles and bridge["representable"] is True
                 and candidate["status"] == bridge["status"] == "candidate"
                 and candidate["admitted"] is bridge["profile_admitted"] is False,
                 "Candidate signature or admission status changed")


def main():
    OUTPUT.unlink(missing_ok=True)
    revision = gate.command(["git", "rev-parse", "HEAD"]).stdout.strip()
    hashes = fingerprint(revision)
    gate.require(gate.lake("env", "lean", "--version").stdout.startswith("Lean (version 4.34.1,"),
                 "Unexpected Lean version")
    gate.require(gate.quint("--version").stdout.strip() == "0.33.1", "Unexpected Quint version")
    built = gate.lake("build", FIXTURE)
    gate.require("declaration uses `sorry`" not in built.stdout + built.stderr, "Admitted Lean proof")
    with tempfile.TemporaryDirectory(prefix="ida-zakat-") as temp:
        script = Path(temp) / "Export.lean"
        script.write_text(f"""import Lean
import {FIXTURE}
open Lean UsulTest.IDAZakatStructure Usul.IDA.ActRegistry
def main : IO Unit := do
  let key := definition.key
  let roles := operation.parameters.flatMap fun p => [p.role, encodeKind p.kind]
  IO.println (toJson ([key.symbol.space, key.symbol.name, toString key.version] ++ roles)).compress
  IO.println (toJson cells).compress
""")
        signature, values = map(json.loads, gate.lake("env", "lean", "--run", script).stdout.splitlines())
        check_candidate(signature)
        trace = Path(temp) / "quint.json"
        gate.quint("run", ROOT / MODEL, "--main", "idaZakatStructure", "--backend", "typescript",
                   "--seed", gate.SEED, "--max-samples", "1", "--max-steps", "0",
                   "--out-itf", trace, "--verbosity", "0")
        other = gate.parse_itf(json.loads(trace.read_bytes()), 21)
        gate.require(values == other, "Lean and Quint structural outcomes differ")
    gate.require(gate.command(["git", "rev-parse", "HEAD"]).stdout.strip() == revision
                 and fingerprint(revision) == hashes, "Inputs changed during replay")
    report = {"schema": "usul.ida.zakat-structure.verification.v1", "status": "passed",
              "revision": revision, "inputs_match_head": True, "source_sha256": hashes,
              "signature": signature, "cells": values,
              "boundary": "Candidate structure only. No juristic admission or interpretation."}
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    temporary = OUTPUT.with_suffix(".tmp")
    temporary.write_text(json.dumps(report, indent=2) + "\n")
    temporary.replace(OUTPUT)
    print(f"ACT-08 zakat candidate structure: {len(values)} matching cells at {revision}.")


if __name__ == "__main__":
    main()
