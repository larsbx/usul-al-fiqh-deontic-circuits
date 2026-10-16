"""PR-33: typed position domains and the Python/Lean reconciliation boundary."""

from copy import deepcopy
import json
from pathlib import Path

import pytest
import jsonschema

from usul_corpus import reconcile, takhrij
from usul_corpus.__main__ import load_dossier

ROOT = Path(__file__).parents[2]
CASES = takhrij.load(ROOT / "corpus")
LEDGER = reconcile.load(ROOT / "corpus")
CASE = next(c for c in CASES if c["far"].endswith("q043.f005"))
ENTRY = next(e for e in LEDGER["entries"] if e["far"] == CASE["far"])


def errors(c):
    return reconcile.check([c], {"entries": [ENTRY]}, load_dossier())


def test_q043_f005_collision_rejected_by_both_validators():
    assert takhrij.check_case(CASE) == [] and errors(CASE) == []
    assert reconcile.resolve(CASE, ENTRY) == ("tawaqquf", None)
    c = deepcopy(CASE)
    c["positions"][0]["ruling"] = 0
    assert takhrij.check_case(c)
    assert errors(c)
    # The public boundary rejects invalid cases before any ranking.
    with pytest.raises(ValueError, match="position"):
        reconcile.resolve(c, ENTRY)
    with pytest.raises(ValueError, match="position"):
        reconcile.attribution(c, ENTRY)


@pytest.mark.parametrize("value", [0, 1, 0.0, 1.0, None, "unsupported", [], {}])
def test_unsupported_position_cannot_pass_either_validator(value):
    c = deepcopy(CASE)
    c["positions"][0]["ruling"] = value
    assert takhrij.check_case(c) and errors(c)


@pytest.mark.parametrize("marker", [True, False, "", "  ", {}, {"reason": "outside"}])
def test_outside_marker_requires_a_nonempty_explanation(marker):
    c = deepcopy(CASE)
    c["positions"][0].update(ruling="alternative", outside=marker)
    assert takhrij.check_case(c) and errors(c)


def test_outside_marker_cannot_hide_wrong_type_or_in_domain_ruling():
    for ruling in (0, 1, None, [], {}, True):
        c = deepcopy(CASE)
        c["positions"][0].update(ruling=ruling, outside="A claimed alternative")
        assert takhrij.check_case(c) and errors(c)


def test_boolean_does_not_enter_an_integer_output_domain(monkeypatch):
    monkeypatch.setitem(takhrij.ENCODERS, "integer_test", {"out": [0, 1], "facts": {}, "py": lambda _: 1})
    c = {"encoder": "integer_test", "class": "derivable", "facts": {}, "expected": 1,
         "positions": [{"who": "holder", "ruling": 1}]}
    assert takhrij.check_case(c) == []
    c["positions"][0]["ruling"] = True
    assert takhrij.check_case(c)


@pytest.mark.parametrize("a,b", [(False, 0), (True, 1), (False, "false"), (True, "true"), (1, "1")])
def test_all_reconciliation_comparisons_use_canonical_identity(a, b, monkeypatch):
    # Synthetic declared domain exercises both sides through the public boundary.
    monkeypatch.setitem(takhrij.ENCODERS, "typed_test", {"out": [a, b]})
    c = {"encoder": "typed_test", "positions": [{"ruling": a}, {"ruling": b}], "expected": b}
    e = {"grades": ["tashih", "wajh"], "proofs": [{"position": 0, "tier": "qiyas"}]}
    assert len(reconcile.rulings(c)) == 2
    assert reconcile.top([(a, "qiyas")], b) is None
    assert not reconcile.favours([(a, b, "muttasil", "stated")], b, a)
    assert reconcile.weigh([a, b], [(a, "qiyas"), (b, "qiyas")], []) is None
    assert reconcile.prevail([(a, "nass"), (b, "nass")]) is None
    assert reconcile.support([(a, "nass")], b) == []
    assert reconcile.standing(c, e) == "against_reading"
    assert reconcile.attribution_standing(c, e) == "against_reading"
    assert not reconcile.marked_for_reading(c, e)
    assert reconcile._against_proofs(c, e)
    assert reconcile._str(a) != reconcile._str(b)


def test_canonical_identity_handles_nested_values_and_ignores_detail():
    a, b = {"a": True, "b": 2}, {"b": 2, "a": True}
    c = {"positions": [{"ruling": a}, {"ruling": b, "detail": "explanation"}]}
    assert reconcile.rulings(c) == [a]
    assert reconcile._same(a, b)
    assert not reconcile._same(a, {"a": 1, "b": 2})
    assert reconcile._str(a) == reconcile._str(b)
    assert json.loads(reconcile._str(a)) == takhrij.code(a)


def test_q160_exceptions_are_explicit_and_preserve_the_split_position():
    cs = [c for c in CASES if ".q160." in c["far"]]
    outside = [(c, p) for c in cs for p in c.get("positions", [])
               if not takhrij.among(p["ruling"], takhrij.ENCODERS[c["encoder"]]["out"])]
    assert len(outside) == 36
    for c, p in outside:
        assert isinstance(p.get("outside"), str) and p["outside"].strip()
        assert takhrij.check_case(c) == []
        unmarked = deepcopy(c)
        for q in unmarked["positions"]:
            q.pop("outside", None)
        assert takhrij.check_case(unmarked)
    c = next(c for c in cs if c["far"].endswith("f031"))
    e = next(e for e in LEDGER["entries"] if e["far"] == c["far"])
    assert c["positions"][0]["ruling"] == "no lot; lineage lost"
    assert c["positions"][3]["ruling"] == "no lot; chosen at puberty"
    assert reconcile.attribution(c, e) == ("tarjih", "no lot; lineage lost")
    assert all(reconcile.resolve(c, e, policy) == ("tawaqquf", None) for policy in reconcile.POLICIES)


def test_outside_migration_is_pinned_metadata_only_and_idempotent():
    from usul_corpus.migrate_pr33 import SOURCES, migrate
    for name in SOURCES:
        data = json.loads((ROOT / "corpus/takhrij" / name).read_text())
        assert migrate(data, name) == data
        changed = deepcopy(data)
        changed["cases"][0]["note"] += " changed"
        with pytest.raises(ValueError):
            migrate(changed, name)


def test_position_schema_rejects_blank_or_nontext_outside_marker():
    schema = json.loads((ROOT / "schemas/takhrij_cases.schema.json").read_text())
    position = schema["properties"]["cases"]["items"]["properties"]["positions"]["items"]
    for value in (True, "", "  ", {}):
        with pytest.raises(jsonschema.ValidationError):
            jsonschema.validate({"who": "holder", "ruling": "alternative", "outside": value}, position)


def test_reconciliation_validates_positions_outside_the_ledger():
    c = deepcopy(CASE)
    c["class"] = "derivable"
    c["positions"][0]["ruling"] = 0
    assert any("position 0" in error for error in
               reconcile.check([c], {"entries": []}, {"entries": []}))


def test_public_identity_imports_share_one_implementation():
    from usul_corpus import values, reconciliation_kernel
    assert takhrij.code is values.code
    assert takhrij.among is values.among
    assert reconcile._same is values.same
    assert reconciliation_kernel.same is values.same
    assert reconcile.weigh is reconciliation_kernel.weigh
    assert reconcile.prevail is reconciliation_kernel.prevail
