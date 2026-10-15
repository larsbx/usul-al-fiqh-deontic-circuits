"""Shared fixtures for what some tests need beyond the repository: skipped where absent, a failure where
`USUL_REQUIRE` (comma-separated) names it, so CI, which sets it, cannot pass by skipping."""

import os
import hashlib
import shutil
import subprocess
from pathlib import Path

import pytest

from usul_corpus import routing

ANSWERS = Path(__file__).parents[2] / routing.ANSWERS


def pytest_addoption(parser):
    parser.addoption("--integration-gate", action="store_true",
                     help="Require working SWI-Prolog and reject every skip in the selected tests")


def pytest_configure(config):
    config.addinivalue_line("markers", "external_source: requires the separately pinned IslamQA archive")
    if config.getoption("--integration-gate"):
        config.pluginmanager.register(_IntegrationGate(), "usul-integration-gate")


class _IntegrationGate:
    def __init__(self):
        self.skipped = []

    def pytest_sessionstart(self, session):
        try:
            executable = shutil.which("swipl")
            if executable is None:
                raise ValueError("swipl not installed")
            # Execute a goal, not just --version: detect broken startup/library paths,
            # require SWI 9+, and exercise the JSON support used by the Python bridge.
            goal = ("current_prolog_flag(version,V),V>=90000,"
                    "use_module(library(http/json)),"
                    "atom_json_dict('{\"ready\":true}',D,[]),get_dict(ready,D,true),"
                    "writeln('usul-prolog-ready')")
            result = subprocess.run([executable, "-q", "-g", goal, "-t", "halt"],
                                    capture_output=True, text=True, timeout=10, check=True)
            if result.stdout.strip() != "usul-prolog-ready":
                raise ValueError("runtime did not execute the probe")
        except (OSError, ValueError, subprocess.SubprocessError) as exc:
            raise pytest.UsageError(f"SWI-Prolog integration preflight failed: {exc}") from exc

    def pytest_collectreport(self, report):
        if report.skipped:
            self.skipped.append(report.nodeid)

    def pytest_runtest_logreport(self, report):
        if report.skipped:
            self.skipped.append(report.nodeid)

    def pytest_sessionfinish(self, session, exitstatus):
        if self.skipped:
            session.exitstatus = pytest.ExitCode.TESTS_FAILED
            reporter = session.config.pluginmanager.get_plugin("terminalreporter")
            if reporter:
                reporter.write_sep("=", "integration gate: unexpected skips")
                for nodeid in self.skipped:
                    reporter.write_line(nodeid)


def _require(name: str, present: bool, reason: str, request) -> None:
    if not present:
        required = request.config.getoption("--integration-gate") or name in os.environ.get("USUL_REQUIRE", "").split(",")
        (pytest.fail if required else pytest.skip)(reason)


@pytest.fixture
def swipl(request):
    """SWI-Prolog, for the replays that run the Prolog rules."""
    _require("swipl", shutil.which("swipl") is not None, "swipl not installed", request)


@pytest.fixture(scope="session")
def islamqa_answers(request) -> Path:
    """The Arabic IslamQA answers (Git LFS); a bare pointer, as a checkout without LFS leaves, is absent."""
    _require("islamqa", ANSWERS.exists() and ANSWERS.stat().st_size > 1000, "IslamQA answers not fetched (git lfs pull)", request)
    from usul_corpus.signature_routing import ANSWERS_SHA256
    with ANSWERS.open("rb") as fh:
        digest = hashlib.file_digest(fh, "sha256").hexdigest()
    assert digest == ANSWERS_SHA256, "IslamQA archive differs from its pinned SHA-256"
    return ANSWERS
