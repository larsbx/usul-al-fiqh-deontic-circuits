#!/usr/bin/env python3
"""Verify the checked case presentation against compiled proofs and fresh Quint."""

from copy import deepcopy
import hashlib
import importlib.util
from itertools import product
import json
from pathlib import Path
import subprocess
import sys
import tempfile

spec = importlib.util.spec_from_file_location(
    "ida_workbench_registry_gate", Path(__file__).with_name("check-ida-act-registry.py"))
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)
pilot = gate.module("ida_workbench_pilot_gate", gate.ROOT / "formal/check-ida-pilot-trace.py")

ROOT, LEAN, require = gate.ROOT, gate.LEAN, gate.require
FIXTURE = "UsulTest.IDACaseWorkbench"
EXPORTER = "scripts.ExportIDACaseWorkbench"
CONTRACT_MODULE = "CaseWorkbenchContracts"
OUTPUT = ROOT / ".cache/ida-case-workbench-formal"
KEYS = list(product(range(16), range(4), range(6)))
CORE_PROOFS = (
    "unknown_iff", "supported_iff", "refuted_iff", "conflicted_iff",
    "signs_roundtrip", "status_roundtrip", "status_injective",
    "guard_requires_supported_refuted", "support_conflict_blocks",
    "exception_conflict_blocks", "unknown_exception_blocks", "View.exact_snapshot",
    "View.current_snapshot", "View.exact_premises", "View.exact_certificates",
    "View.all_source_occurrences", "View.explicit_report_states", "View.nonvacuous",
    "View.conditional_sound",
)
FIXTURE_PROOFS = (
    "source_bound_baseline_checked", "source_bound_destination_unchanged", "four_report_states",
    "missing_and_conflicting_reports_block", "nonvacuity_controls", "current_authority_controls",
    "kind_does_not_transfer_guard", "admission_and_robustness_do_not_imply_truth",
)
PROOFS = {"Usul.IDA.CaseWorkbench." + n for n in CORE_PROOFS} | {
    FIXTURE + "." + n for n in FIXTURE_PROOFS}
REPORT_NAMES = (
    "outsideScope", "unresolved", "fallback", "negativeSupport", "positiveSupport",
    "contestedSupport", "exception", "contestedException",
)
ASSESSMENT_NAMES = ("noCandidates", "inconsistent", "robust", "counterexample")
RESULT_NAMES = (
    "accepted", "destinationPremiseListMismatch", "destinationEvidenceMissing",
    "destinationSnapshotStale", "destinationGrantMissing", "guardRejected",
    "noCandidateHistories", "incompatibleHistories",
)
CONTRACT_SOURCE = """import UsulTest.IDACaseWorkbench
namespace CaseWorkbenchContracts
open Usul.IDA Admission Projection Semantics CaseWorkbench
variable {r : ActRegistry.Registry} {v : Context.Vocabulary}
variable {p : Plan r v} {rule : Rule} {histories : List (History v)}
theorem require_unknown (s : Signs) :
    reportStatus s = .unknown ↔ s.positive = false ∧ s.negative = false := unknown_iff s
theorem require_supported (s : Signs) :
    reportStatus s = .supported ↔ s.positive = true ∧ s.negative = false := supported_iff s
theorem require_refuted (s : Signs) :
    reportStatus s = .refuted ↔ s.positive = false ∧ s.negative = true := refuted_iff s
theorem require_conflicted (s : Signs) :
    reportStatus s = .conflicted ↔ s.positive = true ∧ s.negative = true := conflicted_iff s
theorem require_injective {a b : Signs} (h : reportStatus a = reportStatus b) : a = b :=
  status_injective h
theorem require_exact_snapshot (view : View p rule histories) :
    view.snapshot = view.receipt.admission.destination.application.snapshot := view.exact_snapshot
theorem require_current_snapshot (view : View p rule histories) :
    Context.resolve r view.receipt.admission.authority.contexts view.snapshot = .ok view.snapshot :=
  view.current_snapshot
theorem require_exact_premises (view : View p rule histories) :
    view.premises = p.destination.premises.map (·.subst p.destinationValuation.grounding) :=
  view.exact_premises
theorem require_certificate_formulas (view : View p rule histories) :
    view.receipt.admission.destination.certificates.map Certificate.formula = view.premises :=
  view.exact_certificates
theorem require_report_states (view : View p rule histories) :
    view.dependencies.scope = rule.scope ∧ reportStatus view.dependencies.support = .supported ∧
      reportStatus view.dependencies.exception = .refuted := view.explicit_report_states
theorem require_nonvacuous (view : View p rule histories) :
    compatible (Pilot.destinationPoints p histories) p.destination.premises ≠ [] := view.nonvacuous
theorem require_conditional_sound (view : View p rule histories) (h : History v)
    (empty : Valuation []) (hp : ModelsPremises h p.destinationValuation p.destination.premises) :
    Satisfies h empty view.conclusion := view.conditional_sound h empty hp
theorem require_admitted_countermodel :
    ∃ receipt : Pilot.Receipt UsulTest.IDAPilot.plan UsulTest.IDAPilot.rule (UsulTest.IDAPilot.histories 2),
      UsulTest.IDACaseWorkbench.sourceBoundTrial \"synthetic-case-workbench\" = .ok receipt ∧
      Semantics.compatible (Pilot.destinationPoints UsulTest.IDAPilot.plan (UsulTest.IDAPilot.histories 2))
        UsulTest.IDAPilot.plan.destination.premises ≠ [] ∧
      ¬ Semantics.Satisfies (Γ := []) (UsulTest.IDASemantics.history 0) (fun _ x => nomatch x)
        (present receipt).conclusion :=
  UsulTest.IDACaseWorkbench.admission_and_robustness_do_not_imply_truth
end CaseWorkbenchContracts
"""
CONTRACT_NAMES = {CONTRACT_MODULE + ".require_" + name for name in (
    "unknown", "supported", "refuted", "conflicted", "injective", "exact_snapshot",
    "current_snapshot", "exact_premises", "certificate_formulas", "report_states",
    "nonvacuous", "conditional_sound", "admitted_countermodel",
)}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def fingerprint(modules):
    paths = {f"formal/lean/{name.replace('.', '/')}.lean" for name in modules}
    paths.update(pilot.fingerprint(gate.lean_closure([pilot.FIXTURE])))
    paths.update({"formal/check-ida-case-workbench.py", "formal/lean/Usul.lean",
                  "formal/lean/UsulTest.lean"})
    workflow = ".github/workflows/ida-case-workbench.yml"
    if (ROOT / workflow).exists():
        paths.add(workflow)
    return {p: digest((ROOT / p).read_bytes()) for p in sorted(paths)}


def require_head(revision, hashes):
    for path, expected in hashes.items():
        blob = subprocess.run(["git", "show", f"{revision}:{path}"], cwd=ROOT, capture_output=True)
        require(blob.returncode == 0 and digest(blob.stdout) == expected,
                "Verification input does not match committed HEAD: " + path)


def strict_json(source):
    def pairs(items):
        result = {}
        for key, value in items:
            require(key not in result, "Duplicate JSON key: " + key)
            result[key] = value
        return result
    def invalid_constant(value):
        raise ValueError("Non-JSON numeric constant: " + value)
    return json.loads(source, object_pairs_hook=pairs, parse_constant=invalid_constant)


def expected_signs(positive, negative):
    return {"positive": positive, "negative": negative, "status":
            ("conflicted" if negative else "supported") if positive else
            ("refuted" if negative else "unknown")}


def compare_export(data, quint_values, revision):
    require(type(data) is dict and set(data) == {"schema", "revision", "synthetic", "baseline", "scenarios"},
            "Unexpected workbench envelope")
    require(data["schema"] == "ida-case-workbench-lean-v1" and data["revision"] == revision
            and data["synthetic"] is True, "Wrong workbench schema, revision, or fixture status")
    rows = data["scenarios"]
    require(type(rows) is list and len(rows) == len(KEYS), "Incomplete scenario coverage")
    require(len(quint_values) == len(KEYS) * 4 + 4, "Incomplete independent pilot coverage")
    seen = set()
    for offset, (row, key) in enumerate(zip(rows, KEYS)):
        require(type(row) is dict and set(row) == {
            "mask", "population", "authorityMode", "support", "exception", "guard",
            "reportStatus", "assessment", "result", "resultCode"}, "Unexpected scenario row shape")
        require(all(type(row[k]) is int for k in ("mask", "population", "authorityMode")),
                "Non-integer scenario key")
        actual_key = (row["mask"], row["population"], row["authorityMode"])
        require(actual_key == key and actual_key not in seen, "Missing, duplicated, reordered, or extra scenario")
        seen.add(actual_key)
        mask, _, _ = key
        for field, shift in (("support", 0), ("exception", 2)):
            signs = row[field]
            require(type(signs) is dict and set(signs) == {"positive", "negative", "status"}
                    and type(signs["positive"]) is bool and type(signs["negative"]) is bool,
                    f"Invalid report signs at {key}: {field}")
            require(signs == expected_signs(bool(mask & (1 << shift)), bool(mask & (2 << shift))),
                    f"Incorrect four-sign report status at {key}: {field}")
        guard, report, assessment, result = quint_values[offset * 4:offset * 4 + 4]
        require(guard in (0, 1) and 0 <= report < len(REPORT_NAMES)
                and 0 <= assessment < len(ASSESSMENT_NAMES) and 0 <= result < len(RESULT_NAMES),
                f"Independent output out of bounds at {key}")
        require(type(row["guard"]) is bool and row["guard"] == bool(guard)
                and row["reportStatus"] == REPORT_NAMES[report]
                and row["assessment"] == ASSESSMENT_NAMES[assessment]
                and type(row["resultCode"]) is int and row["resultCode"] == result
                and row["result"] == RESULT_NAMES[result], f"Lean export/Quint disagreement at {key}")
    require(seen == set(KEYS), "Incorrect scenario key set")
    baseline = data["baseline"]
    require(type(baseline) is dict and baseline["authorityRevision"] == revision
            and baseline["result"] == "accepted" and baseline["assessment"] == "robust"
            and baseline["guard"] is True and type(baseline["candidateHistories"]) is int
            and baseline["candidateHistories"] == 1 and type(baseline["compatibleHistories"]) is int
            and baseline["compatibleHistories"] == 1
            and baseline["support"] == expected_signs(True, False)
            and baseline["exception"] == expected_signs(False, True), "Invalid checked baseline")
    require(baseline["certificateTokens"] == [1, 2, 3, 4]
            and [(c["token"], c["side"], c["sourceId"]) for c in baseline["certificates"]]
            == [(1, "source", 1), (2, "source", 2), (3, "destination", 1), (4, "destination", 2)],
            "Baseline lost source-bound certificate occurrences")
    require([c["formula"] for c in baseline["certificates"] if c["side"] == "destination"]
            == baseline["premises"]
            and [c["formulaSyntax"] for c in baseline["certificates"] if c["side"] == "destination"]
            == baseline["premiseSyntax"], "Baseline certificate formulas differ from displayed premises")
    require(baseline["snapshot"]["representation"] and baseline["inquiry"]["target"]
            and baseline["inquiry"]["targetForm"] == "omission", "Baseline scope is missing")


def export_controls(data, values, revision):
    rejected = []
    def mutate(name, change):
        candidate = deepcopy(data)
        change(candidate)
        rejected.append(gate.expect_rejection(lambda: compare_export(candidate, values, revision), name))
    mutate("truncated_scenarios", lambda d: d["scenarios"].pop())
    mutate("extra_scenario", lambda d: d["scenarios"].append(deepcopy(d["scenarios"][0])))
    mutate("duplicate_scenario", lambda d: d["scenarios"].__setitem__(1, deepcopy(d["scenarios"][0])))
    mutate("invalid_scenario_index", lambda d: d["scenarios"][0].__setitem__("mask", 16))
    mutate("absence_promoted_to_refutation", lambda d: d["scenarios"][0]["exception"].__setitem__("status", "refuted"))
    mutate("conflict_hidden", lambda d: d["scenarios"][72]["support"].__setitem__("status", "supported"))
    mutate("unverified_guard", lambda d: d["scenarios"][0].__setitem__("guard", True))
    mutate("result_promoted", lambda d: d["scenarios"][0].__setitem__("result", "accepted"))
    mutate("result_code_promoted", lambda d: d["scenarios"][0].__setitem__("resultCode", 0))
    mutate("stale_export", lambda d: d.__setitem__("revision", "stale"))
    mutate("certificate_occurrence_removed", lambda d: d["baseline"]["certificates"].pop())
    rejected.append(gate.expect_rejection(lambda: strict_json('{"schema":1,"schema":2}'), "duplicate_json_key"))
    return rejected


def audit(work, modules):
    for name in ("Init", "Lean", "Std"):
        require(not (LEAN / name).exists() and not (LEAN / (name + ".lean")).exists(),
                "Standard-library shadow: " + name)
    contract = work / (CONTRACT_MODULE + ".lean")
    contract.write_text(CONTRACT_SOURCE)
    compiled = gate.lake("env", "lean", "--root=" + str(work), contract, "-o", contract.with_suffix(".olean"))
    require(not compiled.stderr.strip() and "sorry" not in compiled.stdout,
            "Invalid fixed proposition contracts: " + compiled.stdout + compiled.stderr)
    target = work / "scripts/ExportIDACaseWorkbench.olean"
    target.parent.mkdir()
    compiled = gate.lake("env", "lean", "scripts/ExportIDACaseWorkbench.lean", "-o", target)
    require(not compiled.stderr.strip() and "declaration uses `sorry`" not in compiled.stdout,
            "Invalid compiled exporter")
    expected = modules | {CONTRACT_MODULE}
    source = work / "InspectCaseWorkbench.lean"
    source.write_text(
        f"import Lean\nimport {FIXTURE}\nimport {EXPORTER}\nimport {CONTRACT_MODULE}\n"
        'private def auditRoots : List String := ["Usul", "UsulTest", "scripts", "CaseWorkbenchContracts"]\n'
        + "private def allowed : List String := " + json.dumps(sorted(expected)) + "\n"
        + "open Lean Elab Command\nrun_cmd do\n"
        + "  for name in (← getEnv).allImportedModuleNames do\n"
        + '    unless ["Init", "Lean", "Std"].contains name.getRoot.toString || allowed.contains name.toString do\n'
        + '      throwError m!"Unexpected project import: {name}"\n'
        + (ROOT / "formal/lean-axiom-audit.lean").read_text())
    result = gate.lake("env", "lean", source, env={"LEAN_PATH": str(work)})
    require(not result.stderr.strip(), "Unexpected audit diagnostics: " + result.stderr)
    declarations = gate.AUDIT.parse_inventory(result.stdout, expected)
    names = {d["name"] for d in declarations if d["kind"] == "theorem"}
    require(len(PROOFS) == 27 and PROOFS <= names, "Missing compiled workbench proof obligations")
    require(CONTRACT_NAMES <= names, "Missing fixed proposition contracts")
    return declarations


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    receipt = OUTPUT / "report.json"
    receipt.unlink(missing_ok=True)
    revision = gate.command(["git", "rev-parse", "HEAD"]).stdout.strip()
    modules = gate.lean_closure([FIXTURE, EXPORTER])
    hashes = fingerprint(modules)
    require_head(revision, hashes)
    overrides = gate.COMMON.runtime_overrides()
    lean = gate.lake("env", "lean", "--version").stdout.strip()
    quint = gate.quint("--version").stdout.strip()
    require(lean.startswith("Lean (version 4.34.1,") and quint == "0.33.1", "Toolchain version mismatch")
    build = gate.lake("build", FIXTURE)
    require("declaration uses `sorry`" not in build.stdout + build.stderr, "Admitted Lean proof")
    with tempfile.TemporaryDirectory(prefix="ida-case-workbench-", dir=OUTPUT.parent) as directory:
        work = Path(directory)
        declarations = audit(work, modules)
        # The dependency gate removes its old receipt, computes fresh Lean and
        # Quint cells, and requires all five independently weakened models to fail.
        pilot.main()
        dependency = strict_json((pilot.OUTPUT / "report.json").read_text())
        require(len(pilot.MUTANTS) == 5 and dependency["status"] == "passed" and dependency["inputs_match_head"] is True
                and dependency["revision"] == revision and dependency["rows"] == 384
                and dependency["comparison_cells"] == 1540
                and dependency["rejected_mutants"] == sorted(pilot.MUTANTS),
                "Fresh independent pilot acceptance is incomplete")
        mutants = strict_json((pilot.OUTPUT / "mutants.json").read_text())
        require(set(mutants) == set(pilot.MUTANTS)
                and all(record["stage"] == "testing" and record["failed"] == ["controlsTest"]
                        and all(not record[k] for k in ("passed", "ignored", "warnings", "errors"))
                        for record in mutants.values()), "Invalid independent semantic mutation failures")
        trace = strict_json((pilot.OUTPUT / "quint-trace.json").read_text())
        values = gate.parse_itf(trace, len(KEYS) * 4 + 4)
        exported = gate.lake("env", "lean", "--run", "scripts/ExportIDACaseWorkbench.lean", revision)
        require(not exported.stderr.strip(), "Unexpected exporter diagnostics: " + exported.stderr)
        data = strict_json(exported.stdout)
        compare_export(data, values, revision)
        parser_controls = export_controls(data, values, revision)
        require(hashes == fingerprint(modules) and overrides == gate.COMMON.runtime_overrides()
                and revision == gate.command(["git", "rev-parse", "HEAD"]).stdout.strip(),
                "Verification inputs changed during replay")
        require_head(revision, hashes)
        dependencies = {str((pilot.OUTPUT / name).relative_to(ROOT)): digest((pilot.OUTPUT / name).read_bytes())
                        for name in ("report.json", "quint-trace.json", "quint-controls.json", "mutants.json")}
        report = {
            "schema": "usul.ida.case-workbench.formal-verification.v1", "status": "passed",
            "revision": revision, "inputs_match_head": True, "source_sha256": hashes,
            "runtime_overrides": overrides, "lean": lean, "quint": quint,
            "modules": sorted(modules), "audited_declarations": len(declarations),
            "proofs": [d for d in declarations if d["name"] in PROOFS],
            "universal_proofs": len(CORE_PROOFS), "fixture_proofs": len(FIXTURE_PROOFS),
            "fixed_contracts": sorted(CONTRACT_NAMES),
            "fixed_contract_source_sha256": digest(CONTRACT_SOURCE.encode()),
            "coverage": {"report_masks": 16, "history_populations": 4, "authority_modes": 6,
                         "scenario_rows": len(KEYS), "independent_comparison_cells": len(KEYS) * 4,
                         "independent_omission_controls": 4},
            "rejected_mutants": sorted(pilot.MUTANTS), "rejected_export_controls": parser_controls,
            "dependencies": dependencies, "output_sha256": digest(exported.stdout.encode()),
            "boundary": "Synthetic source-bound presentation; external authentication and human decisions remain separate.",
        }
        (OUTPUT / "lean-export.json").write_text(exported.stdout)
        (OUTPUT / "compiled-axioms.json").write_text(json.dumps(declarations, indent=2) + "\n")
        (OUTPUT / "fixed-contracts.lean").write_text(CONTRACT_SOURCE)
        staged = work / "report.json"
        staged.write_text(json.dumps(report, indent=2) + "\n")
        staged.replace(receipt)
    print(f"IDA case workbench: {len(PROOFS)} proofs, {len(CONTRACT_NAMES)} fixed contracts, "
          "384 independent rows, "
          f"5 rejected mutants and {len(parser_controls)} export controls at {revision}.")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, TypeError, IndexError, subprocess.SubprocessError) as exc:
        sys.exit("IDA case workbench formal verification: " + str(exc))
