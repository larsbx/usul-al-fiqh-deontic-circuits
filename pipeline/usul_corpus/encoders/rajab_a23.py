"""Shard rajab-a23: readings of Ibn Rajab's qawāʿid 153 and 157 (Usul.Readings.RajabA23)."""

from usul_corpus.takhrij import RAJAB, B

_NS = "Usul.Readings.RajabA23"

ENCODERS: dict[str, dict] = {
    "grandchild_in_child_term": dict(
        sadi=[], qawaid=[RAJAB.format(153)],
        facts={"included_with_or_without_child": B, "included_only_absent_child": B,
               "intermediate_child_present": B},
        out=B,
        lean=(f"{_NS}.grandchildCountsAsChild {{included_with_or_without_child}} "
              "{included_only_absent_child} {intermediate_child_present}"),
        py=lambda f: f["included_with_or_without_child"]
        or (f["included_only_absent_child"] and not f["intermediate_child_present"])),
    "idda_transfer_on_change": dict(
        sadi=[], qawaid=[RAJAB.format(157)],
        facts={"idda_status_changes": B, "husband_can_remedy_in_idda": B, "sick_husband_ibana": B},
        out=B,
        lean=f"{_NS}.transfersToNewIdda {{idda_status_changes}} {{husband_can_remedy_in_idda}} {{sick_husband_ibana}}",
        py=lambda f: f["idda_status_changes"] and (f["husband_can_remedy_in_idda"] or f["sick_husband_ibana"])),
}
