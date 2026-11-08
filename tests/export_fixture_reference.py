#!/usr/bin/env python3
"""Replay the legacy fixture specifications to check or explicitly refresh the migration reference.

This is an optional migration oracle. The default Lean fixture gate reads the
committed reference and never requires SWI-Prolog. No Lean answer is generated
by this program: it records the independent legacy queries and their outcomes.
"""

import argparse
import hashlib
import json
import os
import re
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
REFERENCE = ROOT / "tests/lean-fixture-reference.json"
SUITES = {
    "sheaf": "examples/v39_sheaf_obstruction_fixtures.pl",
    "fatwa": "examples/v40_fatwa_oracle_fixtures.pl",
    "typing": "examples/v41_typing_fixtures.pl",
}
INPUTS = [
    "examples/v38_contextual_affect_deontics.pl",
    "examples/v39_affect_concern.pl", "examples/v39_temporal_concern.pl",
    "examples/v39_claim_concern.pl", "examples/v39_sheaf_concern.pl",
    *SUITES.values(), "examples/v40_fatwa_rules.pl", "examples/v40_fatwa_cases.pl",
    "examples/v41_types.pl", "examples/v41_typing.pl", "tests/fixture_runner.pl",
    "tests/run_fixture_expectations.pl", "tests/test_fixture_runner.pl", "tests/mutation_test.sh",
]


def hashes():
    return {name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest() for name in sorted(INPUTS)}



def unique_object(pairs):
    value = {}
    for key, item in pairs:
        if key in value:
            raise ValueError(f"Duplicate reference JSON key: {key}")
        value[key] = item
    return value


def checked_suites(suites):
    if not isinstance(suites, dict) or set(suites) != set(SUITES):
        raise ValueError("Missing or unexpected reference suites")
    canonical = {}
    for suite, rows in suites.items():
        if not isinstance(rows, list) or not rows:
            raise ValueError(f"Empty or malformed reference suite: {suite}")
        names = set()
        for row in rows:
            if not isinstance(row, dict) or set(row) != {"name", "expected", "actual", "premises"}:
                raise ValueError(f"Malformed reference fixture fields: {suite}")
            name = row["name"]
            if not isinstance(name, str) or not name or any(c in name for c in "\t\r\n") or name in names:
                raise ValueError(f"Invalid or duplicate reference fixture name: {suite}/{name!r}")
            names.add(name)
            if (type(row["expected"]) is not bool or type(row["actual"]) is not bool
                    or not isinstance(row["premises"], list)
                    or any(type(value) is not bool for value in row["premises"])):
                raise ValueError(f"Non-Boolean reference fixture: {suite}/{name}")
        canonical[suite] = sorted(rows, key=lambda row: row["name"])
    return canonical


def validate_reference(value):
    if not isinstance(value, dict) or set(value) != {"schema", "reference_revision", "source_sha256", "suites"}:
        raise ValueError("Malformed reference root fields")
    if value["schema"] != "usul.fixture-migration-reference.v1":
        raise ValueError("Wrong reference schema")
    revision = value["reference_revision"]
    if not isinstance(revision, str) or not re.fullmatch(r"[0-9a-f]{40}", revision):
        raise ValueError("Invalid reference revision: expected a full lowercase commit SHA")
    sources = value["source_sha256"]
    if not isinstance(sources, dict) or set(sources) != set(INPUTS):
        raise ValueError("Incomplete or unexpected reference source inventory")
    if any(not isinstance(digest, str) or not re.fullmatch(r"[0-9a-f]{64}", digest)
           for digest in sources.values()):
        raise ValueError("Malformed reference source hash")
    checked_suites(value["suites"])
    return value


def canonical_suites(suites):
    # JSON distinguishes true from 1; Python dictionary equality does not.
    return json.dumps(checked_suites(suites), sort_keys=True, ensure_ascii=False, separators=(",", ":"))


def verify_source_revision(revision, source_hashes, *, writing=False):
    # A partial clone must also fail rather than fetching missing objects implicitly.
    env = {**os.environ, "GIT_NO_LAZY_FETCH": "1"}
    commit = subprocess.run(["git", "cat-file", "-t", revision], cwd=ROOT, env=env,
                            capture_output=True, timeout=30)
    if commit.returncode or commit.stdout.strip() != b"commit":
        raise ValueError(
            f"Reference revision {revision} is unavailable or is not a commit. "
            "Fetch repository history containing this commit and rerun "
            "(for a shallow clone: git fetch --unshallow; "
            "for actions/checkout: fetch-depth: 0).")
    mismatches = []
    for name, expected in sorted(source_hashes.items()):
        blob = subprocess.run(["git", "show", f"{revision}:{name}"], cwd=ROOT, env=env,
                              capture_output=True, timeout=30)
        if blob.returncode or hashlib.sha256(blob.stdout).hexdigest() != expected:
            mismatches.append(name)
    if mismatches:
        paths = ", ".join(mismatches)
        if writing:
            raise ValueError(
                f"Cannot refresh the reference: legacy inputs differ from git HEAD ({paths}). "
                "Commit the intended legacy input changes first, then rerun "
                "python3 tests/export_fixture_reference.py --write.")
        raise ValueError(
            f"Reference source hashes do not match commit {revision}: {paths}. "
            "Restore the source-bound reference or explicitly refresh it from committed legacy inputs.")


def replay():
    suites = {}
    for suite, path in SUITES.items():
        # First require the original fail-closed loader/runner to accept the suite.
        subprocess.run(["swipl", "tests/run_fixture_expectations.pl", "--", path],
                       cwd=ROOT, check=True, capture_output=True, text=True, timeout=120)
        # Ground each query independently, exactly as check_expectation does.
        goal = (
            "use_module(library(http/json)),"
            "findall(_{name:NameText,expected:Expected,actual:Actual,premises:Values},"
            "(fixture_expectation(Name,query(Query),Kind),"
            "term_string(Name,NameText,[quoted(true)]),"
            "(Kind=expect_true->Expected=true;Kind=expect_false->Expected=false;throw(bad_kind)),"
            "(once(Query)->Actual=true;Actual=false),"
            "findall(Value,(fixture_premise(Name,query(P)),(once(P)->Value=true;Value=false)),Values)),"
            "Rows),json_write_dict(current_output,Rows,[width(0)]),nl,halt"
        )
        result = subprocess.run(["swipl", "-q", "-s", path, "-g", goal], cwd=ROOT,
                                check=True, capture_output=True, text=True, timeout=120)
        if result.stderr.strip():
            raise ValueError(f"Legacy export diagnostics ({suite}): {result.stderr}")
        rows = json.loads(result.stdout, object_pairs_hook=unique_object)
        names = [row["name"] for row in rows]
        if not rows or len(names) != len(set(names)):
            raise ValueError(f"Empty or duplicate legacy suite: {suite}")
        if any(row["actual"] != row["expected"] or not all(row["premises"]) for row in rows):
            raise ValueError(f"Legacy suite failed: {suite}")
        suites[suite] = sorted(rows, key=lambda row: row["name"])
    return checked_suites(suites)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true", help="Explicitly refresh the committed migration reference")
    args = parser.parse_args()
    source_hashes = hashes()
    suites = replay()
    if hashes() != source_hashes:
        raise ValueError("Legacy inputs changed during replay")
    if args.write:
        revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
        verify_source_revision(revision, source_hashes, writing=True)
        value = {"schema": "usul.fixture-migration-reference.v1", "reference_revision": revision,
                 "source_sha256": source_hashes, "suites": suites}
        validate_reference(value)
        REFERENCE.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n")
    else:
        value = validate_reference(json.loads(REFERENCE.read_text(), object_pairs_hook=unique_object))
        verify_source_revision(value["reference_revision"], value["source_sha256"])
        if value["source_sha256"] != source_hashes or canonical_suites(value["suites"]) != canonical_suites(suites):
            raise ValueError("Legacy replay differs from the committed migration reference")
    print("Legacy reference: " + ", ".join(f"{name}={len(rows)}" for name, rows in suites.items()))


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        raise SystemExit(str(error)) from error
