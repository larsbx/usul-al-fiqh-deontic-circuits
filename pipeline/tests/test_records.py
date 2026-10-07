import json
from pathlib import Path

import jsonschema

from usul_corpus.records import qaida_records, unit_tags
from usul_corpus.segment import Unit

SCHEMA = json.loads((Path(__file__).parents[2] / "schemas" / "usul_rule.schema.json").read_text())
WORK = {"id": "ibn_lahham.qawaid_fawaid", "rights": "public_domain_text"}


def test_qaida_records_emit_parent_then_furu_and_validate():
    u = Unit(3, "القاعدة 3", "لا تكليف على الناسي", (1, 37), ("إذا نسي الماء وتيمم", "إذا تكلم في الصلاة ناسيا"), False)
    q, f1, f2 = qaida_records(WORK, "openiti-x", "headed", "q003", u)
    assert q["furu_count"] == 2 and q["locator"] == "src:openiti-x/v01:p037#q003"
    assert f1["qaida"] == q["id"] and f1["id"] == q["id"] + ".f001"
    assert f2["case_ar"] == "إذا تكلم في الصلاة ناسيا"
    for r in (q, f1, f2):
        jsonschema.validate(r, SCHEMA)


def test_modern_rights_cap_excerpts():
    u = Unit(1, "القاعدة الأولى", "ا" * 1000, None, ("ب" * 1000,), False)
    q, f = qaida_records({"id": "sadi.qawaid_jamia", "rights": "modern_cache_only"}, "archive-x", "lines", "q001", u)
    assert len(q["excerpt_ar"]) == 160 and len(f["case_ar"]) == 160


def test_unit_tags_disambiguate_repeats_and_unparsed():
    us = tuple(Unit(n, "", "", None, (), False) for n in (1, 15, None, 15, 1, 15))
    assert unit_tags(us) == ["q001", "q015", "u003", "q015_2", "q001_2", "q015_3"]


def test_sharh_record_links_commentary_to_its_verse_and_validates():
    from usul_corpus.records import sharh_record
    from usul_corpus.verses import CommentaryLink

    work = {"id": "ibn_uthaymin.manzuma", "rights": "modern_cache_only"}
    link = CommentaryLink(89, (1, 337), (1, 339), "والأصل في القيد احتراز", 0.92, "قوله: " + "ش" * 400)
    r = sharh_record(work, "archive-manzuma-tess", link)
    assert r["id"] == "ibn_uthaymin.manzuma.archive_manzuma_tess.q089.sharh"
    assert r["bayt"] == "ibn_uthaymin.manzuma.archive_manzuma_tess.q089"
    assert r["locator"] == "src:archive-manzuma-tess/v01:p337#q089.sharh"
    assert r["page_span"] == [337, 339] and len(r["excerpt_ar"]) == 160
    jsonschema.validate(r, SCHEMA)


def test_sadi_catalogue_is_complete_typed_and_backed_by_records():
    """Every rule 1..60 once, kinds declared, and each number attested by some record."""
    root = Path(__file__).parents[2]
    cat = json.loads((root / "corpus/proposals/sadi_qawaid.json").read_text())
    jsonschema.validate(cat, json.loads((root / "schemas/qawaid_proposal.schema.json").read_text()))
    numbers = [r["number"] for r in cat["rules"]]
    assert numbers == list(range(1, 61))
    assert {r["kind"] for r in cat["rules"]} <= set(cat["kinds"])
    attested = {
        n
        for w in ("archive-pdf1995", "archive-pdf1995-tess")
        for line in (root / f"corpus/records/{w}.jsonl").read_text().splitlines()
        for rec in [json.loads(line)]
        if rec["record_type"] == "qaida" and rec["number"]
        for n in [rec["number"]]
    }
    assert set(numbers) - attested <= {23}   # 23 shares the printed heading of 22 (joint heading)


def test_sadi_catalogue_is_formalised_and_checked():
    """Every rule names at least one Lean constant, and each is #check-ed in UsulTest."""
    root = Path(__file__).parents[2]
    cat = json.loads((root / "corpus/proposals/sadi_qawaid.json").read_text())
    checked = (root / "formal/lean/UsulTest/SignatureMap.lean").read_text()
    assert all(r["lean"] for r in cat["rules"])
    assert all(f"#check @{n}\n" in checked for r in cat["rules"] for n in r["lean"])


def test_schemata_tags_are_pinned():
    """Catalogue schema tags coincide with the typed pins in UsulTest/Schemata.lean."""
    root = Path(__file__).parents[2]
    cat = json.loads((root / "corpus/proposals/sadi_qawaid.json").read_text())
    tagged = {(f"Q{r['number']}", s) for r in cat["rules"] for s in r.get("schemata", [])}
    pins = (root / "formal/lean/UsulTest/Schemata.lean").read_text()
    pinned = {tuple(line.split()[2:4]) for line in pins.splitlines() if line.startswith("-- @schema ")}
    assert tagged == pinned


def test_interpretive_questions_are_grounded():
    """Each open question names tagged rules, pinned constants and a usul-k route; it decides nothing."""
    root = Path(__file__).parents[2]
    reg = json.loads((root / "corpus/review/sadi_interpretive_questions.json").read_text())
    jsonschema.validate(reg, json.loads((root / "schemas/review_question.schema.json").read_text()))
    cat = {r["number"]: r for r in json.loads((root / "corpus/proposals/sadi_qawaid.json").read_text())["rules"]}
    linked = {n for r in cat.values() for n in r["lean"]}
    ids = [q["id"] for q in reg["questions"]]
    assert len(ids) == len(set(ids))
    for q in reg["questions"]:
        assert all(set(q["schemata"]) & set(cat[n].get("schemata", [])) for n in q["rules"]), q["id"]
        assert set(q["pins"]) <= linked, q["id"]


def _register(root):
    return json.loads((root / "corpus/review/sadi_interpretive_questions.json").read_text())


def test_status_is_computed_from_evidence_on_file():
    """Q11 on the register: a status is what its evidence supports (Usul.Process.status), nothing more."""
    for q in _register(Path(__file__).parents[2])["questions"]:
        internal = any(a["kind"] == "internal" for a in q["analogies"])
        expected = "referenced" if q["established"] else "analogized" if internal else "open"
        assert q["status"] in (expected, "withdrawn", "adopted"), q["id"]


def test_adoptions_are_human_and_checked():
    """Review.tla on the register: only a human decision adopts, and what it adopts is #check-ed."""
    root = Path(__file__).parents[2]
    checked = (root / "formal/lean/UsulTest/SignatureMap.lean").read_text()
    for q in (q for q in _register(root)["questions"] if q["status"] == "adopted"):
        assert q["decision"]["by"] == "human" and q["established"], q["id"]
        lean = q["decision"]["lean"] + [n for a in q["decision"].get("amendments", []) for n in a["lean"]]
        assert all(f"#check @{n}\n" in checked for n in lean), q["id"]


def test_citations_resolve_to_pinned_sources():
    """Every established answer cites a committed record or a locator into a registered witness."""
    root = Path(__file__).parents[2]
    ids = {json.loads(line)["id"] for f in (root / "corpus/records").glob("*.jsonl") for line in f.read_text().splitlines()}
    witnesses = {w["id"] for work in json.loads((root / "corpus/registry.json").read_text())["works"] for w in work["witnesses"]}
    for q in _register(root)["questions"]:
        for e in q["established"]:
            ref = e["ref"]
            assert (ref.split("/")[0][4:] in witnesses) if ref.startswith("src:") else ref in ids, (q["id"], ref)
            assert ref.startswith("src:") or "excerpt_ar" not in e, (q["id"], "records carry their own excerpt")


def test_internal_analogies_are_licensed():
    """Q58 on the register: an internal analogy needs the schema on both aṣl and farʿ (else naqḍ)."""
    root = Path(__file__).parents[2]
    tags = {r["number"]: set(r.get("schemata", [])) for r in json.loads((root / "corpus/proposals/sadi_qawaid.json").read_text())["rules"]}
    for q in _register(root)["questions"]:
        for a in (a for a in q["analogies"] if a["kind"] == "internal"):
            assert a["asl"] not in q["rules"], (q["id"], "an analogy needs a distinct aṣl")
            assert a["schema"] in tags[a["asl"]] and all(a["schema"] in tags[n] for n in q["rules"]), (q["id"], a["asl"])


def test_process_is_stratified():
    """No bootstrap deadlock (Usul.Process.no_deadlock_of_stratified at the level of constants):
    the process relies only on constants no live question pins; avoided rules are under question."""
    reg = _register(Path(__file__).parents[2])
    proc = reg["process"]
    live = [q for q in reg["questions"] if q["status"] not in ("withdrawn", "adopted")]
    relied = {c for cs in proc["relies_on"].values() for c in cs}
    assert set(proc["relies_on"]) == set(proc["uses_why"]) == {str(n) for n in proc["uses"]}
    assert not relied & {c for q in live for c in q["pins"]}
    assert {int(n) for n in proc["avoids"]} <= {n for q in live for n in q["rules"]}


def test_questions_do_not_overlap():
    """S7 on the register: two questions pinning the same constant concern one commitment and
    would merge into one."""
    pins = [c for q in _register(Path(__file__).parents[2])["questions"] for c in q["pins"]]
    assert len(pins) == len(set(pins))


def test_citation_maps_are_grounded():
    """Each citation names a registered witness within its excerpt limit; every topic is either
    formalised (by #check-ed constants) or listed as unformalised; every Usul.Qiyas / Usul.Jadal
    constant linked in the catalogue is grounded by some cited topic."""
    from usul_corpus.records import EXCERPT_LEN
    root = Path(__file__).parents[2]
    rights = {w["id"]: work["rights"] for work in json.loads((root / "corpus/registry.json").read_text())["works"] for w in work["witnesses"]}
    checked = (root / "formal/lean/UsulTest/SignatureMap.lean").read_text()
    schema = json.loads((root / "schemas/citation_map.schema.json").read_text())
    linked = {n for r in json.loads((root / "corpus/proposals/sadi_qawaid.json").read_text())["rules"] for n in r["lean"]}
    for f in sorted((root / "corpus/citations").glob("*.json")):
        cmap = json.loads(f.read_text())
        jsonschema.validate(cmap, schema)
        for p in cmap["principles"]:
            assert p["witness"] in rights and p["locator"].startswith(f"src:{p['witness']}/"), p["locator"]
            assert len(p["excerpt_ar"]) <= EXCERPT_LEN[rights[p["witness"]]], p["locator"]
        topics = {p["topic"] for p in cmap["principles"]}
        assert topics == set(cmap["formalises"]) | set(cmap["unformalised"])
        assert not set(cmap["formalises"]) & set(cmap["unformalised"])
        grounded = {n for ns in cmap["formalises"].values() for n in ns}
        assert all(f"#check @{n}\n" in checked for n in grounded)
        qiyas = {n for n in linked if n.startswith(("Usul.Qiyas.", "Usul.Jadal.", "Usul.QiyasLimits."))}
        assert qiyas <= grounded, qiyas - grounded
    # every theorem stated in the qiyās modules is grounded by a cited topic
    import re
    grounded_all = {n for f in (root / "corpus/citations").glob("*.json") for ns in json.loads(f.read_text())["formalises"].values() for n in ns}
    for mod in ("Qiyas", "Jadal", "QiyasLimits"):
        names = re.findall(r"^theorem (\S+)", (root / f"formal/lean/Usul/{mod}.lean").read_text(), re.M)
        assert names and all(f"Usul.{mod}.{n}" in grounded_all for n in names), mod
