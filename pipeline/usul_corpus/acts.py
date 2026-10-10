"""The act and addressee a ruling cue is about: the (act, ḥukm) shape of `hukm_classification`.

A verbal cue («لا يجوز للمسلم أن يبيع الخمر») rules on its complement and names its
addressee right after it; a nominal cue («الغصب محرم») rules on its subject. Acts are
compared by light stems, and opposite acts (ḍidd) by a small antonym table, so the
bank can apply σ to them (Dalala.amr_nahy_didd_of).
"""

from __future__ import annotations

import re
from collections.abc import Iterable, Mapping

_L = r"ء-ي"
STOP = frozenset("""في من على عن الى مع له لها لهم لهن لك لكم عليه عليها عليهم عليهن ان انه انها ما هل حكم هذا هذه
ذلك تلك التي الذي الذين او ثم لا لم لن قد كان يكون بين كل اي بعض غير هو هي هم اذا الا بل و ف""".split())
_PREFIXES = ("وال", "فال", "بال", "كال", "لل", "ال", "و", "ف", "ب")
_SUFFIXES = ("هما", "كما", "ات", "ون", "ين", "ها", "هم", "هن", "ة", "ه")
_PRONOUN_ADDRESSEE = {"عليه": "ه", "عليها": "ها", "عليهم": "هم", "عليهن": "هن", "عليك": "ك", "عليكم": "كم",
                      "له": "ه", "لها": "ها", "لهم": "هم", "لهن": "هن", "لك": "ك", "لكم": "كم"}
# Opposite acts (ḍidd): a ruling on one is σ of the ruling on the other.
ANTONYMS: tuple[tuple[str, str], ...] = (
    (r"عدل|سوي|سوا", r"فضيل|فضل|جور|ميل"),
    (r"متنع|كف|ترك|قلاع", r"بقى|بقا|ستمر|داوم"),
    (r"رد", r"غصب|حبس"),
    (r"وفا|وفي", r"نقض|غدر|خلف"),
    (r"صدق", r"كذب"),
    (r"ستر|حجب|غطي|غطا", r"كشف|تبرج"),
    (r"صلة|وصل", r"قطع"),
    (r"اظهار|بيان|علان", r"كتمان|خفا|سرار"),
)
_ANTONYMS = [(re.compile(a), re.compile(b)) for a, b in ANTONYMS]


def stem(w: str) -> str:
    w = re.sub(rf"[^{_L}]", "", w)
    for p in _PREFIXES:
        if w.startswith(p) and len(w) - len(p) >= 3:
            w = w[len(p):]
            break
    for s in _SUFFIXES:
        if w.endswith(s) and len(w) - len(s) >= 3:
            w = w[:-len(s)]
            break
    if len(w) >= 4 and w[0] in "يتن":
        w = w[1:]
    return w[:4]


def _content(words: Iterable[str]) -> list[str]:
    return [w for w in words if w not in STOP and len(stem(w)) >= 3]


def stems(text: str) -> set[str]:
    return {stem(w) for w in _content(text.split())}


def _addressee(after: list[str]) -> tuple[str | None, int]:
    """«على X», «للX», «لـX», or a pronoun right after the cue; returns (addressee, tokens used)."""
    if not after:
        return None, 0
    w = after[0]
    if w in _PRONOUN_ADDRESSEE:
        return _PRONOUN_ADDRESSEE[w], 1
    if w == "على" and len(after) > 1:
        return stem(after[1]) if after[1] not in _PRONOUN_ADDRESSEE else _PRONOUN_ADDRESSEE[after[1]], 2
    if w.startswith("لل") and len(w) > 4:
        return stem(w), 1
    if w.startswith("ل") and len(w) > 3 and w[1] != "ا" and w not in STOP:
        return stem(w[1:]), 1
    return None, 0


def act_of(scope: str, cue: Mapping, until: int | None = None) -> dict:
    """{"text", "stems", "addressee"} of the act a cue (with start/end in `scope`) rules on."""
    after = scope[cue["end"]:until].split()
    addressee, used = _addressee(after)
    words = _content(after[used:])[:3]
    if not words or cue["text"].startswith(("حرام", "محرم", "واجب", "مستحب", "مكروه", "جائز", "مباح", "حلال", "سنة", "فرض")):
        words = _content(scope[:cue["start"]].split())[-3:] or words
    return {"text": " ".join(words), "stems": sorted({stem(w) for w in words}), "addressee": addressee}


def antonyms(a: Iterable[str], b: Iterable[str]) -> bool:
    a, b = " ".join(a), " ".join(b)
    return any((x.search(a) and y.search(b)) or (x.search(b) and y.search(a)) for x, y in _ANTONYMS)
