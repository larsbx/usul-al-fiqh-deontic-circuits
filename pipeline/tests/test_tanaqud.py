"""The bank applied to its own contradictions (`Usul.Tanaqud`, `corpus/tanaqud/sadi.json`)."""

import json
import re
from pathlib import Path

import jsonschema
import pytest

from usul_corpus.__main__ import CACHE
from usul_corpus.arabic import letters, normalize
from usul_corpus.records import EXCERPT_LEN

ROOT = Path(__file__).parents[2]
REG = json.loads((ROOT / "corpus/tanaqud/sadi.json").read_text(encoding="utf-8"))
PAIRS = REG["pairs"]


def test_register_validates():
    jsonschema.validate(REG, json.loads((ROOT / "schemas/tanaqud.schema.json").read_text()))
    assert [p["id"] for p in PAIRS] == [f"T-{i:02d}" for i in range(1, len(PAIRS) + 1)]


def test_each_pair_once():
    seen = [frozenset(p["rules"]) for p in PAIRS] + [frozenset(e["rules"]) for e in REG["proved_earlier"]]
    assert len(seen) == len(set(seen)) and all(len(s) == 2 for s in seen)


def test_the_bank_resolves_itself():
    """Every pair reaches jamʿ, the first stage of `Usul.resolve`; none is left in tawaqquf."""
    assert {p["resolution"] for p in PAIRS} == {"jam"}


@pytest.mark.parametrize("p", PAIRS, ids=lambda p: p["id"])
def test_qayd_is_the_authors_own(p):
    """The qayd is quoted from one of the two qawāʿid themselves, within the excerpt limit."""
    for a in p["author"]:
        witness, q = re.match(r"src:([a-z0-9-]+)#q(\d{3})$", a["ref"]).groups()
        assert witness == REG["witness"] and int(q) in p["rules"]
        assert len(a["excerpt_ar"]) <= EXCERPT_LEN["modern_cache_only"]


@pytest.mark.parametrize("p", PAIRS, ids=lambda p: p["id"])
def test_quotes_are_verbatim(p):
    src = CACHE / f"{REG['witness']}.txt"
    if not src.exists():
        pytest.skip(f"{REG['witness']} not cached")
    key = lambda s: letters(normalize(s))
    text = key(src.read_text(encoding="utf-8"))
    assert all(key(a["excerpt_ar"]) in text for a in p["author"])


def test_lean_is_checked_and_complete():
    """Every named constant is #check-ed, and every theorem of the module is named by the register."""
    checked = (ROOT / "formal/lean/UsulTest/SignatureMap.lean").read_text(encoding="utf-8")
    named = REG["lean"] + [n for p in PAIRS for n in p["lean"]] + [n for e in REG["proved_earlier"] for n in e["lean"]]
    assert all(f"#check @{n}\n" in checked for n in named)
    module = (ROOT / "formal/lean/Usul/Tanaqud.lean").read_text(encoding="utf-8")
    theorems = {f"Usul.Tanaqud.{n}" for n in re.findall(r"^theorem (\S+)", module, re.M)}
    assert theorems <= set(named), theorems - set(named)
