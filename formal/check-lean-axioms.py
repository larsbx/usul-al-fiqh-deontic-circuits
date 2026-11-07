#!/usr/bin/env python3
"""Build a Lean package and audit transitive axioms in its compiled declarations."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
BODY = ROOT / "formal/lean-axiom-audit.lean"
ALLOWED = {"Classical.choice", "Quot.sound", "propext"}
PACKAGES = {
    "core": ("lean", ("Usul", "UsulTest", "Hadith", "HadithTest"), ("ExportTypes", "ExportAgency")),
    "mathlib": ("lean-mathlib", ("UsulMathlib",), ()),
}
MODULE = re.compile(r"[A-Za-z_][A-Za-z0-9_']*(?:\.[A-Za-z_][A-Za-z0-9_']*)*")


def inputs(package, roots, exporters):
    paths = {package / name for name in ("lakefile.toml", "lake-manifest.json", "lean-toolchain")}
    paths.update((Path(__file__).resolve(), BODY))
    modules = {}
    for directory, children, files in os.walk(package):
        children[:] = sorted(name for name in children if not name.startswith("."))
        for filename in sorted(files):
            if not filename.endswith(".lean"):
                continue
            source = Path(directory) / filename
            name = ".".join(source.relative_to(package).with_suffix("").parts)
            if not MODULE.fullmatch(name):
                raise ValueError(f"Unsupported module path {source}")
            if name in modules:
                raise ValueError(f"Ambiguous module name {name}")
            modules[name] = source
    required = set(roots) | {f"scripts.{name}" for name in exporters}
    if missing := required - modules.keys():
        raise ValueError(f"Missing Lean source modules: {sorted(missing)}")
    paths.update(modules.values())
    return modules, {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
                     for p in sorted(paths)}


def parse_inventory(stdout, expected):
    modules, declarations = set(), {}
    violations = []
    for line in stdout.splitlines():
        fields = line.split("\t")
        if len(fields) == 2 and fields[0] == "module" and fields[1] not in modules:
            modules.add(fields[1])
            continue
        if len(fields) != 4 or fields[0] not in {"axiom", "theorem", "other"}:
            raise ValueError(f"Unexpected Lean inventory output: {line}")
        kind, module, name, dependencies = fields
        if module not in expected or not name or name in declarations:
            raise ValueError(f"Invalid or duplicate declaration {module}: {name}")
        axioms = dependencies.split(",") if dependencies else []
        declarations[name] = {"name": name, "module": module, "kind": kind, "axioms": axioms}
        if kind == "axiom" or set(axioms) - ALLOWED:
            violations.append(f"{module}: {name} ({kind}; axioms: {', '.join(axioms)})")
    if modules != expected:
        raise ValueError(f"Module coverage mismatch. Missing: {sorted(expected - modules)}. "
                         f"Unexpected: {sorted(modules - expected)}.")
    if not declarations:
        raise ValueError("Lean inventory contains no declarations")
    if violations:
        raise ValueError("Disallowed Lean declarations or axiom dependencies:\n" + "\n".join(violations))
    return list(declarations.values())


def audit(scope, receipt):
    directory, roots, exporters = PACKAGES[scope]
    package = ROOT / "formal" / directory
    git = lambda *args: subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()
    revision = git("rev-parse", "HEAD")
    def snapshot():
        modules, hashes = inputs(package, roots, exporters)
        if scope == "mathlib":
            core, core_roots, core_exporters = PACKAGES["core"]
            _, core_hashes = inputs(ROOT / "formal" / core, core_roots, core_exporters)
            hashes.update(core_hashes)
        return modules, hashes

    modules, hashes = snapshot()

    def lake(*args, capture=False, env=None):
        result = subprocess.run(["lake", *args], cwd=package, check=True, text=True,
                                capture_output=capture, env=env)
        if capture and result.stderr:
            raise ValueError(f"Unexpected Lean diagnostics: {result.stderr}")
        return result.stdout

    def build(*args):
        result = subprocess.run(["lake", *args], cwd=package, text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        print(result.stdout, end="", flush=True)
        result.check_returncode()
        # Anonymous examples need not appear in the compiled environment.
        if re.search(r"(?m)^warning: .*declaration uses `sorry`", result.stdout):
            raise ValueError("Lean emitted an admitted-proof diagnostic")

    pin = (package / "lean-toolchain").read_text().strip()
    # The first Lake invocation can install Lean and fetch dependencies. Keep that
    # setup output visible on stderr and capture only the version on stdout.
    version = subprocess.check_output(
        ["lake", "env", "lean", "--version"], cwd=package, text=True
    ).strip()
    if not pin.startswith("leanprover/lean4:v") or not version.startswith(
        f"Lean (version {pin.removeprefix('leanprover/lean4:v')},"
    ):
        raise ValueError(f"Toolchain mismatch: {pin} vs {version}")
    if scope == "mathlib":
        build("exe", "cache", "get", "Mathlib.Order.Lattice", "Mathlib.Order.Interval.Set.Basic")
    build("build")
    with tempfile.TemporaryDirectory(dir=receipt.parent) as tmp:
        work = Path(tmp)
        env = {**os.environ, "LEAN_PATH": str(work)}
        audit_file = work / "CheckLeanAxioms.lean"
        body = BODY.read_text()

        def inspect(imports, owned, expected):
            audit_file.write_text(
                "import Lean\n" + "".join(f"import {name}\n" for name in imports)
                + f"private def auditRoots : List String := {json.dumps(owned)}\n" + body
            )
            result = lake("env", "lean", str(audit_file), capture=True, env=env)
            return parse_inventory(result, expected)

        scripts = {name for name in modules if name.startswith("scripts.")} if exporters else set()
        declarations = inspect(roots, roots, set(modules) - scripts)
        # Standalone executables may all declare `main`. Load them separately.
        for name in sorted(scripts):
            source = modules[name].relative_to(package)
            destination = work / source.with_suffix(".olean")
            destination.parent.mkdir(parents=True, exist_ok=True)
            build("env", "lean", str(source), "-o", str(destination))
            declarations.extend(inspect([name], ["scripts"], {name}))
        if snapshot()[1] != hashes or git("rev-parse", "HEAD") != revision:
            raise ValueError("Lean audit inputs changed during replay")
        tracked = set(git("ls-tree", "-r", "--name-only", "HEAD").splitlines())
        dirty = bool(git("status", "--porcelain", "--untracked-files=no", "--", *hashes))
        payload = {
            "schema": "usul.lean.compiled-axioms.v1", "scope": scope, "revision": revision,
            "inputs_match_head": not dirty and hashes.keys() <= tracked,
            "toolchain": pin, "lean_version": version, "allowed_axioms": sorted(ALLOWED),
            "source_sha256": hashes, "modules": sorted(modules), "declarations": declarations,
        }
        staged = work / receipt.name
        staged.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
        staged.replace(receipt)
    print(f"Lean {scope}: audited {len(declarations)} compiled declarations "
          f"in {len(modules)} modules at {revision}.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("scope", choices=PACKAGES)
    args = parser.parse_args()
    receipt = ROOT / f".cache/lean-axioms/{args.scope}.json"
    receipt.parent.mkdir(parents=True, exist_ok=True)
    receipt.unlink(missing_ok=True)
    try:
        audit(args.scope, receipt)
    except subprocess.CalledProcessError as exc:
        if exc.stdout:
            print(exc.stdout, end="")
        if exc.stderr:
            print(exc.stderr, end="")
        parser.exit(1, f"Lean axiom audit: {exc}\n")
    except (OSError, ValueError) as exc:
        parser.exit(1, f"Lean axiom audit: {exc}\n")


if __name__ == "__main__":
    main()
