#!/usr/bin/env python3
"""Replay the ACT-04 proof contracts and finite independent comparison."""

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

CORE = "Usul.IDA.Semantics."
FIXTURE = "UsulTest.IDASemantics"
CONTRACTS = "UsulTest.IDASemanticsContracts"
EXPORTER = "scripts.ExportIDASemantics"
MODEL = "ida-semantics.qnt"
TABLE = "ida-semantics-table.qnt"
RECEIPT = ROOT / ".cache/ida-semantics"
TESTS = {"substitutionAndVersionTest", "finiteNonvacuityTest"}
PROOFS = {CORE + name for name in (
    "grounding_pull", "pull_id", "pull_comp", "evaluate_subst", "satisfaction_subst",
    "premises_subst", "sound", "opposing_premises_incompatible", "sound_along",
    "supported_subst", "read_isSome_iff", "interpret_subst", "interpretation_supported",
    "groundInquiry_subst", "inquiry_subst", "mem_compatible", "robust_iff",
)} | {"Usul.Cat.IDASemantics." + name for name in (
    "description_naturality", "formula_naturality",
)} | {FIXTURE + "." + name for name in (
    "exact_version_and_roles", "finite_nonvacuity_controls",
    "reports_are_separate", "nonidentity_sound_instance",
)}
MUTANTS = {
    "reverse_assignment": ("    List(ref(a, values), ref(b, values))",
                           "    List(ref(b, values), ref(a, values))", "substitutionAndVersionTest"),
    "ignore_predicate_version": ("if (version == 2) 4 else 1", "1", "substitutionAndVersionTest"),
    "conflate_rigid_namespaces": ("if (term < 2) values[term] else term - 1",
                                 "if (term < 2) values[term] else if (term == 4) 1 else term - 1",
                                 "substitutionAndVersionTest"),
    "ignore_sign": ("truth(mask, q.version, ref(q.term, values)) == q.positive",
                    "truth(mask, q.version, ref(q.term, values))",
                    "substitutionAndVersionTest"),
    "change_history_under_substitution": ("satisfied(mask, pull(a, b, values), f)",
                                          "satisfied(15 - mask, pull(a, b, values), f)",
                                          "substitutionAndVersionTest"),
    "accept_unsupported_schema": ("if (revised) List(0, 0, 0) else List(roles[0], roles[1], 4)",
                                  "List(roles[0], roles[1], 4)", "substitutionAndVersionTest"),
    "vacuous_robustness": ("else if (compatibleWorlds.size() == 0) 1",
                          "else if (compatibleWorlds.size() == 0) 2", "finiteNonvacuityTest"),
}


def observations(source):
    rows = list(csv.reader(source.splitlines()))
    require(rows and rows[0] == ["family", "x", "y", "z", "w", "v", "results"],
            "Bad Lean table header")
    formulas = [("formula", *key) for key in product(range(16), range(4), range(5), range(5), range(8))]
    meanings = [("meaning", *key, 0) for key in product(range(2), range(4), range(5), range(5))]
    assessments = [("assessment", *key, 0, 0) for key in product(range(5), range(7), range(8))]
    keys = formulas + meanings + assessments
    require(len(rows) == len(keys) + 1, "Incorrect Lean row count")
    cells = []
    limits_by_family = {"formula": [1, 1], "meaning": [4] * 8 + [1], "assessment": [3]}
    for row, key in zip(rows[1:], keys):
        limits = limits_by_family[key[0]]
        require(len(row) == 6 + len(limits) and row[:6] == [str(x) for x in key], f"Bad Lean row: {row}")
        values = [int(x) for x in row[6:]]
        require(row[6:] == [str(x) for x in values] and all(0 <= x <= m for x, m in zip(values, limits)),
                f"Bad result at {key}")
        if key[0] == "formula":
            require(values[0] == values[1], f"Formula substitution disagreement at {key}")
        elif key[0] == "meaning":
            require(values[:3] == values[3:6] and values[-1] == 1,
                    f"Description or inquiry substitution disagreement at {key}")
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
    target = work / "scripts/ExportIDASemantics.olean"
    target.parent.mkdir()
    lake("env", "lean", "scripts/ExportIDASemantics.lean", "-o", target)
    source = work / "InspectSemantics.lean"
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
        "formal/check-ida-semantics.py", "formal/check-ida-act-registry.py",
        "formal/check-ida.py", "formal/check-lean-axioms.py", "formal/lean-axiom-audit.lean",
        "formal/ida-act-registry-wire.py", "Makefile", ".github/workflows/ida-semantics.yml",
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
    with tempfile.TemporaryDirectory(prefix="ida-semantics-", dir=RECEIPT.parent) as temp:
        work = Path(temp)
        declarations = audit(work, modules)
        _, tests = test(QUINT / MODEL, work / "tests.json")
        require(tests.get("stage") == "testing" and set(tests.get("passed", [])) == TESTS
                and all(not tests.get(k) for k in ("failed", "ignored", "warnings", "errors")),
                "Incomplete Quint tests")
        lean_csv = lake("env", "lean", "--run", "scripts/ExportIDASemantics.lean").stdout
        values = observations(lean_csv)
        quint("run", QUINT / TABLE, "--main", "idaSemanticsTable", "--backend", "typescript",
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
            "schema": "usul.ida.semantics.verification.v1", "status": "passed",
            "revision": revision, "inputs_match_head": matches, "source_sha256": hashes,
            "runtime_overrides": overrides, "lean": lean_version, "quint": quint_version,
            "formula_cases": 12800, "meaning_cases": 200, "assessment_cases": 280, "comparison_cells": len(values),
            "proofs": sorted(PROOFS), "mutations": sorted(mutants),
        }
        (RECEIPT / "lean.csv").write_text(lean_csv)
        for name, data in (("quint.itf", trace), ("tests", tests), ("mutants", mutants),
                           ("compiled-axioms", declarations), ("report", report)):
            (RECEIPT / (name + ".json")).write_text(json.dumps(data, indent=2) + "\n")
    print(f"ACT-04: {len(values)} matching cells, {len(PROOFS)} proof obligations and witnesses,"
          f" {len(mutants)} rejected mutations at {revision}.")


if __name__ == "__main__":
    main()
