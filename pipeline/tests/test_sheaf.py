"""M10: every genuine ikhtilāf is a sheaf obstruction, and the Lean guards mirror the records."""

import json
from pathlib import Path

from usul_corpus import judgement, sheaf, takhrij

ROOT = Path(__file__).resolve().parents[2]
CORPUS = ROOT / "corpus"
CASES = takhrij.load(CORPUS)
TYPES = judgement.load(CORPUS)


def test_every_ikhtilaf_is_obstructed():
    rep = sheaf.render(CASES, TYPES)
    assert rep["summary"]["cases"] == sum(c["class"] == "genuine_ikhtilaf" for c in CASES)
    assert all(r["obstructions"] for r in rep["cases"]), [r["far"] for r in rep["cases"] if not r["obstructions"]]


def test_records_are_the_disagreeing_pairs():
    case = {"positions": [{"ruling": True}, {"ruling": True}, {"ruling": "x"}, {"ruling": False}]}
    assert sheaf.rulings(case) == [0, 0, 2, 3]
    assert sheaf.obstructions(case) == [[0, 2], [0, 3], [1, 2], [1, 3], [2, 3]]


def test_outside_is_beyond_the_encoder_range():
    case = {"encoder": "lots", "positions": [{"ruling": "lot"}, {"ruling": "lot; whoever wins"}, {"ruling": "divide"}]}
    assert sheaf.outside(case) == [1]
    flag = next(e for e, v in takhrij.ENCODERS.items() if v["out"] == takhrij.B)
    assert sheaf.outside({"encoder": flag, "positions": [{"ruling": True}, {"ruling": 1}, {"ruling": 0}]}) == [1, 2]
    # an outside position never equals the case's expected ruling
    assert all(takhrij.code(c["positions"][k]["ruling"]) != takhrij.code(c["expected"])
               for c in sheaf.ikhtilaf(CASES) for k in sheaf.outside(c))


def test_detail_is_not_part_of_a_ruling():
    case = {"positions": [{"ruling": "divide", "detail": "without oath"}, {"ruling": "divide"}, {"ruling": "lot"}]}
    assert sheaf.rulings(case) == [0, 0, 2]


def test_records_are_typed_by_the_types_layer():
    rep = sheaf.render(CASES, TYPES)
    assert all(r["sort"] == TYPES[r["encoder"]]["sort"] for r in rep["cases"])
    conflicts = sum(len(sheaf.within(r)) for r in rep["cases"] if r["sort"] == "judgement")
    assert rep["summary"]["conflicts_of_khitab"] == conflicts
    assert sum(rep["summary"]["records_within_reading_by_sort"].values()) == rep["summary"]["records_within_reading"]


def test_outputs_are_generated():
    assert json.loads((CORPUS / sheaf.OUTPUT).read_text(encoding="utf-8")) == sheaf.render(CASES, TYPES)
    lean = ROOT / "formal/lean/UsulTest" / sheaf.LEAN
    assert lean.read_text(encoding="utf-8") == sheaf.lean_file(CASES)
