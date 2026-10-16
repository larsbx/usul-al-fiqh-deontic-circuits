"""Pure finite reconciliation operations mirrored from Usul.Tarjih / Usul.Reconcile.

Inputs are encoded ruling values and explicit evidence tiers/advantages. This
module does not load sources, interpret quotations, accept claims, or write reports.
Its ordering policy is unchanged by extraction; input adequacy is a separate gate.
"""
from .values import same, distinct

# Attribution grades, strongest first; mirrors `Usul.Reconcile.Grade.rank`. A record, not a weight.
GRADES = ("tashih", "nass", "zahir", "qiyas", "jazm", "ashab", "takhrij", "wajh")
RANK = {g: len(GRADES) - 1 - i for i, g in enumerate(GRADES)}
MARKED = frozenset(g for g in GRADES if RANK[g] >= RANK["jazm"])
STAGES = ("jam", "naskh", "tarjih", "tawaqquf", "unweighed")
# Proof tiers, weakest first; mirrors `Usul.Tarjih.Tier.rank` (Rawḍa v02 p389–390, Aḥmad's order of resort).
TIERS = ("istishab", "qiyas", "mursalDaif", "aqrabSahabi", "fatwaSahabi", "zanni", "qati", "ijma")
TIER_RANK = {t: i for i, t in enumerate(TIERS)}
# The advantages the Rawḍa (v02 p391–401), al-Kawkab (v04 p650–703) and al-Ṭūfī (v03 p729–746) state between proofs of one tier;
# mirrors `Usul.Tarjih.Murajjih`.
MURAJJIH = ("kathratRuwat", "tayaqquz", "wara", "sahibWaqia", "mubashir",
            "corroborated", "marfu", "consistentNarrator", "muttasil", "naqil", "muthbit",
            "usulMany", "tardAks", "mutaaddiya", "wasf", "ithbat", "aslShari", "aslAgreed", "aslStronger",
            "muaththira", "mulaima", "munasaba",
            "sahihayn", "masmu", "qawl", "fil", "nahy", "amr", "khass", "ammMahfuz", "iqtida", "ima", "muwafaqa",
            "muallal", "hazir",
            "mantuq", "nass", "mubayyan", "haqiqa", "ashhar", "siyaq", "afqah",
            "khiffa", "hissiyya", "fewerAwsaf", "dariHadd")
# Each advantage's standing in the cited sources; mirrors `Usul.Tarjih.Murajjih.standing`.
STANDING = {m: "asserted" for m in MURAJJIH} | dict.fromkeys(
    ("kathratRuwat", "mutaaddiya", "hazir", "qawl", "amr", "naqil"), "disputed") | dict.fromkeys(
    ("khiffa", "hissiyya", "fewerAwsaf"), "weak") | {"dariHadd": "rejected"}
# Which advantages decide: (standings counted, whether the bank's applied advantages count). Mirrors
# `Usul.Tarjih.Policy`; the bank resolves under `sources`, which counts only what a source states.
_STANDINGS = ("asserted", "disputed", "weak", "rejected")
POLICIES = {"strict": (frozenset({"asserted"}), False), "sources": (frozenset({"asserted", "disputed"}), False),
            "applying": (frozenset({"asserted", "disputed"}), True), "all": (frozenset(_STANDINGS), True)}
BASES = ("stated", "applied")
DEFAULT = "sources"


def top(ps: list[tuple[object, str]], p: object) -> int | None:
    return max((TIER_RANK[t] for r, t in ps if same(r, p)), default=None)


def favours(adv: list[tuple[object, object, str, str]], p: object, q: object, policy: str = DEFAULT) -> bool:
    counted, applied = POLICIES[policy]
    return any(same(w, p) and same(l, q) and STANDING[m] in counted and (b == "stated" or applied) for w, l, m, b in adv)


def beats(ps: list[tuple[object, str]], adv: list[tuple[object, object, str, str]], p: object, q: object,
          policy: str = DEFAULT) -> bool:
    """`p` outweighs `q`: a higher tier, or the same tier with a counted advantage and none back."""
    a, b = top(ps, p), top(ps, q)
    return a is not None and (b is None or a > b or (
        a == b and favours(adv, p, q, policy) and not favours(adv, q, p, policy)))


def weigh(rs: list[object], ps: list[tuple[object, str]], adv: list[tuple[object, object, str, str]],
          policy: str = DEFAULT) -> object | None:
    """Mirror of `Usul.Tarjih.prevail`: the reported ruling that outweighs every other, if any."""
    return next((p for p in rs if all(same(q, p) or beats(ps, adv, p, q, policy) for q in rs)), None)


def support(ps: list[tuple[object, str]], p: object) -> list[int]:
    """Ranks for ruling `p`, strongest first; an unmarked grade counts once however many hold it."""
    rs = [RANK[g] for r, g in ps if same(r, p)]
    return sorted([x for x in rs if x >= RANK["jazm"]] + list(dict.fromkeys(x for x in rs if x < RANK["jazm"])), reverse=True)


def prevail(ps: list[tuple[object, str]]) -> object | None:
    """The ruling whose support (ranks, strongest first, compared lexicographically, longer
    beating its own prefix) strictly exceeds every other ruling's."""
    rulings = distinct(r for r, _ in ps)
    return next((p for p in rulings if all(same(q, p) or support(ps, p) > support(ps, q) for q in rulings)), None)

