#!/usr/bin/env python3
"""Check question-indexed source-bound replay under an explicit trusted snapshot.

The independent Lean and Quint models implement the replay rule. This gate
validates coverage, proof contracts, compiled dependencies, and negative controls;
it neither admits sources nor implements another judgment engine.
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
RECEIPTS = ROOT / ".cache/ida-judgment"
SEED = "20261108"
ROW_COUNT = 6 * 36 * 4 * 34
MODULES = [
    "Usul.Hukm", "Usul.Signature", "Usul.Qawaid", "Usul.Judgement", "Usul.IDA",
    "Usul.IDAJudgment", "UsulTest.IDAJudgment", "UsulTest.IDAJudgmentContracts",
]
EXPORTER = "scripts.ExportIDAJudgment"
INPUTS = (
    "formal/check-ida-judgment.py", "formal/check-ida.py", "formal/check-lean-axioms.py",
    "formal/lean-axiom-audit.lean", "formal/lean/lakefile.toml",
    "formal/lean/lake-manifest.json", "formal/lean/lean-toolchain",
    "formal/lean/Usul.lean", "formal/lean/UsulTest.lean",
    "formal/quint/ida-judgment.qnt", "formal/quint/ida-judgment-table.qnt",
    "formal/quint/package.json", "formal/quint/package-lock.json",
    "docs/research/ida-judgments-wire.md", "docs/research/ida-judgments.md",
    "Makefile", ".github/workflows/ida-judgment.yml",
) + tuple("formal/lean/" + name.replace(".", "/") + ".lean"
          for name in MODULES + [EXPORTER])


def load_module(name, relative):
    spec = importlib.util.spec_from_file_location(name, ROOT / relative)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


foundation = load_module("ida_foundation_gate", "formal/check-ida.py")
require = foundation.require
command = foundation.command
lake = foundation.lake
quint = foundation.quint
expect_rejection = foundation.expect_rejection


def fingerprint():
    return {name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest() for name in INPUTS}


def expected_rows():
    for question in range(6):
        for answer in range(36):
            for admission in range(4):
                for variant in range(34):
                    yield question, answer, admission, variant


def valid_result(value):
    return 0 <= value <= 34 or 100 <= value <= 107


def parse_lean(text):
    rows = list(csv.reader(io.StringIO(text)))
    require(rows and rows.pop(0) == ["question", "answer", "admission", "variant", "result"],
            "Unexpected judgment CSV header")
    require(len(rows) == ROW_COUNT, "Incomplete or oversized Lean judgment export")
    values = []
    for row, expected in zip(rows, expected_rows()):
        require(len(row) == 5 and all(re.fullmatch(r"0|[1-9][0-9]*", v) for v in row),
                "Malformed Lean judgment row")
        actual = tuple(map(int, row[:4]))
        require(actual == expected, f"Noncanonical, missing, or duplicate judgment row: {actual}")
        value = int(row[4])
        require(valid_result(value), "Invalid replay result code")
        values.append(value)
    return values


def parse_quint(trace):
    require(isinstance(trace, dict) and trace.get("#meta", {}).get("format") == "ITF"
            and trace["#meta"].get("status") == "ok", "Quint trace is not a successful ITF export")
    require(trace.get("vars") == ["results"], "Unexpected Quint state variables")
    require(len(trace.get("states", [])) == 1, "Judgment export must have one state")
    rows = trace["states"][0].get("results")
    require(isinstance(rows, list) and len(rows) == ROW_COUNT, "Incomplete Quint judgment export")
    values = []
    for row in rows:
        require(isinstance(row, dict) and set(row) == {"#bigint"}
                and isinstance(row["#bigint"], str)
                and re.fullmatch(r"0|[1-9][0-9]*", row["#bigint"]), "Invalid Quint integer")
        value = int(row["#bigint"])
        require(valid_result(value), "Invalid Quint replay result")
        values.append(value)
    return values


def compare(left, right):
    require(len(left) == len(right) == ROW_COUNT, "Replay coverage mismatch")
    for key, a, b in zip(expected_rows(), left, right):
        require(a == b, f"Independent judgment disagreement at {key}: {a} != {b}")


def contract_vectors(values):
    # Stated from the contract, independently of either implementation.
    vectors = [
        ("explicit_mubah", 0, 4, 1, 0, 4),
        ("partial_permission", 0, 30, 1, 0, 30),
        ("all_five", 0, 31, 1, 0, 31),
        ("validity_fasid", 4, 1, 1, 0, 1),
        ("validity_sahih", 4, 2, 1, 0, 2),
        ("validity_partial", 4, 3, 1, 0, 3),
        ("sabab_true", 1, 2, 1, 0, 2),
        ("shart_false", 2, 1, 1, 0, 1),
        ("mani_partial", 3, 3, 1, 0, 3),
        ("unknown_question", 5, 1, 1, 0, 100),
        ("invalid_answer", 0, 35, 1, 0, 100),
        ("taklifi_mask_in_validity", 4, 16, 1, 0, 100),
        ("taklifi_mask_in_sabab", 1, 4, 1, 0, 100),
        ("reported_admission_irrelevant", 0, 1, 1, 20, 1),
        ("candidate_cannot_self_admit", 0, 1, 0, 20, 105),
        ("quarantine_cannot_self_admit", 0, 1, 2, 20, 105),
        ("revoked_cannot_self_admit", 0, 1, 3, 20, 105),
    ]
    vectors += [(f"preserve_status_{tag}", q, tag, 1, 0, tag)
                for q in range(5) for tag in (0, 32, 33, 34)]
    expected_variants = {
        **{v: 103 for v in range(1, 8)}, 8: 106,
        **{v: 104 for v in range(9, 13)}, **{v: 106 for v in range(13, 17)},
        17: 101, 18: 101, 19: 106, 21: 104, 22: 104, 23: 103, 24: 102,
        25: 107, 26: 107, 27: 107, 28: 107, 29: 107, 30: 102, 31: 107,
        32: 103, 33: 107,
    }
    vectors += [(f"binding_variant_{v}", 0, 1, 1, v, expected)
                for v, expected in expected_variants.items()]
    for name, question, answer, status, variant, expected in vectors:
        index = ((question * 36 + answer) * 4 + status) * 34 + variant
        require(values[index] == expected, f"Independent contract vector failed: {name}")
    return [name for name, *_ in vectors]


def export_controls(csv_text, trace, values):
    lines = csv_text.splitlines()
    expect_rejection(lambda: parse_lean("\n".join(lines[:-1])), "truncated Lean export")
    duplicate = lines.copy()
    duplicate[2] = duplicate[1]
    expect_rejection(lambda: parse_lean("\n".join(duplicate)), "duplicate Lean input")
    invalid_code = lines.copy()
    invalid_code[1] = ",".join(invalid_code[1].split(",")[:4] + ["99"])
    expect_rejection(lambda: parse_lean("\n".join(invalid_code)), "invalid result code")
    truncated = json.loads(json.dumps(trace))
    truncated["states"][0]["results"].pop()
    expect_rejection(lambda: parse_quint(truncated), "truncated Quint export")
    invalid = json.loads(json.dumps(trace))
    invalid["states"][0]["results"][0] = {"#bigint": "0", "extra": 1}
    expect_rejection(lambda: parse_quint(invalid), "noncanonical Quint integer")
    unsuccessful = json.loads(json.dumps(trace))
    unsuccessful["#meta"]["status"] = "error"
    expect_rejection(lambda: parse_quint(unsuccessful), "unsuccessful trace")
    wrong_format = json.loads(json.dumps(trace))
    wrong_format["#meta"]["format"] = "other"
    expect_rejection(lambda: parse_quint(wrong_format), "wrong trace format")
    wrong = values.copy()
    wrong[0] = 1 if wrong[0] != 1 else 2
    expect_rejection(lambda: compare(values, wrong), "disagreeing independent export")
    return ["truncated_lean", "duplicate_lean", "invalid_result", "truncated_quint",
            "noncanonical_integer", "unsuccessful_trace", "wrong_trace_format", "disagreement"]


def required_theorems():
    # Explicit names accompany independently stated proposition-type witnesses.
    # Do not derive acceptance obligations from the implementation under review.
    core = {
        "accepted_guards", "replay_of_guards", "guards_accepted", "accepted_iff_guards",
        "accepted_decodes", "accepted_schema", "accepted_rule", "accepted_provenance",
        "accepted_scope", "accepted_source", "accepted_enabled", "accepted_admitted",
        "accepted_receipt", "accepted_admission", "changed_receipt_cannot_reuse",
        "changed_admission_cannot_reuse", "changed_scope_cannot_reuse",
        "changed_source_cannot_reuse", "reported_status_irrelevant", "invalid_type_rejected",
        "known_nonempty", "noRuling_ne_suspended", "noRuling_ne_conflict",
        "suspended_ne_conflict", "known_ne_exceptional", "replay_retains_claim",
        "replay_retains_status", "replay_retains_decoding",
        "decodeQuestion_fidelity", "decode_question_fidelity", "decoded_canonical_codes",
        "taklifi_member_semantics", "sabab_member_semantics", "shart_member_semantics",
        "mani_member_semantics", "validity_member_semantics", "decodeQuestion_rejects",
        "decode_rejects_question", "decodeVerdict_rejects", "decode_rejects_answer",
        "decode_answer_fidelity", "replay_question_fidelity", "replay_answer_fidelity",
        "replayCode_of_success",
    }
    scenarios = {
        "rejects_digest_syntax", "rejects_empty_interpretation",
        "rejects_empty_required_identifiers", "accepts_empty_opaque_scope_identifiers",
        "accepted_taklifi_masks", "accepted_boolean_masks", "accepted_validity_masks",
        "preserved_exceptional_statuses", "rejects_invalid_types",
        "rejects_unsupported_schema_rule", "rejects_malformed_provenance",
        "rejects_changed_scope", "rejects_changed_registered_source",
        "rejects_nonadmitted_despite_report", "ignores_reported_admission",
        "rejects_retained_derivation", "rejects_coherent_claimant_rebind",
        "type_precedes_schema", "schema_precedes_malformed", "malformed_precedes_scope",
        "scope_precedes_source", "source_precedes_admission", "admission_precedes_derivation",
        "derivation_precedes_admission_binding",
    }
    return ({"Usul.IDAJudgment." + name for name in core}
            | {"UsulTest.IDAJudgment." + name for name in scenarios})


def required_tests():
    return {
        "acceptedAllMasksTest", "invalidQuestionTest", "invalidAnswerCodesTest",
        "wrongQuestionCarrierTest", "typedVerdictsTest", "typedSingletonsTest",
        "exceptionalQuestionIdentityTest", "preservedStatusesTest",
        "supportedSchemaRuleTest", "malformedEmptyDigestTest", "malformedUppercaseDigestTest",
        "malformed63DigestTest", "malformed65DigestTest", "malformedNonhexDigestTest",
        "malformedEmptyInterpretationIdTest", "malformedEmptyInterpretationVersionTest",
        "malformedRequiredFieldsTest", "currentScopeBindingTest", "registeredSourceBindingTest",
        "disabledSourceTest", "trustedAdmissionStatusTest", "ignoredReportedAdmissionTest",
        "retainedDerivationBindingTest", "coherentRebindAdmissionTest", "acceptedRetainsClaimTest",
        "opaqueScopeIdentifiersTest", "validationPriorityTest",
    }


def semantic_mutations():
    return [
        ("wrong_question_carrier", "else if (a >= 1 and a <= 3) {",
         "else if (a >= 1 and a <= 31) {", "wrongQuestionCarrierTest"),
        ("missing_as_mubah", "else if (a == 0) DecodedVerdict(NoRuling(questionTag(q)))",
         "else if (a == 0) DecodedVerdict(TaklifiKnown(Set(Mubah)))", "preservedStatusesTest"),
        ("schema_rule_ignored", "if (p.derivation.schema != 1 or p.derivation.rule != 0) Rejected(101)",
         "if (false) Rejected(101)", "supportedSchemaRuleTest"),
        ("provenance_ignored", "      else if (not(wellFormed(p.claim))) Rejected(102)\n",
         "", "malformedRequiredFieldsTest"),
        ("requested_scope_ignored", "      else if (p.claim.scope != t.requestedScope) Rejected(103)\n",
         "", "currentScopeBindingTest"),
        ("source_binding_ignored", "not(t.sourceEnabled) or p.claim.source != t.registeredSource",
         "not(t.sourceEnabled)", "registeredSourceBindingTest"),
        ("source_disable_ignored", "not(t.sourceEnabled) or p.claim.source != t.registeredSource",
         "p.claim.source != t.registeredSource", "disabledSourceTest"),
        ("caller_status_used", "else if (t.admission.status != 1) Rejected(105)",
         "else if (p.reportedAdmission != 1) Rejected(105)", "trustedAdmissionStatusTest"),
        ("receipt_binding_ignored", "      else if (p.claim != p.derivation.claim) Rejected(106)\n",
         "", "retainedDerivationBindingTest"),
        ("admission_binding_ignored", "      else if (p.claim != t.admission.claim) Rejected(107)\n",
         "", "coherentRebindAdmissionTest"),
        ("question_kind_collapse", "else if (q == 2) DecodedVerdict(ShartKnown(bs))",
         "else if (q == 2) DecodedVerdict(SababKnown(bs))", "typedVerdictsTest"),
        ("digest_charset_ignored",
         "d.length() == 64 and d.indices().forall(i => hexChars.contains(d.nth(i)))",
         "d.length() == 64", "malformedNonhexDigestTest"),
        ("boolean_polarity_swapped", "pure def boolBit(v: bool): int = if (v) 2 else 1",
         "pure def boolBit(v: bool): int = if (v) 1 else 2", "typedSingletonsTest"),
        ("validity_polarity_swapped", "pure def validityBit(v: Validity): int = match v { | Fasid => 1 | Sahih => 2 }",
         "pure def validityBit(v: Validity): int = match v { | Fasid => 2 | Sahih => 1 }", "typedSingletonsTest"),
    ]


def quint_dependency_closure(work):
    """Use Quint's parser source map, rather than a regex over import text."""
    def inspect(source, expected, prefix):
        parsed = work / f"{prefix}-parse.json"
        source_map = work / f"{prefix}-sources.json"
        quint("parse", source, "--out", parsed, "--source-map", source_map)
        stage = json.loads(parsed.read_text())
        require(stage.get("stage") == "parsing" and stage.get("errors") == []
                and stage.get("warnings") == [], "Quint dependency parsing failed")
        index = json.loads(source_map.read_text()).get("sourceIndex")
        require(isinstance(index, dict) and index, "Missing Quint parser source inventory")
        require(all(isinstance(path, str) for path in index.values()), "Malformed Quint source inventory")
        discovered = {Path(path).resolve() for path in index.values()}
        require(discovered == {Path(path).resolve() for path in expected},
                f"Unexpected Quint source dependency: {sorted(map(str, discovered))}")
        return sorted(str(path.relative_to(ROOT)) for path in discovered)

    model = QUINT / "ida-judgment.qnt"
    table = QUINT / "ida-judgment-table.qnt"
    model_sources = inspect(model, [model], "judgment-model")
    table_sources = inspect(table, [model, table], "judgment-table")
    directory = work / "quint-extra-import"
    directory.mkdir()
    source = model.read_text()
    marker = "module idaJudgment {"
    require(source.count(marker) == 1, "Cannot construct the extra-import control")
    probe = directory / model.name
    probe.write_text(source.replace(marker, marker + '\n  import idaUnexpected.* from "./ida-unexpected"'))
    (directory / "ida-unexpected.qnt").write_text("module idaUnexpected { pure val extraMarker = 0 }\n")
    quint("typecheck", probe)
    try:
        inspect(probe, [probe], "unexpected-import")
    except ValueError as exc:
        require("Unexpected Quint source dependency" in str(exc),
                f"Quint import control failed for an unrelated reason: {exc}")
    else:
        raise ValueError("An undeclared Quint source passed the dependency boundary")
    return {"model_sources": model_sources, "table_sources": table_sources,
            "negative_controls": ["extra_quint_import"]}


def compiled_audit(work):
    audit = load_module("ida_judgment_axiom_gate", "formal/check-lean-axioms.py")
    body = (ROOT / "formal/lean-axiom-audit.lean").read_text()
    env = {"LEAN_PATH": str(work)}
    owned = set(MODULES + [EXPORTER])
    for root in ("Init", "Lean", "Std"):
        require(not (LEAN / root).exists() and not (LEAN / f"{root}.lean").exists(),
                f"Local source shadows standard library root {root}")

    def inspect(imports, roots, expected):
        source = work / "InspectIDAJudgment.lean"
        source.write_text("import Lean\n" + "".join(f"import {m}\n" for m in imports)
                          + f"private def auditRoots : List String := {json.dumps(roots)}\n"
                          + f"private def allowedProjectImports : List String := {json.dumps(sorted(owned | set(expected)))}\n"
                          + "open Lean Elab Command\nrun_cmd do\n"
                          + "  for name in (← getEnv).allImportedModuleNames do\n"
                          + "    unless [\"Init\", \"Lean\", \"Std\"].contains name.getRoot.toString || "
                          + "allowedProjectImports.contains name.toString do\n"
                          + "      throwError m!\"Unexpected project import: {name}\"\n" + body)
        result = lake("env", "lean", source, env=env)
        require(not result.stderr.strip(), f"Unexpected inventory diagnostics: {result.stderr}")
        return audit.parse_inventory(result.stdout, set(expected))

    declarations = inspect(["UsulTest.IDAJudgmentContracts"], ["Usul", "UsulTest"], MODULES)
    target = work / "scripts/ExportIDAJudgment.olean"
    target.parent.mkdir()
    build = lake("env", "lean", "scripts/ExportIDAJudgment.lean", "-o", target)
    require("declaration uses `sorry`" not in build.stdout + build.stderr, "Exporter contains an admitted proof")
    declarations.extend(inspect([EXPORTER], ["scripts"], [EXPORTER]))
    theorems = {d["name"] for d in declarations if d["kind"] == "theorem"}
    obligations = required_theorems()
    require(obligations, "No required judgment proof obligations are registered")
    require(obligations <= theorems, f"Missing required judgment proofs: {sorted(obligations - theorems)}")
    witnesses = {"UsulTest.IDAJudgmentContracts.require_" + name.replace(".", "_") for name in obligations}
    require(witnesses <= theorems, f"Missing fixed proposition contracts: {sorted(witnesses - theorems)}")

    probes = {"IDAJudgmentPrivateProbe": "private axiom hidden : True\n",
              "IDAJudgmentSorryProbe": "theorem admitted : True := by sorry\n"}
    for name, contents in probes.items():
        source = work / f"{name}.lean"
        source.write_text(contents)
        lake("env", "lean", f"--root={work}", source, "-o", source.with_suffix(".olean"))
        try:
            inspect([name], [name], [name])
        except ValueError as exc:
            require("Disallowed Lean declarations or axiom dependencies" in str(exc),
                    f"Axiom probe failed for an unrelated reason: {exc}")
        else:
            raise ValueError(f"Axiom control accepted {name}")
    dependency = work / "IDAJudgmentUnexpectedDependency.lean"
    dependency.write_text("theorem harmless : True := True.intro\n")
    lake("env", "lean", f"--root={work}", dependency, "-o", dependency.with_suffix(".olean"))
    wrapper = work / "IDAJudgmentImportProbe.lean"
    wrapper.write_text("import IDAJudgmentUnexpectedDependency\ntheorem expected : True := True.intro\n")
    lake("env", "lean", f"--root={work}", wrapper, "-o", wrapper.with_suffix(".olean"), env=env)
    try:
        inspect([wrapper.stem], [wrapper.stem], [wrapper.stem])
    except ValueError as exc:
        require("Unexpected project import: IDAJudgmentUnexpectedDependency" in str(exc),
                f"Import probe failed for an unrelated reason: {exc}")
    else:
        raise ValueError("An undeclared dependency passed the judgment import boundary")
    return {"modules": MODULES + [EXPORTER], "allowed_axioms": sorted(audit.ALLOWED),
            "declarations": declarations, "required_theorems": sorted(obligations),
            "typed_contracts": sorted(witnesses), "allowed_project_imports": sorted(owned),
            "negative_controls": list(probes) + [wrapper.stem]}


def compiler_type_controls(work):
    prefix = "import Usul.IDAJudgment\nopen Usul Usul.IDAJudgment\n"
    good = work / "IDAJudgmentTypedControl.lean"
    good.write_text(prefix + "def acceptedValidity : KnownAnswers (.wadi .validity) :=\n"
                    "  ⟨(fun v => v == .sahih), ⟨.sahih, rfl⟩⟩\n"
                    "def acceptedQuestion : Verdict (.wadi .shart) := .noRuling\n")
    lake("env", "lean", good)
    probes = [
        ("hukm_as_validity", "def wrongValidity : KnownAnswers (.wadi .validity) :=\n"
         "  ⟨(fun h : Hukm => h == .wajib), ⟨.sahih, rfl⟩⟩\n", ("Hukm", "Validity")),
        ("sabab_as_shart", "def wrongQuestion : Verdict (.wadi .shart) :=\n"
         "  (Verdict.noRuling : Verdict (.wadi .sabab))\n", ("sabab", "shart")),
    ]
    results = []
    for name, source, expected_terms in probes:
        path = work / f"{name}.lean"
        path.write_text(prefix + source)
        result = lake("env", "lean", path, allow_failure=True)
        diagnostics = result.stdout + result.stderr
        require(result.returncode != 0 and "type mismatch" in diagnostics.lower()
                and all(term.lower() in diagnostics.lower() for term in expected_terms),
                f"Typed construction control did not fail for its intended type mismatch: {name}\n{diagnostics}")
        results.append({"name": name, "source": path.read_text(), "diagnostics": diagnostics})
    return results


def semantic_controls(work):
    source = (QUINT / "ida-judgment.qnt").read_text()
    mutations = semantic_mutations()
    require(mutations, "No judgment semantic controls are registered")
    results = []
    for name, before, after, test in mutations:
        require(source.count(before) == 1, f"Ambiguous judgment mutation: {name}")
        directory = work / name
        directory.mkdir()
        (directory / "ida-judgment.qnt").write_text(source.replace(before, after))
        quint("typecheck", "ida-judgment.qnt", cwd=directory)
        result = quint("test", "ida-judgment.qnt", "--backend", "typescript", "--max-samples", "1",
                       "--seed", SEED, "--match", f"^{test}$", "--verbosity", "2",
                       cwd=directory, allow_failure=True)
        require(result.returncode != 0, f"Judgment semantic mutant survived: {name}")
        diagnostics = re.findall(r"Error \[(QNT\d+)\]: ([^\n]*)", result.stdout + result.stderr)
        require(diagnostics == [("QNT508", "Assertion failed")],
                f"Mutant failed for a nonsemantic reason: {name}\n{result.stdout}\n{result.stderr}")
        require(f"1) {test} failed after 1 test(s)" in result.stdout,
                f"Required mutation assertion did not fail: {name}")
        results.append({"name": name, "test": test, "failure": "QNT508 Assertion failed"})
    return results


def main():
    if RECEIPTS.exists():
        shutil.rmtree(RECEIPTS)
    RECEIPTS.parent.mkdir(parents=True, exist_ok=True)
    revision = command(["git", "rev-parse", "HEAD"]).stdout.strip()
    hashes = fingerprint()
    overrides = foundation.runtime_overrides()
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
    require(quint_version == "0.33.1", "Quint executable differs from the lock")
    with tempfile.TemporaryDirectory(prefix="ida-judgment-check-", dir=RECEIPTS.parent) as temporary:
        work = Path(temporary)
        build = lake("build", "UsulTest.IDAJudgmentContracts")
        require("declaration uses `sorry`" not in build.stdout + build.stderr,
                "Lean emitted an admitted-proof diagnostic")
        require(not json.loads((LEAN / "lake-manifest.json").read_text()).get("packages"),
                "Scoped judgment kernel unexpectedly uses external Lean packages")
        type_controls = compiler_type_controls(work)
        quint("typecheck", QUINT / "ida-judgment.qnt")
        quint("typecheck", QUINT / "ida-judgment-table.qnt")
        quint_imports = quint_dependency_closure(work)
        tests_path = work / "quint-tests.json"
        quint("test", QUINT / "ida-judgment.qnt", "--backend", "typescript", "--max-samples", "1",
              "--seed", SEED, "--out", tests_path)
        tests = json.loads(tests_path.read_text())
        require(tests.get("stage") == "testing" and tests.get("failed") == [],
                "Quint did not complete its deterministic judgment tests")
        require(all(tests.get(field, []) == [] for field in ("ignored", "warnings", "errors")),
                "Quint reported ignored tests, warnings, or errors")
        require(required_tests() and set(tests.get("passed", [])) == required_tests()
                and len(tests["passed"]) == len(required_tests()), "Missing or unexpected judgment tests")
        print(f"IDA judgments: pinned tools; {len(tests['passed'])} deterministic tests passed.", flush=True)

        lean_csv = lake("env", "lean", "--run", "scripts/ExportIDAJudgment.lean").stdout
        lean_values = parse_lean(lean_csv)
        itf = work / "quint.itf.json"
        quint("run", QUINT / "ida-judgment-table.qnt", "--main", "idaJudgmentTable",
              "--backend", "typescript", "--max-samples", "1", "--max-steps", "0",
              "--seed", SEED, "--out-itf", itf, "--verbosity", "0")
        trace = json.loads(itf.read_text())
        quint_values = parse_quint(trace)
        compare(lean_values, quint_values)
        vectors = contract_vectors(lean_values)
        contract_vectors(quint_values)
        parser_controls = export_controls(lean_csv, trace, lean_values)
        print(f"IDA judgments: all {ROW_COUNT} independent outputs agree.", flush=True)
        axioms = compiled_audit(work)
        mutants = semantic_controls(work)
        require(fingerprint() == hashes and foundation.runtime_overrides() == overrides
                and command(["git", "rev-parse", "HEAD"]).stdout.strip() == revision,
                "Inputs changed during judgment verification")
        matches_head = all(
            result.returncode == 0 and hashlib.sha256(result.stdout).hexdigest() == expected
            for name, expected in hashes.items()
            for result in [subprocess.run(["git", "show", f"HEAD:{name}"], cwd=ROOT,
                                          stdout=subprocess.PIPE, stderr=subprocess.PIPE)]
        )
        report = {
            "schema": "usul.ida.source-bound-judgments.v1", "status": "passed",
            "revision": revision, "inputs_match_head": matches_head, "source_sha256": hashes,
            "runtime_overrides": overrides,
            "tools": {"lean_pin": pin, "lean": lean_version, "quint": quint_version,
                      "node": command(["node", "--version"]).stdout.strip()},
            "coverage": {"question_tags": 6, "answer_tags": 36, "admission_states": 4,
                         "fixture_variants": 34, "total_inputs": ROW_COUNT,
                         "bounds": "declared base fixture and perturbations; arbitrary records covered by Lean theorems"},
            "quint_tests": sorted(required_tests()), "parser_controls": parser_controls,
            "quint_dependencies": quint_imports,
            "compiler_type_controls": [control["name"] for control in type_controls],
            "contract_vectors": vectors, "semantic_mutants": mutants,
            "compiled_audit": {"modules": axioms["modules"],
                               "declarations": len(axioms["declarations"]),
                               "theorems": sum(d["kind"] == "theorem" for d in axioms["declarations"]),
                               "required_obligations": len(required_theorems()),
                               "negative_controls": axioms["negative_controls"]},
            "boundary": {
                "proved": "typed single-source replay and exact bindings under an explicitly trusted snapshot",
                "agreement": "complete within the declared finite fixture family",
                "not_established": ["source/passage byte authentication", "juristic interpretation",
                                    "admission authority authentication", "general inference or derivation DAG",
                                    "multi-source lookup", "concurrent snapshot/revocation storage",
                                    "runtime refinement", "cryptographic receipt signatures"],
            },
        }
        staged = work / "receipts"
        staged.mkdir()
        (staged / "report.json").write_text(json.dumps(report, indent=2) + "\n")
        (staged / "compiled-axioms.json").write_text(json.dumps(axioms, indent=2) + "\n")
        (staged / "compiler-type-controls.json").write_text(json.dumps(type_controls, indent=2) + "\n")
        (staged / "lean.csv").write_text(lean_csv)
        shutil.copyfile(itf, staged / "quint.itf.json")
        shutil.copyfile(tests_path, staged / "quint-tests.json")
        staged.rename(RECEIPTS)
        print(f"IDA judgments: PASS; {len(required_theorems())} fixed proof obligations; "
              f"{len(mutants)} semantic mutants rejected; inputs_match_head={matches_head}.")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, subprocess.SubprocessError) as exc:
        raise SystemExit(f"IDA judgment verification failed: {exc}") from exc
