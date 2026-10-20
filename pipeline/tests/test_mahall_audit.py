"""PR-51: the maḥall layer's accuracy, by blind re-annotation and anchor review."""

import json
from pathlib import Path

from usul_corpus import mahall_audit as audit

ROOT = Path(__file__).resolve().parents[2]
CORPUS = ROOT / "corpus"


def test_the_audit_samples_are_the_fixed_hash_lowest_ids():
    for a in ("x", "y"):
        assert sorted(json.loads((CORPUS / audit.DIR / f"identify_{a}.json").read_text(encoding="utf-8"))) == \
            audit.sample_cases(CORPUS)
    # The anchor sample was drawn before four labels were merged into others, so it is checked as a
    # set of pairs that still exist (read through the aliases), not redrawn.
    alias = audit.aliases(CORPUS)
    live = {"|".join((l["id"], n["ref"], n["excerpt_ar"])) for l in audit.mahall.load(CORPUS)[1] for n in l.get("nass", [])}
    for r in ("r", "s"):
        rows = json.loads((CORPUS / audit.DIR / f"anchors_{r}.json").read_text(encoding="utf-8"))
        keys = {"|".join((alias.get(x["label"], x["label"]), x["ref"], x["excerpt_ar"])) for x in rows}
        assert len(keys) == audit.N and keys <= live
        assert all(x["verdict"] in audit.VERDICTS for x in rows)


def test_aliases_point_at_live_labels():
    live = {l["id"] for l in audit.mahall.load(CORPUS)[1]}
    alias = audit.aliases(CORPUS)
    assert all(new in live and old not in live for old, new in alias.items())


def test_kappa():
    assert audit.kappa(["a", "b"], ["a", "b"]) == 1
    assert audit.kappa(["a", "a", "b", "b"], ["a", "b", "a", "b"]) == 0


def test_the_identification_figures():
    r = audit.identification(CORPUS)
    assert {k: (v["exact"], v["related"], v["any_related"], v["same_bab"]) for k, v in r.items()} == {
        "x": (103, 107, 117, 112), "y": (100, 104, 116, 109), "x~y": (113, 114, 117, 115)}


def test_the_anchor_figures():
    r = audit.anchors(CORPUS)
    assert (r["r"]["names"], r["s"]["names"], r["kappa"], r["either_unrelated"]) == (106, 107, 0.875, 0)
