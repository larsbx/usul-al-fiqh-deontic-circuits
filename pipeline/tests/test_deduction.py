"""Deduction to the qāʿida (Usul.Cat.Deduction): the verdicts a partial situation can reach under each
encoder, computed exhaustively over its fact domains, and the Lean theorems' instances replayed."""

from pathlib import Path

from usul_corpus import deduction, takhrij

ROOT = Path(__file__).resolve().parents[2]
READS = deduction.reads((ROOT / "examples/v41_types.pl").read_text(encoding="utf-8"))
IDHN = "a26_refused_idhn_lapses"


def test_every_encoder_reads_one_field_per_fact():
    assert set(READS) == set(takhrij.ENCODERS)
    assert all(len(READS[e]) == len(enc["facts"]) for e, enc in takhrij.ENCODERS.items())


def test_a_permitted_refusal_excludes_the_lapse():  # idhn_permitted_refusal_excludes_lapse
    assert deduction.reach(IDHN, {"refusal_forbidden": False}, READS[IDHN]) == {False}


def test_a_forbidden_refusal_alone_reaches_both():  # idhn_forbidden_refusal_reaches_both
    assert deduction.reach(IDHN, {"refusal_forbidden": True}, READS[IDHN]) == {False, True}


def test_a_fully_settled_situation_reaches_its_own_verdict():  # pair_total
    for r in (False, True):
        for m in (False, True):
            got = deduction.reach(IDHN, {"refusal_forbidden": r, "mere_permission": m}, READS[IDHN])
            assert got == {takhrij.ENCODERS[IDHN]["py"]({"refusal_forbidden": r, "mere_permission": m})}


def test_reach_is_antitone_and_a_value_outside_the_domain_reaches_nothing():
    e = "a31_rajab88_road_use"
    coarse = deduction.reach(e, {"narrow_or_harmful": False}, READS[e])
    # with the layer open, the air (where leave alone decides) keeps «allowed» in reach
    assert deduction.reach(e, {"narrow_or_harmful": False, "permanent_use": True, "public_benefit": False}, READS[e]) == {False, True}
    fine = deduction.reach(e, {"road_layer": "surface", "narrow_or_harmful": False, "permanent_use": True,
                               "public_benefit": False}, READS[e])
    assert fine <= coarse and fine == {False}  # private_permanent_barred
    assert deduction.reach(e, {"road_layer": "roof"}, READS[e]) == set()


def test_every_annotated_derivation_is_reachable_from_each_restriction():  # sound
    for c in takhrij.load(ROOT / "corpus"):
        if c["class"] != "derivable" or c["encoder"] not in READS:
            continue
        read, names = READS[c["encoder"]], deduction.names(c["encoder"])
        facts = {f: c["facts"][n] for f, n in zip(read, names) if n in c["facts"]}
        for drop in facts:
            assert c["expected"] in deduction.reach(c["encoder"], {k: v for k, v in facts.items() if k != drop}, read)
