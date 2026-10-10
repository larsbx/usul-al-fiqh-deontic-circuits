from usul_corpus.bank_review import ALL, JAWAZ, SIGMA, bank_clauses, lean_guards, review

H = frozenset


def test_kernel_mirrors():
    assert all(SIGMA[SIGMA[h]] == h for h in ALL)          # σ_involutive
    assert {h for h in ALL if SIGMA[h] == h} == {"mubah"}   # σ_fixed_iff
    assert JAWAZ == ALL - {"haram"}                         # ¬(ṭalab al-tark ∧ ilzām)


def sets(text):
    return [c["set"] for cl in bank_clauses(text) for c in cl["cues"]]


def test_denotations_go_through_the_bank():
    assert sets("لا يجوز بيعه") == [H({"haram"})]            # nahyStatus none
    assert sets("يجب الغسل") == [H({"wajib"})]               # obligationStatus _ wujubLabel none
    assert sets("لا حرج في ذلك") == [JAWAZ]                  # raf' al-ḥaraj
    assert sets("لا يجب القضاء") == [ALL - {"wajib"}]
    assert sets("مستحب") == [H({"mandub"})]                  # amrStatus (some mandub)


def test_omission_is_read_through_sigma():
    assert sets("ترك الصلاة حرام") == [H({"wajib"})]
    assert sets("لا يجوز تركها") == [H({"wajib"})]


def test_exceptions_open_a_new_clause():
    (base, exc) = bank_clauses("لا حرج في العمل إلا إذا كان فيه نقل الخمر فيحرم")
    assert [c["set"] for c in base["cues"]] == [JAWAZ] and [c["set"] for c in exc["cues"]] == [H({"haram"})]


def lab(hukm, passage, cue):
    return {"id": "islamqa.1", "hukm": hukm, "evidence": hukm and {"cue": cue, "passage": passage}}


def test_review_classes():
    assert review(lab("haram", "فلا يجوز ذلك .", "لا يجوز"))["class"] == "confirmed"
    assert review(lab("mubah", "لا حرج في ذلك .", "لا حرج"))["class"] == "consistent"
    r = review(lab("mubah", "لا يجب ، ويستحب ذلك .", "يستحب"))
    assert (r["class"], r["set"]) == ("rejected", ["mandub"])
    assert review(lab("haram", "يجب ذلك ويحرم ذلك .", "يجب"))["class"] == "conflict"
    assert review(lab("wajib", "لا يجوز تركه .", "لا يجوز"))["class"] == "confirmed"
    assert review(lab(None, None, None))["class"] == "no_reading"


def test_review_triages_and_never_writes_gold():
    low = review(lab("haram", "لا يجوز .", "لا يجوز"), en="haram")
    assert (low["priority"], "gold" in low) == ("low", False)
    assert review(lab("haram", "لا يجوز .", "لا يجوز"), en="mubah")["priority"] == "high"   # English objects
    assert review(lab("haram", "يجب ذلك ويحرم ذلك .", "يجب"))["priority"] == "high"          # conflict
    assert review(lab("mubah", "لا حرج .", "لا حرج"))["priority"] == "medium"               # bank underdetermines


def test_audit_regressions_in_the_reader():
    assert sets("لا يجوز تركيب الرموش") == [H({"haram"})]       # «تركيب» is not «ترك»
    assert sets("ترك واجب متعمدا") == [H({"wajib"})]             # status as ترك's object: no σ
    assert sets("ترك الصلاة حرام") == [H({"wajib"})]             # status predicated of the omission: σ


def test_lean_guards_cover_every_mirror_entry():
    g = lean_guards()
    assert g.count("#guard") == 5 * 4 + 2 and "Usul.Hukm.σ .wajib) == .haram" in g


def test_english_vote_takes_the_earliest_cue():
    from usul_corpus.bank_review import en_vote
    assert en_vote("Praise be to Allah. It is not permissible to sell it, but it is permissible to gift it.") == "haram"
    assert en_vote("There is nothing wrong with that.") == "mubah"
    assert en_vote("Praise be to Allah. The scholars differed about his lineage.") is None


def test_generated_lean_guards_are_in_sync():
    from pathlib import Path
    root = Path(__file__).resolve().parents[2]
    assert (root / "formal/lean/UsulTest/FatawaBank.lean").read_text() == lean_guards()
    assert "import UsulTest.FatawaBank" in (root / "formal/lean/UsulTest.lean").read_text()
