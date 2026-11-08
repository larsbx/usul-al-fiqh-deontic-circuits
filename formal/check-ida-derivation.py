#!/usr/bin/env python3
"""Verify source-bound IDA derivations with fixed Lean contracts and independent Quint replay."""

import csv
import hashlib
import importlib.util
import io
import json
import os
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
RECEIPTS = ROOT / ".cache/ida-derivation"
SEED = "20261108"
ROW_COUNT = 11032
MODULES = (
    "Usul.Hukm", "Usul.IDA", "Usul.Signature", "Usul.Qawaid", "Usul.Judgement",
    "Usul.Typing.IDAJudgment", "Usul.Typing.IDADerivation",
    "UsulTest.IDADerivation", "UsulTest.IDADerivationContracts",
)
EXPORTER = "scripts.ExportIDADerivation"
FIXTURE_DIR = ROOT / "formal/fixtures/ida-source-auth"
FIXTURES = tuple(sorted("formal/fixtures/ida-source-auth/" + name for name in (
    "README.md", "catalog.json", "catalog.sig", "source-1.txt", "source-2.txt",
    "test-only-issuer-private.pem", "test-only-issuer-public.pem",
    "test-only-untrusted-private.pem", "test-only-trust.json",
)))
INPUTS = tuple(sorted(set(common.INPUTS) | {
    ".gitattributes",
    "formal/check-ida-derivation.py", "formal/check-ida-source-auth.mjs",
    "formal/ida-quint-source-inventory.py", "formal/ida-source-auth.mjs",
    "formal/ida-derivation-mutations.json", "formal/ida-derivation-traceability.json",
    *("formal/lean/" + m.replace(".", "/") + ".lean" for m in (*MODULES, EXPORTER)),
    "formal/quint/ida-judgment.qnt", "formal/quint/ida-derivation.qnt",
    "formal/quint/ida-derivation-table.qnt", "docs/research/ida-source-derivations.md",
    "docs/research/ida-source-auth.md", "docs/research/ida-derivation-wire.md", *FIXTURES,
}))


def fingerprint():
    return {name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest() for name in INPUTS}


def quint_source_audit(work):
    inventory = module_from("ida_quint_sources", ROOT / "formal/ida-quint-source-inventory.py")
    compiler = QUINT / "node_modules/@informalsystems/quint/dist/src/cliCommands.js"
    model, table = QUINT / "ida-derivation.qnt", QUINT / "ida-derivation-table.qnt"
    dependencies = {QUINT / "ida.qnt", QUINT / "ida-judgment.qnt"}
    expected = {model: {model, *dependencies}, table: {model, table, *dependencies}}
    hashed = {ROOT / name for name in INPUTS if name.endswith(".qnt")}
    observed = inventory.verify_exact_quint_closure(compiler, expected, hashed)

    # Both probes must typecheck. An actual direct or transitive source outside
    # the receipt boundary must fail for that precise path, not a parser error.
    directory = work / "quint-source-controls"
    directory.mkdir()
    for source in (model, table, *dependencies):
        shutil.copyfile(source, directory / source.name)
    local_model, local_table = directory / model.name, directory / table.name
    text = local_model.read_text()
    marker = "module idaDerivation {"
    require(text.count(marker) == 1, "Ambiguous Quint source control insertion")
    local_model.write_text(text.replace(marker, marker
        + '\n  import closureExtra.marker from "./closure-extra"\n'
        + '  pure val closureProbe = marker\n'))
    extra, hidden = directory / "closure-extra.qnt", directory / "closure-hidden.qnt"
    extra.write_text("module closureExtra { pure val marker = 1 }\n")
    local_dependencies = {directory / p.name for p in dependencies}
    local_expected = {local_model: {local_model, *local_dependencies},
                      local_table: {local_model, local_table, *local_dependencies}}

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

    require_rejected(local_expected, {local_model, local_table, *local_dependencies}, extra)
    extra.write_text('module closureExtra {\n  import closureHidden.secret from "./closure-hidden"\n'
                     '  pure val marker = secret\n}\n')
    hidden.write_text("module closureHidden { pure val secret = 1 }\n")
    through_extra = {local_model: {local_model, extra, *local_dependencies},
                     local_table: {local_model, local_table, extra, *local_dependencies}}
    require_rejected(through_extra, {local_model, local_table, extra, *local_dependencies}, hidden)
    return {
        "inventories": [{"entry": str(Path(item["entry"]).relative_to(ROOT)),
                         "sources": [str(Path(p).relative_to(ROOT)) for p in item["sources"]]}
                        for item in observed],
        "negative_controls": ["unlisted_direct_source", "unlisted_transitive_source"],
    }


def expected_rows():
    for i in (1, 2):
        for field in range(68):
            yield "source", i, field, 0
    for section, first, second in (
        ("leaf", range(5), range(32)), ("taklifi", range(33), range(33)),
        ("typed", range(1, 5), range(16)), ("scope", range(13), range(1)),
        ("tree", range(10), range(3)), ("alternatives", range(2), range(2)),
    ):
        for a in first:
            for b in second:
                for field in range(8):
                    yield section, a, b, field
    for variant in range(16):
        yield "replay", variant, 0, 0


def parse_lean(text):
    rows = list(csv.reader(io.StringIO(text)))
    require(rows and rows.pop(0) == ["section", "a", "b", "c", "result"],
            "Unexpected derivation CSV header")
    require(len(rows) == ROW_COUNT, "Incomplete or oversized derivation CSV")
    values = []
    for row, expected in zip(rows, expected_rows()):
        require(len(row) == 5 and all(re.fullmatch(r"0|[1-9][0-9]*", v) for v in row[1:]),
                "Malformed derivation CSV row")
        actual = (row[0], *(int(v) for v in row[1:4]))
        require(actual == expected, f"Noncanonical, missing, or duplicate row: {actual}")
        value = int(row[4])
        require(value <= cell_bound(expected), "Out-of-range derivation result")
        values.append(value)
    return values


def parse_quint(trace):
    require(trace.get("#meta", {}).get("format") == "ITF"
            and trace["#meta"].get("status") == "ok", "Derivation trace is not successful ITF")
    require(trace.get("vars") == ["results"], "Unexpected derivation state variables")
    require(len(trace.get("states", [])) == 1, "Derivation export must have one state")
    rows = trace["states"][0].get("results")
    require(isinstance(rows, list) and len(rows) == ROW_COUNT, "Incomplete derivation ITF")
    values = []
    for row, expected in zip(rows, expected_rows()):
        require(isinstance(row, dict) and set(row) == {"#bigint"}
                and isinstance(row["#bigint"], str)
                and re.fullmatch(r"0|[1-9][0-9]*", row["#bigint"]),
                "Noncanonical derivation ITF integer")
        value = int(row["#bigint"])
        require(value <= cell_bound(expected), "Out-of-range derivation result")
        values.append(value)
    return values


def compare(left, right):
    require(len(left) == len(right) == ROW_COUNT, "Derivation parity coverage mismatch")
    for key, a, b in zip(expected_rows(), left, right):
        require(a == b, f"Independent derivation models disagree at {key}: {a} != {b}")


def export_controls(csv_text, trace, values):
    reject = common.expect_rejection
    lines = csv_text.splitlines()
    reject(lambda: parse_lean("\n".join(lines[:-1])), "truncated derivation CSV")
    duplicate = lines.copy()
    duplicate[2] = duplicate[1]
    reject(lambda: parse_lean("\n".join(duplicate)), "duplicate derivation CSV row")
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
    wrong[0] = (wrong[0] + 1) % 256
    reject(lambda: compare(values, wrong), "derivation disagreement")
    return ["truncated_lean", "duplicate_lean", "truncated_quint", "noncanonical_integer",
            "unsuccessful_trace", "wrong_trace_format", "disagreement"]


def contract_vectors(values):
    # Finite expected examples stated from the wire contract, not imported from
    # either implementation. There are 285 eight-projection cases and 16 replay flags.
    lookup = dict(zip(expected_rows(), values))
    checked = []

    def fold(items, radix):
        result = 0
        for item in items:
            result = result * radix + item
        return result

    def expected(q, answer, ids, issues=()):
        if issues:
            return [issues[0], 0, 0, 0, 0, len(ids), fold(issues, 32), fold(ids, 16)]
        return [0, 1, 8, q + 1, answer + 1, len(ids), 0, fold(ids, 16)]

    def check(section, a, b, output):
        for field, result in enumerate(output):
            require(lookup[(section, a, b, field)] == result,
                    f"Derivation contract failed at {(section, a, b, field)}")
        checked.append(f"{section}:{a}:{b}")

    leaf_codes = [0,7,7,7,10,10,10,10,11,11,11,12,12,13,14,14,
                  16,13,17,18,15,19,20,9,9,24,4,8,8,8,8,15]
    for q in range(5):
        answer = 16 if q == 0 else 34 if q < 4 else 36
        for variant, code in enumerate(leaf_codes):
            check("leaf", q, variant, expected(q, answer, [1], [] if code == 0 else [code]))

    def pair(q, a, b):
        issues = [19 if x == 0 else 20 for x in (a, b) if x in (0, 32)]
        if issues:
            return expected(q, 0, [1, 2], issues)
        answer = a & b if q == 0 else a if a == b else 0
        return expected(q, answer, [1, 2], [] if answer else [22])

    for a, b in [(0,0),(0,4),(4,0),(0,32),(32,0),(32,32),(32,4),(4,32),
                 (4,4),(30,31),(30,16),(1,16),(2,8),(31,31)]:
        check("taklifi", a, b, pair(0, a, b))
    for q in range(1, 5):
        codes = [0, 32, 35, 36] if q == 4 else [0, 32, 33, 34]
        for case in range(16):
            check("typed", q, case, pair(q, codes[case // 4], codes[case % 4]))
    for variant in range(13):
        check("scope", variant, 0, expected(1, 34, [1, 2], [] if variant == 0 else [21]))
    tree_codes = [0,19,20,7,16,10,11,21,22,13]
    for variant, code in enumerate(tree_codes):
        for shape in range(3):
            ids = [1, 2, 2, 3] if shape == 2 else [1, 2, 3]
            if variant == 0:
                issues = []
            elif variant == 7:
                issues = [21] * (3 if shape == 2 else 2)
            elif variant == 8:
                issues = [22]
            else:
                issues = [code] * (2 if shape == 2 else 1)
            check("tree", variant, shape, expected(0, 16, ids, issues))
    for scenario in range(2):
        for index in range(2):
            check("alternatives", scenario, index,
                  expected(0, 1 if index == 0 else 16, [index + 1],
                           [7] if scenario == 1 and index == 1 else []))
    for variant in range(16):
        require(lookup[("replay", variant, 0, 0)] == int(variant == 0),
                f"Receipt contract failed at {variant}")
        checked.append(f"replay:{variant}")
    require(len(checked) == 301, "Contract case inventory changed")
    return checked


def required_theorems():
    core = {
        "authorized_iff", "source_accepted_iff", "both_accepted_inputs", "provenance_exact",
        "accepted_leaf_authority", "accepted_leaf_admitted", "accepted_homogeneous",
        "incompatible_scopes_rejected", "rejected_leaf_blocks_tree", "missing_ruling_blocks_tree",
        "suspended_ruling_blocks_tree", "unauthenticated_source_blocks_tree",
        "stale_interpretation_blocks_tree", "non_admitted_leaf_blocks_tree",
        "substituted_record_blocks_tree", "unsupported_evidence_blocks_tree",
        "question_identity_guard", "context_guard", "provenance_grades_preserved",
        "taklifi_intersection_exact", "taklifi_subset_both", "sign_agreement",
        "accepted_conclusion_scope", "classification_admitted_iff", "alternative_order",
        "alternatives_length", "alternatives_provenance", "receipt_valid_original",
        "receipt_accepted_iff", "changed_revision_rejects_receipt", "changed_result_rejects_receipt",
        "accepted_receipt_sources", "verifyReceipt_sound", "unauthorized_evidence_promotion",
    }
    scenarios = {
        "source_catalog_shapes", "leaf_guard_matrix", "source_full_values", "taklifi_full_values",
        "typed_full_values", "scope_guard_matrix", "nested_blocker_matrix", "alternatives_unselected",
        "receipt_mutation_matrix", "forged_admission_rejected",
    }
    return {"Usul.IDA.Derivation." + name for name in core} | {
        "UsulTest.IDADerivation." + name for name in scenarios}


def required_tests():
    return {
        "derivationSourcePreservationTest", "derivationSourceAuthenticationTest",
        "derivationVersionTest", "derivationEvidenceTest", "derivationNoPromotionTest",
        "derivationSourceRuleTest", "derivationLeafCasesTest", "derivationConjunctionTest",
        "derivationTypedConjunctionTest", "derivationScopeTest", "derivationScopeBeforeTaintTest",
        "derivationDeepTaintTest", "derivationAlternativesTest", "derivationReceiptReplayTest",
        "derivationGraphTest", "derivationQuestionIdentityTest", "derivationMetadataAndGradesTest",
        "derivationRawBoundaryTest", "derivationAlgebraTest", "derivationQuestionFamilyTest",
        "derivationScopePredicateTest",
    }


def semantic_mutations():
    spec = json.loads((ROOT / "formal/ida-derivation-mutations.json").read_text())
    mutations = spec["mutations"]
    require(len(mutations) == 23, "Unexpected semantic mutation inventory")
    require(len({m["name"] for m in mutations}) == len(mutations), "Duplicate semantic mutant")
    return [(m["name"], m["before"], m["after"], m["test"]) for m in mutations]


def compiled_audit(work):
    audit = module_from("derivation_axiom_audit", ROOT / "formal/check-lean-axioms.py")
    body = (ROOT / "formal/lean-axiom-audit.lean").read_text()
    env = {"LEAN_PATH": str(work)}
    allowed_modules = set(MODULES) | {EXPORTER}
    for root in ("Init", "Lean", "Std"):
        require(not (LEAN / root).exists() and not (LEAN / f"{root}.lean").exists(),
                f"Local source shadows standard library root {root}")

    def inspect(imports, roots, expected):
        path = work / "InspectDerivation.lean"
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

    declarations = inspect(["UsulTest.IDADerivationContracts"], ["Usul", "UsulTest"], MODULES)
    target = work / "scripts/ExportIDADerivation.olean"
    target.parent.mkdir()
    build = lake("env", "lean", "scripts/ExportIDADerivation.lean", "-o", target)
    require("declaration uses `sorry`" not in build.stdout + build.stderr,
            "Derivation exporter contains an admitted proof")
    declarations.extend(inspect([EXPORTER], ["scripts"], [EXPORTER]))
    theorems = {d["name"] for d in declarations if d["kind"] == "theorem"}
    required = required_theorems()
    require(required and required <= theorems,
            f"Missing derivation proof obligations: {sorted(required - theorems)}")
    witnesses = {"UsulTest.IDADerivationContracts.require_" + name.replace(".", "_") for name in required}
    require(witnesses <= theorems, f"Missing fixed derivation proposition types: {sorted(witnesses - theorems)}")

    probes = {
        "DerivationPrivateAxiomProbe": "private axiom hidden : True\n",
        "DerivationSorryProbe": "theorem admitted : True := by sorry\n",
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
    dep = work / "DerivationUnexpectedDependency.lean"
    dep.write_text("theorem harmless : True := True.intro\n")
    lake("env", "lean", f"--root={work}", dep, "-o", dep.with_suffix(".olean"))
    wrapper = work / "DerivationImportProbe.lean"
    wrapper.write_text("import DerivationUnexpectedDependency\ntheorem expected : True := True.intro\n")
    lake("env", "lean", f"--root={work}", wrapper, "-o", wrapper.with_suffix(".olean"), env=env)
    try:
        inspect(["DerivationImportProbe"], ["DerivationImportProbe"], ["DerivationImportProbe"])
    except ValueError as exc:
        require("Unexpected project import: DerivationUnexpectedDependency" in str(exc),
                f"Import probe failed for an unrelated reason: {exc}")
    else:
        raise ValueError("Undeclared dependency passed derivation audit")
    return {"modules": [*MODULES, EXPORTER], "allowed_axioms": sorted(audit.ALLOWED),
            "allowed_project_imports": sorted(allowed_modules), "declarations": declarations,
            "required_theorems": sorted(required), "typed_contracts": sorted(witnesses),
            "negative_controls": [*probes, "DerivationImportProbe"]}


def semantic_controls(work):
    source = (QUINT / "ida-derivation.qnt").read_text()
    mutations = semantic_mutations()
    require(len(mutations) == 23, "Insufficient derivation semantic controls")
    results = []
    for name, before, after, test in mutations:
        require(re.fullmatch(r"[a-z][a-z0-9_]*", name) is not None, "Unsafe mutation name")
        require(test in required_tests() and before != after and before, "Invalid mutation contract")
        require(source.count(before) == 1, f"Ambiguous derivation mutation: {name}")
        directory = work / name
        directory.mkdir()
        (directory / "ida-derivation.qnt").write_text(source.replace(before, after))
        for dependency in ("ida.qnt", "ida-judgment.qnt"):
            shutil.copyfile(QUINT / dependency, directory / dependency)
        quint("typecheck", "ida-derivation.qnt", cwd=directory)
        result = quint("test", "ida-derivation.qnt", "--main", "idaDerivation",
                       "--backend", "typescript", "--max-samples", "1",
                       "--seed", SEED, "--match", f"^{test}$", "--verbosity", "2",
                       cwd=directory, allow_failure=True)
        require(result.returncode != 0, f"Derivation semantic mutant survived: {name}")
        diagnostics = re.findall(r"Error \[(QNT\d+)\]: ([^\n]*)", result.stdout + result.stderr)
        require(diagnostics == [("QNT508", "Assertion failed")],
                f"Nonsemantic derivation mutation failure: {name}\n{result.stdout}\n{result.stderr}")
        require(f"1) {test} failed after 1 test(s)" in result.stdout,
                f"Required derivation assertion did not fail: {name}")
        results.append({"name": name, "test": test, "failure": "QNT508 Assertion failed"})
    return results


def cell_bound(key):
    if key[0] == "source":
        return 255
    if key[0] == "replay":
        return 1
    return (24, 1, 8, 5, 37, 4, 32 ** 3 - 1, 16 ** 4 - 1)[key[3]]


def authenticate_sources(work, hashes):
    result = command(["node", ROOT / "formal/check-ida-source-auth.mjs"])
    require(not result.stderr.strip(), "Unexpected source authentication diagnostics")
    payload = json.loads(result.stdout)
    require(payload.get("status") == "passed" and payload.get("synthetic_fixtures") is True,
            "Source authentication controls did not pass")
    require(payload.get("fixture_private_keys_public_and_test_only") is True,
            "Source fixtures do not declare the key boundary")
    positive, negative = payload.get("positive_controls", []), payload.get("negative_controls", [])
    expected_positive = ['committed_signature_reproduced_with_public_test_key', 'exact_source_ref_vectors', 'source_ref_only_frozen_output', 'repeated_text_passage_has_explicit_anchor', 'explicitly_repinned_catalog_version', 'binary_passage_across_stream_buffer_boundary']
    expected_negative = ['substituted_source_same_byte_count', 'truncated_source', 'padded_source', 'rehashed_resigned_substitution_without_current_pin', 'changed_passage_range_with_old_digest', 'signed_incorrect_passage_digest', 'signed_incorrect_source_digest', 'equal_text_at_changed_passage_locator', 'stale_signed_catalog_version', 'unknown_catalog_issuer', 'unknown_signing_key', 'corrupted_signature', 'catalog_changed_without_resigning', 'missing_signature', 'missing_current_manifest_pin', 'non_ed25519_configured_key', 'unauthorized_admission_status', 'unauthorized_evidence_promotion', 'unauthorized_interpretation_version', 'catalog_embedded_trust_key', 'catalog_embedded_current_versions', 'unsafe_integer_source_id', 'fractional_passage_offset', 'negative_passage_offset', 'empty_passage_range', 'passage_range_past_source', 'duplicate_source_reference', 'source_id_rebound_to_other_content', 'parent_path_traversal', 'absolute_source_path', 'backslash_source_path', 'source_file_symlink', 'source_parent_symlink', 'source_is_directory', 'source_file_missing', 'noncanonical_catalog_whitespace', 'duplicate_json_catalog_key', 'invalid_utf8_catalog']
    require(positive == expected_positive and negative == expected_negative, "Source control names changed")
    require(len(positive) == len(set(positive)) == 6 and len(negative) == len(set(negative)) == 38,
            "Source authentication control inventory changed")
    results = payload.get("control_results", [])
    require(len(results) == 38 and [r["name"] for r in results] == negative,
            "Source authentication control results incomplete")
    require(all(isinstance(r["expected_error"], str) and r["expected_error"].strip()
                and r["expected_error"] == r["observed_error"] for r in results),
            "Source control failed for an unexpected reason")
    expected_files = {name: hashes[name] for name in FIXTURES}
    require(payload.get("fixture_sha256") == expected_files, "Source fixture receipt does not bind inputs")
    require(payload.get("node_to_lean_refinement_proved") is False
            and payload.get("registry_or_evidence_decisions_produced") is False
            and payload.get("juristic_interpretation_correctness_established") is False,
            "Source adapter changed its assurance boundary")
    return payload


def source_fixture_link(values, source_auth):
    lookup = dict(zip(expected_rows(), values))
    references = source_auth["authenticated_sources"]
    require(isinstance(references, list) and len(references) == 2,
            "Authenticated source references must be a two-element list")
    for reference in references:
        require(isinstance(reference, dict) and set(reference) == {
            "sourceId", "sourceHash", "sourceBytes", "passageStart", "passageEnd", "passageHash"},
            "Authenticated source reference has an unexpected schema")
        for key in ("sourceHash", "passageHash"):
            digest = reference[key]
            require(isinstance(digest, list) and len(digest) == 32
                    and all(type(byte) is int and 0 <= byte <= 255 for byte in digest),
                    "Authenticated digest must contain exactly 32 bytes")
        require(all(type(reference[key]) is int and 0 <= reference[key] <= 2 ** 53 - 1
                    for key in ("sourceId", "sourceBytes", "passageStart", "passageEnd")),
                "Authenticated reference contains a non-natural or unsafe number")
        require(reference["sourceId"] > 0 and reference["sourceBytes"] > 0
                and reference["passageStart"] < reference["passageEnd"] <= reference["sourceBytes"],
                "Authenticated source locator is invalid")
    require([s["sourceId"] for s in references] == [1, 2],
            "Unexpected authenticated fixture source family")
    linked = []
    for reference in references:
        cells = ([reference["sourceId"]] + reference["sourceHash"]
                 + [reference["sourceBytes"], reference["passageStart"], reference["passageEnd"]]
                 + reference["passageHash"])
        require(len(cells) == 68, "Unexpected complete source-reference shape")
        for field, value in enumerate(cells):
            require(lookup[("source", reference["sourceId"], field, 0)] == value,
                    f"Authenticated source differs from formal export at {(reference['sourceId'], field)}")
        linked.append({"source_id": reference["sourceId"], "compared_cells": 68, "reference": reference})
    return {"status": "matched", "compared_cells": 136, "sources": linked,
            "boundary": "Exact fixture data agreement; not a general adapter refinement theorem."}


def source_reference_controls(values, source_auth):
    results = []
    for name in ("shifted_digest_field_boundaries", "boolean_source_identity", "unexpected_authority_field"):
        changed = json.loads(json.dumps(source_auth))
        reference = changed["authenticated_sources"][0]
        if name == "shifted_digest_field_boundaries":
            old_hash = reference["sourceHash"]
            old_bytes, old_start, old_end = (reference[k] for k in ("sourceBytes", "passageStart", "passageEnd"))
            reference["sourceHash"] = old_hash[:-1]
            reference["sourceBytes"], reference["passageStart"], reference["passageEnd"] = old_hash[-1], old_bytes, old_start
            reference["passageHash"] = [old_end] + reference["passageHash"]
        elif name == "boolean_source_identity":
            reference["sourceId"] = True
        else:
            reference["admitted"] = True
        common.expect_rejection(lambda: source_fixture_link(values, changed), name)
        results.append(name)
    return results


def proposition_weakening_control(work):
    directory = work / "weakened-contract"
    shutil.copytree(LEAN, directory, ignore=shutil.ignore_patterns(".lake", "node_modules", ".git"))
    path = directory / "Usul/Typing/IDADerivation.lean"
    original = '''theorem unauthorized_evidence_promotion (env : Environment) (tree : Tree) (p : Premise)
    (hp : p ∈ tree.leaves)
    (he : matchingEvidence env p ≠ [⟨p, .supported⟩]) :
    ¬ (evaluate env tree).Accepted := by
  intro h
  rcases accepted_every_source h p hp with ⟨r, authority, _⟩
  exact he authority.evidence'''
    replacement = '''theorem unauthorized_evidence_promotion (env : Environment) (tree : Tree) (p : Premise)
    (hp : p ∈ tree.leaves)
    (he : matchingEvidence env p ≠ [⟨p, .supported⟩]) :
    True := by
  trivial'''
    contents = path.read_text()
    require(contents.count(original) == 1, "Ambiguous proposition-weakening control")
    path.write_text(contents.replace(original, replacement))
    command(["lake", "build", "Usul.Typing.IDADerivation", "UsulTest.IDADerivation"], cwd=directory)
    result = command(["lake", "build", "UsulTest.IDADerivationContracts"],
                     cwd=directory, allow_failure=True)
    diagnostics = result.stdout + result.stderr
    errors = re.findall(r"(?m)^error: UsulTest/IDADerivationContracts\.lean:\d+:\d+: ([^\n]+)", diagnostics)
    compact = re.sub(r"\s+", "", diagnostics)
    require(result.returncode != 0 and len(errors) == 1
            and re.search(r"[Tt]ype mismatch", errors[0]) is not None
            and "unauthorized_evidence_promotion" in diagnostics and "True" in diagnostics
            and "¬(evaluateenvtree).Accepted" in compact,
            f"Weakened theorem did not fail its fixed proposition: {diagnostics}")
    return {"name": "same_name_unauthorized_evidence_theorem_weakened_to_true",
            "ordinary_modules_compiled": True, "fixed_contract_rejected": True,
            "expected_failure": "proposition type mismatch"}


def traceability(hashes, axioms, tests, mutants, source_auth):
    specification = json.loads((ROOT / "formal/ida-derivation-traceability.json").read_text())
    require(isinstance(specification, dict) and set(specification) == {"schema", "synthetic_sources_only", "links"}
            and specification["schema"] == "usul.ida.derivation.traceability.v1",
            "Unexpected traceability schema")
    require(specification.get("synthetic_sources_only") is True, "Traceability source boundary missing")
    links = specification["links"]
    ids = {"source_binding", "passage_binding", "current_interpretations", "evidence_classification",
           "question_and_scope", "complete_provenance", "no_silent_promotion", "alternative_interpretations",
           "receipt_replay", "typed_conjunction"}
    require(len(links) == 10 and {link["id"] for link in links} == ids,
            "Traceability obligation inventory changed")
    proof_names = set(axioms["required_theorems"])
    mutation_names = {m["name"] for m in mutants}
    receipt_links = []
    for link in links:
        require(isinstance(link, dict) and set(link) ==
                {"id", "fields", "sources", "theorems", "quint_tests", "mutants"},
                "Unexpected traceability link fields")
        require(isinstance(link["fields"], list)
                and all(isinstance(field, str) and field.strip() for field in link["fields"]),
                "Traceability fields must be nonempty strings")
        require(link["fields"] and len(set(link["fields"])) == len(link["fields"]),
                f"Missing or duplicate traceability fields: {link['id']}")
        for field, approved in (("sources", set(hashes)), ("theorems", proof_names),
                                ("quint_tests", set(tests)), ("mutants", mutation_names)):
            entries = link[field]
            require(isinstance(entries, list) and all(isinstance(item, str) and item.strip() for item in entries),
                    f"Malformed traceability {field}")
            require(entries and len(entries) == len(set(entries)) and set(entries) <= approved,
                    f"Unverified traceability {field}: {link['id']}")
        receipt_links.append({**link, "source_sha256": {p: hashes[p] for p in link["sources"]}})
    return {"schema": specification["schema"], "synthetic_sources_only": True,
            "links": receipt_links,
            "source_authentication": {k: source_auth[k] for k in
                                      ("manifest_sha256", "issuer_public_key_sha256", "source_ref_schema")},
            "boundary": "Checker field-to-proof traceability; no source interpretation is established."}


def main():
    if RECEIPTS.exists():
        shutil.rmtree(RECEIPTS)
    RECEIPTS.parent.mkdir(parents=True, exist_ok=True)
    revision = command(["git", "rev-parse", "HEAD"]).stdout.strip()
    require(not os.environ.get("NODE_OPTIONS", "").strip(), "Unsupported nonempty NODE_OPTIONS")
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
            "Derivation core unexpectedly depends on external Lean packages")

    with tempfile.TemporaryDirectory(prefix="ida-derivation-check-", dir=RECEIPTS.parent) as temporary:
        work = Path(temporary)
        result = lake("build", "Usul.Typing.IDADerivation", "UsulTest.IDADerivation", "UsulTest.IDADerivationContracts")
        require("declaration uses `sorry`" not in result.stdout + result.stderr,
                "Lean emitted an admitted-proof diagnostic")
        source_auth = authenticate_sources(work, hashes)
        sources = quint_source_audit(work)
        quint("typecheck", QUINT / "ida-derivation.qnt")
        quint("typecheck", QUINT / "ida-derivation-table.qnt")
        tests_path = work / "quint-tests.json"
        quint("test", QUINT / "ida-derivation.qnt", "--main", "idaDerivation",
              "--backend", "typescript", "--max-samples", "1",
              "--seed", SEED, "--match", "^derivation.*Test$", "--out", tests_path)
        tests = json.loads(tests_path.read_text())
        require(tests.get("stage") == "testing" and tests.get("failed") == [],
                "Quint did not complete derivation tests")
        require(all(tests.get(field, []) == [] for field in ("ignored", "warnings", "errors")),
                "Quint derivation test had ignored cases or diagnostics")
        require(required_tests() and set(tests.get("passed", [])) == required_tests()
                and len(tests["passed"]) == len(required_tests()), "Missing or unexpected derivation tests")
        print(f"IDA derivations: {len(tests['passed'])} deterministic Quint tests passed.", flush=True)
        lean_csv = lake("env", "lean", "--run", "scripts/ExportIDADerivation.lean").stdout
        left = parse_lean(lean_csv)
        trace_path = work / "quint.itf.json"
        quint("run", QUINT / "ida-derivation-table.qnt", "--main", "idaDerivationTable",
              "--backend", "typescript", "--max-samples", "1", "--max-steps", "0",
              "--seed", SEED, "--out-itf", trace_path, "--verbosity", "0")
        trace = json.loads(trace_path.read_text())
        right = parse_quint(trace)
        compare(left, right)
        source_link = source_fixture_link(left, source_auth)
        source_fixture_link(right, source_auth)
        source_link["negative_controls"] = source_reference_controls(left, source_auth)
        vectors = contract_vectors(left)
        contract_vectors(right)
        controls = export_controls(lean_csv, trace, left)
        print(f"IDA derivations: independent agreement on all {ROW_COUNT} declared comparison cells.", flush=True)
        axioms = compiled_audit(work)
        proposition_control = proposition_weakening_control(work)
        mutants = semantic_controls(work)
        traced = traceability(hashes, axioms, tests["passed"], mutants, source_auth)
        require(fingerprint() == hashes and common.runtime_overrides() == overrides
                and command(["git", "rev-parse", "HEAD"]).stdout.strip() == revision,
                "Derivation verification inputs changed during replay")
        matches_head = all(
            result.returncode == 0 and hashlib.sha256(result.stdout).hexdigest() == expected
            for name, expected in hashes.items()
            for result in [subprocess.run(["git", "show", f"{revision}:{name}"], cwd=ROOT,
                                          stdout=subprocess.PIPE, stderr=subprocess.PIPE)]
        )
        require(command(["git", "rev-parse", "HEAD"]).stdout.strip() == revision,
                "Revision changed while checking committed input blobs")
        report = {
            "schema": "usul.ida.derivation.v1", "status": "passed", "revision": revision,
            "inputs_match_head": matches_head, "source_sha256": hashes, "runtime_overrides": overrides,
            "tools": {"lean_pin": pin, "lean": version, "quint": quint_version,
                      "node": command(["node", "--version"]).stdout.strip()},
            "coverage": {
                "source_reference_cells": 136, "source_leaf_cases": 160,
                "taklifi_pair_cases": 1089, "typed_pair_cases": 64, "scope_cases": 13,
                "nested_tree_cases": 30, "alternative_outputs": 4, "evaluation_cases": 1360,
                "projections_per_evaluation": 8, "receipt_replay_cases": 16,
                "total_comparison_cells": ROW_COUNT, "synthetic_fixtures": True,
                "projection_boundary": "Eight declared projections; full-value preservation is separately proved and asserted.",
            },
            "runtime_policy": {"NODE_OPTIONS": "nonempty overrides rejected",
                               "LD_PRELOAD": "paths and library hashes recorded"},
            "source_authentication": source_auth, "authenticated_fixture_link": source_link,
            "traceability_obligations": [link["id"] for link in traced["links"]],
            "proposition_weakening_control": proposition_control,
            "quint_tests": sorted(required_tests()), "parser_controls": controls,
            "quint_source_audit": sources,
            "contract_vectors": vectors, "semantic_mutants": mutants,
            "compiled_audit": {"modules": axioms["modules"], "declarations": len(axioms["declarations"]),
                               "theorems": sum(d["kind"] == "theorem" for d in axioms["declarations"]),
                               "required_obligations": len(required_theorems()),
                               "typed_contracts": len(axioms["typed_contracts"]),
                               "negative_controls": axioms["negative_controls"]},
            "boundary": {
                "proved": "source/required-conjunction calculus over arbitrary finite trees under supplied trust inputs",
                "agreement": "declared finite projections, with separate full-value proofs and scenarios",
                "trusted_input": "registry, authenticated references, current interpretation pins, evidence decisions",
                "not_established": ["juristic interpretation correctness", "historical text authenticity",
                                    "admission authority governance", "action authorization",
                                    "cryptographically authenticated or hermetic verification receipts",
                                    "atomic registry updates", "general Node-to-Lean refinement",
                                    "general inference rules", "agency integration", "repository-wide CI"],
            },
        }

        staged = work / "receipts"
        staged.mkdir()
        (staged / "report.json").write_text(json.dumps(report, indent=2) + "\n")
        (staged / "traceability.json").write_text(json.dumps(traced, indent=2) + "\n")
        (staged / "source-authentication.json").write_text(json.dumps(source_auth, indent=2) + "\n")
        (staged / "authenticated-fixture-link.json").write_text(json.dumps(source_link, indent=2) + "\n")
        (staged / "compiled-axioms.json").write_text(json.dumps(axioms, indent=2) + "\n")
        (staged / "lean.csv").write_text(lean_csv)
        shutil.copyfile(trace_path, staged / "quint.itf.json")
        shutil.copyfile(tests_path, staged / "quint-tests.json")
        require(command(["git", "rev-parse", "HEAD"]).stdout.strip() == revision,
                "Revision changed before receipt publication")
        staged.rename(RECEIPTS)
        print(f"IDA derivations: PASS; {len(required_theorems())} required proofs, "
              f"{len(mutants)} semantic mutants rejected; inputs_match_head={matches_head}.")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, subprocess.SubprocessError) as exc:
        raise SystemExit(f"IDA derivation verification failed: {exc}") from exc
