import pytest

from usul_corpus.arabic import normalize, parse_ordinal


@pytest.mark.parametrize(
    "raw, expected",
    [
        ("اصطلاحاً", "اصطلاحا"),          # tanwīn stripped
        ("الأُولَى", "الاولي"),            # hamza-alif + alif maqṣūra unified
        ("القاعـــدة", "القاعده"),          # tatweel stripped, tāʾ marbūṭa unified
        ("١٤٣٠", "1430"),                  # Arabic-Indic digits
        ("۱۱۹۰٩", "11909"),                # Persian digits
        ("  a‏b  ", "ab"),            # bidi marks and outer space
    ],
)
def test_normalize(raw, expected):
    assert normalize(raw) == expected


def test_normalize_is_idempotent():
    s = "القاعدة الحادية والعشرون بعد المائة"
    assert normalize(normalize(s)) == normalize(s)


@pytest.mark.parametrize(
    "phrase, n",
    [
        ("الأولى", 1),
        ("الثانية", 2),
        ("العاشرة", 10),
        ("الحادية عشرة", 11),
        ("الرابعة عشر", 14),                       # masculine ʿashar as printed
        ("العشرون", 20),
        ("الحادية والعشرون", 21),
        ("الثالثة والتسعون", 93),
        ("المائة", 100),
        ("الحادية بعد المائة", 101),
        ("الثامنة والأربعون بعد المائة", 148),
        ("الخامسة والخمسون  بعد المائة", 155),
        ("الستون بعد المائة", 160),
        ("الأول", 1),                               # masculine (masʾala)
    ],
)
def test_parse_ordinal(phrase, n):
    assert parse_ordinal(phrase) == (n, False)


@pytest.mark.parametrize("phrase", ["", "فصل", "الثانية والثالثة والعشرون", "الأولى الثانية"])
def test_parse_ordinal_rejects_unknown_or_ambiguous(phrase):
    assert parse_ordinal(phrase) is None


def test_parse_ordinal_fuzzy_marks_ocr_correction():
    # OCR variants observed in the al-Saʿdī scan: الثااثون, الثلاتون
    assert parse_ordinal("الثااثون") == (30, True)
    assert parse_ordinal("الحادية والثلاتون") == (31, True)
    assert parse_ordinal("الثااثون", fuzzy=False) is None


def test_parse_ordinal_span_joint_headings():
    from usul_corpus.arabic import parse_ordinal_span

    assert parse_ordinal_span("الثانية والثالثة والعشرون") == ((22, 23), False)
    assert parse_ordinal_span("الرابعة والخامسة") == ((4, 5), False)
    assert parse_ordinal_span("الحادية عشرة") == ((11, 11), False)
    assert parse_ordinal_span("الأولى والثالثة") is None        # not consecutive


def test_revolume_numbers_shamela_volumes_at_page_resets():
    """Shamela fetches mark every page V01; a page number that goes back starts a new volume."""
    from usul_corpus.arabic import revolume
    t = "أ\nPageV01P001\nب\nPageV01P002\nPageV01P002\nج\nPageV01P001\nد\nPageV01P003\n"
    assert revolume(t) == "أ\nPageV01P001\nب\nPageV01P002\nPageV01P002\nج\nPageV02P001\nد\nPageV02P003\n"


def test_revolume_leaves_real_volume_markers_alone():
    from usul_corpus.arabic import revolume
    t = "PageV04P721\nPageV04P722\nPageV01P001\n"   # OpenITI: volumes already explicit
    assert revolume(t) == t


def test_locate_reads_the_volume():
    from usul_corpus.arabic import locate
    t = "أول\nPageV01P009\nكلمة بعد البداية\nPageV01P001\n"
    assert locate(t, "كلمة بعد البداية") == "v02:p001"


def test_revolume_matches_shamela_on_al_irwa():
    """Spot check against Shamela's own volume field (fld_part_top) for page ids 1, 500, 2000,
    2927 of book 22592 (read 2026-10-09): 1, 2, 6, 8. Skipped where the witness is not cached."""
    import re
    from pathlib import Path
    from usul_corpus.arabic import revolume
    src = Path(__file__).parents[2] / ".cache/corpus/shamela-22592.txt"
    if not src.exists():
        pytest.skip("al-Irwāʾ not cached")
    vols = [int(m.group(1)) for m in re.finditer(r"PageV(\d+)P\d+", revolume(src.read_text(encoding="utf-8")))]
    assert [vols[i - 1] for i in (1, 500, 2000, 2927)] == [1, 2, 6, 8]
