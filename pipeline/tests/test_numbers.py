import pytest

from usul_corpus.numbers import is_numbered_start, read_number, with_number
from usul_corpus.segment import _repair


@pytest.mark.parametrize(
    "raw, digits",
    [
        ("۱.0", "105"),        # ٠ is a dot, ٥ a circle: the classic Arabic-Indic confusions
        ("\\ .۷", "07"),        # 107 with its leading ١ lost
        ("\\-۸", "8"),
        ("۱۹", "19"),
        ("١٠٢", "102"),
        ("الله", None),        # a word, not a number
        ("", None),
    ],
)
def test_read_number_maps_confusable_glyphs(raw, digits):
    assert read_number(raw) == digits


def test_repair_prefers_the_longest_suffix_within_the_step():
    assert _repair("105", 104, max_step=4) == 105
    assert _repair("07", 105, max_step=4) == 107     # 07 → …07
    assert _repair("19", 108, max_step=4) == 109     # «١٩» lost its ٠: 119 is too far, last digit 9 fits
    assert _repair("8", 107, max_step=4) == 108


def test_is_numbered_start_and_with_number():
    assert is_numbered_start("4 - يؤمر المؤمنون أن يقابلوا")
    assert is_numbered_start("7 ـ البغي يصرع في الدنيا")
    assert is_numbered_start("بر - مالم يك")
    assert is_numbered_start("1١ والصلاح منحصر في نوعين")     # separator dropped by OCR
    assert is_numbered_start("-١ ولابد من العلم")              # dash read before the digit
    assert is_numbered_start("- وإذا كان الإعطاء لدفع ضرر")    # digits lost, dash kept
    assert not is_numbered_start("فالعلم النافع: هو الإيمان")
    assert not is_numbered_start("البقرة الآية:1487) .")       # digits later in the line don't count
    assert with_number("4 - يؤمر المؤمنون", "105") == "١٠٥ - يؤمر المؤمنون"
    assert with_number("7 ـ البغي يصرع", "07") == "٠٧ - البغي يصرع"
    assert with_number("1١ والصلاح منحصر", "105") == "١٠٥ - والصلاح منحصر"
    assert with_number("-١ ولابد من العلم", "106") == "١٠٦ - ولابد من العلم"
    assert with_number("- وإذا كان الإعطاء", "100") == "١٠٠ - وإذا كان الإعطاء"


def test_number_span_is_everything_right_of_the_dash():
    from usul_corpus.numbers import Glyph, number_span

    # measured on PDF p. 30, line «١٠٥ ـ والصلاح»: (x0, x1, height)
    line = [Glyph(1326, 1331, 30), Glyph(1334, 1354, 26),        # «والصلاح» …
            Glyph(1373, 1392, 6),                                # ـ  flat dash
            Glyph(1418, 1429, 32), Glyph(1451, 1457, 6), Glyph(1477, 1494, 24)]   # ١ ٠ ٥
    assert number_span(line) == (1392, 1494)


def test_number_span_requires_a_dash_near_the_right_edge():
    from usul_corpus.numbers import Glyph, number_span

    prose = [Glyph(1300, 1380, 40), Glyph(1400, 1500, 45), Glyph(1520, 1585, 38)]
    assert number_span(prose) is None
    dot_not_dash = [Glyph(1400, 1406, 6), Glyph(1430, 1450, 30)]      # «٠» is a square dot, not a dash
    assert number_span(dot_not_dash) is None


def test_full_length_reads_anchor_the_chain_across_larger_gaps():
    # «٨٢٤» read in full after 805: an anchor 19 ahead, beyond the modular step
    assert _repair("824", 805, max_step=4, anchor_step=30) == 824
    # a partial read falls back to modular repair within the small step
    assert _repair("7", 805, max_step=4, anchor_step=30) == 807
    # a full-length read too far ahead is not an anchor (likely a misread)
    assert _repair("981", 805, max_step=4, anchor_step=30) > 805 + 30


def test_segment_numbered_recovers_after_a_run_of_lost_numbers():
    from usul_corpus.segment import segment_numbered

    text = "\n".join(f"# {d} - فقرة\n# شرح" for d in ["١", "٢", "٣", "٢٤", "٢٥"])   # 4..23 lost to OCR
    assert [u.number for u in segment_numbered(text, anchor_step=30)] == [1, 2, 3, 24, 25]
    assert [u.number for u in segment_numbered(text)] == [1, 2, 3, 4, 5]      # unanchored: modular only


def test_partial_reads_never_take_long_steps_even_when_anchoring_is_on():
    from usul_corpus.segment import segment_numbered

    # after 10, «٤» is a partial read (one digit where two are due): 14 is beyond the
    # modular step, so it is dropped rather than taken as a long jump; «٣٠» is a full read
    text = "\n".join(f"# {d} - فقرة\n# شرح" for d in ["٨", "٩", "١٠", "٤", "٣٠"])
    assert [u.number for u in segment_numbered(text, anchor_step=30)] == [8, 9, 10, 30]


def test_components_finds_glyphs_left_to_right_and_drops_specks():
    import numpy as np

    from usul_corpus.numbers import components

    a = np.zeros((20, 40), dtype=bool)
    a[5:15, 2:4] = True          # «١»: a vertical bar
    a[9:11, 12:14] = True        # «٠»: a small dot (4 px)
    a[5:15, 25:31] = True        # a block
    a[0, 39] = True              # 1-px speck
    got = [(c.x0, c.x1, c.y0, c.y1) for c in components(a, min_area=3)]
    assert got == [(2, 4, 5, 15), (12, 14, 9, 11), (25, 31, 5, 15)]


def test_nearest_template_classifies_by_shape_and_relative_size():
    import numpy as np

    from usul_corpus.numbers import Templates, components

    def glyph(kind):
        a = np.zeros((40, 40), dtype=bool)
        if kind == "1":
            a[5:35, 18:22] = True                       # tall bar
        elif kind == "0":
            a[18:22, 18:22] = True                      # small dot
        else:
            a[5:35, 10:30] = True; a[12:28, 16:24] = False  # ring
        return components(a, min_area=3)[0], 40

    t = Templates.fit([(glyph(k), k) for k in "105"])
    assert [t.classify(*glyph(k)) for k in "015"] == list("015")


def test_confirmed_labels_are_exact_full_reads_on_the_chain():
    from usul_corpus.numbers import confirmed_labels

    reads = ["1", "2", "70", "4", "070", "6"]
    chain = [(0, 1, False), (1, 2, False), (3, 4, False), (4, 70, False), (5, 6, False)]
    # index 2 is off-chain; index 4 reads «070» for 70: same value, wrong digit count
    assert confirmed_labels(reads, chain) == [(0, "1"), (1, "2"), (3, "4"), (5, "6")]


def test_attach_bands_borrows_lines_the_chosen_read_dropped():
    from usul_corpus.numbers import attach_bands
    from usul_corpus.ocr import Line

    chosen = (Line("سطر قبل", 90, 385, 447), Line("الشرائع لا", 88, 591, 669))
    other = (Line("فما أخبرت به", 80, 496, 570), Line("الشرائع لا", 85, 595, 665))
    bands = [(193, 249), (501, 563)]                        # 193: a numbered band no read has a line for
    lines, idx = attach_bands(chosen, other, bands)
    assert [l.text for l in lines] == ["", "سطر قبل", "فما أخبرت به", "الشرائع لا"]
    assert idx == [0, 2]                                     # band → index into the returned lines
    assert (lines[0].top, lines[0].bottom) == (193, 249)


def test_number_chain_keeps_alternative_values_per_line():
    from usul_corpus.segment import number_chain

    # «13» misread for 4 tempts an anchor jump; later exact reads 5..8 must win back
    reads = ["1", "2", "3", "13", "5", "6", "7", "8"]
    assert [n for _, n, _ in number_chain(reads, anchor_step=30)] == [1, 2, 3, 5, 6, 7, 8]
