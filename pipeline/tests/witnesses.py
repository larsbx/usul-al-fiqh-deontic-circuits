"""The cached witness a verbatim test reads: a required one (`source_verify.required_witnesses`) that is
missing fails, including offline, so CI cannot pass by skipping (PR-06, PR-40); any other is skipped."""

from pathlib import Path

import pytest

from usul_corpus.__main__ import CACHE
from usul_corpus.source_verify import required_witnesses

REQUIRED = required_witnesses(Path(__file__).parents[2] / "corpus")


def cached(wid: str) -> Path:
    path = CACHE / f"{wid}.txt"
    if not path.exists():
        if wid in REQUIRED:
            pytest.fail(f"required witness {wid} not cached; run make source-verify-fetch")
        pytest.skip(f"excluded from required source subset: {wid} not cached")
    return path
