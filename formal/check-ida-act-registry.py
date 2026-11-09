#!/usr/bin/env python3
"""Verify the ACT-01 registry, canonical data boundary, and bound source gate."""

from copy import deepcopy
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
RECEIPT = ROOT / ".cache/ida-act-registry"
SEED = "20261109"
ROWS = 14 * 36 + 36 * 10 * 12
CELLS = ROWS * 2
CORE = "Usul.Typing.IDAActRegistry"
TEST = "UsulTest.IDAActRegistry"
CONTRACTS = "UsulTest.IDAActRegistryContracts"
SCRIPTS = ("ExportIDAActRegistry", "CheckIDAActRegistryWire")
OBLIGATIONS = {
    "resolve_iff", "resolve_registered", "resolve_unique", "resolve_schema",
    "resolve_wellFormed", "registry_conflict_precedes_lookup", "unresolved_not_resolved",
    "checked_target_exact", "project_action_iff", "projection_omits_qualifications",
    "projection_omits_context", "admit_iff", "admitted_resolution", "admitted_exact_binding",
    "admitted_target", "admitted_snapshot", "admitted_source", "admitted_source_authority",
    "admitted_binding_fields", "altered_envelope_rejected", "changed_qualification_rejected",
    "changed_snapshot_rejected", "source_rejection_blocks", "non_admitted_rejected",
    "duplicate_bindings_rejected", "target_mismatch_rejected", "context_mismatch_rejected",
    "receipt_binds_all", "receipt_preserves_source", "definition_roundtrip",
    "definition_decode_sound", "envelope_roundtrip", "envelope_decode_sound",
    "kind_roundtrip", "kind_decode_sound", "decodeList_encode", "decodeList_sound",
    "role_roundtrip", "role_decode_sound", "ref_roundtrip", "ref_decode_sound",
    "parameter_roundtrip", "parameter_decode_sound", "operand_roundtrip", "operand_decode_sound",
    "action_roundtrip", "action_decode_sound", "qualification_roundtrip", "qualification_decode_sound",
    "resolved_roles_exact", "resolve_declared_schema", "unresolved_member_rejected",
}
WITNESSES = {
    "structural_matrix", "bound_guard_matrix", "actual_source_matrix",
    "same_target_changed_qualification", "wrong_target_independently_blocked",
    "snapshot_coordinates_independently_blocked", "candidate_structurally_checked_but_not_admitted",
    "unresolved_ne_unknown", "projection_is_lossy", "omitted_metadata_independently_blocked",
    "independent_sources_share_envelope", "wire_negative_controls",
}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


WIRE = module("ida_act_wire", ROOT / "formal/ida-act-registry-wire.py")
COMMON = module("ida_common", ROOT / "formal/check-ida.py")
AUDIT = module("ida_compiled_audit", ROOT / "formal/check-lean-axioms.py")


def command(args, cwd=ROOT, env=None, fail=True):
    result = subprocess.run([str(x) for x in args], cwd=cwd, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=300,
                            env={**os.environ, "NO_COLOR": "1", **(env or {})})
    require(not fail or result.returncode == 0,
            f"Command failed: {args}\n{result.stdout}\n{result.stderr}")
    return result


def lake(*args, **kwargs):
    return command(["lake", *args], cwd=LEAN, **kwargs)


def quint(*args, **kwargs):
    return command(["node", CLI, *args], **kwargs)


def lean_closure(roots):
    found = set()
    def visit(name):
        if name in found or name.split(".")[0] in ("Init", "Lean", "Std"):
            return
        path = LEAN / (name.replace(".", "/") + ".lean")
        require(path.is_file(), "Missing project dependency: " + name)
        found.add(name)
        for dependency in re.findall(r"^import ([A-Za-z0-9_.]+)$", path.read_text(), re.M):
            visit(dependency)
    for name in roots:
        visit(name)
    return found


def input_paths():
    modules = lean_closure([CONTRACTS, *("scripts." + name for name in SCRIPTS)])
    paths = {"formal/lean/" + name.replace(".", "/") + ".lean" for name in modules}
    paths.update({
        "formal/check-ida-act-registry.py", "formal/ida-act-registry-wire.py",
        "formal/check-ida.py", "formal/check-lean-axioms.py", "formal/lean-axiom-audit.lean",
        "formal/ida-act-registry-mutations.json", "formal/fixtures/ida-act-registry/description.json",
        "formal/lean/lakefile.toml", "formal/lean/lake-manifest.json", "formal/lean/lean-toolchain",
        "formal/lean/Usul.lean", "formal/lean/UsulTest.lean", "formal/quint/package.json",
        "formal/quint/package-lock.json", "formal/quint/ida.qnt", "formal/quint/ida-judgment.qnt",
        "formal/quint/ida-derivation.qnt", "formal/quint/ida-act-registry.qnt",
        "formal/quint/ida-act-registry-table.qnt", "corpus/proposals/fiqh-acts/reference.json",
        "docs/research/ida-act-registry.md", "docs/research/ida-act-classification-roadmap.md",
        "docs/plain-english/Usul/Typing/IDAActRegistry.md",
        "docs/plain-english/UsulTest/IDAActRegistry.md",
        "docs/plain-english/UsulTest/IDAActRegistryContracts.md",
        "docs/plain-english/scripts/ExportIDAActRegistry.md",
        "docs/plain-english/scripts/CheckIDAActRegistryWire.md",
        ".github/workflows/ida-act-registry.yml", "Makefile",
    })
    return sorted(paths)


def fingerprint():
    return {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in input_paths()}


def row_keys():
    for r in range(14):
        for e in range(36):
            yield "structural", r, e, 0
    for e in range(36):
        for b in range(10):
            for s in range(12):
                yield "bound", e, b, s


def parse_csv(text):
    rows = list(csv.reader(io.StringIO(text)))
    require(rows and rows.pop(0) == ["family", "x", "y", "z", "code", "baseIssue"], "Bad Lean table header")
    require(len(rows) == ROWS, "Wrong Lean row count")
    values = []
    for row, expected in zip(rows, row_keys()):
        require(len(row) == 6 and all(re.fullmatch(r"0|[1-9][0-9]*", s) for s in row[1:]), "Noncanonical Lean row")
        require((row[0], *(int(x) for x in row[1:4])) == expected, "Missing, reordered, or duplicate Lean row")
        code, issue = map(int, row[4:])
        require(0 <= code <= 16 and 0 <= issue <= 24, "Output outside declared code range")
        require(code == 15 or issue == 0, "Source issue leaked outside source-rejection outcome")
        values.extend((code, issue))
    return values


def parse_itf(trace, count):
    require(trace.get("#meta", {}).get("format") == "ITF"
            and trace["#meta"].get("status") == "ok", "Unsuccessful Quint trace")
    require(trace.get("vars") == ["results"] and len(trace.get("states", [])) == 1, "Unexpected Quint state shape")
    rows = trace["states"][0].get("results")
    require(type(rows) is list and len(rows) == count, "Quint coverage mismatch")
    values = []
    for row in rows:
        require(type(row) is dict and set(row) == {"#bigint"}
                and type(row["#bigint"]) is str and re.fullmatch(r"0|[1-9][0-9]*", row["#bigint"]),
                "Noncanonical Quint integer")
        values.append(int(row["#bigint"]))
    return values


def expect_rejection(fn, name):
    try:
        fn()
    except ValueError:
        return name
    raise ValueError("Negative control survived: " + name)


def export_controls(csv_text, trace, expected):
    controls = []
    lines = csv_text.splitlines()
    controls.append(expect_rejection(lambda: parse_csv("\n".join(lines[:-1])), "truncated_lean"))
    duplicate = lines.copy(); duplicate[2] = duplicate[1]
    controls.append(expect_rejection(lambda: parse_csv("\n".join(duplicate)), "duplicate_lean_row"))
    short = deepcopy(trace); short["states"][0]["results"].pop()
    controls.append(expect_rejection(lambda: parse_itf(short, CELLS), "truncated_quint"))
    invalid = deepcopy(trace); invalid["states"][0]["results"][0] = {"#bigint": "00"}
    controls.append(expect_rejection(lambda: parse_itf(invalid, CELLS), "noncanonical_quint_integer"))
    invalid = deepcopy(trace); invalid["#meta"]["status"] = "error"
    controls.append(expect_rejection(lambda: parse_itf(invalid, CELLS), "unsuccessful_quint_trace"))
    wrong = expected.copy(); wrong[0] = (wrong[0] + 1) % 17
    controls.append(expect_rejection(lambda: require(wrong == expected, "model disagreement"), "changed_model_output"))
    return controls


def compiled_audit(work):
    modules = lean_closure([CONTRACTS])
    allowed = modules | {"scripts." + name for name in SCRIPTS}
    for name in ("Init", "Lean", "Std"):
        require(not (LEAN / name).exists() and not (LEAN / (name + ".lean")).exists(), "Standard-library shadow")
    body = (ROOT / "formal/lean-axiom-audit.lean").read_text()
    def inspect(imports, roots, expected):
        path = work / "InspectActRegistry.lean"
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
    required = {"Usul.IDA.ActRegistry." + n for n in OBLIGATIONS}
    required |= {"UsulTest.IDAActRegistry." + n for n in WITNESSES}
    require(required <= names, "Missing required proof obligations: " + str(sorted(required - names)))
    wrappers = {"UsulTest.IDAActRegistryContracts.require_" + n.replace(".", "_") for n in required}
    require(wrappers <= names, "Missing fixed typed proposition contracts: " + str(sorted(wrappers - names)))
    for name in SCRIPTS:
        target = work / "scripts" / (name + ".olean")
        target.parent.mkdir(exist_ok=True)
        result = lake("env", "lean", "scripts/" + name + ".lean", "-o", target)
        require("declaration uses `sorry`" not in result.stdout + result.stderr, "Admitted exporter proof")
        declarations += inspect(["scripts." + name], ["scripts"], {"scripts." + name})
    controls = []
    for name, source in {"ActRegistryPrivateAxiomProbe": "private axiom hidden : True\n",
                         "ActRegistrySorryProbe": "theorem missing : True := by sorry\n"}.items():
        path = work / (name + ".lean"); path.write_text(source)
        lake("env", "lean", "--root=" + str(work), path, "-o", path.with_suffix(".olean"))
        try:
            inspect([name], [name], {name})
        except ValueError as exc:
            require("Disallowed Lean declarations or axiom dependencies" in str(exc), "Axiom probe failed for unrelated reason")
            controls.append(name)
        else:
            raise ValueError("Compiled axiom probe survived")
    return {"modules": sorted(modules), "required_obligations": sorted(required),
            "typed_contracts": sorted(wrappers),
            "allowed_axioms": sorted(AUDIT.ALLOWED), "negative_controls": controls,
            "declarations": declarations}


def proposition_control(work):
    source = (LEAN / "Usul/Typing/IDAActRegistry.lean").read_text()
    before = """theorem registry_conflict_precedes_lookup (r : Registry) (e : Envelope)
    (h : ¬ r.Unique) : resolve r e = .error .registryConflict := by simp [resolve, h]"""
    after = """theorem registry_conflict_precedes_lookup (r : Registry) (e : Envelope)
    (h : ¬ r.Unique) : True := by trivial"""
    require(source.count(before) == 1, "Ambiguous proposition mutation")
    path = work / "ActRegistryWeakProof.lean"
    path.write_text(source.replace(before, after))
    lake("env", "lean", "--root=" + str(work), path, "-o", path.with_suffix(".olean"))
    witness = work / "ActRegistryWeakContract.lean"
    witness.write_text("import ActRegistryWeakProof\nopen Usul.IDA.ActRegistry\n"
        "example : ∀ (r : Registry) (e : Envelope), ¬ r.Unique → resolve r e = .error .registryConflict :=\n"
        "  registry_conflict_precedes_lookup\n")
    result = lake("env", "lean", witness, env={"LEAN_PATH": str(work)}, fail=False)
    diagnostic = result.stdout + result.stderr
    require(result.returncode != 0 and "type mismatch" in diagnostic.lower()
            and "registry_conflict_precedes_lookup" in diagnostic, "Weak theorem failed for unrelated reason: " + diagnostic)
    return "same_named_registry_theorem_weakened_to_true"


def qnt(value, mode=""):
    if value is None: return "R::UnresolvedSort"
    if type(value) is bool: return str(value).lower()
    if type(value) is int: return str(value)
    if type(value) is str: return json.dumps(value, ensure_ascii=False)
    if type(value) is list: return "List(" + ",".join(qnt(v, mode) for v in value) + ")"
    result = []
    for key, val in value.items():
        if key == "kind":
            if val is None: text = "R::UnresolvedSort"
            else:
                text = "A::" + val.title() + "Ref"
                if mode == "roles": text = "R::DeclaredSort(" + text + ")"
        else:
            text = qnt(val, key)
        result.append(("act" if key == "action" else key) + ":" + text)
    return "{" + ",".join(result) + "}"


def wire_cases():
    base = WIRE.decode((ROOT / "formal/fixtures/ida-act-registry/description.json").read_bytes())
    cases = [("synthetic_repayment", base, 0)]
    def variant(name, mutate, code):
        value = deepcopy(base); mutate(value); cases.append((name, value, code))
    variant("duplicate_definition", lambda x: x["registry"]["definitions"].append(deepcopy(x["registry"]["definitions"][0])), 1)
    variant("stale_registry", lambda x: x["envelope"].__setitem__("registrySnapshot", 2), 3)
    variant("unknown_kind", lambda x: x["envelope"]["key"]["symbol"].__setitem__("name", "unknown"), 4)
    variant("stale_digest", lambda x: x["envelope"]["definitionDigest"].__setitem__(0, (x["envelope"]["definitionDigest"][0]+1)%256), 5)
    variant("self_declared_signature", lambda x: x["envelope"]["action"]["operation"]["parameters"][0].__setitem__("role", "owner"), 7)
    variant("operand_role_reordering", lambda x: x["envelope"]["action"]["operands"].reverse(), 8)
    variant("empty_reference_name", lambda x: x["envelope"]["action"]["operands"][0]["referent"]["symbol"].__setitem__("name", ""), 9)
    variant("qualification_retained", lambda x: x["envelope"]["qualifications"][0].__setitem__("polarity", False), 0)
    variant("evidence_revision_retained", lambda x: x["envelope"]["context"].__setitem__("evidenceRevision", 2), 0)
    catalogue = WIRE.candidate_catalogue(json.loads((ROOT / "corpus/proposals/fiqh-acts/reference.json").read_text()))
    require(len(catalogue["definitions"]) == 34 and len(catalogue["unresolved_role_worklist"]) == 64
            and sum(c["outcome"] == "unresolved_roles" for c in catalogue["candidates"]) == 33,
            "Candidate catalogue inventory changed; review its explicit outcomes")
    for definition in catalogue["definitions"]:
        value = deepcopy(base)
        value["registry"]["definitions"] = deepcopy(catalogue["definitions"])
        e = value["envelope"]
        e["key"], e["definitionDigest"] = deepcopy(definition["key"]), definition["digest"].copy()
        # An attempted obligation placeholder deliberately exercises rejection
        # for unresolved roles. The registry retains None, never this guess.
        params = [{"role": r["role"], "kind": r["kind"] or "obligation"} for r in definition["roles"]]
        e["action"] = {"operation": {"symbol": deepcopy(definition["key"]["symbol"]), "parameters": params},
                       "operands": [{"role": r["role"], "referent": {"kind": r["kind"],
                           "symbol": {"space": "test.argument", "name": r["role"]}}} for r in params]}
        code = 6 if any(r["kind"] is None for r in definition["roles"]) else 0
        cases.append((definition["key"]["symbol"]["name"], value, code))
    for _, value, _ in cases:
        require(WIRE.decode(WIRE.encode(value)) == value, "Wire semantic roundtrip")
    return base, cases, catalogue


def wire_compare(work):
    base, cases, catalogue = wire_cases()
    inputs = work / "wire-inputs.json"
    inputs.write_bytes(WIRE.canonical([value for _, value, _ in cases]))
    result = lake("env", "lean", "--run", "scripts/CheckIDAActRegistryWire.lean", inputs)
    decoded = json.loads(result.stdout)
    require(type(decoded) is list and len(decoded) == len(cases), "Lean wire coverage")
    for (name, value, expected), actual in zip(cases, decoded):
        require(actual == {"code": expected, "registry": value["registry"], "envelope": value["envelope"],
                           "projectedTarget": WIRE.project(value["envelope"])}, "Lean wire field loss or outcome mismatch: " + name)
    directory = work / "wire-quint"; directory.mkdir()
    for name in ("ida.qnt", "ida-judgment.qnt", "ida-derivation.qnt", "ida-act-registry.qnt"):
        shutil.copyfile(QUINT / name, directory / name)
    declarations = []
    calls = []
    registries = {}
    for i, (_, value, _) in enumerate(cases):
        registry_bytes = WIRE.canonical(value["registry"])
        if registry_bytes not in registries:
            registries[registry_bytes] = len(registries)
            declarations.append(f"pure val r{registries[registry_bytes]}: R::Registry = {qnt(value['registry'])}")
        declarations.append(f"pure val e{i}: R::Envelope = {qnt(value['envelope'])}")
        calls.append(f"R::structuralCode(r{registries[registry_bytes]},e{i})")
    model = directory / "wire.qnt"
    model.write_text('module actWire {\nimport ida as A from "./ida"\n'
        'import idaActRegistry as R from "./ida-act-registry"\n' + "\n".join(declarations)
        + "\nvar results: List[int]\naction init = results' = List(" + ",".join(calls)
        + ")\naction step = init\n}\n")
    quint("typecheck", model)
    output = directory / "wire.itf.json"
    quint("run", model, "--main", "actWire", "--backend", "typescript", "--max-samples", "1",
          "--max-steps", "0", "--seed", SEED, "--out-itf", output, "--verbosity", "0")
    values = parse_itf(json.loads(output.read_text()), len(cases))
    require(values == [expected for _, _, expected in cases], "Canonical wire disagrees with independent Quint resolver")
    return {"cases": len(cases), "names": [n for n, _, _ in cases],
            "hostile_controls": WIRE.negative_controls(base)}, catalogue


def semantic_controls(work, specification):
    result = []
    source = (QUINT / "ida-act-registry.qnt").read_text()
    for mutation in specification["mutations"]:
        before, after = mutation["before"], mutation["after"]
        require(source.count(before) == 1, "Ambiguous semantic mutation: " + mutation["name"])
        directory = work / mutation["name"]; directory.mkdir()
        for name in ("ida.qnt", "ida-judgment.qnt", "ida-derivation.qnt"):
            shutil.copyfile(QUINT / name, directory / name)
        (directory / "ida-act-registry.qnt").write_text(source.replace(before, after))
        quint("typecheck", directory / "ida-act-registry.qnt")
        run = quint("test", directory / "ida-act-registry.qnt", "--main", "idaActRegistry", "--backend", "typescript",
                    "--max-samples", "1", "--seed", SEED, "--match", "^" + mutation["test"] + "$", fail=False)
        diagnostic = run.stdout + run.stderr
        require(run.returncode != 0 and "QNT508" in diagnostic and "Assertion failed" in diagnostic,
                "Mutant survived or failed before assertion: " + mutation["name"] + "\n" + diagnostic)
        require(re.findall(r"Error \[(QNT\d+)\]", diagnostic) == ["QNT508"], "Unexpected mutant diagnostics")
        result.append({"name": mutation["name"], "test": mutation["test"], "failure": "QNT508 Assertion failed"})
    return result


def main():
    if RECEIPT.exists(): shutil.rmtree(RECEIPT)
    RECEIPT.parent.mkdir(parents=True, exist_ok=True)
    revision = command(["git", "rev-parse", "HEAD"]).stdout.strip()
    require(not os.environ.get("NODE_OPTIONS", "").strip(), "Unsupported NODE_OPTIONS")
    hashes, overrides = fingerprint(), COMMON.runtime_overrides()
    pin = (LEAN / "lean-toolchain").read_text().strip()
    version = lake("env", "lean", "--version").stdout.strip()
    require(version.startswith("Lean (version " + pin.removeprefix("leanprover/lean4:v") + ","), "Lean version mismatch")
    require(not json.loads((LEAN / "lake-manifest.json").read_text()).get("packages"), "Unexpected external Lean package")
    require(quint("--version").stdout.strip() == "0.33.1", "Quint version mismatch")
    require(json.loads((QUINT / "package.json").read_text())["devDependencies"]["@informalsystems/quint"] == "0.33.1"
        and json.loads((QUINT / "package-lock.json").read_text())["packages"]["node_modules/@informalsystems/quint"]["version"] == "0.33.1",
        "Quint lock mismatch")
    specification = json.loads((ROOT / "formal/ida-act-registry-mutations.json").read_text())
    with tempfile.TemporaryDirectory(prefix="ida-registry-", dir=RECEIPT.parent) as temporary:
        work = Path(temporary)
        build = lake("build", CORE, TEST, CONTRACTS)
        require("declaration uses `sorry`" not in build.stdout + build.stderr, "Admitted proof diagnostic")
        print("ACT-01: Lean modules and typed contracts compiled.", flush=True)
        quint("typecheck", QUINT / "ida-act-registry.qnt")
        quint("typecheck", QUINT / "ida-act-registry-table.qnt")
        tests_path = work / "quint-tests.json"
        quint("test", QUINT / "ida-act-registry.qnt", "--main", "idaActRegistry", "--backend", "typescript",
              "--max-samples", "1", "--seed", SEED, "--match",
              "^(" + "|".join(specification["required_tests"]) + ")$", "--out", tests_path)
        tests = json.loads(tests_path.read_text())
        require(tests.get("stage") == "testing" and tests.get("failed") == []
                and all(tests.get(k, []) == [] for k in ("ignored", "warnings", "errors")), "Incomplete Quint tests")
        require(set(tests.get("passed", [])) == set(specification["required_tests"])
                and len(tests["passed"]) == len(specification["required_tests"]), "Quint test inventory mismatch")
        csv_text = lake("env", "lean", "--run", "scripts/ExportIDAActRegistry.lean").stdout
        values = parse_csv(csv_text)
        trace_path = work / "quint.itf.json"
        quint("run", QUINT / "ida-act-registry-table.qnt", "--main", "idaActRegistryTable", "--backend", "typescript",
              "--max-samples", "1", "--max-steps", "0", "--seed", SEED, "--out-itf", trace_path, "--verbosity", "0")
        trace = json.loads(trace_path.read_text())
        require(parse_itf(trace, CELLS) == values, "Lean/Quint disagreement")
        print(f"ACT-01: independent agreement on {ROWS} cases / {CELLS} output cells.", flush=True)
        exports = export_controls(csv_text, trace, values)
        wire_result, catalogue = wire_compare(work)
        print(f"ACT-01: {wire_result['cases']} canonical wire cases and 34 candidate catalogue outcomes checked.", flush=True)
        audit = compiled_audit(work)
        weakened = proposition_control(work)
        mutations = semantic_controls(work, specification)
        require(fingerprint() == hashes and COMMON.runtime_overrides() == overrides
                and command(["git", "rev-parse", "HEAD"]).stdout.strip() == revision, "Inputs changed during verification")
        matches = all(r.returncode == 0 and hashlib.sha256(r.stdout).hexdigest() == h
            for p, h in hashes.items()
            for r in [subprocess.run(["git", "show", revision + ":" + p], cwd=ROOT, capture_output=True)])
        report = {"schema": "usul.ida.act-registry.verification.v1", "status": "passed", "revision": revision,
            "inputs_match_head": matches, "source_sha256": hashes, "runtime_overrides": overrides,
            "tools": {"lean": version, "quint": "0.33.1", "node": command(["node", "--version"]).stdout.strip()},
            "coverage": {"structural_cases": 504, "bound_cases": 4320, "comparison_cells": CELLS,
                         "candidate_kinds": 34, "unresolved_kinds": 33, "unresolved_roles": 64},
            "required_proofs": sorted(OBLIGATIONS), "scenario_witnesses": sorted(WITNESSES),
            "typed_contracts": len(audit["typed_contracts"]), "compiled_declarations": len(audit["declarations"]),
            "quint_tests": tests["passed"], "wire": wire_result, "export_controls": exports,
            "semantic_mutants": mutations, "proposition_weakening": weakened,
            "boundary": {"trusted_inputs": ["definition canonicalization/hash verifier", "registry snapshot",
                "exact envelope-to-premise binding authority", "existing source environment"],
                "proved": "structural resolution and exact bound source acceptance under supplied inputs",
                "not_claimed": ["qualification truth", "source interpretation correctness", "authenticated registry governance",
                    "general JSON-parser refinement", "cryptographic hash injectivity", "ACT-02 substitution", "runtime execution authorization"]}}
        staged = work / "receipts"; staged.mkdir()
        for name, data in (("report.json", report), ("compiled-axioms.json", audit), ("candidate-worklist.json", catalogue)):
            (staged / name).write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
        (staged / "lean.csv").write_text(csv_text)
        shutil.copyfile(trace_path, staged / "quint.itf.json")
        shutil.copyfile(tests_path, staged / "quint-tests.json")
        staged.rename(RECEIPT)
        print(f"ACT-01: PASS; {len(OBLIGATIONS)} required proofs; inputs_match_head={matches}.", flush=True)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.SubprocessError) as exc:
        raise SystemExit("ACT-01 verification failed: " + str(exc)) from exc
