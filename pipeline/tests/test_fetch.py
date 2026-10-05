from usul_corpus.fetch import next_page_id, shamela_page_to_markdown, witness_url
from usul_corpus.openiti import parse_markdown

PAGE = (
    '<div class="nass margin-top-10" data-page-id="5" data-page-num="10">'
    '<p><span id="p1" class="anchor"></span><span class="c4">[الأحكام]</span><a href="#p1"><span>x</span></a></p>'
    '<p><span class="c5">الأحكام:</span> جمع حُكم وهو لغةً: القضاء.</p>'
    "</div>"
    '<button id="bu_load_next" data-next-id="6" data-book-id="9942">'
)


def test_shamela_page_to_markdown_round_trips_through_openiti_parser():
    md = shamela_page_to_markdown(PAGE)
    assert md.splitlines()[-1] == "PageV01P010"  # OpenITI: marker closes the page
    (sec,) = parse_markdown(md)
    assert (sec.level, sec.title, sec.page) == (1, "[الأحكام]", (1, 10))
    assert sec.text == "الأحكام: جمع حُكم وهو لغةً: القضاء."


def test_next_page_id():
    assert next_page_id(PAGE) == 6
    assert next_page_id("<div></div>") is None


def test_witness_urls_are_pinned():
    oi = {"kind": "openiti", "repo": "0800AH", "commit": "abc", "path": "data/x/y"}
    assert witness_url(oi) == "https://raw.githubusercontent.com/OpenITI/0800AH/abc/data/x/y"
    ar = {"kind": "archive", "item": "Pdf1995", "file": "a b.txt"}
    assert witness_url(ar) == "https://archive.org/download/Pdf1995/a%20b.txt"
    assert witness_url({"kind": "shamela", "book_id": 9942}) == "https://shamela.ws/book/9942/1"
