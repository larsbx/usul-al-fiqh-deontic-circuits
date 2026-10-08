from usul_corpus.openiti import Section
from usul_corpus.segment import Unit, audit_numbering, segment_headed, segment_lines


def sec(title, text, page=(1, 1), level=1):
    return Section(level=level, title=title, text=text, page=page, end_page=page)


def test_segment_headed_ordinal_header():
    secs = (
        sec("[خطبة المؤلف]", "الحمد لله"),
        sec("(القاعدة الأولى)", "الماء الجاري لا ينجس. ومنها كذا في المتن.\nمنها: إذا نسي الماء وتيمم.\n(ومنها) لو صلى ناسيا.", (1, 3)),
        sec("مسائل من ذلك", "ومنها: ثالث", (1, 4), level=2),
        sec("(القاعدة الثانية) :", "النية شرط", (1, 5)),
    )
    units = segment_headed(secs, marker="القاعدة")
    assert [u.number for u in units] == [1, 2]
    assert units[0].page == (1, 3)
    # furūʿ are paragraphs opening with (و)منها; subsections fold into their unit
    assert units[0].furu == ("إذا نسي الماء وتيمم.", "لو صلى ناسيا.", "ثالث")
    assert units[0].statement.startswith("الماء الجاري")


def test_segment_headed_numeric_header_and_number_on_body_line():
    secs = (
        sec("AUTO القاعدة 2 شرط التكليف العقل", "ذكره الآمدي"),
        sec("القاعدة", "2</span>\nشرط التكليف العقل وفهم الخطاب."),
    )
    units = segment_headed(secs, marker="القاعدة")
    assert [u.number for u in units] == [2, 2]
    assert units[1].statement.startswith("شرط التكليف")


def test_segment_lines_for_ocr_text():
    text = "مقدمة\nالقاعدة الأولى\nالنية\nالقاعدة الثااثون\nكذا\nالقاعدة الثانية\nكذا"
    units = segment_lines(text, marker="القاعدة")
    # 30 is out of sequence after 1 and is dropped from the chain; 2 follows 1
    assert [(u.number, u.ocr_corrected) for u in units] == [(1, False), (2, False)]


def test_segment_lines_bare_ordinals_joint_headings_and_toc_duplicates():
    text = "\n".join([
        "الفهرس", "القاعدة الأولى", "القاعدة الثانية",            # table of contents
        "القاعدة الأولى", "النية شرط في العبادات",
        "انلقف ل",                                              # decorative «القاعدة» OCR'd as junk
        "الثانية", "المشقة تجلب التيسير",
        "وفيها مسائل: الثانية منها كذا",                          # ordinal inside prose: not a heading
        "الثالثة ض",                                            # one stray glyph after the ordinal
        "اليقين لا يزول بالشك",
        "القاعدة الرابعة والخامسة", "الضرر يزال",                 # joint heading: rules 4 and 5
        "السادسة", "العادة محكمة",
    ])
    units = segment_lines(text, marker="القاعدة")
    assert [u.number for u in units] == [1, 2, 3, 4, 6]
    assert units[3].covers == (4, 5)
    assert units[0].statement.startswith("النية شرط")
    a = audit_numbering(units, expected=6)
    assert a["missing"] == [] and a["matches_expected"] and a["duplicates"] == []


def test_audit_numbering():
    units = tuple(Unit(n, "", "", None, (), False) for n in (1, 2, 2, 4, None))
    a = audit_numbering(units, expected=5)
    assert a == {
        "found": 5,
        "numbered": 4,
        "max_number": 4,
        "expected": 5,
        "missing": [3, 5],
        "duplicates": [2],
        "unparsed": 1,
        "matches_expected": False,
    }


def test_consensus_numbering_unions_witnesses():
    from usul_corpus.segment import consensus_numbering

    a = tuple(Unit(n, "", "", None, (), False) for n in (1, 2, 4))
    b = tuple(Unit(n, "", "", None, (), False) for n in (1, 3, None))
    c = consensus_numbering({"djvu": a, "tess": b}, expected=5)
    assert c == {
        "expected": 5,
        "found_by_any": [1, 2, 3, 4],
        "missing_in_all": [5],
        "beyond_expected": {},
        "found_by": {"1": ["djvu", "tess"], "2": ["djvu"], "3": ["tess"], "4": ["djvu"]},
        "complete": False,
    }


def test_segment_numbered_keeps_longest_increasing_verse_run():
    from usul_corpus.segment import segment_numbered

    text = "\n".join([
        "# مقدمة المحقق ٣ - كلام",            # stray number inside prose: not line-initial
        "# ١ - الحمد لله المعيد المبدي",
        "# شرح البيت الأول",
        "# (١) أخرجه البخاري",                 # parenthesised footnote numbers are excluded
        "PageV01P010",
        "# ۲۔ وبعد فالعلم بحور زاخرة",          # Persian digits and the Urdu full stop
        "# ٧ . حاشية رقمية شاردة",             # out-of-run number dropped by the LIS
        "# 3. والأصل في القيد احتراز",
        "# الشرح",
        "PageV01P011",
    ])
    units = segment_numbered(text)
    assert [(u.number, u.page) for u in units] == [(1, (1, 10)), (2, (1, 11)), (3, (1, 11))]
    assert units[0].heading == "الحمد لله المعيد المبدي"
    assert "شرح البيت الأول" in units[0].statement


def test_segment_numbered_repairs_lost_tens_digits():
    from usul_corpus.segment import segment_numbered

    digits = "١٢٣٤٥٦٧٨٩٠١٢"                       # OCR kept only the last digit of 10, 11, 12
    lines = [f"# {d} - بيت رقم {k}" for k, d in enumerate(digits, 1)]
    lines.insert(6, "# ٥٠ - رقم شارد")               # far out of sequence: dropped
    lines.insert(3, "# (٤) حاشية")                   # footnote: never a candidate
    units = segment_numbered("\n".join(lines))
    assert [u.number for u in units] == list(range(1, 13))
    assert [u.ocr_corrected for u in units] == [False] * 9 + [True] * 3
    assert units[9].heading == "بيت رقم 10"


def test_segment_index_reads_numbered_statements():
    from usul_corpus.segment import segment_index

    text = "\n".join([
        "# القاعدة الأولى",                                  # body heading: no colon, not an index entry
        "# الفهرس",
        "# القاعدة الأولى: الشارع لا يأمر إلا بما مصلحته خالصة أو راجحة",
        "# القاعدة الثانية: الوسائل لها أحكام المقاصد",
        "PageV01P170",
        "# القاعدة الثانية والثالثة والعشرون: مثال مشترك",
        "# القاعدة الرابعة: الوجوب يتعلق بالاستطاعة",
    ])
    units = segment_index(text, marker="القاعدة")
    assert [(u.number, u.covers) for u in units] == [(1, ()), (2, ()), (4, ())]
    assert units[1].heading == "القاعدة الثانية"
    assert units[1].statement == "الوسائل لها أحكام المقاصد"
    assert units[0].page == (1, 170)


def test_verse_chain_uses_tighter_step_than_rules():
    from usul_corpus.segment import segment_numbered

    # 1, 2, then a stray «٦» four steps ahead: allowed for rule headings, not for verses
    units = segment_numbered("# ١ - أ ب\n# ٢ - ج د\n# ٦ - شارد\n# ٣ - هـ و")
    assert [u.number for u in units] == [1, 2, 3]


def test_consensus_separates_numbers_beyond_the_expected_count():
    from usul_corpus.segment import consensus_numbering

    good = tuple(Unit(n, "", "", None, (), False) for n in (1, 2, 3))
    over = tuple(Unit(n, "", "", None, (), False) for n in (1, 3, 5))     # e.g. a digit-repair overshoot
    c = consensus_numbering({"tess": good, "djvu": over}, expected=3)
    assert c["missing_in_all"] == [] and c["beyond_expected"] == {"5": ["djvu"]} and c["complete"]


def test_segment_numbered_accepts_tatweel_as_separator():
    from usul_corpus.segment import segment_numbered

    text = "# ١ ـ القاعدة الأولى نصها\n# شرح\n# ٢ ـ الثانية نصها\n# ٣ - الثالثة نصها"
    assert [(u.number, u.heading) for u in segment_numbered(text)] == [
        (1, "القاعدة الأولى نصها"), (2, "الثانية نصها"), (3, "الثالثة نصها")]


def test_four_digit_numbers_match_and_chain_across_1000():
    from usul_corpus.arabic import normalize
    from usul_corpus.segment import _VERSE, _repair

    m = _VERSE.match("١٠١٥ - وأما فوائد الصلاة")
    assert m and normalize(m.group(1)) == "1015"
    assert _repair("1000", 999, anchor_step=30) == 1000   # full four-digit read anchors
    assert _repair("000", 999) == 1000                     # «١» lost: suffix repair still lands on 1000


def test_opening_example_before_the_first_paragraph_farc():
    """A qāʿida's first example, introduced inline after «صور:»/«مسائل:» or by a paragraph
    opening «ومن أمثلة ذلك», is kept as the opening example; the «(و)منها» paragraphs that
    follow keep their own order, so existing farʿ ids do not move."""
    q6 = sec("(القاعدة السادسة) :", "إذا فعل عبادة يظن أنها الواجبة فإنه يجزئه ولذلك صور: منها إذا أحج المعضوب ثم برئ.\n(ومنها) إذا كفر بالإطعام ثم عوفي.")
    q14 = sec("(القاعدة الرابعة عشر) :", "إذا وجد سبب من أحد رجلين ولها صور: (إحداها) إذا وجد اثنان منيا ففيها روايتان (إحداهما) لا يلزم.\n(والثانية) : يلزمهما الغسل.")
    q22 = sec("(القاعدة الثانية والعشرون) :", "العين المنغمرة هل هي كالمعدومة.\nفيه خلاف وينبني عليه مسائل: (ومنها) الماء الذي استهلكت فيه النجاسة.\n(ومنها) اللبن المشوب.")
    q68 = sec("(القاعدة الثامنة والستون) :", "هي نوعان:\nأحدهما ما يشترط فيه النية الجازمة\nومن أمثلة ذلك إذا صلى يظن نفسه محدثا.\nومنها لو شك في المسح.")
    q1 = sec("(القاعدة الأولى)", "الماء الجاري لا ينجس. ومنها كذا في المتن.\nمنها: إذا نسي الماء.")
    u6, u14, u22, u68, u1 = segment_headed((q6, q14, q22, q68, q1), marker="القاعدة")
    assert (u6.opening, u6.furu) == ("إذا أحج المعضوب ثم برئ.", ("إذا كفر بالإطعام ثم عوفي.",))
    # the rest of the prelude belongs to the case: here the second riwāya on it
    assert (u14.opening, u14.furu) == ("إذا وجد اثنان منيا ففيها روايتان (إحداهما) لا يلزم. (والثانية) : يلزمهما الغسل.", ())
    assert (u22.opening, u22.furu) == ("الماء الذي استهلكت فيه النجاسة.", ("اللبن المشوب.",))
    assert u68.opening == "إذا صلى يظن نفسه محدثا." and u68.furu == ("لو شك في المسح.",)
    assert u1.opening is None  # «ومنها» mid-sentence, with no «صور:/مسائل:», is not an example


def test_cases_run_to_the_next_farc_marker():
    """A case crossing a source line break (e.g. a page marker) keeps its continuation, up to
    the next farʿ marker; a marker line with nothing after it still opens no farʿ, so ids stay."""
    q16 = sec("(القاعدة السادسة عشر) :", "إذا كان الواجب بدلا للمسألة صور عديدة: (منها) هدي المتعة ثم وجد الهدي فهل يجب\nعليه الانتقال؟ فيه روايتان.\n(ومنها) كفارة الظهار ونحوها\nوالحكم فيهما كهدي المتعة.\n(ومنها)\nلا شيء.\n(ومنها) إذا أتلف مثليا.")
    (u,) = segment_headed((q16,), marker="القاعدة")
    assert u.opening == "هدي المتعة ثم وجد الهدي فهل يجب عليه الانتقال؟ فيه روايتان."
    assert u.furu == ("كفارة الظهار ونحوها والحكم فيهما كهدي المتعة.", "إذا أتلف مثليا.")


def test_ordinal_cases_where_no_paragraph_farc():
    """A qāʿida with no «(و)منها» paragraph may enumerate its cases by ordinal: «(الصورة
    الثانية)», «المسألة الثالثة:». Those lines then mark its furūʿ; a qāʿida with «(و)منها»
    paragraphs keeps them alone, so no existing id moves. Divisions (النوع, القسم, الضرب)
    are not cases."""
    q14 = sec("(القاعدة الرابعة عشر) :", "ولها صور: (إحداها) إذا وجد اثنان منيا.\n(والثانية) : يلزمهما الغسل.\n(الصورة الثانية) قال أحد الرجلين إن كان غرابا\nففيها وجهان.\nالصورة ms057 الثالثة: قال أحدهما.")
    q52 = sec("(القاعدة الثانية والخمسون) :", "في التصرف قبل القبض.\nالنوع الثاني عقود.\nفهذه أربع مسائل إحداها: ms101 بيع العطاء.\nالمسألة الثانية: بيع الصكاك.\n(المسألة الثالثة) : بيع المغانم.")
    q8 = sec("(القاعدة الثامنة) :", "صور: (منها) كذا.\n(ومنها) كذا أيضا.\n(الصورة الثانية) ليست فرعا هنا.")
    u14, u52, u8 = segment_headed((q14, q52, q8), marker="القاعدة")
    assert u14.opening == "إذا وجد اثنان منيا. (والثانية) : يلزمهما الغسل."
    assert u14.furu == ("قال أحد الرجلين إن كان غرابا ففيها وجهان.", "قال أحدهما.")
    assert (u52.opening, u52.furu) == ("بيع العطاء.", ("بيع الصكاك.", "بيع المغانم."))
    assert u8.furu == ("كذا أيضا. (الصورة الثانية) ليست فرعا هنا.",)


def test_opening_after_fa_min_suwar():
    q13 = sec("(القاعدة الثالثة عشرة) :", "في المسألة خلاف ولها صور كثيرة.\nفمن صور المسألة) ما إذا وقع في الماء نجاسة.\n(ومنها) ما إذا وجد من النائم بللا.")
    (u,) = segment_headed((q13,), marker="القاعدة")
    assert (u.opening, u.furu) == ("ما إذا وقع في الماء نجاسة.", ("ما إذا وجد من النائم بللا.",))


def test_feminine_ordinal_case_lists():
    """With no «(و)منها» and no «الصورة/المسألة», a list of cases by feminine ordinal is cut
    as a chain 1, 2, …: for each k the case starts at the last k-mark before the first
    (k+1)-mark, so a riwāya's «(والثانية)» stays inside its case."""
    q1 = sec("(القاعدة الأولى)", "الماء الجاري فيه خلاف ينبني عليه مسائل: (أحدها) لو وقعت فيه نجاسة\nفيه روايتان\n(والثانية) : المذهب عند القاضي\nوالثانية: لو غمس الإناء النجس\n(والثالثة) : لو انغمس المحدث")
    q93 = sec("(القاعدة الثالثة والتسعون) :", "من قبض مغصوبا من غاصبه.\n(الأولى) الغاصبة يتعلق بها الضمان\n(والثانية) : الآخذة لمصلحة الدافع\nأحدهما: كذا.\n(اليد الثالثة) القابضة لمصلحتها")
    u1, u93 = segment_headed((q1, q93), marker="القاعدة")
    assert u1.opening == "لو وقعت فيه نجاسة فيه روايتان (والثانية) : المذهب عند القاضي"
    assert u1.furu == ("لو غمس الإناء النجس", "لو انغمس المحدث")
    assert (u93.opening, u93.furu) == (None, ("الغاصبة يتعلق بها الضمان", "الآخذة لمصلحة الدافع أحدهما: كذا.", "القابضة لمصلحتها"))


def test_divisions_after_an_announcement():
    """Divisions: «النوع/القسم/الضرب/الحالة/المقرر <ordinal>», or a bare «(و)الثاني:» when the
    qāʿida announces them («نوعان:», «على قسمين:», «ثلاثة أشياء:»). The first division,
    announced in the prelude, is the opening; a second «والثاني:» (a wajh) inside the last
    division does not cut."""
    q66 = sec("(القاعدة السادسة والستون) :", "ولو تصرف مستندا إلى سبب ثم تبين خطؤه فهو نوعان:\nأحدهما: أن يكون الاستناد صحيحا.\nوالثاني: أن لا يكون صحيحا\nأحدهما: يبرأ.\nوالثاني: لا يبرأ.")
    q152 = sec("(القاعدة الثانية والخمسون بعد المائة) :", "المحرمات في النكاح أربعة أنواع:\nالنوع الأول: المحرمات بالنسب.\n[النوع الثاني المحرمات بالصهر]\n، وهن أقارب الزوجين")
    q135 = sec("(القاعدة الخامسة والثلاثون بعد المائة) :", "الملك القاصر لا يستباح فيه الوطء.\nوأما المرهونة فلوجهين:\nأحدهما كذا.\nوالثاني: كذا.")
    u66, u152, u135 = segment_headed((q66, q152, q135), marker="القاعدة")
    assert (u66.opening, u66.furu) == ("أن يكون الاستناد صحيحا.", ("أن لا يكون صحيحا أحدهما: يبرأ. والثاني: لا يبرأ.",))
    assert (u152.opening, u152.furu) == (None, ("المحرمات بالنسب.", "المحرمات بالصهر] ، وهن أقارب الزوجين"))
    assert (u135.opening, u135.furu) == (None, ())  # two wujūh, not announced divisions
