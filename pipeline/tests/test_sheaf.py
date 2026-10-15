"""M10: every genuine ikhtilāf is a sheaf obstruction, and the Lean guards mirror the records."""

import json
from pathlib import Path

from usul_corpus import sheaf, takhrij

ROOT = Path(__file__).resolve().parents[2]
CORPUS = ROOT / "corpus"
CASES = takhrij.load(CORPUS)


def test_every_ikhtilaf_is_obstructed():
    rep = sheaf.render(CASES)
    assert rep["summary"]["cases"] == sum(c["class"] == "genuine_ikhtilaf" for c in CASES)
    assert all(r["obstructions"] for r in rep["cases"]), [r["far"] for r in rep["cases"] if not r["obstructions"]]


def test_records_are_the_disagreeing_pairs():
    case = {"positions": [{"ruling": True}, {"ruling": True}, {"ruling": "x"}, {"ruling": False}]}
    assert sheaf.rulings(case) == [0, 0, 2, 3]
    assert sheaf.obstructions(case) == [[0, 2], [0, 3], [1, 2], [1, 3], [2, 3]]


def test_outside_is_beyond_the_encoder_range():
    for c in sheaf.ikhtilaf(CASES):
        out = takhrij.ENCODERS[c["encoder"]]["out"]
        assert sheaf.outside(c) == [k for k, p in enumerate(c["positions"]) if p["ruling"] not in out]
    # an outside position never equals the case's expected ruling
    assert all(c["positions"][k]["ruling"] != c["expected"] for c in sheaf.ikhtilaf(CASES)
               for k in sheaf.outside(c) if c["expected"] in takhrij.ENCODERS[c["encoder"]]["out"])


def test_outputs_are_generated():
    assert json.loads((CORPUS / sheaf.OUTPUT).read_text(encoding="utf-8")) == sheaf.render(CASES)
    lean = ROOT / "formal/lean/UsulTest" / sheaf.LEAN
    assert lean.read_text(encoding="utf-8") == sheaf.lean_file(CASES)
