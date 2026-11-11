#!/usr/bin/env python3
"""Compile, execute, mutate, and audit the native Lean fixture suites.

The default gate requires no Prolog. A frozen, source-bound legacy replay is
the migration reference, not an implementation of the Lean queries. Every
semantic mutant must compile and fail an executed fixture; a build failure
does not count as detection. Receipts are published only after all gates pass.
"""

import copy
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
RECEIPTS = ROOT / ".cache/lean-fixtures"
REFERENCE = ROOT / "tests/lean-fixture-reference.json"
EXPORTER = "scripts.RunFixtures"
CONTRACTS = "UsulTest.Fixtures.Contracts"
SUITES = ("runner", "sheaf", "fatwa", "typing")
LEGACY_COUNTS = {"sheaf": 58, "fatwa": 300, "typing": 31}
REFERENCE_SOURCES = {
    "examples/v38_contextual_affect_deontics.pl", "examples/v39_affect_concern.pl",
    "examples/v39_temporal_concern.pl", "examples/v39_claim_concern.pl",
    "examples/v39_sheaf_concern.pl", "examples/v39_sheaf_obstruction_fixtures.pl",
    "examples/v40_fatwa_oracle_fixtures.pl", "examples/v41_typing_fixtures.pl",
    "examples/v40_fatwa_rules.pl", "examples/v40_fatwa_cases.pl",
    "examples/v41_types.pl", "examples/v41_typing.pl", "tests/fixture_runner.pl",
    "tests/run_fixture_expectations.pl", "tests/test_fixture_runner.pl", "tests/mutation_test.sh",
}
# Existing kernel proofs use two deprecated simp lemmas. Suppress only this
# advisory linter for that unchanged dependency; other diagnostics remain fatal.
MODULE_OPTIONS = {"Usul.Refinements": ["-Dlinter.deprecated=false"]}
IMPORT = re.compile(r"^\s*(?:public\s+)?import\s+(?:all\s+)?([A-Za-z_][A-Za-z0-9_'.]*)\s*$", re.M)
MODEL_ROOTS = {"Usul", "UsulTest", "scripts"}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def command(args, *, cwd=ROOT, env=None, allow_failure=False, timeout=300):
    result = subprocess.run([str(arg) for arg in args], cwd=cwd, env=env,
                            capture_output=True, text=True, timeout=timeout)
    if result.returncode and not allow_failure:
        raise ValueError(f"Command failed ({result.returncode}): {' '.join(map(str, args))}\n"
                         f"{result.stdout}\n{result.stderr}")
    return result


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, f"Duplicate reference JSON key: {key}")
        result[key] = value
    return result


def validate_reference(reference):
    require(isinstance(reference, dict) and set(reference) == {
        "schema", "reference_revision", "source_sha256", "suites"}, "Malformed reference root")
    require(reference["schema"] == "usul.fixture-migration-reference.v1", "Wrong reference schema")
    require(isinstance(reference["reference_revision"], str) and
            re.fullmatch(r"[0-9a-f]{40}", reference["reference_revision"]), "Invalid reference revision")
    sources = reference["source_sha256"]
    require(isinstance(sources, dict) and set(sources) == REFERENCE_SOURCES,
            "Incomplete or unexpected reference source inventory")
    require(all(isinstance(value, str) and re.fullmatch(r"[0-9a-f]{64}", value)
                for value in sources.values()), "Malformed reference source hash")
    suites = reference["suites"]
    require(isinstance(suites, dict) and set(suites) == set(LEGACY_COUNTS),
            "Missing or unexpected legacy suites")
    for suite, count in LEGACY_COUNTS.items():
        legacy = suites[suite]
        require(isinstance(legacy, list) and len(legacy) == count,
                f"Incomplete migration reference: {suite}")
        for row in legacy:
            require(isinstance(row, dict) and set(row) == {"name", "expected", "actual", "premises"},
                    f"Malformed reference fixture fields: {suite}")
            require(isinstance(row["name"], str) and row["name"] and
                    not any(character in row["name"] for character in "\t\r\n"),
                    f"Invalid reference fixture name: {suite}")
            require(type(row["expected"]) is bool and type(row["actual"]) is bool and
                    isinstance(row["premises"], list) and all(type(value) is bool for value in row["premises"]),
                    f"Non-Boolean reference fixture: {suite}/{row['name']}")
        require(len({row["name"] for row in legacy}) == count, f"Duplicate reference fixture: {suite}")
    return reference


def verify_reference_revision(reference):
    revision = reference["reference_revision"]
    git_env = {**os.environ, "GIT_NO_LAZY_FETCH": "1"}
    available = command(["git", "cat-file", "-e", f"{revision}^{{commit}}"], env=git_env, allow_failure=True)
    require(available.returncode == 0,
            f"Reference commit {revision} is unavailable; fetch repository history before verification")
    for name, expected in reference["source_sha256"].items():
        result = subprocess.run(["git", "show", f"{revision}:{name}"], cwd=ROOT, env=git_env, capture_output=True)
        require(result.returncode == 0 and hashlib.sha256(result.stdout).hexdigest() == expected,
                f"Reference source does not match recorded revision: {name} at {revision}")


def read_reference():
    reference = validate_reference(json.loads(REFERENCE.read_text(), object_pairs_hook=unique_object))
    verify_reference_revision(reference)
    return reference


def dependency_graph(roots):
    graph, visiting = {}, set()
    def visit(module):
        if module in graph:
            return
        require(module not in visiting, f"Cyclic Lean module import: {module}")
        visiting.add(module)
        path = LEAN / (module.replace(".", "/") + ".lean")
        require(path.is_file(), f"Missing fixture dependency: {module}")
        text = path.read_text()
        deps = []
        for imported in IMPORT.findall(text):
            root = imported.split(".")[0]
            if root in MODEL_ROOTS:
                visit(imported)
                deps.append(imported)
            else:
                require(root in {"Init", "Lean", "Std"}, f"Unexpected external dependency: {imported}")
                require(not (LEAN / root).exists() and not (LEAN / f"{root}.lean").exists(),
                        f"Project shadows standard-library import: {root}")
        graph[module] = deps
        visiting.remove(module)
    for root in roots:
        visit(root)
    for module, dependencies in graph.items():
        if module.startswith("Usul.") and not module.startswith("Usul.Fixtures."):
            require(not any(dep.startswith("Usul.Fixtures.") for dep in dependencies),
                    f"Production kernel imports fixture model: {module}")
    return graph


def fingerprint(graph):
    paths = {LEAN / (name.replace(".", "/") + ".lean") for name in graph}
    paths.update(LEAN / name for name in ("lean-toolchain", "lakefile.toml", "lake-manifest.json"))
    paths.update(ROOT / name for name in (
        "formal/check-lean-fixtures.py", "formal/check-lean-axioms.py", "formal/lean-axiom-audit.lean",
        "tests/export_fixture_reference.py", "tests/lean-fixture-reference.json",
        "pipeline/tests/test_layers.py",
        "tests/run_all.sh", "tests/run_legacy_fixtures.sh", ".github/workflows/fixtures.yml", "Makefile"))
    paths.update((ROOT / "tests").glob("lean-*-mutants.json"))
    paths.update((ROOT / "formal/fixtures").glob("gen_*fixtures.py"))
    reference = read_reference()
    paths.update(ROOT / name for name in reference["source_sha256"])
    # Include data-generator inputs even when they are outside the legacy fixture closure.
    paths.update((ROOT / "formal/fixtures").glob("*fixtures*.json"))
    for generator in (ROOT / "formal/fixtures").glob("gen_*fixtures.py"):
        for relative in re.findall(r'["\']((?:corpus|examples)/[^"\'\n]+\.(?:json|pl))["\']', generator.read_text()):
            path = ROOT / relative
            if path.is_file():
                paths.add(path)
    return {str(path.relative_to(ROOT)): digest(path) for path in sorted(paths)}


def parse_rows(text, expected_suites=SUITES):
    rows = list(csv.reader(io.StringIO(text), delimiter="\t"))
    require(rows and rows.pop(0) == ["suite", "name", "expected", "actual", "premises", "status"],
            "Missing or invalid Lean fixture export header")
    result = {suite: {} for suite in expected_suites}
    for row in rows:
        require(len(row) == 6, f"Malformed Lean fixture row: {row}")
        suite, name, expected, actual, premises, status = row
        require(suite in result and name and name not in result[suite],
                f"Unknown suite, empty name, or duplicate fixture: {suite}/{name}")
        require(expected in {"true", "false"} and actual in {"true", "false"},
                f"Fixture query did not produce a Boolean answer: {suite}/{name}")
        premise_values = premises.split(",") if premises else []
        require(all(value in {"true", "false"} for value in premise_values),
                f"Fixture premise evaluation error: {suite}/{name}")
        require(status == "pass" or status.startswith("fail:"), f"Invalid status: {status}")
        result[suite][name] = {"name": name, "expected": expected == "true", "actual": actual == "true",
                               "premises": [value == "true" for value in premise_values], "status": status}
    require(all(result.values()), "Missing or empty fixture suite")
    return result


def check_reference(rows):
    reference = read_reference()
    for path, expected in reference["source_sha256"].items():
        require(digest(ROOT / path) == expected, f"Legacy source drift: {path}; replay the migration reference explicitly")
    for suite, expected_count in LEGACY_COUNTS.items():
        legacy = reference["suites"][suite]
        expected = {row["name"]: row for row in legacy}
        require(set(rows[suite]) == set(expected),
                f"Fixture inventory differs ({suite}): missing={sorted(set(expected)-set(rows[suite]))}; "
                f"unexpected={sorted(set(rows[suite])-set(expected))}")
        for name, row in rows[suite].items():
            require({key: row[key] for key in expected[name]} == expected[name],
                    f"Migration disagreement: {suite}/{name}: {row} != {expected[name]}")
    require(len(rows["runner"]) == 18, "Runner control inventory changed")
    require(all(row["status"] == "pass" for suite in rows.values() for row in suite.values()),
            "A baseline fixture failed")


def export_controls(text):
    cases = {}
    lines = text.splitlines()
    cases["missing_header"] = "\n".join(lines[1:])
    cases["truncated_suite"] = "\n".join(line for line in lines if not line.startswith("typing\t"))
    cases["duplicate_row"] = text + lines[1] + "\n"
    bad = lines.copy()
    fields = bad[1].split("\t")
    fields[3] = "unknown"
    bad[1] = "\t".join(fields)
    cases["unknown_answer"] = "\n".join(bad)
    cases["missing_fixture"] = "\n".join(lines[:-1])
    bad = lines.copy()
    fields = bad[-1].split("\t")
    fields[2] = "false" if fields[2] == "true" else "true"
    bad[-1] = "\t".join(fields)
    cases["changed_polarity"] = "\n".join(bad)
    for name, corrupted in cases.items():
        try:
            check_reference(parse_rows(corrupted))
        except (ValueError, KeyError):
            pass
        else:
            raise ValueError(f"Export corruption accepted: {name}")
    return sorted(cases)


def reference_controls():
    reference = read_reference()
    cases = {name: copy.deepcopy(reference) for name in (
        "missing_actual", "integer_expected", "integer_premise", "missing_source_hash",
        "unexpected_source", "extra_fixture_field", "duplicate_fixture", "missing_root_field")}
    del cases["missing_actual"]["suites"]["fatwa"][0]["actual"]
    cases["integer_expected"]["suites"]["fatwa"][0]["expected"] = 1
    next(row for row in cases["integer_premise"]["suites"]["typing"] if row["premises"])["premises"][0] = 1
    del cases["missing_source_hash"]["source_sha256"][sorted(REFERENCE_SOURCES)[0]]
    cases["unexpected_source"]["source_sha256"]["../untrusted"] = "0" * 64
    cases["extra_fixture_field"]["suites"]["fatwa"][0]["ignored"] = True
    cases["duplicate_fixture"]["suites"]["fatwa"][1] = cases["duplicate_fixture"]["suites"]["fatwa"][0]
    del cases["missing_root_field"]["reference_revision"]
    for name, corrupted in cases.items():
        try:
            validate_reference(corrupted)
        except ValueError:
            pass
        else:
            raise ValueError(f"Reference corruption accepted: {name}")
    try:
        json.loads('{"schema": "first", "schema": "second"}', object_pairs_hook=unique_object)
    except ValueError:
        pass
    else:
        raise ValueError("Duplicate reference JSON key accepted")
    provenance_cases = {name: copy.deepcopy(reference) for name in (
        "missing_reference_revision", "mismatched_reference_blob")}
    provenance_cases["missing_reference_revision"]["reference_revision"] = "0" * 40
    provenance_cases["mismatched_reference_blob"]["source_sha256"][sorted(REFERENCE_SOURCES)[0]] = "0" * 64
    for name, corrupted in provenance_cases.items():
        try:
            verify_reference_revision(corrupted)
        except ValueError:
            pass
        else:
            raise ValueError(f"Reference provenance corruption accepted: {name}")
    return sorted([*cases, *provenance_cases, "duplicate_json_key"])


def load_mutations():
    mutations = []
    for suite in ("sheaf", "fatwa", "typing"):
        path = ROOT / f"tests/lean-{suite}-mutants.json"
        values = json.loads(path.read_text())
        require(isinstance(values, list) and values, f"Empty mutation inventory: {suite}")
        for value in values:
            require(set(value) == {"name", "path", "before", "after"}, f"Malformed mutation: {value}")
            require(value["path"].startswith("formal/lean/Usul/Fixtures/") and ".." not in value["path"],
                    f"Mutation outside fixture model: {value['name']}")
            source = (ROOT / value["path"]).read_text()
            require(value["before"] and value["before"] != value["after"] and source.count(value["before"]) == 1,
                    f"Missing or ambiguous semantic mutation: {value['name']}")
            mutations.append({**value, "suite": suite})
    names = [value["name"] for value in mutations]
    legacy_names = re.findall(r'^  "([^|]+)\|', (ROOT / "tests/mutation_test.sh").read_text(), re.M)
    require(len(legacy_names) == 61 and len(names) == len(set(names)) and set(names) == set(legacy_names),
            f"Semantic mutation coverage differs from legacy: missing={sorted(set(legacy_names)-set(names))}; "
            f"unexpected={sorted(set(names)-set(legacy_names))}")
    return mutations


def main():
    RECEIPTS.parent.mkdir(parents=True, exist_ok=True)
    if RECEIPTS.exists():
        shutil.rmtree(RECEIPTS)
    revision = command(["git", "rev-parse", "HEAD"]).stdout.strip()
    reference_revision = read_reference()["reference_revision"]
    graph = dependency_graph([EXPORTER, CONTRACTS])
    source_hashes = fingerprint(graph)
    runtime = {key: os.environ.get(key) for key in ("LD_PRELOAD", "LEAN_PATH", "LEAN_SYSROOT", "USUL_LEAN_BIN")}
    runtime_hashes = {key: digest(Path(value)) for key, value in runtime.items()
                      if value and Path(value).is_file()}
    pin = (LEAN / "lean-toolchain").read_text().strip()
    # Installation diagnostics are consumed here, before parsing audit output.
    prefix = command(["lake", "env", "lean", "--print-prefix"], cwd=LEAN).stdout.strip()
    compiler = Path(prefix) / "bin/lean"
    require(compiler.is_file(), "Pinned Lean executable is absent")
    version = command([compiler, "--version"], cwd=LEAN).stdout.strip()
    compiler_hash = digest(compiler)
    require(pin.startswith("leanprover/lean4:v") and version.startswith(
        f"Lean (version {pin.removeprefix('leanprover/lean4:v')},"), f"Toolchain mismatch: {pin}: {version}")
    require(not json.loads((LEAN / "lake-manifest.json").read_text()).get("packages"),
            "Fixture package unexpectedly depends on external Lean packages")
    generators = sorted((ROOT / "formal/fixtures").glob("gen_*fixtures.py"))
    for generator in generators:
        command(["python3", generator, "--check"])
    mutations = load_mutations()
    print(f"Lean fixtures: pinned {pin}; {len(graph)} modules; {len(mutations)} semantic controls.", flush=True)

    with tempfile.TemporaryDirectory(prefix="lean-fixtures-", dir=RECEIPTS.parent) as temporary:
        work = Path(temporary).resolve()
        built = work / "baseline"
        built.mkdir()

        def environment(*paths):
            return {**os.environ, "LEAN_PATH": os.pathsep.join(str(path) for path in paths)}

        def compile_module(module, destination, *, source=None, dependencies=()):
            source = source or LEAN / (module.replace(".", "/") + ".lean")
            target = destination / (module.replace(".", "/") + ".olean")
            target.parent.mkdir(parents=True, exist_ok=True)
            root = LEAN if source.is_relative_to(LEAN) else destination
            result = command([compiler, *MODULE_OPTIONS.get(module, []), f"--root={root}", source, "-o", target], cwd=LEAN,
                             env=environment(destination, *dependencies), timeout=600)
            require(not result.stdout.strip() and not result.stderr.strip(),
                    f"Unexpected compilation diagnostics in {module}: {result.stdout}\n{result.stderr}")

        for module in graph:
            compile_module(module, built)
        export = command([compiler, "--run", LEAN / "scripts/RunFixtures.lean"], cwd=LEAN, env=environment(built))
        require(not export.stderr.strip(), f"Unexpected fixture diagnostics: {export.stderr}")
        rows = parse_rows(export.stdout)
        check_reference(rows)
        corruptions = export_controls(export.stdout)
        reference_corruptions = reference_controls()
        print("Lean fixtures: " + ", ".join(f"{suite}={len(values)}" for suite, values in rows.items())
              + "; exact migration agreement.", flush=True)

        # Every baseline answer is challenged with its polarity reversed.
        flipped = {}
        for suite in SUITES:
            result = command([compiler, "--run", LEAN / "scripts/RunFixtures.lean", suite, "--flipped"],
                             cwd=LEAN, env=environment(built), allow_failure=True)
            require(result.returncode == 1 and not result.stderr.strip(), f"Polarity control did not execute: {suite}")
            values = parse_rows(result.stdout, (suite,))[suite]
            require(set(values) == set(rows[suite]) and
                    all(value["status"] == "fail:Usul.Fixtures.Failure.queryMismatch" for value in values.values()),
                    f"Polarity control survived or failed for the wrong reason: {suite}")
            for name, value in values.items():
                original = rows[suite][name]
                require(value["actual"] == original["actual"] and value["expected"] != original["expected"]
                        and value["premises"] == (original["premises"] or [True]),
                        f"Polarity control changed its query or original premises: {suite}/{name}")
            flipped[suite] = len(values)

        spec = importlib.util.spec_from_file_location("fixture_axiom_audit", ROOT / "formal/check-lean-axioms.py")
        audit = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(audit)
        body = (ROOT / "formal/lean-axiom-audit.lean").read_text()

        def inspect(imports, roots, expected, search=built):
            source = work / "InspectFixtures.lean"
            allowed_imports = sorted(set(graph) | set(expected))
            source.write_text("import Lean\n" + "".join(f"import {module}\n" for module in imports)
                              + f"private def auditRoots : List String := {json.dumps(roots)}\n"
                              + f"private def allowedProjectImports : List String := {json.dumps(allowed_imports)}\n"
                              + "open Lean Elab Command\nrun_cmd do\n"
                              + "  for name in (← getEnv).allImportedModuleNames do\n"
                              + "    unless [\"Init\", \"Lean\", \"Std\"].contains name.getRoot.toString || "
                              + "allowedProjectImports.contains name.toString do\n"
                              + "      throwError m!\"Unexpected project import: {name}\"\n" + body)
            result = command([compiler, source], cwd=LEAN, env=environment(search, built))
            require(not result.stderr.strip(), f"Unexpected audit diagnostic: {result.stderr}")
            return audit.parse_inventory(result.stdout, set(expected))

        owned = {module for module in graph if not module.startswith("scripts.")}
        declarations = inspect([CONTRACTS], ["Usul", "UsulTest"], owned)
        declarations += inspect([EXPORTER], ["scripts"], {EXPORTER})
        required = {
            "UsulTest.Fixtures.Contracts.require_negative_premise",
            "UsulTest.Fixtures.Contracts.require_false_negative",
            "UsulTest.Fixtures.Contracts.require_true_positive",
            "UsulTest.Fixtures.Contracts.require_query_error",
            "UsulTest.Fixtures.Contracts.require_premise_error",
            "UsulTest.Fixtures.Contracts.require_false_premise",
            "UsulTest.Fixtures.Contracts.require_polarity_rejection",
            "UsulTest.Fixtures.Contracts.require_flip_query",
            "UsulTest.Fixtures.Contracts.require_flip_polarity",
            "UsulTest.Fixtures.Contracts.require_empty_rejection",
            "UsulTest.Fixtures.Contracts.typing_inventory_matches",
            "UsulTest.Fixtures.Contracts.typing_keeps_derived_conflicts",
            "UsulTest.Fixtures.Contracts.typing_stated_facts_block_derivation",
            "UsulTest.Fixtures.Contracts.require_typing_preservation",
            "UsulTest.Fixtures.Contracts.require_fatwa_priority",
            "UsulTest.Fixtures.Contracts.require_fatwa_candidate",
        }
        theorems = {declaration["name"] for declaration in declarations if declaration["kind"] == "theorem"}
        require(required <= theorems, f"Missing fixed fixture proof contracts: {sorted(required-theorems)}")
        proof_controls = []
        for name, contents in {
            "FixturePrivateAxiomProbe": "private axiom hidden : True\n",
            "FixtureSorryProbe": "theorem admitted : True := by sorry\n",
        }.items():
            source = work / f"{name}.lean"
            source.write_text(contents)
            command([compiler, f"--root={work}", source, "-o", work / f"{name}.olean"], env=environment(work))
            try:
                inspect([name], [name], {name}, search=work)
            except ValueError as exc:
                require("Disallowed Lean declarations or axiom dependencies" in str(exc),
                        f"Audit control failed for the wrong reason: {name}: {exc}")
            else:
                raise ValueError(f"Compiled axiom control accepted: {name}")
            proof_controls.append(name)

        dependency = work / "FixtureUnexpectedDependency.lean"
        dependency.write_text("theorem harmless : True := True.intro\n")
        command([compiler, f"--root={work}", dependency, "-o", dependency.with_suffix(".olean")], env=environment(work))
        wrapper = work / "FixtureImportProbe.lean"
        wrapper.write_text("import FixtureUnexpectedDependency\ntheorem expected : True := True.intro\n")
        command([compiler, f"--root={work}", wrapper, "-o", wrapper.with_suffix(".olean")], env=environment(work))
        try:
            inspect(["FixtureImportProbe"], ["FixtureImportProbe"], {"FixtureImportProbe"}, search=work)
        except ValueError as exc:
            require("Unexpected project import: FixtureUnexpectedDependency" in str(exc),
                    f"Import control failed for the wrong reason: {exc}")
        else:
            raise ValueError("Compiled audit accepted an undeclared dependency")
        proof_controls.append("FixtureImportProbe")

        mutation_results = []
        for mutation in mutations:
            directory = work / mutation["name"]
            # Lean resolves a package root as a unit; a partial search-path
            # overlay can hide sibling modules. Copy the freshly compiled
            # baseline, then rebuild every affected module in that full root.
            shutil.copytree(built, directory)
            module = str(Path(mutation["path"]).relative_to("formal/lean").with_suffix("")).replace("/", ".")
            changed_source = directory / Path(mutation["path"]).relative_to("formal/lean")
            changed_source.parent.mkdir(parents=True, exist_ok=True)
            changed_source.write_text((ROOT / mutation["path"]).read_text().replace(mutation["before"], mutation["after"]))
            affected = set()
            for candidate, deps in graph.items():
                if candidate == module or any(dep in affected for dep in deps):
                    affected.add(candidate)
                    if candidate != CONTRACTS and not candidate.startswith("scripts."):
                        compile_module(candidate, directory, source=changed_source if candidate == module else None,
                                       dependencies=(built,))
            result = command([compiler, "--run", LEAN / "scripts/RunFixtures.lean", mutation["suite"]],
                             cwd=LEAN, env=environment(directory, built), allow_failure=True)
            require(result.returncode == 1 and not result.stderr.strip(),
                    f"Semantic mutant survived or did not execute: {mutation['name']}\n{result.stdout}\n{result.stderr}")
            values = parse_rows(result.stdout, (mutation["suite"],))[mutation["suite"]]
            require(set(values) == set(rows[mutation["suite"]]), f"Mutant changed the fixture inventory: {mutation['name']}")
            failures = [name for name, row in values.items() if row["status"].startswith("fail:")]
            require(failures, f"Semantic mutant has no failing fixture: {mutation['name']}")
            mutation_results.append({"name": mutation["name"], "suite": mutation["suite"], "failed_fixtures": failures})
            print(f"Lean fixtures: rejected {mutation['name']} ({len(failures)} failing vectors).", flush=True)
            shutil.rmtree(directory)

        require({key: os.environ.get(key) for key in runtime} == runtime and
                all(digest(Path(runtime[key])) == value for key, value in runtime_hashes.items()),
                "Runtime overrides changed during fixture verification")
        require(fingerprint(graph) == source_hashes and command(["git", "rev-parse", "HEAD"]).stdout.strip() == revision,
                "Inputs changed during fixture verification")
        matches_head = all(result.returncode == 0 and hashlib.sha256(result.stdout).hexdigest() == expected
                           for name, expected in source_hashes.items()
                           for result in [subprocess.run(["git", "show", f"{revision}:{name}"], cwd=ROOT,
                                                         capture_output=True)])
        payload = {
            "schema": "usul.lean-fixtures.v1", "status": "passed", "revision": revision,
            "reference_revision": reference_revision,
            "inputs_match_head": matches_head, "source_sha256": source_hashes,
            "toolchain": pin, "lean_version": version, "compiler_sha256": compiler_hash, "runtime_overrides": runtime,
            "runtime_override_sha256": runtime_hashes,
            "compile_options_by_module": MODULE_OPTIONS,
            "suites": {name: len(values) for name, values in rows.items()},
            "legacy_fixture_count": sum(LEGACY_COUNTS.values()),
            "polarity_controls": flipped, "semantic_mutants": mutation_results,
            "export_controls": corruptions, "reference_controls": reference_corruptions,
            "compiled_proof_controls": proof_controls,
            "compiled_modules": sorted(graph), "compiled_declarations": len(declarations),
            "required_proof_contracts": sorted(required), "allowed_axioms": sorted(audit.ALLOWED),
            "boundary": {
                "migration": "exact query, polarity, and premise agreement for every declared legacy fixture",
                "semantics": "native, finite Lean models and existing kernel functions",
                "not_established": ["equivalence for all Prolog programs or unenumerated queries",
                                    "source interpretation or juristic authority",
                                    "removal of the independent Prolog oracles and corpus tooling"],
            },
        }
        staged = work / "receipts"
        staged.mkdir()
        (staged / "report.json").write_text(json.dumps(payload, indent=2) + "\n")
        (staged / "compiled-axioms.json").write_text(json.dumps(declarations, indent=2) + "\n")
        (staged / "lean.tsv").write_text(export.stdout)
        require(fingerprint(graph) == source_hashes and digest(compiler) == compiler_hash,
                "Inputs or compiler changed before receipt publication")
        require(command(["git", "rev-parse", "HEAD"]).stdout.strip() == revision, "Revision changed before receipt publication")
        staged.rename(RECEIPTS)
        print(f"Lean fixtures: PASS; {sum(map(len, rows.values()))} fixtures, {len(mutation_results)} semantic mutants; "
              f"inputs_match_head={matches_head}.", flush=True)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, subprocess.SubprocessError) as exc:
        raise SystemExit(f"Lean fixture verification failed: {exc}") from exc
