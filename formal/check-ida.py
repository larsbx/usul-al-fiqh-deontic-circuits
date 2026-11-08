#!/usr/bin/env python3
"""Replay the scoped IDA foundation with pinned tools and independent exports.

This gate compares results; it does not implement a third ruling calculus.
Its receipts establish properties of the declared model, not source fidelity,
evidence authentication, agency behavior, or an application's refinement.
"""

import csv
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
LEAN = ROOT / "formal/lean"
QUINT = ROOT / "formal/quint"
CLI = QUINT / "node_modules/@informalsystems/quint/dist/src/cli.js"
RECEIPTS = ROOT / ".cache/ida"
SEED = "20261108"
BASE_ROW_COUNT = 25 + 25 + 5 + 8 * 33 * 33
TARGET_COUNT = 28
TARGET_PREMISE_COUNT = 6
ROW_COUNT = BASE_ROW_COUNT + TARGET_COUNT + TARGET_COUNT * TARGET_COUNT * TARGET_PREMISE_COUNT
INPUTS = (
    "formal/check-ida.py",
    "formal/check-lean-axioms.py",
    "formal/lean-axiom-audit.lean",
    "formal/lean/Usul/Hukm.lean",
    "formal/lean/Usul/IDA.lean",
    "formal/lean/UsulTest/IDA.lean",
    "formal/lean/UsulTest/IDAContracts.lean",
    "formal/lean/scripts/ExportIDA.lean",
    "formal/lean/lakefile.toml",
    "formal/lean/lake-manifest.json",
    "formal/lean/lean-toolchain",
    "formal/lean/Usul.lean",
    "formal/lean/UsulTest.lean",
    "formal/quint/ida.qnt",
    "formal/quint/ida-table.qnt",
    "formal/quint/package.json",
    "formal/quint/package-lock.json",
    "docs/research/islamic-deontic-algebra-spec.md",
    "docs/research/ida-foundation.md",
    "docs/plain-english/Usul/IDA.md",
    "docs/plain-english/UsulTest/IDA.md",
    "docs/plain-english/UsulTest/IDAContracts.md",
    "docs/plain-english/scripts/ExportIDA.md",
    "Makefile",
    ".github/workflows/ida.yml",
)


def require(condition, message):
    if not condition:
        raise ValueError(message)


def command(args, cwd=ROOT, env=None, allow_failure=False):
    result = subprocess.run(
        [str(a) for a in args], cwd=cwd, text=True,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=240,
        env={**os.environ, "NO_COLOR": "1", **(env or {})},
    )
    if result.returncode != 0 and not allow_failure:
        raise ValueError(f"Command failed ({result.returncode}): {args}\n"
                         f"{result.stdout}\n{result.stderr}")
    return result


def lake(*args, **kwargs):
    return command(["lake", *args], cwd=LEAN, **kwargs)


def quint(*args, **kwargs):
    return command(["node", CLI, *args], **kwargs)


def fingerprint():
    return {name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest()
            for name in INPUTS}


def runtime_overrides():
    # Preserve the trust boundary when a local executor needs a loader shim.
    # Normal hosted CI has no override. Do not record unrelated environment data.
    libraries = [entry for entry in re.split(r"[:\s]+", os.environ.get("LD_PRELOAD", "")) if entry]
    return {"LD_PRELOAD": [{"path": str(Path(entry).resolve()),
                            "sha256": hashlib.sha256(Path(entry).read_bytes()).hexdigest()}
                           for entry in libraries]}


def expected_rows():
    for section in ("meet", "join"):
        for a in range(5):
            for b in range(5):
                yield section, a, b, 0
    for a in range(5):
        yield "sigma", a, 0, 0
    for key in range(8):
        for left in range(33):
            for right in range(33):
                yield "refine", key, left, right
    for target in range(TARGET_COUNT):
        yield "target_admit", target, 0, 0
    for left in range(TARGET_COUNT):
        for right in range(TARGET_COUNT):
            for premise in range(TARGET_PREMISE_COUNT):
                yield "target_refine", left, right, premise


def result_limit(section):
    return {"meet": 4, "join": 4, "sigma": 4, "refine": 34,
            "target_admit": 1, "target_refine": 35}[section]


def parse_lean(text):
    rows = list(csv.reader(io.StringIO(text)))
    require(rows and rows.pop(0) == ["section", "a", "b", "c", "result"],
            "Unexpected Lean export header")
    require(len(rows) == ROW_COUNT, "Incomplete or oversized Lean export")
    values = []
    for row, expected in zip(rows, expected_rows()):
        require(len(row) == 5 and all(re.fullmatch(r"0|[1-9][0-9]*", v)
                                    for v in row[1:]), "Malformed Lean row")
        actual = (row[0], *(int(v) for v in row[1:4]))
        require(actual == expected, f"Noncanonical, missing, or duplicate row: {actual}")
        value = int(row[4])
        require(0 <= value <= result_limit(row[0]), "Invalid result code")
        values.append(value)
    return values


def parse_quint(trace):
    require(trace.get("#meta", {}).get("format") == "ITF"
            and trace["#meta"].get("status") == "ok", "Quint trace is not a successful ITF export")
    require(trace.get("vars") == ["results"], "Unexpected Quint state variables")
    require(len(trace.get("states", [])) == 1, "Quint export must have exactly one state")
    rows = trace["states"][0].get("results")
    require(isinstance(rows, list) and len(rows) == ROW_COUNT, "Incomplete Quint export")
    values = []
    for row, expected in zip(rows, expected_rows()):
        require(isinstance(row, dict) and set(row) == {"#bigint"}
                and isinstance(row["#bigint"], str)
                and re.fullmatch(r"0|[1-9][0-9]*", row["#bigint"]), "Invalid Quint integer")
        value = int(row["#bigint"])
        require(0 <= value <= result_limit(expected[0]), "Invalid Quint result")
        values.append(value)
    return values


def compare(lean, other):
    require(len(lean) == len(other) == ROW_COUNT, "Parity table coverage mismatch")
    for expected, left, right in zip(expected_rows(), lean, other):
        require(left == right, f"Independent model disagreement at {expected}: {left} != {right}")


def expect_rejection(fn, message):
    try:
        fn()
    except ValueError:
        return
    raise ValueError(f"Negative control accepted: {message}")


def export_controls(lean_csv, quint_json, lean_values):
    lines = lean_csv.splitlines()
    expect_rejection(lambda: parse_lean("\n".join(lines[:-1])), "truncated Lean export")
    duplicate = lines.copy()
    duplicate[2] = duplicate[1]
    expect_rejection(lambda: parse_lean("\n".join(duplicate)), "duplicate Lean input")
    truncated = json.loads(json.dumps(quint_json))
    truncated["states"][0]["results"].pop()
    expect_rejection(lambda: parse_quint(truncated), "truncated Quint export")
    invalid = json.loads(json.dumps(quint_json))
    invalid["states"][0]["results"][0] = {"#bigint": "0", "extra": 1}
    expect_rejection(lambda: parse_quint(invalid), "noncanonical Quint integer")
    unsuccessful = json.loads(json.dumps(quint_json))
    unsuccessful["#meta"]["status"] = "error"
    expect_rejection(lambda: parse_quint(unsuccessful), "unsuccessful Quint trace")
    wrong_format = json.loads(json.dumps(quint_json))
    wrong_format["#meta"]["format"] = "other"
    expect_rejection(lambda: parse_quint(wrong_format), "wrong trace format")
    wrong = lean_values.copy()
    wrong[0] = (wrong[0] + 1) % 5
    expect_rejection(lambda: compare(lean_values, wrong), "disagreeing independent result")
    return ["truncated_lean", "duplicate_lean", "truncated_quint", "noncanonical_integer",
            "unsuccessful_trace", "wrong_trace_format", "disagreement"]


def contract_vectors(values):
    # Independently stated examples guard against agreement on a shared mistake.
    vectors = [
        ("explicit_mubah", 0, 4, 4, 4),
        ("broad_constraint", 0, 31, 31, 31),
        ("required_known_refinement", 0, 31, 16, 16),
        ("partial_permission", 0, 30, 8, 8),
        ("opposed_known_rulings", 0, 16, 1, 33),
        ("missing_left", 0, 0, 31, 0),
        ("missing_right", 0, 4, 0, 0),
        ("suspended_left", 0, 32, 4, 32),
        ("suspended_right", 0, 4, 32, 32),
        ("suspension_with_missing", 0, 32, 0, 32),
    ] + [(f"different_{field}", i, 31, 31, 34)
         for i, field in enumerate(("question", "subject", "target", "context",
                                    "time", "profile", "version"), 1)]
    for name, key, left, right, expected in vectors:
        index = 55 + (key * 33 + left) * 33 + right
        require(values[index] == expected, f"Contract vector failed: {name}")
    return [name for name, *_ in vectors]


def target_contract_vectors(values):
    # Fixed fixture contract, independent of both executable target builders.
    # 0 and 1 reconstruct the same full target. 20..27 are malformed syntax.
    for code in range(TARGET_COUNT):
        require(values[BASE_ROW_COUNT + code] == (1 if code < 20 else 0),
                f"Target admission contract failed: {code}")
    vectors = [
        ("reconstructed_target", 0, 1, 0, 16),
        ("reconstruction_reverse", 1, 0, 5, 4),
        ("same_target_conflict", 0, 1, 1, 33),
        ("same_target_missing", 0, 1, 2, 0),
        ("same_target_suspended", 0, 1, 3, 32),
        ("different_act", 0, 2, 0, 34),
        ("operation_namespace", 0, 3, 0, 34),
        ("object_name", 0, 4, 0, 34),
        ("object_namespace", 0, 5, 0, 34),
        ("operand_roles", 0, 6, 0, 34),
        ("signature_roles", 0, 7, 0, 34),
        ("perform_vs_omit", 0, 8, 0, 34),
        ("omitted_act", 8, 9, 0, 34),
        ("opportunity_occurrence", 8, 10, 0, 34),
        ("opportunity_clock", 8, 11, 0, 34),
        ("opportunity_start", 8, 12, 0, 34),
        ("opportunity_end", 8, 13, 0, 34),
        ("perform_vs_affect", 0, 14, 0, 34),
        ("affect_quality", 14, 15, 0, 34),
        ("affect_object", 14, 16, 0, 34),
        ("affect_reference_sort", 14, 17, 0, 34),
        ("signature_sort", 0, 18, 0, 34),
        ("signature_order", 0, 19, 0, 34),
        ("target_scope_before_suspension", 0, 2, 4, 34),
    ]
    for malformed in range(20, 28):
        vectors.extend([
            (f"malformed_left_{malformed}", malformed, 0, 5, 35),
            (f"malformed_right_{malformed}", 0, malformed, 4, 35),
            (f"malformed_same_{malformed}", malformed, malformed, 5, 35),
        ])
    for name, left, right, premise, expected in vectors:
        index = BASE_ROW_COUNT + TARGET_COUNT + (
            (left * TARGET_COUNT + right) * TARGET_PREMISE_COUNT + premise)
        require(values[index] == expected, f"Target contract vector failed: {name}")
    return [f"target_admission_{i}" for i in range(TARGET_COUNT)] + [
        name for name, *_ in vectors]


def weakened_target_contract_control(work):
    # A weaker theorem must still compile before its fixed witness rejects it.
    source = (LEAN / "Usul/IDA.lean").read_text()
    before = """theorem target_mismatch_outOfScope (lk rk : Key) (left right : Input)
    (h : lk.target.expression ≠ rk.target.expression) :
    combine lk rk left right = .outOfScope := by
  apply (outOfScope_iff lk rk left right).2
  intro hk
  exact h (congrArg (fun key : Key => key.target.expression) hk)"""
    after = """theorem target_mismatch_outOfScope (lk rk : Key) (left right : Input)
    (h : lk.target.expression ≠ rk.target.expression) : True := by
  trivial"""
    require(source.count(before) == 1, "Target proposition probe is ambiguous")
    probe = work / "IDAWeakTargetProbe.lean"
    probe.write_text(source.replace(before, after))
    lake("env", "lean", f"--root={work}", probe, "-o", probe.with_suffix(".olean"))
    witness = work / "IDAWeakTargetContractProbe.lean"
    witness.write_text("""import IDAWeakTargetProbe
open Usul.IDA
example : ∀ (lk rk : Key) (left right : Input),
    lk.target.expression ≠ rk.target.expression →
      combine lk rk left right = .outOfScope :=
  Usul.IDA.target_mismatch_outOfScope
""")
    result = lake("env", "lean", witness, env={"LEAN_PATH": str(work)}, allow_failure=True)
    diagnostic = result.stdout + result.stderr
    require(result.returncode != 0 and "type mismatch" in diagnostic.lower()
            and "target_mismatch_outOfScope" in diagnostic,
            f"Weakened target contract did not fail for the expected reason:\n{diagnostic}")
    return "IDAWeakTargetContractProbe"


def compiled_audit(work):
    # Reuse the repository's compiled-environment inventory and strict parser.
    spec = importlib.util.spec_from_file_location("ida_axiom_gate", ROOT / "formal/check-lean-axioms.py")
    audit = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(audit)
    body = (ROOT / "formal/lean-axiom-audit.lean").read_text()
    env = {"LEAN_PATH": str(work)}
    owned_modules = {"Usul.Hukm", "Usul.IDA", "UsulTest.IDA", "UsulTest.IDAContracts",
                     "scripts.ExportIDA"}
    # A project source must never masquerade as an exempt standard-library root.
    for root in ("Init", "Lean", "Std"):
        require(not (LEAN / root).exists() and not (LEAN / f"{root}.lean").exists(),
                f"Local source shadows standard library root {root}")

    def inspect(imports, roots, expected):
        source = work / "InspectIDA.lean"
        allowed = sorted(owned_modules | set(expected))
        source.write_text("import Lean\n" + "".join(f"import {m}\n" for m in imports)
                          + f"private def auditRoots : List String := {json.dumps(roots)}\n"
                          + f"private def allowedProjectImports : List String := {json.dumps(allowed)}\n"
                          + "open Lean Elab Command\n"
                          + "run_cmd do\n"
                          + "  for name in (← getEnv).allImportedModuleNames do\n"
                          + "    unless [\"Init\", \"Lean\", \"Std\"].contains name.getRoot.toString || "
                          + "allowedProjectImports.contains name.toString do\n"
                          + "      throwError m!\"Unexpected project import: {name}\"\n" + body)
        result = lake("env", "lean", source, env=env)
        require(not result.stderr.strip(), f"Unexpected audit diagnostics: {result.stderr}")
        return audit.parse_inventory(result.stdout, set(expected))

    modules = ["Usul.Hukm", "Usul.IDA", "UsulTest.IDA", "UsulTest.IDAContracts"]
    declarations = inspect(["UsulTest.IDAContracts"], ["Usul", "UsulTest"], modules)
    target = work / "scripts/ExportIDA.olean"
    target.parent.mkdir()
    build = lake("env", "lean", "scripts/ExportIDA.lean", "-o", target)
    require("declaration uses `sorry`" not in build.stdout + build.stderr,
            "Exporter contains an admitted proof")
    declarations.extend(inspect(["scripts.ExportIDA"], ["scripts"], ["scripts.ExportIDA"]))
    theorems = {d["name"] for d in declarations if d["kind"] == "theorem"}
    require(required_theorems() <= theorems,
            f"Missing required IDA proof obligations: {sorted(required_theorems() - theorems)}")
    witnesses = {"UsulTest.IDAContracts.require_" + name.replace(".", "_")
                 for name in required_theorems()}
    require(witnesses <= theorems, f"Missing typed proof contracts: {sorted(witnesses - theorems)}")

    # Real compiled controls include an unused private axiom, not just a named theorem.
    probes = {
        "IDAPrivateAxiomProbe": "private axiom hidden : True\n",
        "IDASorryProbe": "theorem admitted : True := by sorry\n",
    }
    for name, contents in probes.items():
        source = work / f"{name}.lean"
        source.write_text(contents)
        lake("env", "lean", f"--root={work}", source, "-o", work / f"{name}.olean")
        try:
            inspect([name], [name], [name])
        except ValueError as exc:
            require("Disallowed Lean declarations or axiom dependencies" in str(exc),
                    f"Probe failed for an unrelated reason: {exc}")
        else:
            raise ValueError(f"Compiled axiom control accepted {name}")
    dependency = work / "IDAUnexpectedDependency.lean"
    dependency.write_text("theorem harmless : True := True.intro\n")
    lake("env", "lean", f"--root={work}", dependency, "-o", dependency.with_suffix(".olean"))
    wrapper = work / "IDAImportProbe.lean"
    wrapper.write_text("import IDAUnexpectedDependency\ntheorem expected : True := True.intro\n")
    lake("env", "lean", f"--root={work}", wrapper, "-o", wrapper.with_suffix(".olean"), env=env)
    try:
        inspect(["IDAImportProbe"], ["IDAImportProbe"], ["IDAImportProbe"])
    except ValueError as exc:
        require("Unexpected project import: IDAUnexpectedDependency" in str(exc),
                f"Import probe failed for an unrelated reason: {exc}")
    else:
        raise ValueError("Undeclared dependency passed the compiled import boundary")
    return {"modules": modules + ["scripts.ExportIDA"],
            "allowed_axioms": sorted(audit.ALLOWED), "declarations": declarations,
            "required_theorems": sorted(required_theorems()),
            "typed_contracts": sorted(witnesses),
            "allowed_project_imports": sorted(owned_modules),
            "negative_controls": list(probes) + ["IDAImportProbe",
                                 weakened_target_contract_control(work)]}


def semantic_controls(work):
    # Filled with exact changes to the independent Quint relation. Each mutant
    # must typecheck and fail its named assertion, rather than fail to start.
    source = (QUINT / "ida.qnt").read_text()
    mutations = semantic_mutations()
    results = []
    for name, before, after, test in mutations:
        require(source.count(before) == 1, f"Ambiguous semantic mutation: {name}")
        directory = work / name
        directory.mkdir()
        (directory / "ida.qnt").write_text(source.replace(before, after))
        quint("typecheck", "ida.qnt", cwd=directory)
        result = quint("test", "ida.qnt", "--backend", "typescript", "--max-samples", "1",
                       "--seed", SEED, "--match", f"^{test}$", "--verbosity", "2",
                       cwd=directory, allow_failure=True)
        require(result.returncode != 0, f"Semantic mutant survived: {name}")
        diagnostics = re.findall(r"Error \[(QNT\d+)\]: ([^\n]*)", result.stdout + result.stderr)
        require(diagnostics == [("QNT508", "Assertion failed")],
                f"Mutant failed for a nonsemantic reason: {name}\n{result.stdout}\n{result.stderr}")
        require(f"1) {test} failed after 1 test(s)" in result.stdout,
                f"Required assertion did not fail: {name}")
        results.append({"name": name, "test": test, "failure": "QNT508 Assertion failed"})
    return results


def required_tests():
    return {
        "latticeLawsTest", "sigmaLawsTest", "codecRoundtripTest", "invalidCodeTest",
        "missingPremiseTest", "suspensionTest", "partialPermissionTest", "conflictTest",
        "commutativeRefinementTest", "keyScopeTest",
        "targetAdmissionTest", "targetIdentityTest", "targetScopeTest", "targetBoundaryTest",
    }


def required_theorems():
    algebra = {
        "meet_le_left", "meet_le_right", "le_meet_iff", "left_le_join", "right_le_join",
        "join_le_iff", "meet_comm", "join_comm", "meet_assoc", "join_assoc",
        "meet_idem", "join_idem", "meet_absorb", "join_absorb", "meet_join_distrib",
        "join_meet_distrib", "meet_top", "join_bottom", "meet_bottom", "join_top",
        "bottom_le", "le_top", "sigma_involutive", "sigma_order_reversing",
        "sigma_le_sigma_iff", "sigma_meet", "sigma_join",
    }
    partial = {
        "Key.eq_iff_fields", "outOfScope_iff", "inScope_iff_all_fields", "known_result_exact",
        "known_result_subset_both", "known_result_nonempty", "known_requires_two_known",
        "missing_left_not_known", "missing_right_not_known", "suspended_left_preserved",
        "suspended_right_preserved", "conflict_iff_empty", "conflict_iff_no_common_ruling",
        "unknown_ne_all", "unknown_ne_mubah", "all_ne_mubah", "hukm_roundtrip",
        "decodeHukm_rejects", "decodeInput_rejects", "decodeConstraint_rejects_zero",
    }
    structured_targets = {
        "operation_wellFormed_parameter_roles",
        "operation_wellFormed_unique_roles",
        "action_wellFormed_operation",
        "action_wellFormed_signature",
        "action_wellFormed_references",
        "action_eq_iff_fields",
        "opportunity_wellFormed_bounds",
        "omit_wellFormed_iff",
        "perform_ne_omit",
        "perform_ne_affect",
        "omit_ne_affect",
        "perform_eq_iff",
        "omit_eq_iff",
        "affect_eq_iff",
        "target_eq_iff_expression_eq",
        "target_validate_eq_some_iff",
        "target_validate_eq_none_iff",
        "target_validate_roundTrip",
        "target_mismatch_outOfScope",
        "known_result_same_target",
    }
    scenarios = {
        "wire_tags", "all_masks_decode", "all_inputs_decode", "all_key_variants_decode",
        "missing_required", "suspension_priority", "key_priority", "intersect_compatible",
        "intersect_conflict", "all_constraint_identity_on_known", "mubah_explicit", "invalid_codes",
        "target_fixture_admission", "target_reconstruction", "target_distinctions",
        "malformed_targets_rejected", "target_selector_bounds",
    }
    return {f"Usul.IDA.{name}" for name in algebra | partial | structured_targets} | {
        f"UsulTest.IDA.{name}" for name in scenarios}


def semantic_mutations():
    return [
        ("missing_as_mubah", "else if (isMissing(left) or isMissing(right)) RNoRuling",
         "else if (isMissing(left) or isMissing(right)) RKnown(Set(M))", "missingPremiseTest"),
        ("empty_as_mubah", "if (common.size() == 0) Conflict else RKnown(common)",
         "if (common.size() == 0) RKnown(Set(M)) else RKnown(common)", "conflictTest"),
        ("union_for_intersection", "val common = leftValues.intersect(rightValues)",
         "val common = leftValues.union(rightValues)", "partialPermissionTest"),
        ("missing_time_guard", "    a.time == b.time,\n", "", "keyScopeTest"),
        ("missing_profile_guard", "    a.profile == b.profile,\n", "", "keyScopeTest"),
        ("target_namespace", "    a.space == b.space,\n", "", "targetIdentityTest"),
        ("target_operation", "    sameOperation(a.operation, b.operation),\n", "", "targetIdentityTest"),
        ("target_roles", "sameOperand(a[i], b[i])", "indices(b).exists(j => sameEntity(a[i].referent, b[j].referent))", "targetIdentityTest"),
        ("target_omitted_action", "sameAct(a.act, b.act) and sameOpportunity(a.opportunity, b.opportunity)", "sameOpportunity(a.opportunity, b.opportunity)", "targetIdentityTest"),
        ("target_occurrence", "    sameSymbol(a.occurrence, b.occurrence),\n", "", "targetIdentityTest"),
        ("target_clock", "    sameSymbol(a.clock, b.clock),\n", "", "targetIdentityTest"),
        ("target_open", "    a.opensAt == b.opensAt,\n", "", "targetIdentityTest"),
        ("target_close", "    a.closesAt == b.closesAt,\n", "", "targetIdentityTest"),
        ("target_affect_quality", "    sameSymbol(a.quality, b.quality),\n", "", "targetIdentityTest"),
        ("target_affect_object", "    sameEntity(a.concerns, b.concerns),\n", "", "targetIdentityTest"),
        ("target_reference_sort", "    a.kind == b.kind,\n", "", "targetIdentityTest"),
        ("target_signature_shape", "    operandParameters(act.operands) == act.operation.parameters,\n", "", "targetAdmissionTest"),
        ("target_empty_interval", "opportunity.opensAt < opportunity.closesAt", "opportunity.opensAt <= opportunity.closesAt", "targetAdmissionTest"),
        ("target_duplicate_roles", "    indices(operation.parameters).forall(i => indices(operation.parameters).forall(j =>\n      (i != j).implies(operation.parameters[i].role != operation.parameters[j].role))),\n", "", "targetAdmissionTest"),
        ("target_kind_collapse", "    | Perform(a) => match right {\n      | Perform(b) => sameAct(a, b)\n      | _ => false\n    }", "    | Perform(a) => match right {\n      | Perform(b) => sameAct(a, b)\n      | Omit(b) => sameAct(a, b.act)\n      | _ => false\n    }", "targetIdentityTest"),
        ("target_raw_admission", "    if (not(validTarget(leftKey.target) and validTarget(rightKey.target))) OutOfScope\n    else if (not(sameKey(leftKey, rightKey))) OutOfScope", "    if (not(sameKey(leftKey, rightKey))) OutOfScope", "targetBoundaryTest"),
    ]


def main():
    if RECEIPTS.exists():
        shutil.rmtree(RECEIPTS)
    RECEIPTS.parent.mkdir(parents=True, exist_ok=True)
    revision = command(["git", "rev-parse", "HEAD"]).stdout.strip()
    hashes = fingerprint()
    overrides = runtime_overrides()
    pin = (LEAN / "lean-toolchain").read_text().strip()
    lean_version = lake("env", "lean", "--version").stdout.strip()
    require(pin.startswith("leanprover/lean4:v") and lean_version.startswith(
        f"Lean (version {pin.removeprefix('leanprover/lean4:v')},"), "Lean pin mismatch")
    manifest = json.loads((QUINT / "package.json").read_text())
    lock = json.loads((QUINT / "package-lock.json").read_text())
    require(manifest["devDependencies"]["@informalsystems/quint"] == "0.33.1"
            and lock["packages"]["node_modules/@informalsystems/quint"]["version"] == "0.33.1",
            "Unexpected Quint dependency pin")
    quint_version = quint("--version").stdout.strip()
    require(quint_version == "0.33.1", "Quint executable does not match lock")

    with tempfile.TemporaryDirectory(prefix="ida-check-", dir=RECEIPTS.parent) as temporary:
        work = Path(temporary)
        build = lake("build", "Usul.IDA", "UsulTest.IDA", "UsulTest.IDAContracts")
        require("declaration uses `sorry`" not in build.stdout + build.stderr,
                "Lean emitted an admitted-proof diagnostic")
        require(not json.loads((LEAN / "lake-manifest.json").read_text()).get("packages"),
                "The scoped IDA core unexpectedly depends on external Lean packages")
        quint("typecheck", QUINT / "ida.qnt")
        quint("typecheck", QUINT / "ida-table.qnt")
        tests_path = work / "quint-tests.json"
        quint("test", QUINT / "ida.qnt", "--backend", "typescript", "--max-samples", "1",
              "--seed", SEED, "--out", tests_path)
        tests = json.loads(tests_path.read_text())
        require(tests.get("stage") == "testing" and tests.get("failed") == [],
                "Quint did not complete its deterministic tests")
        require(all(tests.get(field, []) == [] for field in ("ignored", "warnings", "errors")),
                "Quint reported an ignored test, warning, or error")
        require(set(tests.get("passed", [])) == required_tests()
                and len(tests["passed"]) == len(required_tests()), "Missing or unexpected Quint tests")
        print(f"IDA: pinned Lean and Quint; {len(tests['passed'])} deterministic tests passed.", flush=True)

        lean_csv = lake("env", "lean", "--run", "scripts/ExportIDA.lean").stdout
        lean_values = parse_lean(lean_csv)
        itf = work / "quint.itf.json"
        quint("run", QUINT / "ida-table.qnt", "--main", "idaTable", "--backend", "typescript", "--max-samples", "1",
              "--max-steps", "0", "--seed", SEED, "--out-itf", itf, "--verbosity", "0")
        quint_json = json.loads(itf.read_text())
        quint_values = parse_quint(quint_json)
        compare(lean_values, quint_values)
        vectors = contract_vectors(lean_values) + target_contract_vectors(lean_values)
        contract_vectors(quint_values)
        target_contract_vectors(quint_values)
        parser_controls = export_controls(lean_csv, quint_json, lean_values)
        print(f"IDA: independent agreement on all {ROW_COUNT} declared inputs.", flush=True)
        axioms = compiled_audit(work)
        mutants = semantic_controls(work)
        require(fingerprint() == hashes and runtime_overrides() == overrides
                and command(["git", "rev-parse", "HEAD"]).stdout.strip() == revision,
                "Inputs changed during verification")
        matches_head = all(
            result.returncode == 0 and hashlib.sha256(result.stdout).hexdigest() == expected
            for name, expected in hashes.items()
            for result in [subprocess.run(["git", "show", f"HEAD:{name}"], cwd=ROOT,
                                          stdout=subprocess.PIPE, stderr=subprocess.PIPE)]
        )
        report = {
            "schema": "usul.ida.structured-targets.v1", "status": "passed", "revision": revision,
            "inputs_match_head": matches_head, "source_sha256": hashes,
            "runtime_overrides": overrides,
            "tools": {"lean_pin": pin, "lean": lean_version, "quint": quint_version,
                      "node": command(["node", "--version"]).stdout.strip()},
            "coverage": {"meet_pairs": 25, "join_pairs": 25, "sigma_inputs": 5,
                         "refinement_inputs": 8 * 33 * 33,
                         "target_admission_inputs": TARGET_COUNT,
                         "target_refinement_inputs": TARGET_COUNT * TARGET_COUNT * TARGET_PREMISE_COUNT,
                         "target_cases": "20 wellformed entries (0 and 1 identical); 8 malformed entries",
                         "target_boundary_tag": "35 is rejected target syntax, not a ruling or Result",
                         "total_inputs": ROW_COUNT,
                         "key_family": "fixed baseline left key; equal right key or one changed field; target is structured",
                         "input_codes": "0 no ruling; 1..31 nonempty status sets; 32 suspension"},
            "quint_tests": sorted(required_tests()), "parser_controls": parser_controls,
            "contract_vectors": vectors,
            "semantic_mutants": mutants,
            "compiled_audit": {"modules": axioms["modules"],
                               "declarations": len(axioms["declarations"]),
                               "theorems": sum(d["kind"] == "theorem" for d in axioms["declarations"]),
                               "required_obligations": len(required_theorems()),
                               "negative_controls": axioms["negative_controls"]},
            "boundary": {
                "proved": "the declared algebra, structured target validation, and conjunction model",
                "agreement": "complete within the explicitly enumerated wire domain",
                "not_established": ["source interpretation", "evidence authentication",
                                    "operation-signature authority", "reference resolution",
                                    "opportunity-to-context consistency", "general inference engine",
                                    "agency changes", "runtime refinement"],
            },
        }
        staged = work / "receipts"
        staged.mkdir()
        (staged / "report.json").write_text(json.dumps(report, indent=2) + "\n")
        (staged / "compiled-axioms.json").write_text(json.dumps(axioms, indent=2) + "\n")
        (staged / "lean.csv").write_text(lean_csv)
        shutil.copyfile(itf, staged / "quint.itf.json")
        shutil.copyfile(tests_path, staged / "quint-tests.json")
        staged.rename(RECEIPTS)
        print(f"IDA: PASS; {report['compiled_audit']['theorems']} audited theorems, "
              f"{len(mutants)} semantic mutants rejected; inputs_match_head={matches_head}.")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, subprocess.SubprocessError) as exc:
        raise SystemExit(f"IDA verification failed: {exc}") from exc
