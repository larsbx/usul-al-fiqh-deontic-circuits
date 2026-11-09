#!/usr/bin/env python3
"""Replay the ACT-02 proof contracts and finite independent comparison."""

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

CORE = "Usul.IDA.Substitution."
FIXTURE = "UsulTest.IDASubstitution"
CONTRACTS = "UsulTest.IDASubstitutionContracts"
EXPORTER = "scripts.ExportIDASubstitution"
MODEL = "ida-substitution.qnt"
TABLE = "ida-substitution-table.qnt"
RECEIPT = ROOT / ".cache/ida-substitution"
TESTS = {"rigidAndRoleTest", "premiseTest"}
PROOFS = {CORE + name for name in (
    "Term.decode_wrong_sort", "Term.rigid_preserved", "Sub.assoc", "Args.get_subst",
    "Args.shared_image", "Description.subst_id", "Description.subst_comp",
    "Description.schema_preserved", "Description.subst_wellFormed", "operands_signature",
    "Inquiry.frame_preserved", "Inquiry.ground_comp", "Formula.subst_id", "Formula.subst_comp",
    "Derives.subst", "Derives.cut", "Derives.iff_atoms", "PremiseArrow.check_iff",
    "PremiseArrow.id_comp", "PremiseArrow.comp_id", "PremiseArrow.assoc",
)} | {FIXTURE + "." + name for name in (
    "controls", "grounded_inquiry_checked", "composed_nonidentity_arrows",
    "opposing_atoms_do_not_supply_another_atom",
)}
MUTANTS = {
    "wrong_sort": ('ref.sort == "person" and ', '', "rigidAndRoleTest"),
    "rewrite_rigid_debt": ('| Constant(ref) => Constant(ref)',
                           '| Constant(ref) => if (ref == debt) Constant(alice) else Constant(ref)',
                           "rigidAndRoleTest"),
    "reverse_composition": ("sequence(sequence(first, second), grounded)",
                            "sequence(sequence(second, first), grounded)", "rigidAndRoleTest"),
    "drop_required_premise": ("Set(moveAtom(atom(x), proposed), moveAtom(atom(y), proposed))",
                              "Set(moveAtom(atom(x), proposed))", "premiseTest"),
    "collapse_namespaces": ("if (ref == alice) 1", 'if (ref.name == "alice") 1', "rigidAndRoleTest"),
}


def observations(source):
    rows = list(csv.reader(source.splitlines()))
    require(rows and rows[0] == ["family", "a", "b", "c", "d", "result"], "Bad Lean table header")
    syntax = [("syntax", *key) for key in product(range(7), repeat=4)]
    premise = [("premise", *key, 0) for key in product(range(9), range(7), range(7))]
    keys = syntax + premise
    require(len(rows) == len(keys) + 1, "Incorrect Lean row count")
    cells = []
    for row, key in zip(rows[1:], keys):
        count, maximum = (8, 4) if key[0] == "syntax" else (1, 2)
        require(len(row) == 5 + count and row[:5] == [str(x) for x in key], f"Bad Lean row: {row}")
        values = [int(x) for x in row[5:]]
        require(row[5:] == [str(x) for x in values] and all(0 <= x <= maximum for x in values),
                f"Bad result at {key}")
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
    target = work / "scripts/ExportIDASubstitution.olean"
    target.parent.mkdir()
    lake("env", "lean", "scripts/ExportIDASubstitution.lean", "-o", target)
    source = work / "InspectSubstitution.lean"
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
        "formal/check-ida-substitution.py", "formal/check-ida-act-registry.py",
        "formal/check-ida.py", "formal/check-lean-axioms.py", "formal/lean-axiom-audit.lean",
        "formal/ida-act-registry-wire.py", "Makefile", ".github/workflows/ida-substitution.yml",
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
    with tempfile.TemporaryDirectory(prefix="ida-substitution-", dir=RECEIPT.parent) as temp:
        work = Path(temp)
        declarations = audit(work, modules)
        _, tests = test(QUINT / MODEL, work / "tests.json")
        require(tests.get("stage") == "testing" and set(tests.get("passed", [])) == TESTS
                and all(not tests.get(k) for k in ("failed", "ignored", "warnings", "errors")),
                "Incomplete Quint tests")
        lean_csv = lake("env", "lean", "--run", "scripts/ExportIDASubstitution.lean").stdout
        values = observations(lean_csv)
        quint("run", QUINT / TABLE, "--main", "idaSubstitutionTable", "--backend", "typescript",
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
            "schema": "usul.ida.substitution.verification.v1", "status": "passed",
            "revision": revision, "inputs_match_head": matches, "source_sha256": hashes,
            "runtime_overrides": overrides, "lean": lean_version, "quint": quint_version,
            "syntax_cases": 2401, "premise_cases": 441, "comparison_cells": len(values),
            "proofs": sorted(PROOFS), "mutations": sorted(mutants),
        }
        (RECEIPT / "lean.csv").write_text(lean_csv)
        for name, data in (("quint.itf", trace), ("tests", tests), ("mutants", mutants),
                           ("compiled-axioms", declarations), ("report", report)):
            (RECEIPT / (name + ".json")).write_text(json.dumps(data, indent=2) + "\n")
    print(f"ACT-02: {len(values)} matching cells, {len(PROOFS)} proof obligations and witnesses,"
          f" {len(mutants)} rejected mutations at {revision}.")


if __name__ == "__main__":
    main()
