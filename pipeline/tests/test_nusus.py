"""The textual foundation and the term guards (`corpus/nusus/foundation.json`,
`corpus/dossier/term_guards.json`): every āya and ḥadīth verbatim in its pinned witness at its
place, every ḥadīth graded by al-Albānī and gated, every ruled term resting on them, and no English
gloss standing in for a term it could conflate."""

import json
import re
import unicodedata
from pathlib import Path

import jsonschema
import pytest

from usul_corpus import nusus
from usul_corpus.__main__ import CACHE, CORPUS, GLOSSARY

ROOT = Path(__file__).parents[2]
F = nusus.load(CORPUS)
GLOSS = json.loads(GLOSSARY.read_text(encoding="utf-8"))
GUARDS = json.loads((CORPUS / "dossier" / "term_guards.json").read_text(encoding="utf-8"))
IDS = {x["id"]: x for k in ("ayat", "ahadith", "athar") for x in F[k]}
TERMS = {t["key"]: t for t in GLOSS["terms"]}
HUJJA = {"sahih", "hasan"}                                       # Usul.Seam.admitted (D4)


def _text(witness):
    p = CACHE / f"{witness}.txt"
    if not p.exists():
        pytest.skip(f"{witness} not cached")
    return p.read_text(encoding="utf-8")


def test_schema():
    jsonschema.validate(F, json.loads((ROOT / "schemas/nusus.schema.json").read_text()))
    assert len(IDS) == sum(len(F[k]) for k in ("ayat", "ahadith", "athar"))


@pytest.mark.parametrize("a", F["ayat"], ids=lambda a: a["id"])
def test_aya_is_verbatim_at_its_place(a):
    line = nusus.aya(_text(a["witness"]), a["sura"], a["aya"])
    assert line and nusus.key(a["excerpt_ar"]) in nusus.key(line)
    assert a["id"].startswith(f"Q{a['sura']:03d}:{a['aya']:03d}")


@pytest.mark.parametrize("s", [dict(s, _h=h) for h in F["ahadith"] for s in h["sources"]],
                         ids=lambda s: f"{s['_h']['id']}@{s['work']}")
def test_hadith_is_verbatim_under_its_number(s):
    text = _text(s["witness"])
    matn = s.get("matn_ar", s["_h"]["matn_ar"])
    sp = nusus.span(text, matn)
    assert sp is not None, "matn not in the collection"
    assert not nusus.in_heading(text, sp[0]), "matched a bāb heading, not the ḥadīth"
    assert nusus.number_at(text, sp[0]) == s["number"]


@pytest.mark.parametrize("h", F["ahadith"], ids=lambda h: h["id"])
def test_albani_verdict_is_his(h):
    """The verdict is the one al-Albānī gives in the cited entry, and the entry is this ḥadīth (a run
    of 15 letters of the matn appears in it)."""
    verdict, entry = nusus.albani_verdict(h["albani"]["work"], _text(h["albani"]["witness"]), h["albani"]["number"])
    assert verdict == h["albani"]["verdict"]
    m, e = nusus.key(h["matn_ar"]), nusus.key(entry)
    assert any(m[i:i + 15] in e for i in range(max(1, len(m) - 14))), "not the ḥadīth of that entry"


def test_a_hadith_outside_the_collections_is_one_the_gate_rejects():
    assert all(h["albani"]["verdict"] not in HUJJA for h in F["ahadith"] if not h["sources"])


def test_irwa_coverage_is_pinned():
    """The pinned al-Irwāʾ lacks the entries on pages blank on Shamela (PR-16); the gap is pinned
    so that it can only shrink by a deliberate re-pin."""
    pinned = json.loads((CORPUS / "hadith/irwa_coverage.json").read_text(encoding="utf-8"))
    cov = nusus.irwa_coverage(_text(pinned["witness"]))
    assert {k: cov[k] for k in ("entries_found", "last", "missing")} == {k: pinned[k] for k in ("entries_found", "last", "missing")}
    cited = [h["albani"]["number"] for h in F["ahadith"] if h["albani"]["work"] == "albani.irwa"]
    assert not set(cited) & set(pinned["missing"])


@pytest.mark.parametrize("a", F["athar"], ids=lambda a: a["id"])
def test_athar_and_albani_word_are_verbatim(a):
    text = nusus.key(_text(a["witness"]))
    assert nusus.key(a["excerpt_ar"]) in text and nusus.key(a["albani_ar"]) in text


def test_every_ruled_term_rests_on_the_foundation():
    """A term with rulings cites only ids of the foundation; every marfūʿ ḥadīth it cites passes the
    gate; a term resting on athar alone says so in its conditions."""
    for t in (t for t in GLOSS["terms"] if "rulings" in t):
        cited = [IDS[i] for i in t["nusus"]]
        assert all(c["albani"]["verdict"] in HUJJA for c in cited if c["id"].startswith("H-"))
        if all(c["id"].startswith("A-") for c in cited):
            assert any("athar" in c for c in t.get("conditions", [])), t["key"]


def test_cited_furuq_exist():
    items = {i["id"] for p in (CORPUS / "furuq").glob("*.json") for i in json.loads(p.read_text())["items"]}
    assert {f for t in GLOSS["terms"] for f in t.get("furuq", [])} <= items


def _fold(tr):
    s = unicodedata.normalize("NFKD", tr.removeprefix("al-"))
    return re.sub(r"[^a-z]", "", "".join(c for c in s if not unicodedata.combining(c)).lower())


def test_homographs_are_declared_distinct():
    """Transliterations that fold to one ASCII form (al-manī المني, al-māniʿ المانع) name each other in
    `distinct_from`, so one never stands for the other."""
    for a in GLOSS["terms"]:
        for b in GLOSS["terms"]:
            if a["key"] < b["key"] and _fold(a["tr"]) == _fold(b["tr"]):
                assert b["key"] in a.get("distinct_from", []) and a["key"] in b.get("distinct_from", []), (a["key"], b["key"])


def _english_fields():
    """(scope, where, text) for every English field a guard may read."""
    for p in sorted((CORPUS / "furuq").glob("*.json")):
        for i in json.loads(p.read_text())["items"]:
            yield "registers", i["id"], " ".join(i["cases_en"] + [i["note"]])
    for p in sorted((CORPUS / "takhrij").glob("*.json")):
        if p.name != "report.json":
            for c in json.loads(p.read_text())["cases"]:
                yield "registers", c["far"], " ".join([c.get("note", "")] + [x["who"] for x in c.get("positions") or []])
    for p in sorted((CORPUS / "tanaqud").glob("*.json")):
        for x in json.loads(p.read_text())["pairs"]:
            yield "registers", x["id"], x["case_en"] + " " + x["qayd_en"]
    for t in GLOSS["terms"]:
        yield "glossary", t["key"], t["gloss"] + " " + t["definition"]
    for p in sorted((ROOT / "formal/lean").rglob("*.lean")):
        if ".lake" not in p.parts:
            for k, m in enumerate(re.finditer(r"/-[-!].*?-/", p.read_text(encoding="utf-8"), re.S)):
                yield "lean", f"{p.name}#{k}", m.group(0)


def test_no_english_gloss_stands_alone():
    """Where an English gloss could mean several terms, the same field names the term it means."""
    bad = []
    for g in GUARDS["guards"]:
        names = [n for k in g["terms"] for n in (TERMS[k]["tr"].removeprefix("al-"), TERMS[k]["ar"].removeprefix("ال"))]
        scope = set(g.get("scope", ["registers", "glossary", "lean"]))
        for sc, where, s in _english_fields():
            if sc in scope and re.search(g["gloss_en"], s, re.I) and not any(n in s for n in names):
                bad.append((where, re.search(g["gloss_en"], s, re.I).group(0)))
    assert not bad, bad


def test_table_lean_is_generated():
    from usul_corpus.__main__ import NUSUS_LEAN
    from usul_corpus import furuq
    assert NUSUS_LEAN.read_text(encoding="utf-8") == nusus.table_lean(F, GLOSS, [i for t in furuq.tranches(CORPUS) for i in t["items"]])
