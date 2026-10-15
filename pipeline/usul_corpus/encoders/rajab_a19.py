"""Shard rajab-a19: readings of Ibn Rajab's qawāʿid 142, 143 and 145 (Usul.Readings.RajabA19)."""

from usul_corpus.takhrij import RAJAB, B

_NS = "Usul.Readings.RajabA19"

ENCODERS: dict[str, dict] = {
    "returned_takes_first_ruling": dict(
        sadi=[], qawaid=[RAJAB.format(142)], facts={"restored_by_life": B, "old_materials": B},
        out=B, lean=f"{_NS}.returnedIsFirst {{restored_by_life}} {{old_materials}}",
        py=lambda f: f["restored_by_life"]),
    "badal_stands_for_original": dict(
        sadi=[], qawaid=[RAJAB.format(143)], facts={"sold_for_price": B},
        out=B, lean=f"{_NS}.badalStands {{sold_for_price}}",
        py=lambda f: not f["sold_for_price"]),
    "bain_in_idda_as_wife": dict(
        sadi=[], qawaid=[RAJAB.format(145)], facts={"in_idda": B, "ties_cut": B},
        out=B, lean=f"{_NS}.bainAsWife {{in_idda}} {{ties_cut}}",
        py=lambda f: f["in_idda"] and not f["ties_cut"]),
}
