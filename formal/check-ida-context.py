#!/usr/bin/env python3
"""Replay the bounded ACT-01 context proofs and independent Quint comparison."""

import csv
import hashlib
import io
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

# Reuse the registry gate's tool pins, import closure, ITF parser and runtime audit.
from importlib.machinery import SourceFileLoader
from importlib.util import module_from_spec, spec_from_loader

loader = SourceFileLoader("ida_registry_gate", str(Path(__file__).with_name("check-ida-act-registry.py")))
spec = spec_from_loader(loader.name, loader)
registry = module_from_spec(spec)
loader.exec_module(registry)

ROOT, LEAN, QUINT = registry.ROOT, registry.LEAN, registry.QUINT
require, command, lake, quint = registry.require, registry.command, registry.lake, registry.quint
RECEIPT = ROOT / ".cache/ida-context"
CORE = "Usul.Typing.IDAContext"
FIXTURES = "UsulTest.IDAContext"
CONTRACTS = "UsulTest.IDAContextContracts"
EXPORTER = "scripts.ExportIDAContext"
MODEL = "ida-context.qnt"
TABLE = "ida-context-table.qnt"
QUINT_SOURCES = ("ida", "ida-judgment", "ida-derivation", "ida-act-registry", "agency", "ida-context",
                 "ida-context-table")
TESTS = {"exactIdentityTest", "syntaxAndTimeTest", "candidateSourceTest", "evidenceRevisionTest"}
PROOFS = {
    "decode_encode", "encode_decode", "encode_injective", "resolve_iff", "resolve_unique",
    "resolve_rigid", "changed_snapshot_stale", "changed_qualification_stale",
    "no_target_factorization", "typed_arguments", "bind_iff", "ambiguous_rejected",
    "inconsistent_rejected", "time_identity_unique", "resolved_target_wellFormed", "omission_clock",
    "phase_closes",
}
WITNESSES = {"guard_controls", "same_target_changed_qualification", "candidate_source_stays_candidate",
             "historical_receipt_current_authority"}
COVERAGE = {"binding": 2800, "phase": 6, "agency": 24}
MUTANTS = {
    "first_matching_snapshot": (
        "if (not(unambiguous(catalog))) 1", "if (false) 1",
        "else if (found.length() != 1) 1", "else if (false) 1", "exactIdentityTest"),
    "target_only_equality": (
        "if (actual != expected) 3", "if (target(actual) != target(expected)) 3", "exactIdentityTest"),
    "skip_definition_consistency": (
        "else if (not(consistent(catalog))) 6", "else if (false) 6", "exactIdentityTest"),
    "ignore_opportunity_clock": (
        "A::validOpportunity(o) and o.clock == m.clock", "A::validOpportunity(o)", "syntaxAndTimeTest"),
    "skip_exact_premise_scope": (
        "record.scope == s.inquiry.scope,", "true,", "exactIdentityTest"),
}


def row_keys():
    for snapshot in range(28):
        for catalog in range(10):
            for premise in range(10):
                yield ("binding", snapshot, catalog, premise)
    for tick in range(8, 14):
        yield ("phase", tick, 0, 0)
    for profile in range(2):
        for history in range(4):
            for coordinate in range(3):
                yield ("agency", profile, history, coordinate)


def lean_values(source):
    lines = list(csv.reader(io.StringIO(source)))
    require(lines and lines[0] == ["family", "x", "y", "z", "result"], "Invalid Lean table header")
    expected = list(row_keys())
    require(len(lines) == len(expected) + 1, "Incomplete Lean table")
    values = []
    for row, key in zip(lines[1:], expected):
        require(len(row) == 5, f"Invalid row: {row}")
        observed = int(row[4])
        limit = 6 if key[0] == "binding" else 2
        require(row == [str(x) for x in (*key, observed)] and 0 <= observed <= limit,
                f"Invalid or reordered row: {row}")
        values.append(observed)
    return expected, values


def fingerprint():
    modules = registry.lean_closure([CONTRACTS, EXPORTER])
    paths = {LEAN / (name.replace(".", "/") + ".lean") for name in modules}
    paths.update(QUINT / (name + ".qnt") for name in QUINT_SOURCES)
    paths.update(ROOT / path for path in (
        "formal/lean/lakefile.toml", "formal/lean/lake-manifest.json", "formal/lean/lean-toolchain",
        "formal/quint/package.json", "formal/quint/package-lock.json",
        "formal/check-ida-context.py", "formal/check-ida-act-registry.py", "formal/ida-act-registry-wire.py",
        "formal/check-ida.py", "formal/check-lean-axioms.py", "formal/lean-axiom-audit.lean",
        "Makefile", ".github/workflows/ida-act-registry.yml",
    ))
    return {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in sorted(paths)}


def inspect(work):
    body = (ROOT / "formal/lean-axiom-audit.lean").read_text()
    source = work / "InspectContext.lean"
    target = work / "scripts/ExportIDAContext.olean"
    target.parent.mkdir()
    compiled = lake("env", "lean", "scripts/ExportIDAContext.lean", "-o", target)
    require("declaration uses `sorry`" not in compiled.stdout + compiled.stderr, "Admitted exporter proof")
    source.write_text(
        f"import Lean\nimport {CONTRACTS}\nimport {EXPORTER}\n"
        'private def auditRoots : List String := ["Usul", "UsulTest", "scripts"]\n' + body)
    result = lake("env", "lean", source, env={"LEAN_PATH": str(work)})
    require(not result.stderr.strip(), result.stderr)
    modules = registry.lean_closure([CONTRACTS, EXPORTER])
    declarations = registry.AUDIT.parse_inventory(result.stdout, modules)
    names = {d["name"] for d in declarations if d["kind"] == "theorem"}
    proofs = {"Usul.IDA.Context." + name for name in PROOFS}
    proofs.update(FIXTURES + "." + name for name in WITNESSES)
    require(proofs <= names, "Missing proof obligations: " + str(sorted(proofs - names)))
    return {"modules": sorted(modules), "required_proofs": sorted(proofs), "declarations": declarations}


def run_tests(model, output, match=None, fail=True):
    args = ["test", model, "--main", "idaContext", "--backend", "typescript",
            "--max-samples", "1", "--seed", registry.SEED, "--out", output]
    selected = [match] if match is not None else sorted(TESTS)
    args += ["--match", "^(" + "|".join(selected) + ")$"]
    result = quint(*args, fail=fail)
    evidence = json.loads(output.read_text())
    return result, {key: evidence[key] for key in
                    ("stage", "passed", "failed", "ignored", "warnings", "errors") if key in evidence}


def negative_controls(work):
    for name in QUINT_SOURCES:
        if name + ".qnt" != MODEL:
            shutil.copyfile(QUINT / (name + ".qnt"), work / (name + ".qnt"))
    original = (QUINT / MODEL).read_text()
    outcomes = {}
    for name, spec in MUTANTS.items():
        *edits, test = spec
        changed = original
        for before, after in zip(edits[::2], edits[1::2]):
            require(changed.count(before) == 1, f"Missing or ambiguous mutation point: {name}")
            changed = changed.replace(before, after)
        mutant = work / MODEL
        mutant.write_text(changed)
        quint("typecheck", mutant)
        result, evidence = run_tests(mutant, work / (name + ".json"), test, fail=False)
        require(result.returncode != 0 and evidence.get("stage") == "testing"
                and evidence.get("failed") == [test], f"Mutation survived or failed for another reason: {name}")
        outcomes[name] = evidence
    return outcomes


def main():
    RECEIPT.mkdir(parents=True, exist_ok=True)
    (RECEIPT / "report.json").unlink(missing_ok=True)
    revision = command(["git", "rev-parse", "HEAD"]).stdout.strip()
    hashes = fingerprint()
    overrides = registry.COMMON.runtime_overrides()
    lean_version = lake("env", "lean", "--version").stdout.strip()
    quint_version = quint("--version").stdout.strip()
    require(lean_version.startswith("Lean (version 4.34.1,") and quint_version == "0.33.1",
            "Unexpected Lean or Quint version")
    build = lake("build", CONTRACTS)
    require("declaration uses `sorry`" not in build.stdout + build.stderr, "Admitted Lean proof")
    quint("typecheck", QUINT / TABLE)
    with tempfile.TemporaryDirectory(prefix="ida-context-", dir=RECEIPT.parent) as temp:
        work = Path(temp)
        audit = inspect(work)
        _, tests = run_tests(QUINT / MODEL, work / "tests.json")
        require(tests.get("stage") == "testing" and set(tests.get("passed", [])) == TESTS
                and all(tests.get(key, []) == [] for key in ("failed", "ignored", "warnings", "errors")),
                "Incomplete Quint test inventory")
        lean_csv = lake("env", "lean", "--run", "scripts/ExportIDAContext.lean").stdout
        keys, expected = lean_values(lean_csv)
        trace_path = work / "trace.json"
        quint("run", QUINT / TABLE, "--main", "idaContextTable", "--backend", "typescript",
              "--max-samples", "1", "--max-steps", "0", "--seed", registry.SEED,
              "--out-itf", trace_path, "--verbosity", "0")
        trace = json.loads(trace_path.read_text())
        actual = registry.parse_itf(trace, len(keys))
        for key, l_value, q_value in zip(keys, expected, actual):
            require(l_value == q_value, f"Lean/Quint disagreement at {key}: {l_value} vs {q_value}")
        mutants = negative_controls(work)
        require(hashes == fingerprint() and overrides == registry.COMMON.runtime_overrides()
                and revision == command(["git", "rev-parse", "HEAD"]).stdout.strip(),
                "Verification inputs changed during replay")
        matches = all(result.returncode == 0 and hashlib.sha256(result.stdout).hexdigest() == digest
                      for path, digest in hashes.items()
                      for result in [subprocess.run(["git", "show", f"{revision}:{path}"], cwd=ROOT,
                                                    capture_output=True)])
        report = {
            "schema": "usul.ida.context.verification.v1", "status": "passed", "revision": revision,
            "inputs_match_head": matches, "source_sha256": hashes, "runtime_overrides": overrides,
            "tools": {"lean": lean_version, "quint": quint_version, "node": command(["node", "--version"]).stdout.strip()},
            "coverage": COVERAGE, "required_proofs": audit["required_proofs"],
            "compiled_declarations": len(audit["declarations"]), "quint_tests": sorted(TESTS),
            "rejected_mutants": sorted(mutants),
            "boundary": "Ground structural context and exact binding. Candidate agency replay is separate.",
        }
        (RECEIPT / "lean.csv").write_text(lean_csv)
        shutil.copyfile(trace_path, RECEIPT / "quint.itf.json")
        for name, data in (("proofs", audit), ("quint-tests", tests), ("mutants", mutants), ("report", report)):
            (RECEIPT / (name + ".json")).write_text(json.dumps(data, indent=2) + "\n")
    print(f"ACT-01 context: {len(keys)} matching observations, {len(audit['required_proofs'])} proof obligations"
          f" and witnesses, {len(mutants)} rejected model mutations at {revision}.")


if __name__ == "__main__":
    main()
