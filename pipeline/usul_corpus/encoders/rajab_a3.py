"""Shard rajab-a3: Ibn Rajab's qawāʿid 53 and 78 (Usul.Readings.RajabA3)."""

from usul_corpus.takhrij import RAJAB, B

ENCODERS = {
    "attached_right_disposal": dict(
        sadi=[], qawaid=[RAJAB.format(53)], facts={"demanded": B, "fixed_in_ayn": B},
        out=B, lean="Usul.Readings.RajabA3.disposalStands {demanded} {fixed_in_ayn}",
        py=lambda f: not (f["demanded"] and f["fixed_in_ayn"])),
    "rescue_loss_liability": dict(
        sadi=[], qawaid=[RAJAB.format(78)],
        facts={"causes_loss": B, "sufferer_negligent": B, "emptying_permitted": B},
        out=B, lean="Usul.Readings.RajabA3.lossLiable {causes_loss} {sufferer_negligent} {emptying_permitted}",
        py=lambda f: f["causes_loss"] and not f["sufferer_negligent"] and not f["emptying_permitted"]),
}
