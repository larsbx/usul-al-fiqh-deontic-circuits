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
    text = "مقدمة\nالقاعدة الأولى\nالنية\nالقاعدة الثااثون\nكذا\nالقاعدة الثانية والثالثة والعشرون\nكذا"
    units = segment_lines(text, marker="القاعدة")
    assert [(u.number, u.ocr_corrected) for u in units] == [(1, False), (30, True), (None, False)]
    assert units[2].heading == "القاعدة الثانية والثالثة والعشرون"


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
