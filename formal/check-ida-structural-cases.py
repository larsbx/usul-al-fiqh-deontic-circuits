#!/usr/bin/env python3
"""Verify the bounded ACT-08 structural examples at one exact source revision."""

from copy import deepcopy
import csv
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
FIXTURE = "UsulTest.IDAStructuralCases"
CONTRACTS = "UsulTest.IDAStructuralCasesContracts"
MODEL = QUINT / "ida-structural-cases.qnt"
OUTPUT = ROOT / ".cache/ida-structural-cases"
CATALOG = "corpus/proposals/fiqh-acts/reference.json"
FAMILIES = (
    ("registry", (9, 1, 1), (16,)),
    ("qualification", (2, 16, 1), (1, 7, 7, 2, 1, 1, 1, 12)),
    ("occurrence", (2, 2, 10), (2, 2, 2, 1, 1, 12, 12, 12)),
)
ROWS, CELLS = 81, 585
PROOF_NAMES = ('revoke_unresolved',
 'registry_controls',
 'substitution_retains_occurrence',
 'substitution_retains_profile',
 'two_stage_inquiry',
 'projection_retains_occurrence',
 'projection_view_contract',
 'distinct_occurrences_remain_distinct',
 'cross_occurrence_certificate_rejected',
 'changed_context_receipt_rejected',
 'occurrence_matrix',
 'qualification_matrix',
 'fresh_qualification_authority_admits',
 'native_models',
 'native_conditional_sound',
 'hidden_exception_same_core',
 'same_kind_distinct_occurrences')
TESTS = {'certificateAndInputControlsTest',
 'crossOccurrenceCertificateTest',
 'finiteTableShapeTest',
 'nativeAdmissionTest',
 'occurrenceProjectionTest',
 'qualificationDependencyTest',
 'qualificationProjectionTest',
 'receiptAuthorityTest',
 'sameProfileSubstitutionTest',
 'sourceEvidenceAndGrantTest',
 'staleContextTest',
 'unresolvedMandateTest'}
MUTANTS = {'coerce_unresolved_role': ('| OpenSort => UnresolvedSignature',
                            '| OpenSort => ResolvedSignature(parameters.append({ name: role.name, '
                            'sort: ObligationSort }))',
                            'unresolvedMandateTest'),
 'drop_qualification': ('pure def reportsRead(s: Snapshot): List[Report] = s.reports',
                        'pure def reportsRead(s: Snapshot): List[Report] = s.reports.select(q => '
                        'q.predicate != exceptionKind)',
                        'qualificationDependencyTest'),
 'erase_occurrence': ('o.with("occurrence", o.occurrence)',
                      'o.with("occurrence", named("synthetic.event", "one"))',
                      'occurrenceProjectionTest'),
 'ignore_stale_context': ('a.contexts.select(s => s.scope.contextId == expected.scope.contextId) '
                          '== List(expected)',
                          'true',
                          'staleContextTest'),
 'reuse_cross_occurrence_certificate': ('c.application == app and c.premise.scope == '
                                        'premiseScope(app.snapshot)',
                                        'c.application.snapshot.scope.target.act == '
                                        'app.snapshot.scope.target.act',
                                        'crossOccurrenceCertificateTest')}
WEAKEN_BEFORE = 'theorem same_kind_distinct_occurrences :\n    (destinationSnapshot false true 9).envelope.key = (destinationSnapshot true true 9).envelope.key ∧\n    (destinationSnapshot false true 9).target ≠ (destinationSnapshot true true 9).target := by decide'
WEAKEN_AFTER = 'theorem same_kind_distinct_occurrences : True := by trivial'


def fingerprints(modules):
    paths = {f"formal/lean/{name.replace('.', '/')}.lean" for name in modules}
    paths.update({
        CATALOG, "Makefile", ".github/workflows/ida-pilot.yml",
        ".github/workflows/ida-structural-cases.yml", "formal/lean/UsulTest.lean",
        "formal/check-ida-structural-cases.py", "formal/check-ida-pilot.py",
        "formal/test-ida-pilot.py", "formal/check-ida-act-registry.py",
        "formal/check-ida.py", "formal/check-lean-axioms.py", "formal/lean-axiom-audit.lean",
        "formal/lean-proof-claims.json",
        "formal/ida-act-registry-wire.py", "formal/lean/lean-toolchain",
        "formal/lean/lakefile.toml", "formal/lean/lake-manifest.json",
        "formal/quint/package.json", "formal/quint/package-lock.json",
        str(MODEL.relative_to(ROOT)), "docs/research/ida-structural-cases.md",
        "docs/plain-english/UsulTest/IDAStructuralCases.md",
        "docs/plain-english/UsulTest/IDAStructuralCasesContracts.md",
    })
    return {name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest()
            for name in sorted(paths)}


def expected_rows():
    for family, dimensions, maxima in FAMILIES:
        for coordinates in product(*(range(n) for n in dimensions)):
            yield (family, *coordinates), maxima


def observations(source):
    lines = source.splitlines()
    require(len(lines) >= 2, "Missing exported signature or table")
    signature = json.loads(lines[0])
    require(type(signature) is list and all(type(v) is str for v in signature),
            "Malformed candidate signature")
    table = list(csv.reader(lines[1:]))
    require(table and table.pop(0) == ["family", "a", "b", "c", "values"],
            "Unexpected structural table header")
    require(len(table) == ROWS, "Incomplete structural case table")
    values = []
    for row, (key, maxima) in zip(table, expected_rows(), strict=True):
        require(len(row) == 4 + len(maxima) and row[:4] == [str(v) for v in key],
                f"Missing, duplicate, or reordered row: {key}")
        require(all(re.fullmatch(r"0|[1-9][0-9]*", value) for value in row[4:]),
                f"Noncanonical numeric output at {key}")
        cells = list(map(int, row[4:]))
        require(all(0 <= value <= maximum for value, maximum in zip(cells, maxima, strict=True)),
                f"Unexpected result code at {key}")
        values.extend(cells)
    require(len(values) == CELLS, "Unexpected comparison width")
    return signature, values


def candidate_binding(signature):
    catalogue = json.loads((ROOT / CATALOG).read_bytes())
    candidates = [c for c in catalogue["proposals"] if c["proposed_kind_id"] == "agency.revoke"]
    require(len(candidates) == 1, "Expected one exact agency-revocation candidate")
    candidate, = candidates
    bridge = candidate["ida_bridge"]
    key = bridge["operation_symbol"]
    roles = bridge["parameters"]
    expected = [key["space"], key["name"], str(candidate["proposed_definition_version"])]
    expected += [value for row in roles for value in
                 (row["role"], row["ref_kind"] if row["ref_kind"] is not None else "unresolved")]
    require(signature == expected, "Lean definition differs from the source-linked candidate")
    require(candidate["status"] == bridge["status"] == "candidate"
            and candidate["admitted"] is False and bridge["profile_admitted"] is False
            and bridge["representable"] is False, "Candidate admission status changed")
    require({row["role"] for row in roles if row["ref_kind"] is None}
            == {"mandate_reference", "manifestation"}, "Unresolved candidate roles changed")
    loci = candidate.get("source_loci")
    require(type(loci) is list and loci and all(
        type(row.get("locator")) is str and row["locator"]
        and row.get("mapping_status") == "candidate" for row in loci),
        "Candidate has no retained source-linked interpretation status")
    return {"kind": candidate["proposed_kind_id"], "signature": signature,
            "status": candidate["status"], "admitted": False, "source_loci": loci}


def inspect(work, imports, roots, expected):
    path = work / "Inspect.lean"
    path.write_text("import Lean\n" + "".join(f"import {name}\n" for name in imports)
                    + "private def auditRoots : List String := " + json.dumps(roots) + "\n"
                    + (ROOT / "formal/lean-axiom-audit.lean").read_text())
    result = lake("env", "lean", path, env={"LEAN_PATH": str(work)})
    require(not result.stderr.strip(), "Unexpected audit diagnostics: " + result.stderr)
    return gate.AUDIT.parse_inventory(result.stdout, expected)


def audit(work, modules):
    inventory = inspect(work, [CONTRACTS], ["Usul", "UsulTest"], modules)
    names = {d["name"] for d in inventory if d["kind"] == "theorem"}
    proofs = {FIXTURE + "." + name for name in PROOF_NAMES}
    wrappers = {CONTRACTS + ".require_" + name for name in PROOF_NAMES}
    require(proofs and proofs <= names, "Missing structural proof obligations")
    require(wrappers <= names, "Missing fixed typed proposition contracts")
    controls = []
    for name, source in {
        "StructuralPrivateAxiomProbe": "private axiom hidden : True\n",
        "StructuralSorryProbe": "theorem missing : True := by sorry\n",
    }.items():
        path = work / (name + ".lean")
        path.write_text(source)
        lake("env", "lean", "--root=" + str(work), path, "-o", path.with_suffix(".olean"))
        try:
            inspect(work, [name], [name], {name})
        except ValueError as exc:
            require("Disallowed Lean declarations or axiom dependencies" in str(exc),
                    "Compiled audit probe failed for an unrelated reason")
            controls.append(name)
        else:
            raise ValueError("Compiled invalid proof escaped the audit")
    return inventory, sorted(proofs), sorted(wrappers), controls


def weakened_proposition(work):
    source = (LEAN / "UsulTest/IDAStructuralCases.lean").read_text()
    require(WEAKEN_BEFORE and source.count(WEAKEN_BEFORE) == 1, "Ambiguous proposition control")
    weak = work / "WeakStructuralCases.lean"
    weak.write_text(source.replace(WEAKEN_BEFORE, WEAKEN_AFTER))
    compiled = lake("env", "lean", "--root=" + str(work), weak, "-o", weak.with_suffix(".olean"))
    require("declaration uses " + chr(96) + "sorry" + chr(96) not in compiled.stdout + compiled.stderr,
            "Weakening probe must compile without an admitted proof")
    fixed = work / "FixedStructuralContracts.lean"
    contracts = (LEAN / "UsulTest/IDAStructuralCasesContracts.lean").read_text()
    require(contracts.count("import " + FIXTURE + "\n") == 1, "Ambiguous fixed-contract import")
    fixed.write_text(contracts.replace("import " + FIXTURE + "\n", "import WeakStructuralCases\n", 1))
    result = lake("env", "lean", fixed, env={"LEAN_PATH": str(work)}, fail=False)
    diagnostic = result.stdout + result.stderr
    require(result.returncode != 0 and "type mismatch" in diagnostic.lower()
            and "same_kind_distinct_occurrences" in diagnostic,
            "Weakened proposition did not fail the intended fixed contract: " + diagnostic)
    return "same_kind_distinct_occurrences_weakened_to_true"


def run_tests(model, output, names, fail=True):
    result = quint("test", model, "--main", "idaStructuralCases", "--backend", "typescript",
                   "--max-samples", "1", "--seed", gate.SEED,
                   "--match", "^(?:" + "|".join(sorted(names)) + ")$", "--out", output, fail=fail)
    record = json.loads(output.read_bytes())
    return result, {key: record.get(key) for key in
                    ("stage", "passed", "failed", "ignored", "warnings", "errors")}


def export_controls(source, trace):
    controls = []
    def reject(fn, name):
        controls.append(gate.expect_rejection(fn, name))
    lines = source.splitlines()
    reject(lambda: observations("\n".join(lines[:-1])), "truncated_lean_table")
    duplicate = lines.copy()
    duplicate[3] = duplicate[2]
    reject(lambda: observations("\n".join(duplicate)), "duplicate_lean_row")
    swapped = lines.copy()
    swapped[2], swapped[3] = swapped[3], swapped[2]
    reject(lambda: observations("\n".join(swapped)), "reordered_lean_row")
    invalid = lines.copy()
    invalid[2] = invalid[2].rsplit(",", 1)[0] + ",99"
    reject(lambda: observations("\n".join(invalid)), "unexpected_lean_result")
    short = deepcopy(trace)
    short["states"][0]["results"].pop()
    reject(lambda: gate.parse_itf(short, CELLS), "truncated_quint_trace")
    invalid_trace = deepcopy(trace)
    invalid_trace["states"][0]["results"][0] = {"#bigint": "00"}
    reject(lambda: gate.parse_itf(invalid_trace, CELLS), "noncanonical_quint_integer")
    failed = deepcopy(trace)
    failed["#meta"]["status"] = "error"
    reject(lambda: gate.parse_itf(failed, CELLS), "unsuccessful_quint_trace")
    return controls


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    (OUTPUT / "report.json").unlink(missing_ok=True)
    require(PROOF_NAMES and TESTS and MUTANTS and WEAKEN_BEFORE,
            "Structural verification contract is incomplete")
    revision = gate.command(["git", "rev-parse", "HEAD"]).stdout.strip()
    modules = gate.lean_closure([CONTRACTS])
    hashes, overrides = fingerprints(modules), gate.COMMON.runtime_overrides()
    lean_version = lake("env", "lean", "--version").stdout.strip()
    quint_version = quint("--version").stdout.strip()
    require(lean_version.startswith("Lean (version 4.34.1,") and quint_version == "0.33.1",
            "Unexpected Lean or Quint version")
    build = lake("build", CONTRACTS)
    require("declaration uses " + chr(96) + "sorry" + chr(96) not in build.stdout + build.stderr,
            "Admitted structural proof diagnostic")
    print("ACT-08 structural cases: Lean fixtures and fixed contracts compiled.", flush=True)
    quint("typecheck", MODEL)
    with tempfile.TemporaryDirectory(prefix="ida-structural-", dir=OUTPUT.parent) as directory:
        work = Path(directory)
        inventory, proofs, wrappers, proof_controls = audit(work, modules)
        weakened = weakened_proposition(work)
        export = work / "Export.lean"
        export.write_text(f"""import Lean
import {FIXTURE}
open Lean {FIXTURE}
def main : IO Unit := do
  IO.println (toJson candidateSignature).compress
  IO.println "family,a,b,c,values"
  for (family, coordinates, values) in rows do
    IO.println (String.intercalate "," ([family] ++ coordinates.map toString ++ values.map toString))
""")
        lean_csv = lake("env", "lean", "--run", export).stdout
        signature, values = observations(lean_csv)
        candidate = candidate_binding(signature)
        quint("run", MODEL, "--main", "idaStructuralCases", "--backend", "typescript",
              "--max-samples", "1", "--max-steps", "0", "--seed", gate.SEED,
              "--out-itf", work / "trace.json", "--verbosity", "0")
        trace = json.loads((work / "trace.json").read_bytes())
        other = gate.parse_itf(trace, CELLS)
        for index, (left, right) in enumerate(zip(values, other, strict=True)):
            require(left == right, f"Lean/Quint disagreement at cell {index}: {left} vs {right}")
        print(f"ACT-08 structural cases: independent agreement on {ROWS} rows / {CELLS} cells.", flush=True)
        adverse_exports = export_controls(lean_csv, trace)
        _, tests = run_tests(MODEL, work / "tests.json", TESTS)
        require(tests["stage"] == "testing" and set(tests["passed"] or []) == TESTS
                and len(tests["passed"]) == len(TESTS)
                and all(not tests[k] for k in ("failed", "ignored", "warnings", "errors")),
                "Incomplete independent structural tests")
        original, mutations = MODEL.read_text(), {}
        for name, (before, after, witness) in MUTANTS.items():
            require(original.count(before) == 1, f"Ambiguous model mutation: {name}")
            changed = work / MODEL.name
            changed.write_text(original.replace(before, after))
            quint("typecheck", changed)
            result, record = run_tests(changed, work / "mutant.json", {witness}, fail=False)
            require(result.returncode != 0 and record["stage"] == "testing"
                    and record["failed"] == [witness]
                    and not record["errors"] and not record["warnings"],
                    f"Mutant survived or failed for an unrelated reason: {name}")
            mutations[name] = record
        require(fingerprints(modules) == hashes and gate.COMMON.runtime_overrides() == overrides
                and gate.command(["git", "rev-parse", "HEAD"]).stdout.strip() == revision,
                "Structural verification inputs changed during execution")
        matches = all(blob.returncode == 0 and hashlib.sha256(blob.stdout).hexdigest() == expected
                      for path, expected in hashes.items()
                      for blob in [subprocess.run(["git", "show", f"{revision}:{path}"],
                                                  cwd=ROOT, capture_output=True)])
        require(matches, "Structural receipt inputs differ from the named Git revision")
        report = {
            "schema": "usul.ida.structural-cases.verification.v1", "status": "passed",
            "revision": revision, "inputs_match_head": matches, "source_sha256": hashes,
            "runtime_overrides": overrides, "lean": lean_version, "quint": quint_version,
            "rows": ROWS, "comparison_cells": CELLS, "proofs": proofs, "typed_contracts": wrappers,
            "families": [{"name": name, "dimensions": dimensions, "width": len(maxima)}
                         for name, dimensions, maxima in FAMILIES],
            "candidate": candidate, "tests": sorted(TESTS),
            "rejected_mutants": sorted(mutations), "export_controls": adverse_exports,
            "compiled_proof_controls": proof_controls, "weakened_proposition": weakened,
            "boundary": {
                "scope": "Synthetic same-profile structural views and exact application admission.",
                "trusted_inputs": ["supplied test registry", "supplied certificate and grant authority",
                                   "source-admission environment", "fixed synthetic history"],
                "not_claimed": ["truth of attributed reports", "juristic admission of agency.revoke",
                                "general schema or profile migration", "new signed premise ingestion",
                                "complete ACT-08 acceptance"],
            },
        }
        (OUTPUT / "lean.csv").write_text(lean_csv)
        for name, data in (("quint-trace", trace), ("quint-tests", tests), ("mutants", mutations),
                           ("compiled-axioms", inventory), ("report", report)):
            (OUTPUT / (name + ".json")).write_text(json.dumps(data, indent=2) + "\n")
    print(f"ACT-08 structural cases: PASS; {len(proofs)} fixed proofs, {len(MUTANTS)} rejected mutants; "
          f"inputs_match_head={matches}; revision={revision}.", flush=True)


if __name__ == "__main__":
    main()

