"""Shared fixtures for what some tests need beyond the repository: skipped where absent, a failure where
`USUL_REQUIRE` (comma-separated) names it, so CI, which sets it, cannot pass by skipping."""

import os
import shutil
from pathlib import Path

import pytest

from usul_corpus import routing

ANSWERS = Path(__file__).parents[2] / routing.ANSWERS


def _require(name: str, present: bool, reason: str) -> None:
    if not present:
        (pytest.fail if name in os.environ.get("USUL_REQUIRE", "").split(",") else pytest.skip)(reason)


@pytest.fixture
def swipl():
    """SWI-Prolog, for the replays that run the Prolog rules."""
    _require("swipl", shutil.which("swipl") is not None, "swipl not installed")


@pytest.fixture
def islamqa_answers() -> Path:
    """The Arabic IslamQA answers (Git LFS); a bare pointer, as a checkout without LFS leaves, is absent."""
    _require("islamqa", ANSWERS.exists() and ANSWERS.stat().st_size > 1000, "IslamQA answers not fetched (git lfs pull)")
    return ANSWERS
