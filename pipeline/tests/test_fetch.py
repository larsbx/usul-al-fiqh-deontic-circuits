import urllib.error

import pytest

from usul_corpus import fetch as fetch_mod
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


@pytest.mark.parametrize("err", [ConnectionResetError(104, "reset"), urllib.error.URLError("down"), TimeoutError()])
def test_get_retries_transient_failures(monkeypatch, err):
    """A reset or timeout mid-book is retried; one dropped page must not lose an hours-long fetch."""
    calls = []

    class Resp:
        def __enter__(self): return self
        def __exit__(self, *a): return False
        def read(self): return b"ok"

    def urlopen(req, timeout):
        calls.append(req)
        if len(calls) == 1:
            raise err
        return Resp()

    monkeypatch.setattr(fetch_mod.urllib.request, "urlopen", urlopen)
    monkeypatch.setattr(fetch_mod.time, "sleep", lambda s: None)
    assert fetch_mod._get("https://example.invalid/") == b"ok" and len(calls) == 2


def test_get_does_not_retry_client_errors(monkeypatch):
    def urlopen(req, timeout):
        raise urllib.error.HTTPError("u", 404, "nf", {}, None)

    monkeypatch.setattr(fetch_mod.urllib.request, "urlopen", urlopen)
    with pytest.raises(urllib.error.HTTPError):
        fetch_mod._get("https://example.invalid/")
