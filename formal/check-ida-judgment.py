#!/usr/bin/env python3
"""Verify typed IDA records and exact binding to a supplied registry snapshot."""

import csv
import hashlib
import importlib.util
import io
import json
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def module_from(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


common = module_from("ida_foundation_gate", ROOT / "formal/check-ida.py")
require, command, lake, quint = common.require, common.command, common.lake, common.quint
LEAN, QUINT = common.LEAN, common.QUINT
RECEIPTS = ROOT / ".cache/ida-judgment"
SEED = "20261108"
ROW_COUNT = 6 * 38 + 5 * 4 * 38 + 5 * 8
MODULES = (
    "Usul.Hukm", "Usul.IDA", "Usul.Signature", "Usul.Qawaid", "Usul.Judgement",
    "Usul.Typing.IDAJudgment", "UsulTest.IDAJudgment", "UsulTest.IDAJudgmentContracts",
)
EXPORTER = "scripts.ExportIDAJudgment"
INPUTS = tuple(sorted(set(common.INPUTS) | {
    "formal/check-ida-judgment.py",
    "formal/ida-quint-source-inventory.py",
    *("formal/lean/" + m.replace(".", "/") + ".lean" for m in (*MODULES, EXPORTER)),
    "formal/quint/ida-judgment.qnt", "formal/quint/ida-judgment-table.qnt",
    "docs/research/ida-judgment-records.md",
}))


def fingerprint():
    return {name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest() for name in INPUTS}


def quint_source_audit(work):
    inventory = module_from("ida_quint_sources", ROOT / "formal/ida-quint-source-inventory.py")
    compiler = QUINT / "node_modules/@informalsystems/quint/dist/src/cliCommands.js"
    model, table = QUINT / "ida-judgment.qnt", QUINT / "ida-judgment-table.qnt"
    expected = {model: {model}, table: {model, table}}
    hashed = {ROOT / name for name in INPUTS if name.endswith(".qnt")}
    observed = inventory.verify_exact_quint_closure(compiler, expected, hashed)

    # Both probes must typecheck. An actual direct or transitive source outside
    # the receipt boundary must fail for that precise path, not a parser error.
    directory = work / "quint-source-controls"
    directory.mkdir()
    for source in (model, table):
        shutil.copyfile(source, directory / source.name)
    local_model, local_table = directory / model.name, directory / table.name
    text = local_model.read_text()
    marker = "module idaJudgment {"
    require(text.count(marker) == 1, "Ambiguous Quint source control insertion")
    local_model.write_text(text.replace(marker, marker
        + '\n  import closureExtra.marker from "./closure-extra"\n'
        + '  pure val closureProbe = marker\n'))
    extra, hidden = directory / "closure-extra.qnt", directory / "closure-hidden.qnt"
    extra.write_text("module closureExtra { pure val marker = 1 }\n")
    local_expected = {local_model: {local_model}, local_table: {local_model, local_table}}

    def require_rejected(expected_map, approved, forbidden):
        path = directory / "typecheck.json"
        quint("typecheck", local_table, "--out", path)
        stage = json.loads(path.read_text())
        require(stage.get("stage") == "typechecking" and stage.get("errors") == []
                and stage.get("warnings") == [], "Quint import probe did not typecheck cleanly")
        try:
            inventory.verify_exact_quint_closure(compiler, expected_map, approved)
        except inventory.ClosureError as exc:
            require(str(exc) == f"Unexpected Quint source: {forbidden}",
                    f"Quint source probe failed for an unrelated reason: {exc}")
        else:
            raise ValueError("Unlisted Quint source passed the receipt boundary")

    require_rejected(local_expected, {local_model, local_table}, extra)
    extra.write_text('module closureExtra {\n  import closureHidden.secret from "./closure-hidden"\n'
                     '  pure val marker = secret\n}\n')
    hidden.write_text("module closureHidden { pure val secret = 1 }\n")
    through_extra = {local_model: {local_model, extra}, local_table: {local_model, local_table, extra}}
    require_rejected(through_extra, {local_model, local_table, extra}, hidden)
    return {
        "inventories": [{"entry": str(Path(item["entry"]).relative_to(ROOT)),
                         "sources": [str(Path(p).relative_to(ROOT)) for p in item["sources"]]}
                        for item in observed],
        "negative_controls": ["unlisted_direct_source", "unlisted_transitive_source"],
    }


def expected_rows():
    for question in range(6):
        for answer in range(38):
            yield "codec", question, answer, 0
    for question in range(5):
        for status in range(4):
            for variant in range(38):
                yield "admission", question, status, variant
    for question in range(5):
        for update in range(8):
            yield "revalidation", question, update, 0


def parse_lean(text):
    rows = list(csv.reader(io.StringIO(text)))
    require(rows and rows.pop(0) == ["section", "a", "b", "c", "result"],
            "Unexpected judgment CSV header")
    require(len(rows) == ROW_COUNT, "Incomplete or oversized judgment CSV")
    values = []
    for row, expected in zip(rows, expected_rows()):
        require(len(row) == 5 and all(re.fullmatch(r"0|[1-9][0-9]*", v) for v in row[1:]),
                "Malformed judgment CSV row")
        actual = (row[0], *(int(v) for v in row[1:4]))
        require(actual == expected, f"Noncanonical, missing, or duplicate row: {actual}")
        value = int(row[4])
        require(value <= (37 if row[0] == "codec" else 8), "Out-of-range judgment result")
        values.append(value)
    return values


def parse_quint(trace):
    require(trace.get("#meta", {}).get("format") == "ITF"
            and trace["#meta"].get("status") == "ok", "Judgment trace is not successful ITF")
    require(trace.get("vars") == ["results"], "Unexpected judgment state variables")
    require(len(trace.get("states", [])) == 1, "Judgment export must have one state")
    rows = trace["states"][0].get("results")
    require(isinstance(rows, list) and len(rows) == ROW_COUNT, "Incomplete judgment ITF")
    values = []
    for row, expected in zip(rows, expected_rows()):
        require(isinstance(row, dict) and set(row) == {"#bigint"}
                and isinstance(row["#bigint"], str)
                and re.fullmatch(r"0|[1-9][0-9]*", row["#bigint"]),
                "Noncanonical judgment ITF integer")
        value = int(row["#bigint"])
        require(value <= (37 if expected[0] == "codec" else 8), "Out-of-range judgment result")
        values.append(value)
    return values


def compare(left, right):
    require(len(left) == len(right) == ROW_COUNT, "Judgment parity coverage mismatch")
    for key, a, b in zip(expected_rows(), left, right):
        require(a == b, f"Independent judgment models disagree at {key}: {a} != {b}")


def export_controls(csv_text, trace, values):
    reject = common.expect_rejection
    lines = csv_text.splitlines()
    reject(lambda: parse_lean("\n".join(lines[:-1])), "truncated judgment CSV")
    duplicate = lines.copy()
    duplicate[2] = duplicate[1]
    reject(lambda: parse_lean("\n".join(duplicate)), "duplicate judgment CSV row")
    for name, edit in (
        ("truncated_quint", lambda t: t["states"][0]["results"].pop()),
        ("noncanonical_integer", lambda t: t["states"][0]["results"].__setitem__(0, {"#bigint": "01"})),
        ("unsuccessful_trace", lambda t: t["#meta"].__setitem__("status", "error")),
        ("wrong_trace_format", lambda t: t["#meta"].__setitem__("format", "other")),
    ):
        corrupt = json.loads(json.dumps(trace))
        edit(corrupt)
        reject(lambda: parse_quint(corrupt), name)
    wrong = values.copy()
    wrong[0] = (wrong[0] + 1) % 38
    reject(lambda: compare(values, wrong), "judgment disagreement")
    return ["truncated_lean", "duplicate_lean", "truncated_quint", "noncanonical_integer",
            "unsuccessful_trace", "wrong_trace_format", "disagreement"]


def contract_vectors(values):
    # Written directly from the shared contract, independently of either model.
    vectors = [
        ("missing_is_present_tag", ("codec", 0, 0, 0), 1),
        ("explicit_mubah", ("codec", 0, 4, 0), 5),
        ("partial_nonforbidden", ("codec", 0, 30, 0), 31),
        ("all_statuses", ("codec", 0, 31, 0), 32),
        ("suspended_tag", ("codec", 0, 32, 0), 33),
        ("bool_is_not_taklifi", ("codec", 0, 33, 0), 0),
        ("taklifi_is_not_bool", ("codec", 1, 4, 0), 0),
        ("false_sign", ("codec", 1, 33, 0), 34),
        ("true_sign", ("codec", 1, 34, 0), 35),
        ("fasid", ("codec", 4, 35, 0), 36),
        ("sahih", ("codec", 4, 36, 0), 37),
        ("bool_is_not_validity", ("codec", 4, 34, 0), 0),
        ("unknown_question", ("codec", 5, 0, 0), 0),
        ("unknown_answer", ("codec", 0, 37, 0), 0),
        ("different_boolean_question", ("admission", 1, 1, 1), 8),
        ("cross_family_question", ("admission", 0, 1, 1), 1),
        ("taklifi_capacity", ("admission", 0, 1, 4), 3),
        ("stale_snapshot", ("admission", 0, 1, 27), 4),
        ("missing_entry", ("admission", 0, 1, 28), 5),
        ("duplicate_entry", ("admission", 0, 1, 29), 6),
        ("evidence_required", ("admission", 0, 1, 32), 3),
    ]
    vectors += [(f"accepted_question_{q}", ("admission", q, 1, 0), 0) for q in range(5)]
    vectors += [(f"not_admitted_status_{s}", ("admission", 0, s, 0), 7) for s in (0, 2, 3)]
    vectors += [(f"bound_field_{v}", ("admission", 1, 1, v), 8) for v in range(2, 27)]
    vectors += [(f"bad_reference_{v}", ("admission", 0, 1, v), 2)
                for v in (30, 31, 33, 34, 35, 36, 37)]
    vectors += [(f"receipt_q{q}_update{u}", ("revalidation", q, u, 0), outcome)
                for q in range(5) for u, outcome in enumerate((0, 4, 7, 7, 8, 8, 5, 6))]
    lookup = dict(zip(expected_rows(), values))
    for name, key, expected in vectors:
        require(lookup[key] == expected, f"Judgment contract vector failed: {name}")
    return [name for name, _, _ in vectors]


def required_theorems():
    # Explicit obligations, paired with independently stated proposition types.
    core = {
        "question_roundtrip", "question_decode_sound", "payload_roundtrip", "payload_decode_sound",
        "record_roundtrip", "record_decode_sound", "accepted_iff", "accepted_decoded",
        "accepted_preserves_record", "accepted_reference_shape", "accepted_well_typed",
        "accepted_snapshot", "accepted_unique_admitted", "accepted_registered_record",
        "accepted_preserves_grade", "mismatched_record_not_accepted", "question_change_not_accepted",
        "source_hash_change_not_accepted", "profile_change_not_accepted",
        "profile_version_change_not_accepted", "non_admitted_not_accepted",
        "duplicate_entries_not_accepted", "missing_entry_not_accepted", "stale_snapshot_not_accepted",
        "receipt_request_preserved", "revalidate_original", "revalidate_stale_not_accepted",
        "revalidate_non_admitted_not_accepted", "revalidate_revoked_not_accepted",
        "missing_ne_suspended", "missing_ne_known", "suspended_ne_known",
    }
    scenarios = {
        "codec_family_matrix", "out_of_range_codes", "baseline_admitted", "unadmitted_statuses",
        "all_metadata_bound", "duplicate_id_priority", "snapshot_binding", "missing_entry_binding",
        "reference_shape", "evidence_required", "typed_capacity", "all_taklifi_payloads_preserved",
        "missing_and_suspension_preserved", "partial_permission_distinct", "grade_preserved",
        "revalidation_cases", "export_bounds",
    }
    return {"Usul.IDA.Judgment." + name for name in core} | {
        "UsulTest.IDAJudgment." + name for name in scenarios}


def required_tests():
    return {
        "codecFamiliesTest", "typedPayloadTest", "metadataBindingTest", "admissionStatusTest",
        "duplicateEntryTest", "capacityAndEvidenceTest", "referenceShapeTest",
        "unresolvedAndPartialTest", "snapshotTest", "receiptRevalidationTest",
        "acceptancePreservationTest", "diagnosticPriorityTest", "negativeNaturalBoundaryTest",
    }


def semantic_mutations():
    return [('missing_question_binding', '    a.questionCode == b.questionCode,\n', '', 'metadataBindingTest'),
     ('missing_source_hash_binding', '    a.sourceHash == b.sourceHash,\n', '', 'metadataBindingTest'),
     ('missing_profile_version_binding',
      '    a.profileVersion == b.profileVersion,\n',
      '',
      'metadataBindingTest'),
     ('missing_snapshot_guard',
      'else if (request.snapshot != registry.snapshot) Rejected(StaleSnapshot)',
      'else if (false) Rejected(StaleSnapshot)',
      'snapshotTest'),
     ('unadmitted_entry_accepted',
      'if (entry.status != Admitted) Rejected(NotAdmitted)',
      'if (false) Rejected(NotAdmitted)',
      'admissionStatusTest'),
     ('duplicate_first_match',
      'else if (matching.length() != 1) Rejected(AmbiguousEntry)',
      'else if (false) Rejected(AmbiguousEntry)',
      'duplicateEntryTest'),
     ('boolean_as_validity',
      'else if (code == 36) PayloadValue(Known(ValidityAnswer(Sahih)))',
      'else if (code == 36 or code == 34) PayloadValue(Known(ValidityAnswer(Sahih)))',
      'codecFamiliesTest'),
     ('missing_reference_guard',
      'else if (not(referenceShape(typed.provenance))) Rejected(BadReference)',
      'else if (false) Rejected(BadReference)',
      'referenceShapeTest'),
     ('missing_as_suspended',
      'if (code == 0) PayloadValue(NoRuling)',
      'if (code == 0) PayloadValue(Suspended)',
      'unresolvedAndPartialTest'),
     ('missing_capacity_guard',
      '    record.question != Taklifi or (record.scope.subject.baligh and '
      'record.scope.subject.aqil),\n',
      '    true,\n',
      'capacityAndEvidenceTest'),
     ('missing_evidence_guard',
      '    record.provenance.dalil.length() > 0,\n',
      '    true,\n',
      'capacityAndEvidenceTest'),
     ('missing_natural_boundary',
      'if (not(boundaryNaturals(registry, request))) Rejected(BadReference)',
      'if (false) Rejected(BadReference)',
      'negativeNaturalBoundaryTest'),
     ('receipt_skips_revalidation',
      '| RecordCode(raw) => validate(registry, {\n'
      '      snapshot: receipt.snapshot, entryId: receipt.entryId, record: raw\n'
      '    })',
      '| RecordCode(_) => Accepted(receipt)',
      'receiptRevalidationTest'),
     ('receipt_overwrites_profile',
      'else Accepted({ snapshot: request.snapshot, entryId: request.entryId, record: typed })',
      'else Accepted({ snapshot: request.snapshot, entryId: request.entryId, record: '
      'typed.with("scope", typed.scope.with("profile", 1)) })',
      'acceptancePreservationTest')]


def compiled_audit(work):
    audit = module_from("judgment_axiom_audit", ROOT / "formal/check-lean-axioms.py")
    body = (ROOT / "formal/lean-axiom-audit.lean").read_text()
    env = {"LEAN_PATH": str(work)}
    allowed_modules = set(MODULES) | {EXPORTER}
    for root in ("Init", "Lean", "Std"):
        require(not (LEAN / root).exists() and not (LEAN / f"{root}.lean").exists(),
                f"Local source shadows standard library root {root}")

    def inspect(imports, roots, expected):
        path = work / "InspectJudgment.lean"
        allowed = sorted(allowed_modules | set(expected))
        path.write_text("import Lean\n" + "".join(f"import {m}\n" for m in imports)
                        + f"private def auditRoots : List String := {json.dumps(roots)}\n"
                        + f"private def allowedProjectImports : List String := {json.dumps(allowed)}\n"
                        + "open Lean Elab Command\nrun_cmd do\n"
                        + "  for name in (← getEnv).allImportedModuleNames do\n"
                        + "    unless [\"Init\", \"Lean\", \"Std\"].contains name.getRoot.toString || "
                        + "allowedProjectImports.contains name.toString do\n"
                        + "      throwError m!\"Unexpected project import: {name}\"\n" + body)
        result = lake("env", "lean", path, env=env)
        require(not result.stderr.strip(), f"Unexpected compiled audit diagnostics: {result.stderr}")
        return audit.parse_inventory(result.stdout, set(expected))

    declarations = inspect(["UsulTest.IDAJudgmentContracts"], ["Usul", "UsulTest"], MODULES)
    target = work / "scripts/ExportIDAJudgment.olean"
    target.parent.mkdir()
    build = lake("env", "lean", "scripts/ExportIDAJudgment.lean", "-o", target)
    require("declaration uses `sorry`" not in build.stdout + build.stderr,
            "Judgment exporter contains an admitted proof")
    declarations.extend(inspect([EXPORTER], ["scripts"], [EXPORTER]))
    theorems = {d["name"] for d in declarations if d["kind"] == "theorem"}
    required = required_theorems()
    require(required and required <= theorems,
            f"Missing judgment proof obligations: {sorted(required - theorems)}")
    witnesses = {"UsulTest.IDAJudgmentContracts.require_" + name.replace(".", "_") for name in required}
    require(witnesses <= theorems, f"Missing fixed judgment proposition types: {sorted(witnesses - theorems)}")

    probes = {
        "JudgmentPrivateAxiomProbe": "private axiom hidden : True\n",
        "JudgmentSorryProbe": "theorem admitted : True := by sorry\n",
    }
    for name, contents in probes.items():
        source = work / f"{name}.lean"
        source.write_text(contents)
        lake("env", "lean", f"--root={work}", source, "-o", source.with_suffix(".olean"))
        try:
            inspect([name], [name], [name])
        except ValueError as exc:
            require("Disallowed Lean declarations or axiom dependencies" in str(exc),
                    f"Compiled probe failed for an unrelated reason: {exc}")
        else:
            raise ValueError(f"Compiled axiom probe accepted: {name}")
    dep = work / "JudgmentUnexpectedDependency.lean"
    dep.write_text("theorem harmless : True := True.intro\n")
    lake("env", "lean", f"--root={work}", dep, "-o", dep.with_suffix(".olean"))
    wrapper = work / "JudgmentImportProbe.lean"
    wrapper.write_text("import JudgmentUnexpectedDependency\ntheorem expected : True := True.intro\n")
    lake("env", "lean", f"--root={work}", wrapper, "-o", wrapper.with_suffix(".olean"), env=env)
    try:
        inspect(["JudgmentImportProbe"], ["JudgmentImportProbe"], ["JudgmentImportProbe"])
    except ValueError as exc:
        require("Unexpected project import: JudgmentUnexpectedDependency" in str(exc),
                f"Import probe failed for an unrelated reason: {exc}")
    else:
        raise ValueError("Undeclared dependency passed judgment audit")
    return {"modules": [*MODULES, EXPORTER], "allowed_axioms": sorted(audit.ALLOWED),
            "allowed_project_imports": sorted(allowed_modules), "declarations": declarations,
            "required_theorems": sorted(required), "typed_contracts": sorted(witnesses),
            "negative_controls": [*probes, "JudgmentImportProbe"]}


def semantic_controls(work):
    source = (QUINT / "ida-judgment.qnt").read_text()
    mutations = semantic_mutations()
    require(len(mutations) >= 8, "Insufficient judgment semantic controls")
    results = []
    for name, before, after, test in mutations:
        require(source.count(before) == 1, f"Ambiguous judgment mutation: {name}")
        directory = work / name
        directory.mkdir()
        (directory / "ida-judgment.qnt").write_text(source.replace(before, after))
        shutil.copyfile(QUINT / "ida.qnt", directory / "ida.qnt")
        quint("typecheck", "ida-judgment.qnt", cwd=directory)
        result = quint("test", "ida-judgment.qnt", "--main", "idaJudgment",
                       "--backend", "typescript", "--max-samples", "1",
                       "--seed", SEED, "--match", f"^{test}$", "--verbosity", "2",
                       cwd=directory, allow_failure=True)
        require(result.returncode != 0, f"Judgment semantic mutant survived: {name}")
        diagnostics = re.findall(r"Error \[(QNT\d+)\]: ([^\n]*)", result.stdout + result.stderr)
        require(diagnostics == [("QNT508", "Assertion failed")],
                f"Nonsemantic judgment mutation failure: {name}\n{result.stdout}\n{result.stderr}")
        require(f"1) {test} failed after 1 test(s)" in result.stdout,
                f"Required judgment assertion did not fail: {name}")
        results.append({"name": name, "test": test, "failure": "QNT508 Assertion failed"})
    return results


def main():
    if RECEIPTS.exists():
        shutil.rmtree(RECEIPTS)
    RECEIPTS.parent.mkdir(parents=True, exist_ok=True)
    revision = command(["git", "rev-parse", "HEAD"]).stdout.strip()
    hashes, overrides = fingerprint(), common.runtime_overrides()
    pin = (LEAN / "lean-toolchain").read_text().strip()
    version = lake("env", "lean", "--version").stdout.strip()
    require(pin.startswith("leanprover/lean4:v") and version.startswith(
        f"Lean (version {pin.removeprefix('leanprover/lean4:v')},"), "Lean pin mismatch")
    manifest = json.loads((QUINT / "package.json").read_text())
    lock = json.loads((QUINT / "package-lock.json").read_text())
    require(manifest["devDependencies"]["@informalsystems/quint"] == "0.33.1"
            and lock["packages"]["node_modules/@informalsystems/quint"]["version"] == "0.33.1",
            "Unexpected Quint dependency pin")
    quint_version = quint("--version").stdout.strip()
    require(quint_version == "0.33.1", "Quint binary differs from lock")
    require(not json.loads((LEAN / "lake-manifest.json").read_text()).get("packages"),
            "Judgment core unexpectedly depends on external Lean packages")

    with tempfile.TemporaryDirectory(prefix="ida-judgment-check-", dir=RECEIPTS.parent) as temporary:
        work = Path(temporary)
        result = lake("build", "Usul.Typing.IDAJudgment", "UsulTest.IDAJudgment", "UsulTest.IDAJudgmentContracts")
        require("declaration uses `sorry`" not in result.stdout + result.stderr,
                "Lean emitted an admitted-proof diagnostic")
        sources = quint_source_audit(work)
        quint("typecheck", QUINT / "ida-judgment.qnt")
        quint("typecheck", QUINT / "ida-judgment-table.qnt")
        tests_path = work / "quint-tests.json"
        quint("test", QUINT / "ida-judgment.qnt", "--main", "idaJudgment",
              "--backend", "typescript", "--max-samples", "1",
              "--seed", SEED, "--out", tests_path)
        tests = json.loads(tests_path.read_text())
        require(tests.get("stage") == "testing" and tests.get("failed") == [],
                "Quint did not complete judgment tests")
        require(all(tests.get(field, []) == [] for field in ("ignored", "warnings", "errors")),
                "Quint judgment test had ignored cases or diagnostics")
        require(required_tests() and set(tests.get("passed", [])) == required_tests()
                and len(tests["passed"]) == len(required_tests()), "Missing or unexpected judgment tests")
        print(f"IDA judgments: {len(tests['passed'])} deterministic Quint tests passed.", flush=True)
        lean_csv = lake("env", "lean", "--run", "scripts/ExportIDAJudgment.lean").stdout
        left = parse_lean(lean_csv)
        trace_path = work / "quint.itf.json"
        quint("run", QUINT / "ida-judgment-table.qnt", "--main", "idaJudgmentTable",
              "--backend", "typescript", "--max-samples", "1", "--max-steps", "0",
              "--seed", SEED, "--out-itf", trace_path, "--verbosity", "0")
        trace = json.loads(trace_path.read_text())
        right = parse_quint(trace)
        compare(left, right)
        vectors = contract_vectors(left)
        contract_vectors(right)
        controls = export_controls(lean_csv, trace, left)
        print(f"IDA judgments: independent agreement on all {ROW_COUNT} declared inputs.", flush=True)
        axioms = compiled_audit(work)
        mutants = semantic_controls(work)
        require(fingerprint() == hashes and common.runtime_overrides() == overrides
                and command(["git", "rev-parse", "HEAD"]).stdout.strip() == revision,
                "Judgment verification inputs changed during replay")
        matches_head = all(
            result.returncode == 0 and hashlib.sha256(result.stdout).hexdigest() == expected
            for name, expected in hashes.items()
            for result in [subprocess.run(["git", "show", f"HEAD:{name}"], cwd=ROOT,
                                          stdout=subprocess.PIPE, stderr=subprocess.PIPE)]
        )
        report = {
            "schema": "usul.ida.judgment.v1", "status": "passed", "revision": revision,
            "inputs_match_head": matches_head, "source_sha256": hashes, "runtime_overrides": overrides,
            "tools": {"lean_pin": pin, "lean": version, "quint": quint_version,
                      "node": command(["node", "--version"]).stdout.strip()},
            "coverage": {"codec_inputs": 228, "admission_inputs": 760, "revalidation_inputs": 40,
                         "total_inputs": ROW_COUNT, "synthetic_fixtures": True,
                         "questions": 5, "statuses": 4, "admission_variants": 38,
                         "codec_question_tags": "0..5", "codec_answer_tags": "0..37"},
            "quint_tests": sorted(required_tests()), "parser_controls": controls,
            "quint_source_audit": sources,
            "contract_vectors": vectors, "semantic_mutants": mutants,
            "compiled_audit": {"modules": axioms["modules"], "declarations": len(axioms["declarations"]),
                               "theorems": sum(d["kind"] == "theorem" for d in axioms["declarations"]),
                               "required_obligations": len(required_theorems()),
                               "typed_contracts": len(axioms["typed_contracts"]),
                               "negative_controls": axioms["negative_controls"]},
            "boundary": {
                "proved": "typed record preservation and exact binding to the supplied registry",
                "agreement": "complete over the declared synthetic family, not arbitrary records",
                "trusted_input": "registry contents, status decisions, snapshot and identity assignment",
                "not_established": ["source-byte authentication", "source interpretation",
                                    "cryptographic receipt authentication", "derivation graph correctness",
                                    "registry authorization or concurrency", "runtime refinement"],
            },
        }
        staged = work / "receipts"
        staged.mkdir()
        (staged / "report.json").write_text(json.dumps(report, indent=2) + "\n")
        (staged / "compiled-axioms.json").write_text(json.dumps(axioms, indent=2) + "\n")
        (staged / "lean.csv").write_text(lean_csv)
        shutil.copyfile(trace_path, staged / "quint.itf.json")
        shutil.copyfile(tests_path, staged / "quint-tests.json")
        staged.rename(RECEIPTS)
        print(f"IDA judgments: PASS; {len(required_theorems())} required proofs, "
              f"{len(mutants)} semantic mutants rejected; inputs_match_head={matches_head}.")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, subprocess.SubprocessError) as exc:
        raise SystemExit(f"IDA judgment verification failed: {exc}") from exc
