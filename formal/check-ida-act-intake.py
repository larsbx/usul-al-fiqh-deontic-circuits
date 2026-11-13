#!/usr/bin/env python3
"""Verify candidate-only intake through Lean, independent Quint, and the host CLI."""

from copy import deepcopy
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


GATE = module("intake_registry_gate", ROOT / "formal/check-ida-act-registry.py")
HOST = module("intake_host", ROOT / "formal/ida-act-intake.py")
WIRE, AUDIT, COMMON = GATE.WIRE, GATE.AUDIT, GATE.COMMON
command, lake, quint, require = GATE.command, GATE.lake, GATE.quint, GATE.require
LEAN, QUINT = GATE.LEAN, GATE.QUINT
RECEIPT = ROOT / ".cache/ida-act-intake"
CORE, TEST = "Usul.Typing.IDAActIntake", "UsulTest.IDAActIntake"
CONTRACTS, SCRIPT = "UsulTest.IDAActIntakeContracts", "scripts.CheckIDAActIntake"
SEED = "20261113"
MATRIX_ROWS = 14 * 36
HOST_TESTS = 27
QUINT_FILES = ("ida.qnt", "ida-judgment.qnt", "ida-derivation.qnt",
               "ida-act-registry.qnt", "ida-act-intake.qnt")
OBLIGATIONS = {
    "prepare_retains_input", "prepare_preserves_fields", "prepared_resolves",
    "prepared_registered", "prepared_signature", "prepared_role_order", "prepared_pins",
    "prepared_wellFormed", "prepared_unique", "prepared_target_exact", "unresolved_rejected",
    "conflict_precedes_input", "qualifications_distinguished", "operands_distinguished",
}
WITNESSES = {
    "preparation_matrix", "signature_is_derived", "same_sort_swap_retained",
    "qualifications_and_context_retained", "unresolved_is_not_unknown", "malformed_operands_rejected",
}


def input_paths():
    modules = GATE.lean_closure([CONTRACTS, SCRIPT])
    paths = {"formal/lean/" + name.replace(".", "/") + ".lean" for name in modules}
    _, source_inputs = HOST.REFERENCE.load_inputs(ROOT)
    paths.update(source_inputs)
    paths.update("formal/quint/" + name for name in QUINT_FILES)
    paths.update({
        "formal/check-ida-act-intake.py", "formal/ida-act-intake.py",
        "formal/ida-act-intake-mutations.json", "pipeline/tests/test_act_intake.py",
        "formal/check-ida-act-registry.py", "formal/ida-act-registry-wire.py",
        "formal/check-ida.py", "formal/check-lean-axioms.py", "formal/lean-axiom-audit.lean",
        "formal/fixtures/ida-act-registry/description.json", "formal/lean/lakefile.toml",
        "formal/lean/lake-manifest.json", "formal/lean/lean-toolchain",
        "formal/lean/Usul.lean", "formal/lean/UsulTest.lean",
        "formal/quint/package.json", "formal/quint/package-lock.json",
        "docs/research/ida-act-intake.md", "docs/research/ida-act-reference.md",
        "docs/research/ida-case-workbench.md", "docs/research/ida-act-classification-roadmap.md",
        "docs/plain-english/Usul/Typing/IDAActIntake.md",
        "docs/plain-english/UsulTest/IDAActIntake.md",
        "docs/plain-english/UsulTest/IDAActIntakeContracts.md",
        "docs/plain-english/scripts/CheckIDAActIntake.md",
        ".github/workflows/ida-act-intake.yml", "Makefile",
    })
    paths.update(str(p.relative_to(ROOT)) for p in (ROOT / "formal/fixtures/ida-act-intake").glob("*.json"))
    return sorted(paths)


def fingerprint():
    return {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in input_paths()}


def copy_quint(directory):
    directory.mkdir()
    for name in QUINT_FILES:
        shutil.copyfile(QUINT / name, directory / name)


def run_table(directory, body, count):
    model = directory / "table.qnt"
    model.write_text('module intakeTable {\nimport ida as A from "./ida"\n'
                     'import idaActRegistry as R from "./ida-act-registry"\n'
                     'import idaActIntake as I from "./ida-act-intake"\n' + body + '\n}\n')
    quint("typecheck", model)
    trace_path = directory / "trace.itf.json"
    quint("run", model, "--main", "intakeTable", "--backend", "typescript",
          "--max-samples", "1", "--max-steps", "0", "--seed", SEED,
          "--out-itf", trace_path, "--verbosity", "0")
    trace = json.loads(trace_path.read_text())
    return GATE.parse_itf(trace, count), trace


def parse_matrix(text):
    rows = text.splitlines()
    require(len(rows) == MATRIX_ROWS, "Incomplete Lean intake matrix")
    values = []
    for index, row in enumerate(rows):
        require(re.fullmatch(r"(0|[1-9][0-9]*),(0|[1-9][0-9]*),(0|[1-9][0-9]*)", row),
                "Noncanonical Lean matrix row")
        r, i, code = map(int, row.split(","))
        require((r, i) == divmod(index, 36) and 0 <= code <= 9,
                "Duplicate, reordered, or invalid Lean matrix row")
        values.append(code)
    return values


def matrix_compare(work):
    path = work / "ExportIntakeMatrix.lean"
    path.write_text("import UsulTest.IDAActIntake\n"
                    "def main : IO Unit := do\n"
                    "  for r in List.range 14 do\n"
                    "    for i in List.range 36 do\n"
                    '      IO.println s!"{r},{i},{UsulTest.IDAActIntake.preparationCode r i}"\n')
    csv_text = lake("env", "lean", "--run", path).stdout
    expected = parse_matrix(csv_text)
    directory = work / "matrix-quint"
    copy_quint(directory)
    calls = [f"I::preparationCode({r},{i})" for r in range(14) for i in range(36)]
    body = "var results: List[int]\naction init = results' = List(" + ",".join(calls) + ")\naction step = init"
    values, trace = run_table(directory, body, MATRIX_ROWS)
    require(values == expected, "Independent Lean/Quint intake matrix disagreement")
    return csv_text, trace


def expected_result(value, code):
    if code:
        return {"code": code, "envelope": None, "definition": None}
    selected = [d for d in value["registry"]["definitions"] if d["key"] == value["input"]["key"]]
    require(len(selected) == 1 and all(r["kind"] is not None for r in selected[0]["roles"]),
            "Positive fixture lacks one complete registered definition")
    definition, supplied = selected[0], value["input"]
    envelope = {name: deepcopy(supplied[name]) for name in
                ("key", "definitionDigest", "registrySnapshot", "qualifications", "context")}
    envelope["action"] = {
        "operation": {"symbol": deepcopy(definition["key"]["symbol"]), "parameters": deepcopy(definition["roles"])},
        "operands": deepcopy(supplied["operands"]),
    }
    return {"code": 0, "envelope": envelope, "definition": deepcopy(definition)}


def wire_cases(catalogue):
    old = WIRE.decode((ROOT / "formal/fixtures/ida-act-registry/description.json").read_bytes())
    base = {"registry": old["registry"], "input": {k: deepcopy(v) for k, v in old["envelope"].items() if k != "action"}}
    base["input"]["operands"] = deepcopy(old["envelope"]["action"]["operands"])
    cases = [("synthetic_repayment", deepcopy(base), 0)]

    def variant(name, mutate, code):
        value = deepcopy(base)
        mutate(value)
        cases.append((name, value, code))

    variant("duplicate_registry_key", lambda v: v["registry"]["definitions"].append(deepcopy(v["registry"]["definitions"][0])), 1)
    variant("malformed_registry_role", lambda v: v["registry"]["definitions"][0]["roles"][0].update(role=""), 2)
    variant("stale_registry_snapshot", lambda v: v["input"].update(registrySnapshot=2), 3)
    variant("unknown_kind", lambda v: v["input"]["key"]["symbol"].update(name="unknown"), 4)
    variant("unknown_kind_version", lambda v: v["input"]["key"].update(version=2), 4)
    variant("stale_digest", lambda v: v["input"]["definitionDigest"].__setitem__(0, (v["input"]["definitionDigest"][0] + 1) % 256), 5)
    variant("reordered_roles", lambda v: v["input"]["operands"].reverse(), 8)
    variant("missing_operand", lambda v: v["input"]["operands"].pop(), 8)
    variant("extra_operand", lambda v: v["input"]["operands"].append(deepcopy(v["input"]["operands"][0])), 8)
    variant("wrong_role", lambda v: v["input"]["operands"][0].update(role="owner"), 8)
    variant("wrong_reference_sort", lambda v: v["input"]["operands"][0]["referent"].update(kind="asset"), 8)
    variant("empty_reference_name", lambda v: v["input"]["operands"][0]["referent"]["symbol"].update(name=""), 9)
    variant("malformed_qualification", lambda v: v["input"]["qualifications"][0].update(version=0), 9)
    variant("malformed_clock", lambda v: v["input"]["context"]["clock"].update(space=""), 9)
    variant("qualification_polarity_retained", lambda v: v["input"]["qualifications"][0].update(polarity=False), 0)
    variant("qualification_order_retained", lambda v: v["input"]["qualifications"].append({**deepcopy(v["input"]["qualifications"][0]), "polarity": False}), 0)
    variant("empty_qualifications_retained", lambda v: v["input"].update(qualifications=[]), 0)

    def swap(value):
        operands = value["input"]["operands"]
        operands[0]["referent"], operands[1]["referent"] = operands[1]["referent"], operands[0]["referent"]

    variant("same_sort_participants_retained", swap, 0)
    for field in base["input"]["context"]:
        def change(value, field=field):
            if field == "clock":
                value["input"]["context"][field]["name"] += "-other"
            else:
                value["input"]["context"][field] += 1
        variant("context_" + field + "_retained", change, 0)
    definitions = catalogue["registry"]["definitions"]
    require(len(definitions) == 34 and sum(bool(e["unresolved_roles"]) for e in catalogue["entries"]) == 33
            and sum(len(e["unresolved_roles"]) for e in catalogue["entries"]) == 64,
            "Catalogue changed: explicitly review candidate outcomes and remaining roles")
    for definition in definitions:
        value = deepcopy(base)
        value["registry"] = deepcopy(catalogue["registry"])
        value["input"].update(key=deepcopy(definition["key"]), definitionDigest=definition["digest"].copy())
        # A caller's attempted placeholder exercises rejection; registry None is unchanged.
        value["input"]["operands"] = [
            {"role": r["role"], "referent": {"kind": r["kind"] or "obligation",
             "symbol": {"space": "test.intake", "name": r["role"]}}} for r in definition["roles"]]
        code = 6 if any(r["kind"] is None for r in definition["roles"]) else 0
        cases.append(("catalogue:" + definition["key"]["symbol"]["name"], value, code))
    return cases


def check_wire(cases, actual):
    require(type(actual) is list and len(actual) == len(cases), "Incomplete Lean wire output")
    for (name, value, code), returned in zip(cases, actual):
        WIRE.fields(returned, ("code", "envelope", "definition"), "Lean intake result")
        require(type(returned["code"]) is int, "Noninteger Lean intake code")
        if returned["code"] == 0:
            WIRE.definition(returned["definition"])
            WIRE.envelope(returned["envelope"])
        require(returned == expected_result(value, code), "Wire code or retained payload mismatch: " + name)


def wire_compare(work, catalogue):
    cases = wire_cases(catalogue)
    actual = HOST.lean_prepare([value for _, value, _ in cases])
    check_wire(cases, actual)
    directory = work / "wire-quint"
    copy_quint(directory)
    declarations, calls, registries = [], [], {}
    for index, (_, value, code) in enumerate(cases):
        registry_bytes = WIRE.canonical(value["registry"])
        if registry_bytes not in registries:
            registries[registry_bytes] = len(registries)
            declarations.append(f"pure val r{registries[registry_bytes]}: R::Registry = {GATE.qnt(value['registry'])}")
        declarations.append(f"pure val i{index}: I::Input = {GATE.qnt(value['input'])}")
        declarations.append(f"pure val p{index}: I::Result = I::prepare(r{registries[registry_bytes]},i{index})")
        expected = expected_result(value, code)
        envelopes = [] if code else [expected["envelope"]]
        definitions = [] if code else [expected["definition"]]
        declarations.append(f"pure val es{index}: List[R::Envelope] = {GATE.qnt(envelopes)}")
        declarations.append(f"pure val ds{index}: List[R::Definition] = {GATE.qnt(definitions)}")
        calls.extend((f"I::resultCode(p{index})", f"if (I::draftEnvelopes(p{index}) == es{index} and "
                      f"I::draftDefinitions(p{index}) == ds{index}) 1 else 0"))
    body = "\n".join(declarations) + "\nvar results: List[int]\naction init = results' = List(" + ",".join(calls) + ")\naction step = init"
    values, trace = run_table(directory, body, 2 * len(cases))
    expected_cells = [cell for _, _, code in cases for cell in (code, 1)]
    require(values == expected_cells, "Independent Quint code or full retained payload disagreement")
    return cases, actual, trace


def compiled_audit(work):
    modules = GATE.lean_closure([CONTRACTS])
    allowed = modules | {SCRIPT}
    for name in ("Init", "Lean", "Std"):
        require(not (LEAN / name).exists() and not (LEAN / (name + ".lean")).exists(), "Standard-library shadow")
    body = (ROOT / "formal/lean-axiom-audit.lean").read_text()

    def inspect(imports, roots, expected):
        path = work / "InspectIntake.lean"
        path.write_text("import Lean\n" + "".join("import " + n + "\n" for n in imports)
            + "private def auditRoots : List String := " + json.dumps(roots) + "\n"
            + "private def allowed : List String := " + json.dumps(sorted(allowed | expected)) + "\n"
            + "open Lean Elab Command\nrun_cmd do\n"
            + "  for name in (← getEnv).allImportedModuleNames do\n"
            + "    unless [\"Init\", \"Lean\", \"Std\"].contains name.getRoot.toString || allowed.contains name.toString do\n"
            + "      throwError m!\"Unexpected project import: {name}\"\n" + body)
        result = lake("env", "lean", path, env={"LEAN_PATH": str(work)})
        require(not result.stderr.strip(), "Unexpected audit diagnostics: " + result.stderr)
        return AUDIT.parse_inventory(result.stdout, expected)

    declarations = inspect([CONTRACTS], ["Usul", "UsulTest"], modules)
    names = {d["name"] for d in declarations if d["kind"] == "theorem"}
    required = {"Usul.IDA.ActIntake." + n for n in OBLIGATIONS}
    required |= {"UsulTest.IDAActIntake." + n for n in WITNESSES}
    wrappers = {CONTRACTS + ".require_" + n for n in OBLIGATIONS | WITNESSES}
    require(required <= names, "Missing required intake proofs: " + str(sorted(required - names)))
    require(wrappers <= names, "Missing fixed intake proposition contracts: " + str(sorted(wrappers - names)))
    target = work / "scripts/CheckIDAActIntake.olean"
    target.parent.mkdir()
    result = lake("env", "lean", "scripts/CheckIDAActIntake.lean", "-o", target)
    require("declaration uses `sorry`" not in result.stdout + result.stderr, "Admitted wire proof")
    declarations += inspect([SCRIPT], ["scripts"], {SCRIPT})
    controls = []
    for name, source in {"IntakePrivateAxiomProbe": "private axiom hidden : True\n",
                         "IntakeSorryProbe": "theorem missing : True := by sorry\n"}.items():
        path = work / (name + ".lean")
        path.write_text(source)
        lake("env", "lean", "--root=" + str(work), path, "-o", path.with_suffix(".olean"))
        try:
            inspect([name], [name], {name})
        except ValueError as exc:
            require("Disallowed Lean declarations or axiom dependencies" in str(exc), "Axiom probe failed for unrelated reason")
            controls.append(name)
        else:
            raise ValueError("Compiled axiom probe survived")
    return {"modules": sorted(modules), "required_obligations": sorted(required),
            "typed_contracts": sorted(wrappers), "allowed_axioms": sorted(AUDIT.ALLOWED),
            "negative_controls": controls, "declarations": declarations}


def proposition_control(work):
    source = (LEAN / "Usul/Typing/IDAActIntake.lean").read_text()
    before = """theorem conflict_precedes_input (r : Registry) (i : Input) (h : ¬ r.Unique) :
    prepare r i = .error .registryConflict := by simp [prepare, selectOperation, h]"""
    after = """theorem conflict_precedes_input (r : Registry) (i : Input) (h : ¬ r.Unique) :
    True := by trivial"""
    require(source.count(before) == 1, "Ambiguous proposition mutation")
    path = work / "IntakeWeakProof.lean"
    path.write_text(source.replace(before, after))
    lake("env", "lean", "--root=" + str(work), path, "-o", path.with_suffix(".olean"))
    contract = work / "IntakeWeakContract.lean"
    contract.write_text("import IntakeWeakProof\nopen Usul.IDA.ActRegistry Usul.IDA.ActIntake\n"
        "example : ∀ (r : Registry) (i : Input), ¬ r.Unique → prepare r i = .error .registryConflict :=\n"
        "  conflict_precedes_input\n")
    result = lake("env", "lean", contract, env={"LEAN_PATH": str(work)}, fail=False)
    diagnostic = result.stdout + result.stderr
    require(result.returncode != 0 and "type mismatch" in diagnostic.lower()
            and "conflict_precedes_input" in diagnostic, "Weak theorem failed for unrelated reason: " + diagnostic)
    return "same_named_intake_theorem_weakened_to_true"


def semantic_controls(work, specification):
    source = (QUINT / "ida-act-intake.qnt").read_text()
    results = []
    for mutation in specification["mutations"]:
        changed = source
        for before, after in mutation["replacements"]:
            require(changed.count(before) == 1, "Ambiguous semantic mutation: " + mutation["name"])
            changed = changed.replace(before, after)
        directory = work / mutation["name"]
        copy_quint(directory)
        model = directory / "ida-act-intake.qnt"
        model.write_text(changed)
        quint("typecheck", model)
        result = quint("test", model, "--main", "idaActIntake", "--backend", "typescript",
                       "--max-samples", "1", "--seed", SEED, "--match", "^" + mutation["test"] + "$", fail=False)
        diagnostic = result.stdout + result.stderr
        require(result.returncode != 0 and "Assertion failed" in diagnostic
                and re.findall(r"Error \[(QNT\d+)\]", diagnostic) == ["QNT508"],
                "Mutation survived or failed before assertion: " + mutation["name"] + "\n" + diagnostic)
        results.append({"name": mutation["name"], "test": mutation["test"], "failure": "QNT508 Assertion failed"})
    return results


def export_controls(csv_text, matrix_trace, cases, actual):
    rejected = []
    reject = GATE.expect_rejection
    lines = csv_text.splitlines()
    rejected.append(reject(lambda: parse_matrix("\n".join(lines[:-1])), "truncated_lean_matrix"))
    duplicate = lines.copy()
    duplicate[1] = duplicate[0]
    rejected.append(reject(lambda: parse_matrix("\n".join(duplicate)), "duplicate_lean_row"))
    truncated = deepcopy(matrix_trace)
    truncated["states"][0]["results"].pop()
    rejected.append(reject(lambda: GATE.parse_itf(truncated, MATRIX_ROWS), "truncated_quint_matrix"))
    malformed = deepcopy(matrix_trace)
    malformed["states"][0]["results"][0] = {"#bigint": "00"}
    rejected.append(reject(lambda: GATE.parse_itf(malformed, MATRIX_ROWS), "noncanonical_quint_integer"))
    rejected.append(reject(lambda: check_wire(cases, actual[:-1]), "missing_wire_result"))
    changed = deepcopy(actual)
    changed[0]["code"] = 9
    rejected.append(reject(lambda: check_wire(cases, changed), "changed_wire_code"))
    changed = deepcopy(actual)
    changed[0]["envelope"]["qualifications"] = []
    rejected.append(reject(lambda: check_wire(cases, changed), "discarded_qualification_payload"))
    changed = deepcopy(actual)
    changed[0]["envelope"]["context"]["evidenceRevision"] += 1
    rejected.append(reject(lambda: check_wire(cases, changed), "changed_context_payload"))
    changed = deepcopy(actual)
    changed[1]["envelope"] = deepcopy(actual[0]["envelope"])
    rejected.append(reject(lambda: check_wire(cases, changed), "draft_attached_to_rejection"))
    changed = deepcopy(actual)
    changed[0]["definition"]["key"]["version"] = True
    rejected.append(reject(lambda: check_wire(cases, changed), "boolean_definition_version"))
    return rejected


def host_checks(work, catalogue, cases, actual):
    suite = work / "host-tests.xml"
    result = command([sys.executable, "-m", "pytest", "-q", "tests/test_act_intake.py", "--junitxml=" + str(suite)], cwd=ROOT / "pipeline")
    tests = ET.parse(suite).findall(".//testcase")
    require(len(tests) == HOST_TESTS and all(not list(test) for test in tests), "Host test inventory changed or incomplete")
    outcomes = []
    for (name, value, code), returned in zip(cases, actual):
        if not name.startswith("catalogue:"):
            continue
        request = {"format": HOST.FORMAT, "kind": deepcopy(value["input"]["key"]),
                   **{k: deepcopy(v) for k, v in value["input"].items() if k != "key"}}
        output = HOST.result_for(request, catalogue, returned)
        entry = next(e for e in catalogue["entries"] if e["definition"]["key"] == request["kind"])
        require(output["candidate"] == entry and output["status"] == "candidate" and output["admitted"] is False
                and output["ruling"] is None and output["prepared"] == (code == 0)
                and output["catalogue"]["source_metadata_checked"] is True
                and output["catalogue"]["source_bytes_verified"] is False,
                "Host lost candidate provenance or crossed its evidence boundary: " + name)
        outcomes.append({"name": name, "code": code, "outcome": output["outcome"]})
    require(len(outcomes) == 34, "Host catalogue coverage")
    positive = HOST.decode_request((ROOT / "formal/fixtures/ida-act-intake/zakat-request.json").read_bytes())
    unresolved = HOST.decode_request((ROOT / "formal/fixtures/ida-act-intake/unresolved-agency-request.json").read_bytes())
    swapped, bad_role, unknown = deepcopy(positive), deepcopy(positive), deepcopy(positive)
    persons = [i for i, operand in enumerate(swapped["operands"]) if operand["referent"]["kind"] == "person"]
    require(len(persons) >= 2, "Positive fixture needs distinct same-sort participants")
    a, b = persons[:2]
    swapped["operands"][a]["referent"], swapped["operands"][b]["referent"] = swapped["operands"][b]["referent"], swapped["operands"][a]["referent"]
    bad_role["operands"][0]["role"] = "unregistered-role"
    unknown["kind"]["symbol"]["name"] = "unlisted-kind"
    runs = []
    for name, request, code in (("zakat_candidate", positive, 0), ("participants_swapped", swapped, 0),
                                ("wrong_role", bad_role, 8), ("unknown_kind", unknown, 4),
                                ("unresolved_agency", unresolved, 6)):
        path = work / (name + ".json")
        path.write_bytes(WIRE.canonical(request))
        execution = command([sys.executable, ROOT / "formal/ida-act-intake.py", "prepare", path])
        output = json.loads(execution.stdout)
        require(not execution.stderr.strip() and output["code"] == code
                and output["request"] == request and output["admitted"] is False
                and output["ruling"] is None and output["prepared"] == (code == 0),
                "Real CLI preparation mismatch: " + name)
        runs.append({"name": name, "result": output})
    require(runs[0]["result"]["target"] != runs[1]["result"]["target"], "Host collapsed distinct participants")
    return {"unit_tests": len(tests), "unit_test_names": [t.attrib["name"] for t in tests],
            "catalogue_outcomes": outcomes, "real_cli_cases": len(runs)}, runs


def main():
    if RECEIPT.exists():
        shutil.rmtree(RECEIPT)
    RECEIPT.parent.mkdir(parents=True, exist_ok=True)
    revision = command(["git", "rev-parse", "HEAD"]).stdout.strip()
    hashes, overrides = fingerprint(), COMMON.runtime_overrides()
    require(not os.environ.get("NODE_OPTIONS", "").strip(), "Unsupported NODE_OPTIONS")
    pin = (LEAN / "lean-toolchain").read_text().strip()
    version = lake("env", "lean", "--version").stdout.strip()
    require(version.startswith("Lean (version " + pin.removeprefix("leanprover/lean4:v") + ","), "Lean version mismatch")
    require(not json.loads((LEAN / "lake-manifest.json").read_text()).get("packages"), "Unexpected external Lean package")
    require(quint("--version").stdout.strip() == "0.33.1", "Quint version mismatch")
    require(json.loads((QUINT / "package.json").read_text())["devDependencies"]["@informalsystems/quint"] == "0.33.1"
            and json.loads((QUINT / "package-lock.json").read_text())["packages"]["node_modules/@informalsystems/quint"]["version"] == "0.33.1",
            "Quint lock mismatch")
    specification = json.loads((ROOT / "formal/ida-act-intake-mutations.json").read_text())
    with tempfile.TemporaryDirectory(prefix="ida-intake-", dir=RECEIPT.parent) as temporary:
        work = Path(temporary)
        build = lake("build", CORE, TEST, CONTRACTS)
        require("declaration uses `sorry`" not in build.stdout + build.stderr, "Admitted proof diagnostic")
        print("CW-01: Lean intake modules and 20 fixed proposition contracts compiled.", flush=True)
        quint("typecheck", QUINT / "ida-act-intake.qnt")
        tests_path = work / "quint-tests.json"
        quint("test", QUINT / "ida-act-intake.qnt", "--main", "idaActIntake", "--backend", "typescript",
              "--max-samples", "1", "--seed", SEED, "--match", "^(" + "|".join(specification["required_tests"]) + ")$",
              "--out", tests_path)
        tests = json.loads(tests_path.read_text())
        require(tests.get("stage") == "testing" and tests.get("failed") == []
                and all(tests.get(k, []) == [] for k in ("ignored", "warnings", "errors")), "Incomplete Quint tests")
        require(set(tests.get("passed", [])) == set(specification["required_tests"])
                and len(tests["passed"]) == len(specification["required_tests"]), "Quint test inventory mismatch")
        csv_text, matrix_trace = matrix_compare(work)
        catalogue = HOST.load_catalogue()
        cases, actual, wire_trace = wire_compare(work, catalogue)
        print(f"CW-01: independent agreement on 504 matrix cases and {len(cases)} complete wire outcomes.", flush=True)
        audit = compiled_audit(work)
        weakened = proposition_control(work)
        controls = export_controls(csv_text, matrix_trace, cases, actual)
        mutations = semantic_controls(work, specification)
        host, host_results = host_checks(work, catalogue, cases, actual)
        print(f"CW-01: {len(mutations)} semantic mutants rejected; {HOST_TESTS} host tests and 5 actual CLI executions passed.", flush=True)
        require(fingerprint() == hashes and COMMON.runtime_overrides() == overrides
                and command(["git", "rev-parse", "HEAD"]).stdout.strip() == revision, "Inputs changed during verification")
        matches = all(r.returncode == 0 and hashlib.sha256(r.stdout).hexdigest() == h
                      for p, h in hashes.items()
                      for r in [subprocess.run(["git", "show", revision + ":" + p], cwd=ROOT, capture_output=True)])
        report = {"schema": "usul.ida.act-intake.verification.v1", "status": "passed", "revision": revision,
            "inputs_match_head": matches, "source_sha256": hashes, "runtime_overrides": overrides,
            "tools": {"lean": version, "quint": "0.33.1", "node": command(["node", "--version"]).stdout.strip()},
            "coverage": {"matrix_cases": MATRIX_ROWS, "wire_cases": len(cases),
                         "comparison_cells": MATRIX_ROWS + 2 * len(cases), "candidate_kinds": 34,
                         "unresolved_kinds": 33, "unresolved_roles": 64},
            "required_proofs": sorted(OBLIGATIONS), "scenario_witnesses": sorted(WITNESSES),
            "typed_contracts": len(audit["typed_contracts"]), "compiled_declarations": len(audit["declarations"]),
            "quint_tests": tests["passed"], "wire_case_names": [name for name, _, _ in cases],
            "export_controls": controls, "semantic_mutants": mutations,
            "compiled_controls": audit["negative_controls"] + [weakened], "host": host,
            "boundary": {"proved": "registered structural preparation and exact retention of the supplied input",
                "trusted_inputs": ["candidate source-metadata validator", "canonical definition hashing", "selected repository catalogue"],
                "not_claimed": ["full source witness byte verification", "qualification truth", "actual occurrence",
                    "correctness of source interpretation", "unresolved role classification", "narrative extraction",
                    "source premise admission", "application authorization", "fiqh ruling", "general JSON parser refinement"]}}
        staged = work / "receipts"
        staged.mkdir()
        for name, value in (("report.json", report), ("compiled-axioms.json", audit), ("catalogue.json", catalogue),
                            ("wire-inputs.json", [v for _, v, _ in cases]), ("wire-results.json", actual),
                            ("matrix.itf.json", matrix_trace), ("wire.itf.json", wire_trace), ("host-results.json", host_results)):
            (staged / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n")
        (staged / "lean-matrix.csv").write_text(csv_text)
        shutil.copyfile(tests_path, staged / "quint-tests.json")
        shutil.copyfile(work / "host-tests.xml", staged / "host-tests.xml")
        staged.rename(RECEIPT)
        print(f"CW-01: PASS; 20 typed contracts; inputs_match_head={matches}.", flush=True)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.SubprocessError) as exc:
        raise SystemExit("CW-01 candidate intake verification failed: " + str(exc)) from exc
