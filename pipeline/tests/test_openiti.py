from usul_corpus.openiti import parse_markdown, Section

SAMPLE = """######OpenITI#
#META# 020.BookTITLE	:: القواعد
#META#Header#End#

# PageV00P000
### | [خطبة المؤلف]
# الحمد لله
~~رب العالمين.
PageV01P001
### | (القاعدة الأولى)
# الماء الجاري لا ينجس إلا بالتغير
### || مسائل من ذلك
# ومنها كذا
PageV01P002
# ومنها كذا وكذا
PageV01P003
"""


def test_page_markers_close_pages_openiti_convention():
    # OpenITI places PageVxxPyyy at the *end* of page yyy.
    secs = parse_markdown(SAMPLE)
    assert secs[0].page == (1, 1)
    assert secs[1].page == (1, 2)
    assert (secs[2].page, secs[2].end_page) == ((1, 2), (1, 3))


def test_parse_markdown_sections_levels():
    secs = parse_markdown(SAMPLE)
    assert [(s.level, s.title) for s in secs] == [
        (1, "[خطبة المؤلف]"),
        (1, "(القاعدة الأولى)"),
        (2, "مسائل من ذلك"),
    ]


def test_parse_markdown_joins_continuations():
    secs = parse_markdown(SAMPLE)
    assert secs[0].text == "الحمد لله رب العالمين."


def test_sections_are_immutable():
    sec = parse_markdown(SAMPLE)[0]
    assert isinstance(sec, Section)
    try:
        sec.title = "x"  # type: ignore[misc]
    except AttributeError:
        return
    raise AssertionError("Section must be frozen")


def test_metadata_header_is_skipped():
    assert all("META" not in s.text for s in parse_markdown(SAMPLE))
