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
CLAIMS = ROOT / "formal/lean-proof-claims.json"
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


def checked_claims(declarations):
    """Resolve every registered theorem against the audited compiled inventory."""
    register = json.loads(CLAIMS.read_text())
    if not isinstance(register, dict) or register.get("schema") != "usul.lean.proof-claims.v1":
        raise ValueError("Invalid Lean proof claim register schema")
    claims = register.get("claims")
    if not isinstance(claims, list) or not claims:
        raise ValueError("Lean proof claim register is empty")
    required_text = ("id", "claim", "hypotheses", "finite_checks", "source_review", "refinement")
    theorems = {row["name"] for row in declarations if row["kind"] == "theorem"}
    seen = set()
    for claim in claims:
        if (not isinstance(claim, dict)
                or set(claim) != {*required_text, "theorems"}
                or any(not isinstance(claim[key], str) or not claim[key].strip()
                       for key in required_text)):
            raise ValueError("Malformed Lean proof claim")
        claim_id = claim["id"]
        if claim_id in seen:
            raise ValueError(f"Duplicate Lean proof claim ID: {claim_id}")
        seen.add(claim_id)
        names = claim["theorems"]
        if (not isinstance(names, list) or not names
                or any(not isinstance(name, str) for name in names)
                or len(set(names)) != len(names)):
            raise ValueError(f"Invalid theorem references for {claim_id}")
        if missing := set(names) - theorems:
            raise ValueError(f"Missing compiled theorem for {claim_id}: {sorted(missing)}")
    return claims


def audit(scope, receipt):
    directory, roots, exporters = PACKAGES[scope]
    package = ROOT / "formal" / directory
    git = lambda *args: subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()
    revision = git("rev-parse", "HEAD")
    def snapshot():
        modules, hashes = inputs(package, roots, exporters)
        if scope == "core":
            hashes[str(CLAIMS.relative_to(ROOT))] = hashlib.sha256(CLAIMS.read_bytes()).hexdigest()
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
    # A cold Lake invocation installs the pinned toolchain and resolves locked
    # dependencies. Keep that preparation output visible and require success,
    # then query the version again through the strict diagnostic boundary. This
    # does not exempt later version or compiled-inventory output from auditing.
    build("env", "lean", "--version")
    version = lake("env", "lean", "--version", capture=True).strip()
    if len(version.splitlines()) != 1 or not pin.startswith("leanprover/lean4:v") or not version.startswith(
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
        claims = checked_claims(declarations) if scope == "core" else None
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
        if claims is not None:
            payload["proof_claims"] = claims
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
