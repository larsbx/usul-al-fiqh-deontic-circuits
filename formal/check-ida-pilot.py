#!/usr/bin/env python3
"""Replay and index the bounded ACT-08 pilot checks at one revision."""

import hashlib
import json
from pathlib import Path, PurePosixPath
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
CHECKS = ("context", "admission", "omission-auth", "pilot-trace", "zakat-structure", "structural-cases")
OUTPUT = ROOT / ".cache/ida-pilot/report.json"


def digest(data):
    return hashlib.sha256(data).hexdigest()


def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT)


def validate_report(raw, check, revision, source_digest):
    report = json.loads(raw)
    if (report.get("schema") != f"usul.ida.{check}.verification.v1"
            or report.get("revision") != revision
            or report.get("status") != "passed"
            or report.get("inputs_match_head") is not True):
        raise ValueError(f"{check}: expected a passing receipt for {revision}")

    inputs = report.get("source_sha256")
    if not isinstance(inputs, dict) or not inputs:
        raise ValueError(f"{check}: missing input fingerprints")
    for name, expected in inputs.items():
        path = PurePosixPath(name)
        if path.is_absolute() or ".." in path.parts or str(path) != name or name == ".":
            raise ValueError(f"{check}: invalid input path {name!r}")
        if source_digest(name) != expected:
            raise ValueError(f"{check}: source fingerprint mismatch for {name}")
    return {"path": f".cache/ida-{check}/report.json", "sha256": digest(raw),
            "fingerprinted_inputs": len(inputs)}


def main():
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.unlink(missing_ok=True)
    revision = git("rev-parse", "HEAD").decode().strip()

    def source_digest(name):
        committed = digest(git("show", f"{revision}:{name}"))
        if digest((ROOT / name).read_bytes()) != committed:
            raise ValueError(f"working source differs from {revision}: {name}")
        return committed

    inputs = {name: source_digest(name) for name in ("Makefile", "formal/check-ida-pilot.py", "formal/test-ida-pilot.py")}
    components = {}
    for check in CHECKS:
        path = ROOT / f".cache/ida-{check}/report.json"
        path.unlink(missing_ok=True)
        subprocess.run([sys.executable, str(ROOT / f"formal/check-ida-{check}.py")],
                       cwd=ROOT, check=True)
        components[check] = validate_report(path.read_bytes(), check, revision, source_digest)

    if git("rev-parse", "HEAD").decode().strip() != revision:
        raise ValueError("Git revision changed during pilot replay")
    for name, expected in inputs.items():
        if source_digest(name) != expected:
            raise ValueError(f"pilot input changed during replay: {name}")
    for check, evidence in components.items():
        if validate_report((ROOT / evidence["path"]).read_bytes(), check,
                           revision, source_digest) != evidence:
            raise ValueError(f"{check}: receipt changed during pilot replay")

    report = {"schema": "usul.ida.pilot.verification.v1", "status": "passed",
              "revision": revision, "source_sha256": inputs, "components": components,
              "boundary": "Bounded shared application trace and component replay. ACT-08 full exit remains open."}
    temporary = OUTPUT.with_suffix(".tmp")
    temporary.write_text(json.dumps(report, indent=2) + "\n")
    temporary.replace(OUTPUT)
    print(f"ACT-08 bounded pilot replay passed at {revision}.")


if __name__ == "__main__":
    main()
