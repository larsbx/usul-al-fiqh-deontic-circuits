"""Automated review of candidate fatwā labels by the deontic-circuits bank.

Each ruling cue is read as an input to a kernel function, and denotes the *set*
of statuses (``Usul.Hukm``) the bank allows for it:

- explicit status («حرام», «مستحب», …)   amrStatus (some h) = h       (the indication decides)
- prohibition form («لا يجوز», «لا يحل») nahyStatus none = σ (amrStatus none)
- obligation label («يجب», «فرض عين»)    CommandSchemata.obligationStatus r e none, over both readings
- jawāz («يجوز», «لا حرج», «حلال»)       {h | ¬(mode h = ṭalab al-tark ∧ binding h)}  (raf' al-ḥaraj)
- negated status («لا يجب», «ليس بحرام») {h | h ≠ s}

A clause's predications are intersected. When they clash, the clash goes through
the rounds of ``docs/architecture/fatawa-labels.md#conflicts``:

R1 reading   only predications on the act take part: not a cue inside another's
             complement, a relative or reason clause (subordinate), after a
             preposition or inside a proof-text (mention), or مَحْرَم (kinship)
R2 jamʿ (σ)  a ruling on the act's opposite («التهاون», «الكف عن», «أن يتركها»)
             is read through σ: H(ḍidd a) = σ(H a) (Dalala.amr_nahy_didd_of)
R3 jamʿ      «بل / وإنما / ومنه ما» and «،» open a new predication scope
R4 tarjīḥ    Usul.resolve ⟨none, none, some p⟩ when the text prefers p
             («والصواب …»); otherwise tawaqquf
R5 act       a ruling is compared only with rulings on the same act and
             addressee (acts.py); on the opposite act by meaning («يعدل» /
             «تفضيل») it is read through σ

The Python mirrors are guarded against Lean in ``UsulTest/FatawaBank.lean``.
"""

from __future__ import annotations

import re
from collections.abc import Mapping
from functools import reduce

from .acts import act_of, antonyms
from .labels import HUKM, cues, normalize_ar
from .takhrij import ENCODERS

ALL = frozenset(HUKM)
STAGES = frozenset({"roles", "didd", "scope", "tarjih", "act"})
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
_TARK = re.compile(r"^[وف]?(?:ال)?ترك(?:ه|ها|هم|هما|ك|كم)?$")
_OPPOSITE = re.compile(r"^[وف]?(?:(?:ال)?(?:ترك|تهاون|كف|امتناع|اخلال|تفريط|تقصير|كتمان|اقلاع|حذر|اجتناب|تجنب|ابتعاد)(?:ه|ها|هم)?"
                       r"|[يت]ترك(?:ه|ها|هم|ون|ان)?)$")
_COMPLEMENT_SKIP = {"ان", "له", "لها", "لهم", "عليه", "عليها", "عليهم", "للمسلم", "للانسان", "للمراة", "للمرء", "لك", "لكم"}
_SENTENCE = (rf"[.؟!?\n؛]+|(?=(?<![{_L}])(?:[وف]?(?:الا\s+اذا|الا\s+ان|لكن|اما\s+اذا)|والا(?![{_L}])"
             rf"|[وف](?:ان|اذا)(?![{_L}])))")
_SCOPE = (rf"[،,]+|:(?!\s*[\"«(])|(?=(?<![{_L}])(?:بل|وانما|[وف]منه\s+ما|[وف]منها\s+ما|[وف]?اما|ما\s+عدا|سوى)(?![{_L}]))")
_RELATIVE = {"الذي", "التي", "الذين", "اللاتي", "اللذين", "مما", "لما", "لمن", "ممن", "ان", "ما", "من"}
_REASON = {"لان", "لانه", "لانها", "لانهم", "لكون"}
_PREPOSITION = {"على", "في", "عن", "الى", "مع", "بدون", "بلا", "كل", "اي", "بعض", "من"}
_KIN_BEFORE = {"ذو", "ذي", "بدون", "بلا", "مع"}
_NOT_KIN = {"لم", "لن", "لا", "لما", "لكن", "لكنه", "لان", "لانه", "لانها", "لذاته", "لعينه", "لغيره", "لذلك", "لهذا"}
_HEADS = {"هو", "هي", "هم", "هذا", "هذه", "ذلك", "تلك", "هؤلاء", "انه", "انها", "انهم", "كان", "يكون", "تكون", "صار", "اصبح"}
_NOMINAL = re.compile(r"^(?:حرام|محرم|واجب|مستحب|مسنون|مندوب|مكروه|جائز|مباح|حلال)")
_VERBAL = re.compile(r"^(?:[يت]|لا\s|لم\s|لن\s|وجب)")
_TARJIH_BACK = re.compile(rf"(?<![{_L}])[وف]?(?:هو|هذا|هي)\s+(?:ال)?(?:صحيح|صواب|راجح|اظهر|اقرب)(?![{_L}])")
_RELATIVE_2 = {"الذي", "التي", "الذين", "اللاتي", "ما", "من", "مما", "لمن"}
_REPORTED = {"بان", "بانه", "بانها"}
_QUESTION_WORDS = {"هل", "متى", "ام"}
_FRAME_OBJECT = re.compile(r"^[نتي](?:علم|عرف|نبه|بين)")
_IHRAM = re.compile(rf"(?<![{_L}])(?:بالحج|بالعمرة|بحج|بعمرة|احرام|الاحرام)(?![{_L}])")
_PROOF = re.compile(r"(?:تعالى|وسلم|عنه|عنها|عنهما)\s*:?\s*[\"«]")
_VERB_TOKEN = re.compile(rf"^[وف]?[يت][{_L}]{{2,}}$")
_TARJIH = re.compile(rf"(?<![{_L}])(?:[وف](?:ال)?(?:صواب|صحيح|راجح|اظهر|اقرب|مختار)|(?:ال)?(?:صحيح|راجح)\s+من\s+(?:اقوال|قولي))(?![{_L}])")
_REPORT = re.compile(rf"(?<![{_L}])[وف]?(?:ذهب|قال\s+بعض|عند\s+(?:الجمهور|بعض|الحنفية|المالكية|الشافعية|الحنابلة)|عندهم"
                     rf"|في\s+قول|قيل|يرى|اختلف|اختلاف)(?![{_L}])")


def _ordered(s) -> list[str]:
    return [h for h in HUKM if h in s]


def resolve(jam: str | None, naskh: str | None, tarjih: str | None) -> tuple[str, str | None]:
    """Mirror of Usul.resolve (Taarud.lean): jamʿ ≻ naskh ≻ tarjīḥ ≻ tawaqquf."""
    return next(((stage, p) for stage, p in (("jam", jam), ("naskh", naskh), ("tarjih", tarjih)) if p), ("tawaqquf", None))


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


def _bare(w: str) -> str:
    """A token without an attached و/ف."""
    return w[1:] if len(w) > 2 and w[0] in "وف" else w


def _definite(w: str) -> bool:
    return w.startswith(("ال", "لل")) or (len(w) > 3 and w[0] in "بكل" and w[1:].startswith("ال"))


def _role(scope: str, c: Mapping) -> str:
    """R1/R5/R6: is this cue a predication on the act, or something else?"""
    prefix = scope[:c["start"]]
    before, after = prefix.split(), scope[c["end"]:].split()
    if before and before[-1] in ("و", "ف"):
        before = before[:-1]                                  # «ومحرم»: the conjunction is not a word before it
    prev = [_bare(w) for w in before[-2:]]
    t = c["text"]
    nominal = bool(_NOMINAL.match(t))
    if "محرم" in t and "محرمة" not in t:
        if _IHRAM.search(scope):
            return "ihram"                                    # مُحْرِم, in iḥrām
        if (after and after[0].startswith("ل") and after[0] not in _NOT_KIN) or prev[-1:] and prev[-1] in _KIN_BEFORE:
            return "kinship"                                  # مَحْرَم
    if prev[-1:] == ["قد"]:
        return "modal"
    nxt = " ".join(after[:3])
    if re.search(r"(?<![\u0621-\u064A])في\s+شريعة", nxt) or ("في حقه" in nxt and "شرعنا" in scope and "شرعنا" not in nxt):
        return "prior_law"                                    # sharʿ man qablanā: reported, not our ruling
    if prev[-1:] and prev[-1] in _QUESTION_WORDS:
        return "question"
    if (("يجب" in t or "تجب" in t) and after[:1] == ["ان"] and len(after) > 1 and _FRAME_OBJECT.match(after[1])) or (
            "لزم" in t and after[:1] and after[0].startswith("من")):
        return "frame"                                        # «يجب أن تعلم أن …», «لا يلزم منه» (entailment)
    m = max((prefix.rfind(k.group()) for k in _PROOF.finditer(prefix)), default=-1)
    if prefix.count("(") > prefix.count(")") or (m >= 0 and prefix[m:].count('"') % 2 == 1) or (nominal and _PREPOSITION & set(prev)):
        return "mention"
    if (prev[-1:] and prev[-1] in _RELATIVE | _REPORTED) or (len(prev) > 1 and prev[0] in _RELATIVE_2) or _REASON & {_bare(w) for w in before}:
        return "subordinate"
    if nominal and prev:
        head = prev[-1]
        governed = len(before) == 1 or len(prev) > 1 and (_definite(prev[0]) or prev[0] in _HEADS)
        if not _definite(head) and head not in _HEADS and not governed:
            return "mention"                                  # attributive: «بتجارة مباحة», «شروط شرعية مباحة»
    return "predication"


def _omission(scope: str, c: Mapping, didd: bool, since: int = 0, until: int | None = None) -> bool:
    """«ترك X حرام» (predicated of the omission, after the previous cue); with R2 also the cue's
    object: «لا يجوز التهاون», «لا يحل له أن يتركها», «يجب الحذر من …» — up to another verb."""
    before = scope[since:c["start"]].split()[-3:]
    after = scope[c["end"]:until].split()
    if any(_TARK.match(w) for w in before[:-1]):
        return True
    if not didd:
        return bool(after and _TARK.match(after[0]))
    for w in after[:6]:
        if _bare(w) in _RELATIVE - {"ان"}:
            return False                                     # «يجب على من تركها»: the omission describes the subject
        if _OPPOSITE.match(w):
            return True
        if _VERB_TOKEN.match(w):
            return False                                     # «أن يحلف على ترك …»: ترك belongs to another verb
    return False


def _coordinated(scope: str) -> list[str]:
    """R5: a verbal ruling joined by «و» to an earlier one rules on its own act («الغصب محرم ويجب رده»)."""
    found = cues(scope)
    cuts = [c["start"] - 1 for c in found[1:]
            if c["start"] > 1 and scope[c["start"] - 1] == "و" and scope[c["start"] - 2] == " " and _VERBAL.match(c["text"])]
    return [scope[a:b] for a, b in zip([0, *cuts], [*cuts, len(scope)])]


def _disjoin(scope: str, read: list[dict]) -> list[dict]:
    """R5: «مكروه أو محرم» leaves both open: the union."""
    out: list[dict] = []
    for x in read:
        if out and re.fullmatch(r"(?:\S+\s+)?(?:او|ام)", scope[out[-1]["end"]:x["start"]].strip()):
            y = out.pop()
            x = y | {"cue": f"{y['cue']} او {x['cue']}", "reading": "∪ (او)", "set": y["set"] | x["set"], "end": x["end"]}
        out.append(x)
    return out


def bank_clauses(text: str, stages: frozenset = STAGES) -> list[dict]:
    out = []
    for sentence in filter(str.strip, re.split(_SENTENCE, normalize_ar(text))):
        scopes = re.split(_SCOPE, sentence) if "scope" in stages else [sentence]
        for scope in filter(str.strip, [p for s in scopes for p in (_coordinated(s) if "scope" in stages else [s])]):
            read, since, found = [], 0, cues(scope)
            for c, nxt in zip(found, [*found[1:], None]):
                how, s = _reading(c)
                literal, sigma = s, _omission(scope, c, "didd" in stages, since, nxt and nxt["start"])
                if sigma:
                    how, s = f"σ ∘ {how}", frozenset(SIGMA[h] for h in s)
                read.append({"cue": c["text"], "reading": how, "set": s, "literal": literal, "sigma": sigma,
                             "act": act_of(scope, c, nxt and nxt["start"]),
                             "start": c["start"], "end": c["end"],
                             "role": _role(scope, c) if "roles" in stages else "predication"})
                since = c["end"]
            read = _disjoin(scope, read) if "scope" in stages else read
            out.append({"text": scope.strip(), "cues": [{k: v for k, v in x.items() if k not in ("start", "end")} for x in read]})
    return out


def _preferred(clauses: list[dict]) -> str | None:
    """The status the text itself prefers: forward («والصواب أنها مستحبة») or backward
    («… أنها فرض كفاية وهو الصحيح»), if it names exactly one."""
    for cl in clauses:
        m = _TARJIH_BACK.search(cl["text"])
        if m:
            preds = [x for x in cl["cues"] if x["role"] == "predication" and len(x["set"]) == 1
                     and -1 < cl["text"].rfind(x["cue"].split(" او ")[0]) < m.start()]
            if preds:
                return next(iter(preds[-1]["set"]))
    for i, cl in enumerate(clauses):
        if _TARJIH.search(cl["text"]):
            for nxt in clauses[i:i + 2]:
                preds = [x for x in nxt["cues"] if x["role"] == "predication" and len(x["set"]) == 1]
                if preds:
                    return next(iter(preds[0]["set"]))
    return None


def _comparable(own: Mapping, read: list[dict], by_act: bool) -> list[frozenset]:
    """R5: the status sets that constrain the label's act: same act and addressee as is,
    the opposite act through σ, other acts not at all."""
    out = []
    for x in read:
        if x is own or x["role"] != "predication":
            continue
        if by_act:
            a, b = own["act"], x["act"]
            if a["addressee"] and b["addressee"] and a["addressee"] != b["addressee"]:
                continue
            if a["stems"] and b["stems"] and not set(a["stems"]) & set(b["stems"]):
                if not antonyms(a["stems"], b["stems"]):
                    continue
                out.append(frozenset(SIGMA[h] for h in x["set"]))
                continue
        out.append(x["set"])
    return out


def _priority(cls: str, h: str | None, en: str | None) -> str:
    """Human-review order. The bank checks how the clause's statuses combine, not which act
    they are about, so a confirmation is never a gold label (docs/architecture/fatawa-labels.md)."""
    if cls in ("conflict", "ikhtilaf", "rejected", "no_reading", "misread") or (en and en != h):
        return "high"
    return "low" if cls == "confirmed" and en == h else "medium"


def review(label: Mapping, en: str | None = None, stages: frozenset = STAGES) -> dict:
    """Bank verdict on one candidate label; ``en`` is the English version's vote, if any."""
    h, ev = label["hukm"], label.get("evidence")
    out = {"class": "no_reading", "set": [], "steps": [], "en": en, "resolution": None, "act": None, "priority": "high"}
    if not (h and ev):
        return out
    clauses = [c for c in bank_clauses(ev["passage"], stages) if c["cues"]]
    cue = normalize_ar(ev["cue"])
    hits = [(cl, x) for cl in clauses for x in cl["cues"] if cue in x["cue"].split(" او ")]
    cl, own = hits[min(ev.get("nth", 0), len(hits) - 1)] if hits else (None, None)  # the label's own occurrence
    if cl is None:
        return out
    steps = [{"cue": x["cue"], "reading": x["reading"], "set": _ordered(x["set"]), "role": x["role"]} for x in cl["cues"]]
    out |= {"clause": cl["text"][:300], "steps": steps}
    if own["role"] != "predication":
        return out | {"class": "misread", "priority": "high"}
    s = reduce(frozenset.__and__, _comparable(own, cl["cues"], "act" in stages), own["set"])
    p = _preferred(clauses) if "tarjih" in stages else None
    if p and (not s or _REPORT.search(cl["text"])):
        stage, v = resolve(None, None, p)
        s, out["resolution"] = frozenset({v}), stage
    elif not s:
        out["resolution"] = resolve(None, None, None)[0]
    elif h not in s and own["sigma"] and h in own["literal"]:
        out["act"] = "omission"                               # the label rules on the omission: σ of the act's status
        sigma_s = frozenset(SIGMA[x] for x in s)
        cls = "confirmed" if sigma_s == {h} else "consistent"
        return out | {"class": cls, "set": _ordered(s), "priority": _priority(cls, h, en)}
    reported = _REPORT.search(cl["text"]) or "اختلف" in normalize_ar(ev["passage"])
    cls = ("ikhtilaf" if reported else "conflict") if not s else "rejected" if h not in s else "confirmed" if s == {h} else "consistent"
    return out | {"class": cls, "set": _ordered(s), "priority": _priority(cls, h, en)}


# An independent vote from the English version of the same answer (not a bank reading).
# Negations claim their span first; a negated non-prohibition («not obligatory») casts no vote.
_EN_NEG = (("haram", r"must not|should not|may not|cannot|can not|not permissible|impermissible|not allowed|not permitted"
                     r"|not halal|not lawful"),
           (None, r"not obligatory|not compulsory|not wajib|not waajib|not required|no need to|not necessary"
                  r"|not recommended|not mustahabb|not sunnah|not makrooh|not makruh|not disliked"
                  r"|not haram|not haraam|not forbidden|not prohibited"))
_EN = (("haram", r"haraam|haram|forbidden|prohibited"),
       ("wajib", r"obligatory|must|waajib|wajib|compulsory|required to"),
       ("mandub", r"mustahabb|recommended|sunnah to|it is sunnah"),
       ("makruh", r"makrooh|makruh|disliked"),
       ("mubah", r"no problem|no harm|permissible|allowed|halaal|halal|nothing wrong"))
_EN_RX = [(h, re.compile(rf"\b(?:{p})\b")) for h, p in _EN]
_EN_NEG_RX = [(h, re.compile(rf"\b(?:{p})\b")) for h, p in _EN_NEG]


def en_vote(text: str | None, window: int = 600) -> str | None:
    """Status of the earliest English ruling cue in the opening of the answer."""
    t = (text or "").lower()[:window]
    claimed = [(m.start(), m.end(), h) for h, rx in _EN_NEG_RX for m in rx.finditer(t)]
    free = [(m.start(), m.end(), h) for h, rx in _EN_RX for m in rx.finditer(t)
            if all(m.end() <= s or m.start() >= e for s, e, _ in claimed)]
    votes = sorted((s, s - e, h) for s, e, h in claimed + free if h)
    return votes[0][2] if votes else None


def lean_guards() -> str:
    """Exhaustive Lean guards for the Python mirrors above."""
    b = lambda v: "true" if v else "false"  # noqa: E731
    lines = ["-- GENERATED by `python -m usul_corpus bank-review`. Do not edit.",
             "-- The fatwā reviewer's mirrors of Usul.Hukm, Usul.Dalala and Usul.resolve equal the Lean definitions.",
             "import Usul", ""]
    for h in HUKM:
        lines += [f"#guard (Usul.Hukm.σ .{h}) == .{SIGMA[h]}",
                  f"#guard (Usul.Hukm.mode .{h}) == .{MODE[h]}",
                  f"#guard (Usul.Hukm.binding .{h}) == {b(BINDING[h])}",
                  f"#guard (!(Usul.Hukm.mode .{h} == .talabTark && Usul.Hukm.binding .{h})) == {b(h in JAWAZ)}"]
    lines += ['#guard (Usul.Dalala.amrStatus none) == .wajib', '#guard (Usul.Dalala.nahyStatus none) == .haram']
    opt = lambda v: f"(some .{v})" if v else "none"  # noqa: E731
    for jam in ("wajib", None):
        for naskh in ("haram", None):
            for tarjih in ("mandub", None):
                stage, v = resolve(jam, naskh, tarjih)
                rhs = f"(.{stage} .{v} : Usul.Resolution Usul.Hukm)" if v else "(.tawaqquf : Usul.Resolution Usul.Hukm)"
                lines.append(f"#guard (Usul.resolve ({{ jam := {opt(jam)}, naskh := {opt(naskh)}, tarjih := {opt(tarjih)} }}"
                             f" : Usul.Conflict Usul.Hukm)) == {rhs}")
    return "\n".join(lines) + "\n"
