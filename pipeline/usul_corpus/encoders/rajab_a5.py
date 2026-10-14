"""Shard rajab-a5: readings of Ibn Rajab's qawāʿid 94, 95 and 97 (Usul.Readings.RajabA5)."""

from usul_corpus.takhrij import RAJAB, B

_NS = "Usul.Readings.RajabA5"

ENCODERS: dict[str, dict] = {
    "second_receiver_liable": dict(
        sadi=[], qawaid=[RAJAB.format(94)], facts={"handover_permitted": B, "first_trustee": B},
        out=B, lean=f"{_NS}.secondReceiverLiable {{handover_permitted}} {{first_trustee}}",
        py=lambda f: not f["handover_permitted"] or not f["first_trustee"]),
    "error_actor_liable": dict(
        sadi=[], qawaid=[RAJAB.format(95)],
        facts={"external_cause": B, "basis_void": B, "ruling_overturned": B, "as_owner": B, "negligent": B},
        out=B,
        lean=f"{_NS}.errorActorLiable {{external_cause}} {{basis_void}} {{ruling_overturned}} {{as_owner}} {{negligent}}",
        py=lambda f: False if f["external_cause"] else (
            f["ruling_overturned"] if f["basis_void"] else (f["as_owner"] or f["negligent"]))),
    "dispose_without_judge": dict(
        sadi=[], qawaid=[RAJAB.format(97)], facts={"owner_known": B, "trivial": B, "despaired": B},
        out=B, lean=f"{_NS}.disposeWithoutJudge {{owner_known}} {{trivial}} {{despaired}}",
        py=lambda f: not f["owner_known"] or f["trivial"] or f["despaired"]),
}
