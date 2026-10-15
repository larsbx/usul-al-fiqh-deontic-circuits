from usul_corpus.ocr import Line, parse_tsv
from usul_corpus.verses import Band, bands_from_rows, inner_gap, is_verse, merge_verses, verse_line

# Measured on the Sharḥ Manẓūma scan at 300 dpi (PDF pages 42 and 339).
VERSE = Band(2617, 2684, 502, 2003, 1147, 1269)        # «٥ - وبعد فالعلم … ‹gap› لن يبلغ …»
PROSE = Band(1558, 1625, 496, 2002, 785, 817)          # justified commentary: word gap only
HEADER = Band(483, 530, 487, 1922, 841, 1790)          # running head: page number far from title
SHORT = Band(1017, 1058, 1746, 1998, 1883, 1909)       # last line of a paragraph
TEXT_WIDTH = 1510


def test_is_verse_separates_verse_lines_from_prose_headers_and_short_lines():
    assert is_verse(VERSE, TEXT_WIDTH)
    assert not any(is_verse(b, TEXT_WIDTH) for b in (PROSE, HEADER, SHORT))


def test_bands_from_rows_merges_ink_runs_and_drops_specks():
    rows = [0] * 5 + [9] * 30 + [0] * 3 + [9] * 2 + [0] * 10 + [7] * 25 + [0] * 4
    assert bands_from_rows(rows, min_ink=5, min_height=20) == [(5, 35), (50, 75)]


def test_inner_gap_finds_widest_blank_run_between_first_and_last_ink():
    cols = [False] * 3 + [True] * 10 + [False] * 4 + [True] * 5 + [False] * 12 + [True] * 8 + [False] * 2
    assert inner_gap(cols) == (3, 41, 22, 34)          # (left, right, gap start, gap end)
    assert inner_gap([False, False]) is None


def test_verse_line_reads_right_hemistich_first_with_separator():
    line = verse_line(Line("٨٩ - والأصل في القيد احتراز ويقل", 88.0), Line("لغيره ككشف تعليل جهل", 82.0), top=675, bottom=761)
    assert line.text == "٨٩ - والأصل في القيد احتراز ويقل * لغيره ككشف تعليل جهل"
    assert (line.conf, line.top, line.bottom) == (85.0, 675, 761)


def test_merge_verses_replaces_overlapping_garbled_lines_in_reading_order():
    lines = (
        Line("سطر قبل البيت", 90.0, 500, 560),
        Line("بدلية الشع ل ات", 30.0, 2620, 2680),      # tesseract's garbled reading of the verse
        Line("قوله: (وبعد)", 92.0, 2700, 2760),
    )
    verse = Line("٥ - وبعد فالعلم بحور زاخرة * لن يبلغ الكادح فيه آخره", 80.0, 2617, 2684)
    assert [l.text for l in merge_verses(lines, (verse,))] == ["سطر قبل البيت", verse.text, "قوله: (وبعد)"]


def test_parse_tsv_keeps_vertical_extent():
    tsv = "\n".join([
        "level\tpage_num\tblock_num\tpar_num\tline_num\tword_num\tleft\ttop\twidth\theight\tconf\ttext",
        "5\t1\t1\t1\t1\t1\t900\t120\t80\t40\t90\tقال",
        "5\t1\t1\t1\t1\t2\t800\t110\t70\t60\t80\tالله",
    ])
    (line,) = parse_tsv(tsv)
    assert (line.top, line.bottom) == (110, 170)


def test_segment_verse_block_numbers_the_first_block_by_position():
    from usul_corpus.verses import segment_verse_block

    text = "\n".join([
        "# متن منظومة أصول الفقه",
        "# -١ الحمد لله المعيد المبدي * معطي النوال كل من يستجدي",
        "# ٢ - مثبت الأحكام بالأصول * معين من يصبو إلى الوصول",
        "PageV01P023",
        "# الصفحة 24",                                                # running head between pages
        "# بر ثم الصلاة مع سلام قد تم * على الذي أعطي جوامع الكلم",     # number unreadable
        "# ٧ - محمد المبعوث رحمة الورى * وخير هاد لجميع من ذرى",       # printed digit disagrees
        "PageV01P024",
        "# قوله: (المعيد المبدي): هذان الوصفان",                      # commentary: block ends
        "# قوله: كلام آخر",
        "# ثم شرح طويل",
        "# ١ - الحمد لله المعيد المبدي * معطي النوال كل من يستجدي",   # verse quoted in the sharḥ
    ])
    units = segment_verse_block(text)
    assert [u.number for u in units] == [1, 2, 3, 4]
    assert units[0].heading == "الحمد لله المعيد المبدي * معطي النوال كل من يستجدي"
    assert [u.ocr_corrected for u in units] == [False, False, True, True]   # True: number from position only
    assert [u.page for u in units] == [(1, 23), (1, 23), (1, 24), (1, 24)]


def test_verse_text_strips_unreadable_number_prefix():
    from usul_corpus.verses import verse_text

    assert verse_text("٨٩ - والأصل في القيد * لغيره") == ("والأصل في القيد * لغيره", "89")
    assert verse_text("بر ثم الصلاة * على الذي") == ("ثم الصلاة * على الذي", "")
    assert verse_text("-١ الحمد لله * معطي") == ("الحمد لله * معطي", "1")


def test_segment_verse_block_takes_the_longest_block_not_the_first():
    from usul_corpus.verses import segment_verse_block

    early = ["# عضوا في هيئة كبار العلماء * من عام", "# عضوا في المجلس العلمي * بجامعة الإمام"]
    gap = ["# نص نثري", "# نص نثري آخر", "# ونص ثالث"]
    matn = [f"# بيت رقم {k} في المتن * وعجزه {k}" for k in range(1, 6)]
    units = segment_verse_block("\n".join(early + gap + matn))
    assert [u.number for u in units] == [1, 2, 3, 4, 5]
    assert units[0].heading.startswith("بيت رقم 1")


def test_page_level_bar_split_counts_as_a_verse_line():
    from usul_corpus.verses import as_verse, segment_verse_block

    assert as_verse("٠١ مالم يكن متصفا بوصف | يفيد علة فخذ بالوصف") == "٠١ مالم يكن متصفا بوصف * يفيد علة فخذ بالوصف"
    assert as_verse("الموضوع | الصفحة") is None                     # one word a side: not a bayt
    assert as_verse("قوله: كلام بلا فاصل") is None
    text = "\n".join([
        "# واعتبر العموم في نص أثر * ما خصوص سبب فما اعتبر",
        "# ٠١ مالم يكن متصفا بوصف | يفيد علة فخذ بالوصف",
        "# وخصص العام بخاص وردا * كقيد مطلق بما قد قيدا",
    ])
    assert [u.heading[:8] for u in segment_verse_block(text)] == ["واعتبر ا", "مالم يكن", "وخصص الع"]


def test_trigram_similarity_ignores_diacritics_and_ocr_marks():
    from usul_corpus.verses import similarity

    assert similarity("والأصلُ في القيدِ احترازٌ", "والاصل في القيد احتراز") == 1.0
    assert similarity("الحمد لله المعيد المبدي", "كتاب الصلاة باب الأذان") < 0.1


def test_link_commentary_aligns_sharh_quotations_to_matn_verses():
    from usul_corpus.verses import link_commentary

    matn = [
        "# الحمد لله المعيد المبدي * معطي النوال كل من يستجدي",
        "# مثبت الأحكام بالأصول * معين من يصبو إلى الوصول",
        "# ثم الصلاة مع سلام قد تم * على الذي أعطي جوامع الكلم",
        "PageV01P027",
        "# مقدمة الشرح", "# الحمد لله وحده", "# أما بعد فهذا شرح",   # prose separates matn and sharḥ
        "PageV01P028",
    ]
    sharh = [
        "# الحمد لله المعيد المبدي * معطي النوال كل من يستجدي",       # verse 1 quoted
        "# قوله: (المعيد المبدي): هذان الوصفان",
        "# مأخوذان من قوله تعالى", "# وفيه براعة استهلال",
        "PageV01P029",
        "# قال الشاعر في غير المنظومة * بيت لا صلة له",               # another poem: below threshold
        "# شرح متصل", "# ثم شرح آخر", "# وتتمة الشرح",
        "# الحمد لله المعيد المبدي * معطي النوال",                     # re-quote of verse 1: out of order
        "# شرح متصل", "# ثم شرح آخر", "# وتتمة الشرح",
        "# ثم الصلاة مع سلام قد تم * على الذي أعطي جوامع الكلم",       # verse 3 (verse 2's commentary lost)
        "# قوله: (جوامع الكلم)",
        "PageV01P031",
    ]
    links = link_commentary("\n".join(matn + sharh))
    assert [(l.number, l.page, l.end_page) for l in links] == [(1, (1, 29), (1, 31)), (3, (1, 31), (1, 31))]
    assert links[0].commentary.startswith("قوله: (المعيد المبدي)")
    assert "قال الشاعر" in links[0].commentary          # unlinked lines stay inside the running commentary
    assert links[1].similarity == 1.0


def test_last_commentary_stops_at_the_index():
    from usul_corpus.verses import link_commentary

    text = "\n".join([
        "# الحمد لله المعيد المبدي * معطي النوال كل من يستجدي",
        "# مثبت الأحكام بالأصول * معين من يصبو إلى الوصول",
        "PageV01P027",
        "# مقدمة", "# تمهيد", "# أما بعد",
        "# مثبت الأحكام بالأصول * معين من يصبو إلى الوصول",
        "# قوله: (بالأصول)",
        "PageV01P368",
        "# فهرس الموضوعات",
        "# الموضوع الصفحة",
        "PageV01P372",
    ])
    (link,) = link_commentary(text)
    assert link.end_page == (1, 368) and "فهرس" not in link.commentary
