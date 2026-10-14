"""al-Saʿdī's furūq, graded by him (`Usul.Furuq`, `corpus/furuq/sadi_tranche*.json`)."""

import json
import re
from pathlib import Path

import jsonschema
import pytest

from usul_corpus.__main__ import CACHE
from usul_corpus.arabic import letters, normalize

ROOT = Path(__file__).parents[2]
TRANCHES = [json.loads(p.read_text(encoding="utf-8")) for p in sorted((ROOT / "corpus/furuq").glob("sadi_tranche*.json"))]
ITEMS = [i for t in TRANCHES for i in t["items"]]
key = lambda s: letters(normalize(s))


@pytest.mark.parametrize("t", TRANCHES, ids=lambda t: t["items"][0]["id"])
def test_tranche_validates(t):
    jsonschema.validate(t, json.loads((ROOT / "schemas/furuq_tranche.schema.json").read_text()))


def test_items_are_consecutive():
    assert [i["id"] for i in ITEMS] == [f"F{n:02d}" for n in range(1, len(ITEMS) + 1)]


@pytest.mark.parametrize("i", ITEMS, ids=lambda i: i["id"])
def test_grade_is_coherent(i):
    """A sound or weak farq answers masāʾil ruled apart; a weak non-distinction answers masāʾil ruled alike."""
    assert (i["madhhab"] == "alike") == (i["grade"] == "jamDaif")
    assert (i["ruling"] == i["madhhab"]) == (i["grade"] in ("sahih", "reported"))   # Usul.Furuq.confirms_iff_sahih


def test_quotes_are_verbatim_and_in_order():
    """Every quote is in the witness, and the items follow the book: none reordered or skipped over."""
    src = CACHE / f"{TRANCHES[0]['witness']}.txt"
    if not src.exists():
        pytest.skip("witness not cached")
    text, pos = key(src.read_text(encoding="utf-8")), -1
    assert key(TRANCHES[0]["asl"]["excerpt_ar"]) in text
    for i in ITEMS:
        nxt = text.find(key(i["author"]["excerpt_ar"]), pos + 1)
        assert nxt > pos, i["id"]
        pos = nxt


def test_lean_is_checked_and_complete():
    checked = (ROOT / "formal/lean/UsulTest/SignatureMap.lean").read_text(encoding="utf-8")
    named = {n for t in TRANCHES for n in t["lean"]} | {n for i in ITEMS for n in i["grounds"]}
    assert all(f"#check @{n}\n" in checked for n in named)
    module = (ROOT / "formal/lean/Usul/Furuq.lean").read_text(encoding="utf-8")
    theorems = {f"Usul.Furuq.{n}" for n in re.findall(r"^theorem (\S+)", module, re.M)}
    assert theorems <= named, theorems - named


def test_tally_is_pinned():
    from collections import Counter
    assert Counter(i["grade"] for i in ITEMS) == {"sahih": 96, "daif": 41, "jamDaif": 6, "reported": 23}


def test_table_lean_is_generated():
    from usul_corpus.__main__ import CORPUS, FURUQ_LEAN
    from usul_corpus.furuq import table_lean
    assert FURUQ_LEAN.read_text(encoding="utf-8") == table_lean(CORPUS)


def test_overturns_only_a_bare_report():
    """The register applied to itself: two items ruling one case differently are a bare report and
    the grade he gives it later; his own grades never overturn each other (`overturn_iff_daif`)."""
    seen = {}
    for i in ITEMS:
        if "overturns" in i:
            p = seen[i["overturns"]]                      # an earlier item
            assert (p["grade"], i["grade"]) == ("reported", "daif"), i["id"]
            assert p["ruling"] != i["ruling"], i["id"]
        seen[i["id"]] = i
    assert sum("overturns" in i for i in ITEMS) == 6


def test_qaida_basis_is_grounded():
    """An item whose reason is a qāʿida names a theorem, unless the aṣl lies outside the sixty."""
    outside = {"F27", "F47"}                              # «الأصل المحكم في كل الأبواب», «الأصول الشرعية»
    assert {i["id"] for i in ITEMS if i["basis"] == "qaida" and not i["grounds"]} == outside


def test_no_quote_stops_before_its_qualifier():
    """No excerpt ends where the text goes on with «إلا», «ما لم», «بشرط» …: a quote cut there
    reads as unqualified (problem register PR-07)."""
    from usul_corpus.nusus import cut_before_qualifier
    src = CACHE / f"{TRANCHES[0]['witness']}.txt"
    if not src.exists():
        pytest.skip("witness not cached")
    text = src.read_text(encoding="utf-8")
    assert [i["id"] for i in ITEMS if cut_before_qualifier(text, i["author"]["excerpt_ar"])] == []


def test_quotes_are_unique_in_the_witness():
    """A furūq quote carries no page, so it must occur once: a prefix of another passage (F63 in
    F49's «… الثابتة بالنص والإجماع») would be found at the wrong place (problem register PR-17)."""
    src = CACHE / f"{TRANCHES[0]['witness']}.txt"
    if not src.exists():
        pytest.skip("witness not cached")
    text = key(src.read_text(encoding="utf-8"))
    assert [i["id"] for i in ITEMS if text.count(key(i["author"]["excerpt_ar"])) != 1] == []


def test_nass_basis_rests_on_the_foundation():
    """An item whose basis is a naṣṣ cites it from the foundation, unless al-Saʿdī leaves it
    unspecified; every ḥadīth it rests on passes the gate. Where he says no sound ḥadīth exists
    («لم يصح حديث», «كلها ضعيفة»), al-Albānī's verdict on the ḥadīth cited agrees (PR-04)."""
    from usul_corpus.nusus import load
    from usul_corpus.__main__ import CORPUS
    f = load(CORPUS)
    ids = {x["id"]: x for k in ("ayat", "ahadith", "athar") for x in f[k]}
    hujja = lambda i: ids[i]["albani"]["verdict"] in ("sahih", "hasan")
    for i in ITEMS:
        cited = i.get("nusus", [])
        assert set(cited) <= set(ids), i["id"]
        if i["basis"] == "nass":
            assert i["nass_cited"] == "unspecified" or cited, i["id"]
            assert all(hujja(c) for c in cited if c.startswith("H-")), i["id"]
        if i["basis"] == "no_sound_hadith":
            assert any(c.startswith("H-") for c in cited) and not any(hujja(c) for c in cited if c.startswith("H-")), i["id"]
        assert ("nass_cited" in i) == (i["basis"] in ("nass", "no_sound_hadith")), i["id"]
