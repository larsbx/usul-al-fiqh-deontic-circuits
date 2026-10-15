"""Exercise the actual pytest entrypoint, including setup and collection skips."""

import os
from pathlib import Path
import subprocess
import sys

import pytest


def run_gate(tmp_path, body, runtime=None, extra=(), answers=None):
    conftest = Path(__file__).with_name("conftest.py").read_text()
    if answers is not None:
        (tmp_path / "answers.gz").write_bytes(answers)
        conftest += "\nANSWERS = Path(__file__).with_name('answers.gz')\n"
    (tmp_path / "conftest.py").write_text(conftest)
    (tmp_path / "test_probe.py").write_text(body)
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    if runtime is not None:
        executable = bin_dir / "swipl"
        executable.write_text("#!/bin/sh\n" + runtime + "\n")
        executable.chmod(0o755)
    env = os.environ | {"PATH": str(bin_dir), "PYTHONPATH": str(Path(__file__).parents[1]),
                        "PYTEST_DISABLE_PLUGIN_AUTOLOAD": "1", "PYTEST_ADDOPTS": "", "USUL_REQUIRE": ""}
    return subprocess.run([sys.executable, "-m", "pytest", "--integration-gate", "-q", *extra],
                          cwd=tmp_path, env=env, text=True, capture_output=True, timeout=30)


@pytest.mark.parametrize("runtime", [None, "exit 7", "exit 0", "echo wrong-output"])
def test_gate_rejects_missing_or_broken_runtime(tmp_path, runtime):
    result = run_gate(tmp_path, "def test_ok(): pass\n", runtime)
    assert result.returncode != 0
    assert "SWI-Prolog integration preflight failed" in result.stdout + result.stderr


@pytest.mark.parametrize("body", [
    "import pytest\n@pytest.mark.skip(reason='unexpected')\ndef test_probe(): pass\n",
    "import pytest\n@pytest.fixture\ndef unavailable(): pytest.skip('unexpected')\ndef test_probe(unavailable): pass\n",
    "import pytest\npytest.skip('unexpected', allow_module_level=True)\n",
])
def test_gate_rejects_unexpected_skips(tmp_path, body):
    result = run_gate(tmp_path, body, "echo usul-prolog-ready")
    assert result.returncode != 0
    assert "integration gate: unexpected skips" in result.stdout + result.stderr


def test_external_source_can_be_deselected_but_cannot_skip_in_its_gate(tmp_path):
    body = ("import pytest\n"
            "def test_committed(): pass\n"
            "@pytest.mark.external_source\n"
            "def test_external(islamqa_answers): pass\n")
    result = run_gate(tmp_path, body, "echo usul-prolog-ready", ("-m", "not external_source"))
    assert result.returncode == 0, result.stdout + result.stderr
    assert "1 passed, 1 deselected" in result.stdout


def test_external_gate_fails_on_missing_answers(tmp_path):
    result = run_gate(tmp_path, "def test_external(islamqa_answers): pass\n", "echo usul-prolog-ready")
    assert result.returncode != 0
    assert "IslamQA answers not fetched" in result.stdout + result.stderr
    assert "skipped" not in result.stdout


def test_empty_gate_cannot_pass(tmp_path):
    result = run_gate(tmp_path, "", "echo usul-prolog-ready")
    assert result.returncode != 0


def test_external_gate_rejects_corrupt_cached_archive(tmp_path):
    result = run_gate(tmp_path, "def test_external(islamqa_answers): pass\n", "echo usul-prolog-ready",
                      answers=b"wrong archive" * 1000)
    assert result.returncode != 0
    assert "IslamQA archive differs from its pinned SHA-256" in result.stdout + result.stderr
