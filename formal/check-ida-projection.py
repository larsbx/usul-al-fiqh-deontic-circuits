#!/usr/bin/env python3
"""Replay the ACT-03 proof contracts and finite independent comparison."""

import csv
import hashlib
import importlib.util
from itertools import product
import json
from pathlib import Path
import subprocess
import tempfile

spec = importlib.util.spec_from_file_location(
    "ida_registry_gate", Path(__file__).with_name("check-ida-act-registry.py"))
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)
ROOT, LEAN, QUINT = gate.ROOT, gate.LEAN, gate.QUINT
require, lake, quint = gate.require, gate.lake, gate.quint

CORE = "Usul.IDA.Projection."
FIXTURE = "UsulTest.IDAProjection"
CONTRACTS = "UsulTest.IDAProjectionContracts"
EXPORTER = "scripts.ExportIDAProjection"
MODEL = "ida-projection.qnt"
TABLE = "ida-projection-table.qnt"
RECEIPT = ROOT / ".cache/ida-projection"
TESTS = {"reportDependenciesTest", "scopeAndFallbackTest"}
PROOFS = {CORE + name for name in (
    "signs_positive", "signs_negative", "signs_append_irrelevant", "projection_exact",
    "equivalence", "frame", "irrelevant_append", "factors", "same_scope",
    "classify_fallback_iff", "fallback_requires_negative", "projection_preserves_target",
)} | {"Usul.Cat.IDAProjection.evaluation_functor"} | {FIXTURE + "." + name for name in (
    "hidden_exception", "core_loses_relevant_reports", "kind_loses_occurrence",
    "kind_does_not_factor", "equivalent_receipt_can_be_stale",
    "equal_answers_do_not_imply_equivalence", "explicit_negative_only",
)}
MUTANTS = {
    "drop_exception": ("4 * flag(observes(source, guard, performer, true)) +", "0 +",
                       "reportDependenciesTest"),
    "ignore_predicate_version": ("q.version == 1 and", "true and", "reportDependenciesTest"),
    "ignore_participant": ("q.person == person and", "true and", "reportDependenciesTest"),
    "absence_as_negative": ("List(1,4,3,5,6,6,6,6,defaultCase",
                            "List(defaultCase,4,3,5,6,6,6,6,defaultCase", "scopeAndFallbackTest"),
    "collapse_occurrence": ("shape != 1 and shape != 13", "shape != 13", "scopeAndFallbackTest"),
    "ignore_scope": ("if (shape == 0) status[observed] else 0", "status[observed]", "scopeAndFallbackTest"),
    "same_answer_equivalence": ("List(flag(a == b),",
                                "List(flag(outcome(fallbackEnabled, 0, a) == outcome(fallbackEnabled, 0, b)),",
                                "reportDependenciesTest"),
}


def observations(source):
    rows = list(csv.reader(source.splitlines()))
    require(rows and rows[0] == ["family", "default", "shape", "left", "right", "results"],
            "Bad Lean table header")
    cases = [("case", *key) for key in product(range(2), range(15), range(16), range(6))]
    pairs = [("pair", enabled, 0, left, right)
             for enabled, left, right in product(range(2), range(16), range(16))]
    keys = cases + pairs
    require(len(rows) == len(keys) + 1, "Incorrect Lean row count")
    cells = []
    for row, key in zip(rows[1:], keys):
        limits = [1, 7, 7, 1, 1, 1, 1, 1, 1, 1] if key[0] == "case" else [1] * 4
        require(len(row) == 5 + len(limits) and row[:5] == [str(x) for x in key], f"Bad Lean row: {row}")
        values = [int(x) for x in row[5:]]
        require(row[5:] == [str(x) for x in values] and all(0 <= x <= m for x, m in zip(values, limits)),
                f"Bad result at {key}")
        if key[0] == "case":
            require(values[0] == 1 and values[1] == values[2],
                    f"Uncertified snapshot or projection disagreement at {key}")
        cells.extend(values)
    return cells


def test(model, output, test_name=None, fail=True):
    names = [test_name] if test_name else sorted(TESTS)
    result = quint("test", model, "--backend", "typescript", "--max-samples", "1",
                   "--seed", gate.SEED, "--match", "^(" + "|".join(names) + ")$",
                   "--out", output, fail=fail)
    data = json.loads(output.read_text())
    return result, {k: data[k] for k in ("stage", "passed", "failed", "ignored", "warnings", "errors")
                    if k in data}


def audit(work, modules):
    target = work / "scripts/ExportIDAProjection.olean"
    target.parent.mkdir()
    lake("env", "lean", "scripts/ExportIDAProjection.lean", "-o", target)
    source = work / "InspectProjection.lean"
    source.write_text(f"import Lean\nimport {CONTRACTS}\nimport {EXPORTER}\n"
                      'private def auditRoots : List String := ["Usul", "UsulTest", "scripts"]\n'
                      + (ROOT / "formal/lean-axiom-audit.lean").read_text())
    result = lake("env", "lean", source, env={"LEAN_PATH": str(work)})
    require(not result.stderr.strip(), result.stderr)
    declarations = gate.AUDIT.parse_inventory(result.stdout, modules)
    names = {d["name"] for d in declarations if d["kind"] == "theorem"}
    require(PROOFS <= names, "Missing fixed proof obligations: " + str(sorted(PROOFS - names)))
    return declarations


def fingerprint(modules):
    paths = {LEAN / (m.replace(".", "/") + ".lean") for m in modules}
    paths.update(ROOT / p for p in (
        "formal/lean/lean-toolchain", "formal/lean/lakefile.toml", "formal/lean/lake-manifest.json",
        "formal/quint/package.json", "formal/quint/package-lock.json",
        "formal/check-ida-projection.py", "formal/check-ida-act-registry.py",
        "formal/check-ida.py", "formal/check-lean-axioms.py", "formal/lean-axiom-audit.lean",
        "formal/ida-act-registry-wire.py", "Makefile", ".github/workflows/ida-projection.yml",
    ))
    paths.update((QUINT / MODEL, QUINT / TABLE))
    return {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(paths)}


def main():
    RECEIPT.mkdir(parents=True, exist_ok=True)
    (RECEIPT / "report.json").unlink(missing_ok=True)
    revision = gate.command(["git", "rev-parse", "HEAD"]).stdout.strip()
    modules = gate.lean_closure([CONTRACTS, EXPORTER])
    hashes = fingerprint(modules)
    overrides = gate.COMMON.runtime_overrides()
    lean_version = lake("env", "lean", "--version").stdout.strip()
    quint_version = quint("--version").stdout.strip()
    require(lean_version.startswith("Lean (version 4.34.1,") and quint_version == "0.33.1",
            "Lean or Quint version mismatch")
    build = lake("build", CONTRACTS)
    require("declaration uses `sorry`" not in build.stdout + build.stderr, "Admitted Lean proof")
    quint("typecheck", QUINT / TABLE)
    with tempfile.TemporaryDirectory(prefix="ida-projection-", dir=RECEIPT.parent) as temp:
        work = Path(temp)
        declarations = audit(work, modules)
        _, tests = test(QUINT / MODEL, work / "tests.json")
        require(tests.get("stage") == "testing" and set(tests.get("passed", [])) == TESTS
                and all(not tests.get(k) for k in ("failed", "ignored", "warnings", "errors")),
                "Incomplete Quint tests")
        lean_csv = lake("env", "lean", "--run", "scripts/ExportIDAProjection.lean").stdout
        values = observations(lean_csv)
        quint("run", QUINT / TABLE, "--main", "idaProjectionTable", "--backend", "typescript",
              "--max-samples", "1", "--max-steps", "0", "--seed", gate.SEED,
              "--out-itf", work / "trace.json", "--verbosity", "0")
        trace = json.loads((work / "trace.json").read_text())
        quint_values = gate.parse_itf(trace, len(values))
        for i, (expected, actual) in enumerate(zip(values, quint_values)):
            require(expected == actual, f"Lean/Quint disagreement at cell {i}: {expected} vs {actual}")
        original = (QUINT / MODEL).read_text()
        mutants = {}
        for name, (before, after, witness) in MUTANTS.items():
            require(original.count(before) == 1, f"Nonunique mutation point: {name}")
            changed = work / MODEL
            changed.write_text(original.replace(before, after))
            quint("typecheck", changed)
            result, record = test(changed, work / "mutant.json", witness, fail=False)
            require(result.returncode != 0 and record.get("stage") == "testing"
                    and record.get("failed") == [witness], f"Mutation survived or failed out of scope: {name}")
            mutants[name] = record
        require(hashes == fingerprint(modules) and overrides == gate.COMMON.runtime_overrides()
                and revision == gate.command(["git", "rev-parse", "HEAD"]).stdout.strip(),
                "Verification inputs changed")
        matches = all(p.returncode == 0 and hashlib.sha256(p.stdout).hexdigest() == digest
                      for path, digest in hashes.items()
                      for p in [subprocess.run(["git", "show", revision + ":" + path],
                                               cwd=ROOT, capture_output=True)])
        report = {
            "schema": "usul.ida.projection.verification.v1", "status": "passed",
            "revision": revision, "inputs_match_head": matches, "source_sha256": hashes,
            "runtime_overrides": overrides, "lean": lean_version, "quint": quint_version,
            "scope_cases": 2880, "pair_cases": 512, "comparison_cells": len(values),
            "proofs": sorted(PROOFS), "mutations": sorted(mutants),
        }
        (RECEIPT / "lean.csv").write_text(lean_csv)
        for name, data in (("quint.itf", trace), ("tests", tests), ("mutants", mutants),
                           ("compiled-axioms", declarations), ("report", report)):
            (RECEIPT / (name + ".json")).write_text(json.dumps(data, indent=2) + "\n")
    print(f"ACT-03: {len(values)} matching cells, {len(PROOFS)} proof obligations and witnesses,"
          f" {len(mutants)} rejected mutations at {revision}.")


if __name__ == "__main__":
    main()
