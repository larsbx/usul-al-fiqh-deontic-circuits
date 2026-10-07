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
