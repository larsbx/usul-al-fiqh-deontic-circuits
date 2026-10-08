"""al-Albānī track, H0: each kernel scale has the recalled number of rungs, numbered 1…n, every
rung verbatim in its pinned witness (where cached), within that witness's rights, and every
Lean link #check-ed by the generated HadithTest/ScaleMap.lean."""

import json
from pathlib import Path

import jsonschema
import pytest

from usul_corpus.__main__ import CACHE, SCALE_LEAN, hadith_lean_names, signature_lean
from usul_corpus.arabic import locate
from usul_corpus.records import EXCERPT_LEN

ROOT = Path(__file__).parents[2]
SCALES = json.loads((ROOT / "corpus/hadith/kernel_scales.json").read_text(encoding="utf-8"))
REGISTRY = json.loads((ROOT / "corpus/registry.json").read_text(encoding="utf-8"))["works"]
WORKS = {w["id"]: w for w in REGISTRY}
ITEMS = [(s, i) for s in SCALES["scales"] for i in s["items"]]


def _witness(ref):
    return ref[4:].split("/")


def test_schema():
    jsonschema.validate(SCALES, json.loads((ROOT / "schemas/hadith_scales.schema.json").read_text()))


@pytest.mark.parametrize("scale", SCALES["scales"], ids=lambda s: s["id"])
def test_counts_match_the_claim(scale):
    assert [i["n"] for i in scale["items"]] == list(range(1, scale["claim"] + 1))


@pytest.mark.parametrize("scale,item", ITEMS, ids=lambda x: x.get("id") or str(x.get("n")))
def test_refs_within_the_work_and_its_rights(scale, item):
    work = WORKS[scale["work"]]
    w, _ = _witness(item["ref"])
    assert w in {x["id"] for x in work["witnesses"]} and work.get("track") == "albani_hadith"
    assert len(item["excerpt_ar"]) <= EXCERPT_LEN[work["rights"]]


@pytest.mark.parametrize("scale,item", ITEMS, ids=lambda x: x.get("id") or str(x.get("n")))
def test_excerpts_are_verbatim(scale, item):
    w, loc = _witness(item["ref"])
    src = CACHE / f"{w}.txt"
    if not src.exists():
        pytest.skip(f"{w} not cached")
    assert locate(src.read_text(encoding="utf-8"), item["excerpt_ar"]) == loc


def test_scale_map_is_generated():
    assert SCALE_LEAN.read_text(encoding="utf-8") == signature_lean(hadith_lean_names(), "Hadith")
