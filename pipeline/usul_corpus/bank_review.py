"""Automated review of candidate fatwā labels by the deontic-circuits bank.

Each ruling cue is read as an input to a kernel function, and denotes the *set*
of statuses (``Usul.Hukm``) the bank allows for it:

- explicit status («حرام», «مستحب», …)   amrStatus (some h) = h       (the indication decides)
- prohibition form («لا يجوز», «لا يحل») nahyStatus none = σ (amrStatus none)
- obligation label («يجب», «فرض عين»)    CommandSchemata.obligationStatus r e none, over both readings
- jawāz («يجوز», «لا حرج», «حلال»)       {h | ¬(mode h = ṭalab al-tark ∧ binding h)}  (raf' al-ḥaraj)
- negated status («لا يجب», «ليس بحرام») {h | h ≠ s}
- a ruling on the omission («ترك X حرام», «لا يجوز تركه»): σ applied to the set

Cues in one clause are intersected; an exception («إلا إذا», «لكن») opens a new
clause. The result classifies the candidate the way takhrīj classifies a farʿ.
The Python mirrors are guarded against Lean in ``UsulTest/FatawaBank.lean``.
"""

from __future__ import annotations

import re
from collections.abc import Mapping
from functools import reduce

from .labels import HUKM, cues, normalize_ar
from .takhrij import ENCODERS

ALL = frozenset(HUKM)
# Mirrors of Usul.Hukm (formal/lean/Usul/Hukm.lean), guarded exhaustively.
SIGMA = {"wajib": "haram", "mandub": "makruh", "mubah": "mubah", "makruh": "mandub", "haram": "wajib"}
MODE = {"wajib": "talabFil", "mandub": "talabFil", "mubah": "takhyir", "makruh": "talabTark", "haram": "talabTark"}
BINDING = {"wajib": True, "mandub": False, "mubah": False, "makruh": False, "haram": True}
JAWAZ = frozenset(h for h in HUKM if not (MODE[h] == "talabTark" and BINDING[h]))

_amr = ENCODERS["amr"]["py"]
_obligation = ENCODERS["command_obligation_status"]["py"]
_READINGS = ENCODERS["command_obligation_status"]["facts"]["reading"]
_L = r"ء-ي"
_JAWAZ_CUE = re.compile(r"^(?:لا\s+(?:حرج|باس|مانع)|[يت]جوز|جائز|حلال|[يت]باح)")
_PROHIBITION = re.compile(r"^(?:لا|لم|لن)\s")
_FARD = re.compile(r"^فرض\s")
_TARK = re.compile(rf"^[وف]?(?:ال)?ترك(?:ه|ها|هم|هما|ك|كم)?$")
_CLAUSE = re.compile(rf"[.؟!?\n؛]+|(?=(?<![{_L}])[وف]?(?:الا\s+اذا|الا\s+ان|لكن|اما\s+اذا))")


def _ordered(s) -> list[str]:
    return [h for h in HUKM if h in s]


def _reading(c: Mapping) -> tuple[str, frozenset]:
    """(kernel reading, denoted status set) for one cue, before omission."""
    h, t = c["hukm"], c["text"]
    if c["polarity"] == "-":
        return f"≠ {h}", ALL - {h}
    if h == "wajib":
        e = "fardLabel" if _FARD.match(t) else "wujubLabel"
        return (f"CommandSchemata.obligationStatus _ .{e} none",
                frozenset(_obligation({"reading": r, "expression": e, "qarina": "none"}) for r in _READINGS))
    if h == "haram" and _PROHIBITION.match(t):
        return "Dalala.nahyStatus none", frozenset({SIGMA[_amr({"qarina": "none"})]})
    if h == "mubah" and _JAWAZ_CUE.match(t):
        return "jawāz: ¬(mode = talabTark ∧ binding)", JAWAZ
    return f"Dalala.amrStatus (some .{h})", frozenset({_amr({"qarina": h})})


def _omission(clause: str, c: Mapping) -> bool:
    """The status is predicated of an omission: «ترك X حرام» or «لا يجوز تركه», not «ترك واجب»."""
    before = clause[:c["start"]].split()[-3:]
    after = clause[c["end"]:].split()[:1]
    return any(_TARK.match(w) for w in before[:-1]) or bool(after and _TARK.match(after[0]))


def bank_clauses(text: str) -> list[dict]:
    out = []
    for clause in filter(str.strip, _CLAUSE.split(normalize_ar(text))):
        read = []
        for c in cues(clause):
            how, s = _reading(c)
            if _omission(clause, c):
                how, s = f"σ ∘ {how}", frozenset(SIGMA[h] for h in s)
            read.append({"cue": c["text"], "reading": how, "set": s})
        out.append({"text": clause.strip(), "cues": read})
    return out


def _priority(cls: str, h: str | None, en: str | None) -> str:
    """Human-review order. The bank checks how the clause's statuses combine, not which act
    they are about, so a confirmation is never a gold label (docs/architecture/fatawa-labels.md)."""
    if cls in ("conflict", "rejected", "no_reading") or (en and en != h):
        return "high"
    return "low" if cls == "confirmed" and en == h else "medium"


def review(label: Mapping, en: str | None = None) -> dict:
    """Bank verdict on one candidate label; ``en`` is the English version's vote, if any."""
    h, ev = label["hukm"], label.get("evidence")
    out = {"class": "no_reading", "set": [], "steps": [], "en": en, "priority": "high"}
    if not (h and ev):
        return out
    clauses = [c for c in bank_clauses(ev["passage"]) if c["cues"]]
    cue = normalize_ar(ev["cue"])
    clause = next((c for c in clauses if any(x["cue"] == cue for x in c["cues"])), clauses[0] if clauses else None)
    if clause is None:
        return out
    s = reduce(frozenset.__and__, (x["set"] for x in clause["cues"]))
    cls = ("conflict" if not s else "rejected" if h not in s else "confirmed" if s == {h} else "consistent")
    return out | {"class": cls, "set": _ordered(s), "clause": clause["text"][:300],
                  "steps": [{"cue": x["cue"], "reading": x["reading"], "set": _ordered(x["set"])} for x in clause["cues"]],
                  "priority": _priority(cls, h, en)}


def lean_guards() -> str:
    """Exhaustive Lean guards for the Python mirrors above."""
    b = lambda v: "true" if v else "false"  # noqa: E731
    lines = ["-- GENERATED by `python -m usul_corpus bank-review`. Do not edit.",
             "-- The fatwā reviewer's mirrors of Usul.Hukm and Usul.Dalala equal the Lean definitions.",
             "import Usul", ""]
    for h in HUKM:
        lines += [f"#guard (Usul.Hukm.σ .{h}) == .{SIGMA[h]}",
                  f"#guard (Usul.Hukm.mode .{h}) == .{MODE[h]}",
                  f"#guard (Usul.Hukm.binding .{h}) == {b(BINDING[h])}",
                  f"#guard (!(Usul.Hukm.mode .{h} == .talabTark && Usul.Hukm.binding .{h})) == {b(h in JAWAZ)}"]
    lines += ['#guard (Usul.Dalala.amrStatus none) == .wajib', '#guard (Usul.Dalala.nahyStatus none) == .haram']
    return "\n".join(lines) + "\n"


# An independent vote from the English version of the same answer (not a bank reading).
_EN = (("haram", r"not permissible|impermissible|haraam|haram|forbidden|prohibited|not allowed"),
       ("wajib", r"obligatory|must|waajib|wajib|compulsory|required to"),
       ("mandub", r"mustahabb|recommended|sunnah to|it is sunnah"),
       ("makruh", r"makrooh|makruh|disliked"),
       ("mubah", r"no problem|no harm|permissible|allowed|halaal|halal|nothing wrong"))
_EN_RX = [(h, re.compile(rf"\b(?:{p})\b")) for h, p in _EN]


def en_vote(text: str | None, window: int = 600) -> str | None:
    """Status of the earliest English ruling cue in the opening of the answer."""
    t = (text or "").lower()[:window]
    hits = [(m.start(), -len(m.group()), h) for h, rx in _EN_RX for m in rx.finditer(t)]
    return min(hits)[2] if hits else None
