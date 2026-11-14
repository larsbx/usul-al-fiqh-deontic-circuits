#!/usr/bin/env python3
"""Replay the ACT-03 proof contracts and finite independent comparison."""

import csv
from copy import deepcopy
import hashlib
import importlib.util
from itertools import product
import json
from pathlib import Path
import re
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
TESTS = {"reportDependenciesTest", "scopeAndFallbackTest",
         "outputRelabelingTest", "unattestedFeatureTest"}
BOUNDARY_PROOF_NAMES = (
    "relabel_same_reads", "relabel_same_projection", "relabel_same_applicability",
    "relabel_changes_applicable_answer", "relabel_factorization", "relabel_matrix",
    "unattested_known_nonempty_consistent", "unattested_candidate_factorization",
    "unattested_candidate_agreement", "unattested_feature_absent",
    "unattested_two_extensions", "unattested_free_answer", "unattested_matrix",
    "relabeling_boundary", "unattested_boundary",
)
BOUNDARY_PROOFS = {FIXTURE + "." + name for name in BOUNDARY_PROOF_NAMES}
BOUNDARY_CONTRACTS = {CONTRACTS + ".require_" + name for name in BOUNDARY_PROOF_NAMES}
CELLS = 31040
ROWS = 3416
PROOFS = {CORE + name for name in (
    "signs_positive", "signs_negative", "signs_append_irrelevant", "projection_exact",
    "equivalence", "frame", "irrelevant_append", "factors", "same_scope",
    "classify_fallback_iff", "fallback_requires_negative", "projection_preserves_target",
)} | {"Usul.Cat.IDAProjection.evaluation_functor"} | {FIXTURE + "." + name for name in (
    "hidden_exception", "core_loses_relevant_reports", "kind_loses_occurrence",
    "kind_does_not_factor", "equivalent_receipt_can_be_stale",
    "equal_answers_do_not_imply_equivalence", "explicit_negative_only",
)} | BOUNDARY_PROOFS
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
    "same_information_same_answer": (
        "val relabeledAnswer = negateAnswer(relabeledProjection)",
        "val relabeledAnswer = if (originalProjection == relabeledProjection) originalAnswer "
        "else negateAnswer(relabeledProjection)", "outputRelabelingTest"),
    "unseen_answer_from_known_labels": ("if (point.feature) unseenValue else knownValue",
                                        "knownValue", "unattestedFeatureTest"),
}


def observations(source):
    rows = list(csv.reader(source.splitlines()))
    require(rows and rows[0] == ["family", "default", "shape", "left", "right", "results"],
            "Bad Lean table header")
    cases = [("case", *key) for key in product(range(2), range(15), range(16), range(6))]
    pairs = [("pair", enabled, 0, left, right)
             for enabled, left, right in product(range(2), range(16), range(16))]
    relabel = [("relabel", enabled, 0, feature, noise)
               for enabled, feature, noise in product(range(2), repeat=3)]
    unattested = [("unattested", *key) for key in product(range(2), repeat=4)]
    keys = cases + pairs + relabel + unattested
    require(len(keys) == ROWS, "Declared Lean row domain changed")
    require(len(rows) == len(keys) + 1, "Incorrect Lean row count")
    cells = []
    bounds = {
        "case": [1, 7, 7, 1, 1, 1, 1, 1, 1, 1],
        "pair": [1] * 4,
        "relabel": [2, 2, 1, 1, 2, 2, 1, 1],
        "unattested": [1] * 8,
    }
    for row, key in zip(rows[1:], keys):
        limits = bounds[key[0]]
        require(len(row) == 5 + len(limits) and row[:5] == [str(x) for x in key], f"Bad Lean row: {row}")
        values = [int(x) for x in row[5:]]
        require(row[5:] == [str(x) for x in values] and all(0 <= x <= m for x, m in zip(values, limits)),
                f"Bad result at {key}")
        if key[0] == "case":
            require(values[0] == 1 and values[1] == values[2],
                    f"Uncertified snapshot or projection disagreement at {key}")
        cells.extend(values)
    require(len(cells) == CELLS, "Declared comparison cell count changed")
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
    require(BOUNDARY_CONTRACTS <= names,
            "Missing named boundary contracts: " + str(sorted(BOUNDARY_CONTRACTS - names)))
    return declarations


def weakened_propositions(work):
    """The altered module must compile before its unchanged contracts reject it."""
    source = (LEAN / "UsulTest/IDAProjection.lean").read_text()
    contracts = (LEAN / "UsulTest/IDAProjectionContracts.lean").read_text()
    original_import = "import " + FIXTURE + "\n"
    require(contracts.count(original_import) == 1, "Ambiguous boundary-contract import")
    controls = []
    for name, module in (("relabeling_boundary", "WeakProjectionRelabeling"),
                         ("unattested_boundary", "WeakProjectionUnattested")):
        pattern = re.compile(r"^theorem " + re.escape(name)
                             + r"\b.*?(?=^theorem |^end )", re.M | re.S)
        matches = list(pattern.finditer(source))
        require(len(matches) == 1, "Ambiguous proposition control: " + name)
        weak = work / (module + ".lean")
        weak.write_text(pattern.sub("theorem " + name + " : True := by trivial\n\n", source))
        compiled = lake("env", "lean", "--root=" + str(work), weak,
                        "-o", weak.with_suffix(".olean"))
        require("declaration uses `sorry`" not in compiled.stdout + compiled.stderr,
                "Weakening probe must compile without an admitted proof")
        fixed = work / ("Fixed" + module + ".lean")
        fixed.write_text(contracts.replace(original_import, "import " + module + "\n", 1))
        result = lake("env", "lean", fixed, env={"LEAN_PATH": str(work)}, fail=False)
        diagnostic = result.stdout + result.stderr
        require(result.returncode != 0 and "type mismatch" in diagnostic.lower()
                and name in diagnostic,
                "Weakened proposition did not fail its fixed contract: " + diagnostic)
        controls.append(name + "_weakened_to_true")
    return controls


def export_controls(source, trace):
    controls = []
    def reject(fn, name):
        controls.append(gate.expect_rejection(fn, name))
    lines = source.splitlines()
    reject(lambda: observations("\n".join(lines[:-1])), "truncated_boundary_table")
    duplicate = lines.copy()
    duplicate[-1] = duplicate[-2]
    reject(lambda: observations("\n".join(duplicate)), "duplicate_boundary_row")
    swapped = lines.copy()
    swapped[-1], swapped[-2] = swapped[-2], swapped[-1]
    reject(lambda: observations("\n".join(swapped)), "reordered_boundary_rows")
    invalid = lines.copy()
    row = 1 + 2880 + 512
    fields = invalid[row].split(",")
    fields[5] = "3"  # Option Bool codes are exactly 0, 1, or 2.
    invalid[row] = ",".join(fields)
    reject(lambda: observations("\n".join(invalid)), "invalid_relabel_projection_code")
    short = deepcopy(trace)
    short["states"][0]["results"].pop()
    reject(lambda: gate.parse_itf(short, CELLS), "truncated_quint_trace")
    invalid_trace = deepcopy(trace)
    invalid_trace["states"][0]["results"][-1] = {"#bigint": "00"}
    reject(lambda: gate.parse_itf(invalid_trace, CELLS), "noncanonical_quint_integer")
    failed = deepcopy(trace)
    failed["#meta"]["status"] = "error"
    reject(lambda: gate.parse_itf(failed, CELLS), "unsuccessful_quint_trace")
    return controls


def fingerprint(modules):
    paths = {LEAN / (m.replace(".", "/") + ".lean") for m in modules}
    paths.update(ROOT / p for p in (
        "formal/lean/lean-toolchain", "formal/lean/lakefile.toml", "formal/lean/lake-manifest.json",
        "formal/quint/package.json", "formal/quint/package-lock.json",
        "formal/check-ida-projection.py", "formal/check-ida-act-registry.py",
        "formal/check-ida.py", "formal/check-lean-axioms.py", "formal/lean-axiom-audit.lean",
        "formal/ida-act-registry-wire.py", "Makefile", ".github/workflows/ida-projection.yml",
        "formal/lean-proof-claims.json", "docs/research/ida-projection.md",
        "docs/plain-english/UsulTest/IDAProjection.md",
        "docs/plain-english/UsulTest/IDAProjectionContracts.md",
        "docs/plain-english/scripts/ExportIDAProjection.md",
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
        weakened = weakened_propositions(work)
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
        exports = export_controls(lean_csv, trace)
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
            # Quint 0.33.1 suppresses diagnostics with --out and omits test
            # failure reasons from that JSON. Replay the same named test with
            # console diagnostics to distinguish assertion failure from a
            # runtime error, while retaining the machine-readable inventory.
            asserted = quint("test", changed, "--backend", "typescript", "--max-samples", "1",
                             "--seed", gate.SEED, "--match", "^" + witness + "$",
                             "--verbosity", "2", fail=False)
            diagnostic = asserted.stdout + asserted.stderr
            require(asserted.returncode != 0 and "Assertion failed" in diagnostic
                    and re.findall(r"\[(QNT\d+)\]", diagnostic) == ["QNT508"],
                    "Mutation failed outside its intended assertion: " + name)
            record["assertion_code"] = "QNT508"
            record["assertion_diagnostic"] = diagnostic
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
            "scope_cases": 2880, "pair_cases": 512, "relabel_cases": 8,
            "unattested_cases": 16, "rows": ROWS, "comparison_cells": len(values),
            "proofs": sorted(PROOFS), "mutations": sorted(mutants),
            "boundary_proofs": sorted(BOUNDARY_PROOFS),
            "fixed_boundary_contracts": sorted(BOUNDARY_CONTRACTS),
            "weakened_propositions": weakened, "export_controls": exports,
            "boundary": "Synthetic information-dependence and finite extension controls. "
                        "They do not establish source interpretation or evidence admission.",
        }
        (RECEIPT / "lean.csv").write_text(lean_csv)
        for name, data in (("quint.itf", trace), ("tests", tests), ("mutants", mutants),
                           ("compiled-axioms", declarations), ("report", report)):
            (RECEIPT / (name + ".json")).write_text(json.dumps(data, indent=2) + "\n")
    print(f"ACT-03: {len(values)} matching cells, {len(PROOFS)} proof obligations and witnesses,"
          f" {len(mutants)} rejected mutations at {revision}.")


if __name__ == "__main__":
    main()
