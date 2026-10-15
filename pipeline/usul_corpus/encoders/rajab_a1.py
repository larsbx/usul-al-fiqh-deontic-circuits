"""Shard rajab-a1: readings of Ibn Rajab's qawāʿid 60, 67, 69 and 71 (Usul.Readings.RajabA1)."""

from usul_corpus.takhrij import RAJAB, B

ENCODERS: dict[str, dict] = {
    "rescission_harm": dict(
        sadi=[], qawaid=[RAJAB.format(60)], facts={"harm": B, "remediable": B},
        out=("barred", "withRemedy", "free"),
        lean="Usul.Readings.RajabA1.rescission {harm} {remediable}",
        py=lambda f: "free" if not f["harm"] else "withRemedy" if f["remediable"] else "barred"),
    "recourse_after_return": dict(
        sadi=[], qawaid=[RAJAB.format(67)], facts={"returned_by_gift": B},
        out=B, lean="Usul.Readings.RajabA1.recourseAfterReturn {returned_by_gift}",
        py=lambda f: f["returned_by_gift"]),
    "delegating_work": dict(
        sadi=[], qawaid=[RAJAB.format(69)],
        facts={"binding": B, "personal_required": B, "permission_indicated": B},
        out=B,
        lean="Usul.Readings.RajabA1.mayDelegate {binding} {personal_required} {permission_indicated}",
        py=lambda f: (not f["personal_required"]) if f["binding"] else f["permission_indicated"]),
    "eating_without_permission": dict(
        sadi=[], qawaid=[RAJAB.format(71)],
        facts={"necessity": B, "ward_wilaya": B, "compensated_otherwise": B, "unguarded_craved": B},
        out=B,
        lean="Usul.Readings.RajabA1.mayEat {necessity} {ward_wilaya} {compensated_otherwise} {unguarded_craved}",
        py=lambda f: f["necessity"] or (f["ward_wilaya"] and not f["compensated_otherwise"]) or f["unguarded_craved"]),
}
