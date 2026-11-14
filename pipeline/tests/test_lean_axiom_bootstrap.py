"""Exercise the audit CLI's setup/verification boundary without downloading Lean."""

import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

import pytest


ROOT = Path(__file__).resolve().parents[2]
PIN = "leanprover/lean4:v4.34.1"
VERSION = "Lean (version 4.34.1, fixture, commit fixture, Release)\n"

# This executable models process output and failure, not Lean proof checking.
# Its location is the only PATH entry supplied to the CLI, so no real Lake can
# accidentally install a toolchain or satisfy a negative control.
FAKE_LAKE = r'''
import json
import os
from pathlib import Path
import sys

config = json.loads(Path(os.environ["FAKE_LAKE_CONFIG"]).read_text())
log = Path(os.environ["FAKE_LAKE_LOG"])
calls = [json.loads(line) for line in log.read_text().splitlines()] if log.exists() else []
args = sys.argv[1:]
with log.open("a") as stream:
    stream.write(json.dumps(args) + "\n")

def finish(stage, stdout="", stderr=""):
    print(config.get(stage + "_stdout", stdout), end="")
    print(config.get(stage + "_stderr", stderr), end="", file=sys.stderr)
    sys.exit(config.get(stage + "_exit", 0))

version = "Lean (version 4.34.1, fixture, commit fixture, Release)\n"
if args == ["env", "lean", "--version"]:
    if args not in calls:
        if config.get("mutate_during_setup"):
            with Path("lake-manifest.json").open("a") as stream:
                stream.write("\n")
        finish("setup", version,
               "info: downloading pinned Lean toolchain\n"
               "info: installing pinned Lean toolchain\n"
               "info: dependency: checking out locked revision\n")
    finish("version", version)

if args == ["build"] or args[:3] == ["exe", "cache", "get"]:
    finish("build")

if args[:2] == ["env", "lean"] and "-o" in args:
    Path(args[args.index("-o") + 1]).write_bytes(b"fixture olean")
    finish("export")

if args[:2] == ["env", "lean"] and Path(args[2]).name == "CheckLeanAxioms.lean":
    imports = [line.removeprefix("import ")
               for line in Path(args[2]).read_text().splitlines()
               if line.startswith("import ") and line != "import Lean"]
    mode = config.get("inventory_mode", "valid")
    if mode == "missing_module":
        imports = imports[1:]
    rows = []
    for module in imports:
        kind = {"named_axiom": "axiom", "definition": "other"}.get(mode, "theorem")
        axioms = "sorryAx" if mode == "sorry" else "Classical.choice,Quot.sound,propext"
        rows.extend(["module\t" + module,
                     "\t".join([kind, module, module + ".fixture", axioms])])
    if mode == "unexpected_stdout":
        rows.append("info: unexpected output in the compiled inventory")
    finish("inventory", "\n".join(rows) + "\n")

print("unexpected fixture command: " + repr(args), file=sys.stderr)
sys.exit(99)
'''


@pytest.fixture
def run_audit(tmp_path):
    repo = tmp_path / "repo"
    formal = repo / "formal"
    formal.mkdir(parents=True)
    for name in ("check-lean-axioms.py", "lean-axiom-audit.lean"):
        shutil.copyfile(ROOT / "formal" / name, formal / name)
    claims = formal / "lean-proof-claims.json"
    claims.write_text(json.dumps({
        "schema": "usul.lean.proof-claims.v1",
        "claims": [{
            "id": "fixture-proof", "theorems": ["Usul.fixture"],
            "claim": "Fixture theorem", "hypotheses": "Fixture assumptions",
            "finite_checks": "Fixture checks", "source_review": "Fixture scope",
            "refinement": "Fixture model",
        }],
    }))
    for package, modules in (
        ("lean", ("Usul", "UsulTest", "Hadith", "HadithTest",
                  "scripts/ExportTypes", "scripts/ExportAgency")),
        ("lean-mathlib", ("UsulMathlib",)),
    ):
        directory = formal / package
        directory.mkdir()
        (directory / "lean-toolchain").write_text(PIN + "\n")
        (directory / "lakefile.toml").write_text('name = "fixture"\n')
        (directory / "lake-manifest.json").write_text("{}\n")
        for module in modules:
            path = directory / (module + ".lean")
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("-- fixture source; no real compiler runs in this test\n")

    git = shutil.which("git")
    assert git is not None
    subprocess.run([git, "init", "--quiet", str(repo)], check=True)
    subprocess.run([git, "-C", str(repo), "add", "formal"], check=True)
    subprocess.run([git, "-C", str(repo), "-c", "user.name=Audit Fixture",
                    "-c", "user.email=audit-fixture@example.invalid",
                    "-c", "commit.gpgsign=false", "-c", "core.hooksPath=/dev/null",
                    "commit", "--quiet", "-m", "Fixture inputs"], check=True)

    binaries = tmp_path / "bin"
    binaries.mkdir()
    (binaries / "git").symlink_to(git)
    lake = binaries / "lake"
    lake.write_text(f"#!{sys.executable}\n" + FAKE_LAKE)
    lake.chmod(0o755)
    config_path, log = tmp_path / "config.json", tmp_path / "calls.jsonl"
    env = {**os.environ, "PATH": str(binaries),
           "FAKE_LAKE_CONFIG": str(config_path), "FAKE_LAKE_LOG": str(log)}

    def run(scope="core", *, missing_lake=False, missing_claim=False, **config):
        if missing_claim:
            claims.write_text(claims.read_text().replace("Usul.fixture", "Usul.absent"))
        config_path.write_text(json.dumps(config))
        if missing_lake:
            lake.unlink()
        receipt = repo / f".cache/lean-axioms/{scope}.json"
        receipt.parent.mkdir(parents=True, exist_ok=True)
        # A failing replay must remove rather than preserve a previous result.
        receipt.write_text('{"stale": true}\n')
        result = subprocess.run(
            [sys.executable, str(formal / "check-lean-axioms.py"), scope],
            cwd=repo, env=env, capture_output=True, text=True,
        )
        calls = [json.loads(line) for line in log.read_text().splitlines()] if log.exists() else []
        return result, receipt, calls

    return run


@pytest.mark.parametrize("scope", ["core", "mathlib"])
def test_cold_preparation_is_visible_and_followed_by_strict_audit(run_audit, scope):
    result, receipt, calls = run_audit(scope)
    assert result.returncode == 0, result.stdout + result.stderr
    assert "info: downloading pinned Lean toolchain" in result.stdout
    assert "checking out locked revision" in result.stdout
    assert calls[:2] == [["env", "lean", "--version"]] * 2
    payload = json.loads(receipt.read_text())
    assert payload["toolchain"] == PIN
    assert payload["lean_version"] == VERSION.strip()
    assert payload["inputs_match_head"] is True
    assert payload["allowed_axioms"] == ["Classical.choice", "Quot.sound", "propext"]
    assert payload["declarations"]
    if scope == "core":
        assert payload["proof_claims"][0]["theorems"] == ["Usul.fixture"]
        assert "formal/lean-proof-claims.json" in payload["source_sha256"]
    else:
        assert "proof_claims" not in payload
    script = receipt.parents[2] / "formal/check-lean-axioms.py"
    assert payload["source_sha256"]["formal/check-lean-axioms.py"] == hashlib.sha256(
        script.read_bytes()).hexdigest()


@pytest.mark.parametrize("status", [1, 127])
def test_failed_preparation_stops_before_version_and_removes_stale_receipt(run_audit, status):
    result, receipt, calls = run_audit(setup_exit=status, setup_stderr="error: setup failed\n")
    assert result.returncode != 0
    assert "error: setup failed" in result.stdout + result.stderr
    assert calls == [["env", "lean", "--version"]]
    assert not receipt.exists()


def test_missing_preparation_executable_cannot_produce_receipt(run_audit):
    result, receipt, calls = run_audit(missing_lake=True)
    assert result.returncode != 0
    assert "No such file or directory" in result.stderr
    assert calls == []
    assert not receipt.exists()


@pytest.mark.parametrize("stage", ["version", "inventory"])
def test_installation_info_is_forbidden_after_preparation(run_audit, stage):
    result, receipt, _ = run_audit(**{stage + "_stderr": "info: downloading pinned Lean toolchain\n"})
    assert result.returncode != 0
    assert "Unexpected Lean diagnostics" in result.stderr
    assert not receipt.exists()


def test_preparation_success_does_not_hide_missing_toolchain_on_strict_recheck(run_audit):
    result, receipt, calls = run_audit(version_exit=1, version_stderr="error: toolchain missing\n")
    assert result.returncode != 0
    assert "error: toolchain missing" in result.stdout + result.stderr
    assert len(calls) == 2
    assert not receipt.exists()


@pytest.mark.parametrize("version", [
    "Lean (version 4.33.0, fixture)\n",
    VERSION + "info: unexpected extra version output\n",
])
def test_strict_version_requires_the_pin_and_one_output_line(run_audit, version):
    result, receipt, calls = run_audit(version_stdout=version)
    assert result.returncode != 0
    assert "Toolchain mismatch" in result.stderr
    assert len(calls) == 2
    assert not receipt.exists()


@pytest.mark.parametrize("mode, error", [
    ("unexpected_stdout", "Unexpected Lean inventory output"),
    ("missing_module", "Module coverage mismatch"),
    ("named_axiom", "Disallowed Lean declarations"),
    ("sorry", "Disallowed Lean declarations"),
])
def test_preparation_does_not_weaken_compiled_inventory_checks(run_audit, mode, error):
    result, receipt, _ = run_audit(inventory_mode=mode)
    assert result.returncode != 0
    assert error in result.stderr
    assert not receipt.exists()


def test_admitted_anonymous_build_diagnostic_still_fails(run_audit):
    result, receipt, _ = run_audit(build_stdout="warning: example: declaration uses `sorry`\n")
    assert result.returncode != 0
    assert "admitted-proof diagnostic" in result.stderr
    assert not receipt.exists()


@pytest.mark.parametrize("config", [{"missing_claim": True}, {"inventory_mode": "definition"}])
def test_registered_claim_requires_a_compiled_theorem(run_audit, config):
    result, receipt, _ = run_audit(**config)
    assert result.returncode != 0
    assert "Missing compiled theorem for fixture-proof" in result.stderr
    assert not receipt.exists()


def test_preparation_cannot_change_hashed_inputs(run_audit):
    result, receipt, _ = run_audit(mutate_during_setup=True)
    assert result.returncode != 0
    assert "Lean audit inputs changed during replay" in result.stderr
    assert not receipt.exists()
