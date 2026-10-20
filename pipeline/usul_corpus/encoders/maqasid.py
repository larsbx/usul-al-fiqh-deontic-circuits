"""Shard: the maqāṣid al-sharīʿa (formal/lean/Usul/Readings/Maqasid.lean).

Two new encoders, read from the Rawḍa, al-Mustaṣfā, al-Muwāfaqāt and Sharḥ al-Kawkab al-Munīr:
`istislah` answers whether a maṣlaḥa is a proof, `maqasid_tarjih` which of two conflicting maṣāliḥ
is put first. Each pins its policy point as a fact (`istislah_stance`, `din_reading`), never a choice.
"""

from usul_corpus.takhrij import B

KULLI = ("din", "nafs", "aql", "nasl", "mal", "ird")
MAQSAD = KULLI + ("mukammil", "haji", "tahsini")
TIER = {**dict.fromkeys(KULLI, 3), "mukammil": 2, "haji": 1, "tahsini": 0}
RANK = {"din": 4, "nafs": 3, "aql": 2, "nasl": 1, "mal": 0, "ird": 0}


def _key(m: str, reading: str) -> tuple[int, int]:
    if m not in KULLI:
        return TIER[m], 0
    return 3, RANK[m] if reading == "kawkab" else 0 if m == "din" else RANK[m] + 1


def _taqdim(f: dict) -> str:
    a, b = _key(f["maqsad_first"], f["din_reading"]), _key(f["maqsad_second"], f["din_reading"])
    return "first" if a > b else "second" if a < b else "tawaqquf"


def _hujja(f: dict) -> bool:
    if f["maslaha_shahada"] != "irsal":
        return f["maslaha_shahada"] == "itibar"
    if f["maslaha_rutba"] != "daruri":
        return False
    return {"rawda": False, "malik": True}.get(f["istislah_stance"], f["maslaha_qatiyya"] and f["maslaha_kulliyya"])


ENCODERS = {
    "istislah": dict(
        sadi=[], qawaid=[],
        facts={"maslaha_shahada": ("itibar", "ilgha", "irsal"), "maslaha_rutba": ("daruri", "haji", "tahsini"),
               "maslaha_qatiyya": B, "maslaha_kulliyya": B, "istislah_stance": ("rawda", "mustasfa", "malik")},
        out=B,
        lean="Usul.Readings.Maqasid.hujja {istislah_stance} ⟨{maslaha_shahada}, {maslaha_rutba}, {maslaha_qatiyya}, {maslaha_kulliyya}⟩",
        py=_hujja),
    "maqasid_tarjih": dict(
        sadi=[], qawaid=[],
        facts={"maqsad_first": MAQSAD, "maqsad_second": MAQSAD, "din_reading": ("kawkab", "qila")},
        out=("first", "second", "tawaqquf"),
        lean="Usul.Readings.Maqasid.taqdim {din_reading} {maqsad_first} {maqsad_second}",
        py=_taqdim),
}
