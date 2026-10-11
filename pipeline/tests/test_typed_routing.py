"""T3/T4: the blind-typed IslamQA situations, routed by type (Prolog over the Lean export)."""

import json
import re
import shutil
from pathlib import Path

import pytest

from usul_corpus import typed_routing as tr

ROOT = Path(__file__).resolve().parents[2]
if not (ROOT / tr.SITUATIONS).exists():
    pytest.skip("the blind-typed situations are not committed yet", allow_module_level=True)
DATA = json.loads((ROOT / tr.SITUATIONS).read_text(encoding="utf-8"))
EXPORT = (ROOT / "examples/v41_types.pl").read_text(encoding="utf-8")


def allowed(lean_type: str) -> set:
    """The values a field of this Lean type takes: Bool, or the kernel's constructors (type_value/2)."""
    inner, nested = lean_type, 0
    while inner.startswith("Option "):
        inner, nested = inner[len("Option "):].strip("()"), nested + 1
    if inner == "Bool":
        return {True, False}
    ctors = set(re.findall(rf"^type_value\('{re.escape(inner)}', (\w+)\)\.", EXPORT, re.M))
    return ctors | ({"none"} if nested > 1 else set())


def test_allowed_values_come_from_the_kernel():
    assert allowed("Option Usul.Grade") == {"wahm", "shakk", "zann", "qat"}
    assert "none" in allowed("Option (Option Usul.Hukm)") and "wajib" in allowed("Option (Option Usul.Hukm)")


def test_situations_use_only_exported_fields_and_rights_capped_quotes():
    fields = dict(re.findall(r"^type_field\(\w+, (\w+), '([^']*)'\)\.", EXPORT, re.M))
    for a in DATA["answers"]:
        for s in a["situations"]:
            assert set(s["facts"]) <= set(fields), (a["answer"], set(s["facts"]) - set(fields))
            assert set(s["evidence"]) == set(s["facts"]), a["answer"]
            assert all(v in allowed(fields[f]) for f, v in s["facts"].items()), a["answer"]
            assert all(0 < len(q) <= 160 for q in s["evidence"].values()), a["answer"]


def test_every_tranche_answer_is_typed():
    cases = json.loads((ROOT / tr.TRANCHE).read_text(encoding="utf-8"))["cases"]
    assert {c["far"].rsplit(".", 1)[0] for c in cases} == {a["answer"] for a in DATA["answers"]}


def test_the_prolog_situations_are_current():
    assert tr.prolog_file(DATA) == (ROOT / tr.PROLOG).read_text(encoding="utf-8")


@pytest.mark.skipif(shutil.which("swipl") is None, reason="swipl not installed")
def test_the_report_is_current():
    assert json.dumps(tr.report(ROOT, tr.coverage(ROOT)), ensure_ascii=False, indent=2) + "\n" == \
        (ROOT / tr.REPORT).read_text(encoding="utf-8")
