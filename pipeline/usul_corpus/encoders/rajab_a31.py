"""Shard rajab-a31: readings of Ibn Rajab's qawāʿid 87 and 88 (Usul.Readings.RajabA31)."""

from usul_corpus.takhrij import RAJAB, B

_NS = "Usul.Readings.RajabA31"


def _transfer(f: dict) -> bool:
    k = f["holding"]
    if k == "tamm":
        return True
    if k == "manfaa":
        return f["lazim"] and not f["higher_than_title"]
    if k == "harmRight":
        return False
    return f["lazim"] and not f["for_iwad"]


def _road(f: dict) -> bool:
    if f["narrow_or_harmful"]:
        return False
    if f["layer"] == "air":
        return f["imam_leave"]
    return not f["permanent"] or (f["public_benefit"] and f["imam_leave"])


ENCODERS: dict[str, dict] = {
    "a31_rajab87_transfer_of_holding": dict(
        sadi=[], qawaid=[RAJAB.format(87)],
        facts={"holding": ("tamm", "manfaa", "harmRight", "ikhtisas"), "lazim": B,
               "higher_than_title": B, "for_iwad": B},
        out=B, lean=f"{_NS}.transferValid {{holding}} {{lazim}} {{higher_than_title}} {{for_iwad}}",
        py=_transfer),
    "a31_rajab88_road_use": dict(
        sadi=[], qawaid=[RAJAB.format(88)],
        facts={"layer": ("surface", "below", "air"), "narrow_or_harmful": B, "permanent": B,
               "public_benefit": B, "imam_leave": B},
        out=B, lean=(f"{_NS}.roadUseAllowed {{layer}} {{narrow_or_harmful}} {{permanent}} "
                     "{public_benefit} {imam_leave}"),
        py=_road),
}
