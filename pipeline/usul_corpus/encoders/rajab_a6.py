"""Shard rajab-a6: readings of Ibn Rajab's qawāʿid 96, 98 and 99 (Usul.Readings.RajabA6)."""

from usul_corpus.takhrij import RAJAB, B

ENCODERS: dict[str, dict] = {
    "performed_without_leave_owned": dict(
        sadi=[], qawaid=[RAJAB.format(96)], facts={"wilaya": B, "distinct": B},
        out=B, lean="Usul.Readings.RajabA6.ownedDischarge {wilaya} {distinct}",
        py=lambda f: f["wilaya"] or f["distinct"]),
    "performed_without_leave_not_owned": dict(
        sadi=[], qawaid=[RAJAB.format(96)], facts={"recipient_determined": B},
        out=B, lean="Usul.Readings.RajabA6.unownedDischarge {recipient_determined}",
        py=lambda f: f["recipient_determined"]),
    "handover_by_description": dict(
        sadi=[], qawaid=[RAJAB.format(98)],
        facts={"described": B, "owner_unknown": B, "owner_hand": B},
        out=B, lean="Usul.Readings.RajabA6.byDescription {described} {owner_unknown} {owner_hand}",
        py=lambda f: f["described"] and f["owner_unknown"] and not f["owner_hand"]),
    "free_bestowal_of_needed_ayn": dict(
        sadi=[], qawaid=[RAJAB.format(99)], facts={"needed": B, "harmless": B},
        out=B, lean="Usul.Readings.RajabA6.freeAyn {needed} {harmless}",
        py=lambda f: f["needed"] and f["harmless"]),
    "free_bestowal_of_needed_benefit": dict(
        sadi=[], qawaid=[RAJAB.format(99)], facts={"needed": B},
        out=B, lean="Usul.Readings.RajabA6.freeBenefit {needed}",
        py=lambda f: f["needed"]),
}
