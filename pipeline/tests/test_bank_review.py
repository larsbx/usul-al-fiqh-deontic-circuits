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
    assert review(lab("haram", "هو واجب حرام .", "واجب"))["class"] == "conflict"
    assert review(lab("wajib", "لا يجوز تركه .", "لا يجوز"))["class"] == "confirmed"
    assert review(lab(None, None, None))["class"] == "no_reading"


def test_review_triages_and_never_writes_gold():
    low = review(lab("haram", "لا يجوز .", "لا يجوز"), en="haram")
    assert (low["priority"], "gold" in low) == ("low", False)
    assert review(lab("haram", "لا يجوز .", "لا يجوز"), en="mubah")["priority"] == "high"   # English objects
    assert review(lab("haram", "هو واجب حرام .", "واجب"))["priority"] == "high"             # conflict
    assert review(lab("mubah", "لا حرج .", "لا حرج"))["priority"] == "medium"               # bank underdetermines


def test_audit_regressions_in_the_reader():
    assert sets("لا يجوز تركيب الرموش") == [H({"haram"})]       # «تركيب» is not «ترك»
    assert sets("ترك واجب متعمدا") == [H({"wajib"})]             # status as ترك's object: no σ
    assert sets("ترك الصلاة حرام") == [H({"wajib"})]             # status predicated of the omission: σ


def test_lean_guards_cover_every_mirror_entry():
    g = lean_guards()
    assert g.count("#guard") == 5 * 4 + 2 + 8 and "Usul.Hukm.σ .wajib) == .haram" in g


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


# ── Round 1: only predications enter the comparison ─────────────────────────
def roles(text):
    return [(c["cue"], c["role"]) for cl in bank_clauses(text) for c in cl["cues"]]


def test_r1_non_predications_are_set_aside():
    assert roles("لا يجوز لصاحب العمل ان يلزم العامل") == [("لا يجوز", "predication"), ("يلزم", "subordinate")]
    assert roles("الاعياد المحدثة التي لا يجوز احداثها") == [("لا يجوز", "subordinate")]
    assert roles("لان الزكاة انما تجب على صاحب المال") == [("تجب", "subordinate")]
    assert roles("ما لم تشتمل على محرم") == [("محرم", "mention")]
    assert roles("( هذا حلال وهذا حرام )") == [("حلال", "mention"), ("حرام", "mention")]
    assert roles("عمك محرم لبناتك") == [("محرم", "kinship")]


def test_r1_ghayr_jaiz_is_a_prohibition():
    assert sets("وغير جائز") == [H({"haram"})]


# ── Round 2: jamʿ through σ (al-amr bi'l-shayʾ nahy ʿan ḍiddih) ─────────────
def test_r2_opposite_act_is_read_through_sigma():
    assert sets("لا يجوز التهاون في ادائها ، بل يجب المحافظة") == [H({"wajib"}), H({"wajib"})]
    assert sets("وجب عليه ان يعمل هذه الطاعة ولا يحل له ان يتركها") == [H({"wajib"}), H({"wajib"})]
    assert sets("محرم يجب الكف عنه") == [H({"haram"}), H({"haram"})]


# ── Round 3: jamʿ by scope — each predication rules on its own act ──────────
def test_r3_contrast_division_and_coordination_open_new_scopes():
    assert len(bank_clauses("لا يجب عليه ذلك وانما يجب عليه غيره")) == 2
    assert len(bank_clauses("فمنه ما هو جائز ومنه ما هو محرم")) == 2
    r = review(lab("mubah", "يجوز التداوي بالحقن للصائم ، ولا يجوز للصائم حقن التغذية .", "يجوز"))
    assert r["class"] == "consistent"


# ── Round 4: tarjīḥ, then tawaqquf (Usul.resolve) ───────────────────────────
def test_r4_reported_disagreement_resolves_by_the_texts_preference():
    p = "ذهب بعض العلماء الى وجوب صلاة ركعتين وهي واجبة عندهم ، وهي مستحبة عند غيرهم . والصواب انها مستحبة ."
    r = review(lab("wajib", p, "واجبة"))
    assert (r["class"], r["resolution"], r["set"]) == ("rejected", "tarjih", ["mandub"])


def test_r4_unresolved_conflict_is_tawaqquf():
    r = review(lab("haram", "هو واجب حرام .", "واجب"))
    assert (r["class"], r["resolution"]) == ("conflict", "tawaqquf")


def test_misread_when_the_candidates_own_cue_is_not_a_ruling():
    r = review(lab("haram", "والخلاصة : ان عمك محرم لبناتك .", "محرم"))
    assert (r["class"], r["priority"]) == ("misread", "high")


def test_resolve_mirror_follows_the_kernel_order():
    from usul_corpus.bank_review import resolve
    assert resolve("wajib", None, "mandub") == ("jam", "wajib")
    assert resolve(None, "wajib", "mandub") == ("naskh", "wajib")
    assert resolve(None, None, "mandub") == ("tarjih", "mandub")
    assert resolve(None, None, None) == ("tawaqquf", None)


# ── Round 5: the bank applied to its own residue ────────────────────────────
def test_r5_reader_fixes_from_the_misread_audit():
    assert roles("على نفسه لا يجوز للابن") == [("لا يجوز", "predication")]       # verbal cue after a PP
    assert roles("والتاويل بدعة محرمة لم تنقل") == [("محرمة", "predication")]               # not مَحْرَم
    assert roles("ومن تجب عليكم نفقتهم") == [("تجب", "subordinate")]              # و-prefixed relative


def test_r5_syndetic_coordination_opens_a_new_predication():
    assert len(bank_clauses("الغصب محرم ويجب رد المغصوب")) == 2
    assert len(bank_clauses("فلا باس والا فلا يجوز")) == 2
    assert len(bank_clauses("يجوز ذلك فان كان بالربا فلا يجوز")) == 2


def test_r5_sigma_is_bounded_by_the_previous_cue_and_reaches_the_object():
    assert sets("يجب تركه ولا تجوز المشاركة فيه") == [H({"haram"}), H({"haram"})]
    assert sets("لا يجوز للمسلمين في اي بلد تركها") == [H({"wajib"})]
    assert sets("يجب الاقلاع عنه") == [H({"haram"})]


def test_r5_attributive_status_words_are_mentions():
    assert roles("مشاركته وان اختلط بتجارة مباحة") == [("مباحة", "mention")]
    assert roles("الوفاء بشروط شرعية مباحة") == [("مباحة", "mention")]
    assert roles("الغصب محرم") == [("محرم", "predication")]                       # definite subject
    assert roles("فهذا تعامل محرم") == [("محرم", "predication")]                 # after a demonstrative


def test_r5_disjunction_and_modality():
    assert sets("مكروه او محرم عند اكثر اهل العلم") == [H({"makruh", "haram"})]
    assert roles("وقد يجب") == [("يجب", "modal")]
    assert sets("مباح لهن غير مكروه") == [H({"mubah"}), ALL - {"makruh"}]


def test_a_label_on_one_disjunct_finds_the_merged_cue():
    r = review(lab("haram", "بل هو مكروه او محرم عند اكثر اهل العلم .", "محرم"))
    assert (r["class"], r["set"]) == ("consistent", ["makruh", "haram"])


# ── Round 6: the bank applied to the round-5 residue ────────────────────────
def test_r6_contrast_exception_conditions_and_colon_open_scopes():
    assert len(bank_clauses("يجوز ذلك للنساء اما الرجل فلا يجوز له ذلك")) == 2
    assert len(bank_clauses("يجوز لها ذلك ما عدا شعر الحاجب فلا يجوز")) == 2
    assert len(bank_clauses("وجب عليها الغسل فان عاد عليها الدم وجب عليها ترك الصلاة")) == 2
    assert len(bank_clauses("وكانت الشروط مباحة : وجب الوفاء بالشرط")) == 2


def test_r6_frames_questions_homographs_and_proof_texts():
    assert roles("يجب ان تعلم انه لا يحل الاتجار")[0] == ("يجب", "frame")
    assert roles("لا يلزم منها انها واجبة")[0] == ("لا يلزم", "frame")
    assert roles("ومتى تجب")[0] == ("تجب", "question")
    assert sets("جائز شرعا ام غير جائز") == [ALL]
    assert roles("لا يجوز صيده لمحرم بالحج او غير محرم")[-1] == ("غير محرم", "ihram")
    assert roles("شاب غير محرم لك") == [("غير محرم", "kinship")]
    assert roles('قوله تعالى : " ولا تقولوا هذا حلال وهذا حرام "') == [("حلال", "mention"), ("حرام", "mention")]


def test_r6_definiteness_and_relatives():
    assert roles("العمل في البنوك التي تتعامل بالربا حرام")[0] == ("حرام", "predication")
    assert roles("وضع النغمات منكر ومحرم") == [("محرم", "predication")]
    assert roles("في المقاطع التي محتواها مباح") == [("مباح", "subordinate")]
    assert roles("ويباح فيها ما هو محرم في الشرع")[1] == ("محرم", "subordinate")
    assert roles("من يقول بانه يلزمك كفارة")[0] == ("يلزمك", "subordinate")


def test_r6_avoidance_is_an_opposite_and_sigma_stops_at_another_verb():
    assert sets("يجب الحذر من مشاهدة هذه البرامج") == [H({"haram"})]
    assert sets("لا يجوز للزوج ان يحلف على ترك معاشرة زوجته") == [H({"haram"})]


def test_r6_backward_tarjih_and_genuine_ikhtilaf():
    p = "ذهب بعض العلماء الى ان عيادة المريض سنة مؤكدة واختار شيخ الاسلام انها فرض كفاية وهو الصحيح ."
    r = review(lab("mandub", p, "سنة مؤكدة"))
    assert (r["class"], r["resolution"], r["set"]) == ("rejected", "tarjih", ["wajib"])
    q = "اختلف العلماء فمنهم من قال انها سنة مؤكدة ومنهم من قال انها واجبة على كل مسلم ."
    r = review(lab("mandub", q, "سنة مؤكدة"))
    assert (r["class"], r["resolution"]) == ("ikhtilaf", "tawaqquf")


def test_r6_a_ruling_on_the_omission_is_the_same_ruling_through_sigma():
    r = review(lab("haram", "فلا يجوز التفريط فيها .", "لا يجوز"))
    assert (r["class"], r["act"], r["set"]) == ("confirmed", "omission", ["wajib"])
