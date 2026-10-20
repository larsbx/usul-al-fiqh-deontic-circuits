import http.client
import urllib.error

import pytest

from usul_corpus import fetch as fetch_mod
from usul_corpus.fetch import merge_lock, next_page_id, shamela_page_to_markdown, witness_url
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
    assert witness_url({"kind": "url", "url": "https://example.org/a.doc"}) == "https://example.org/a.doc"


def test_doc_witness_is_converted_beside_the_locked_original(tmp_path, monkeypatch):
    """A Word witness: the lock pins the downloaded .doc; readers use the UTF-8 text beside it."""
    import usul_corpus.fetch as F
    calls = []
    monkeypatch.setattr(F, "_get", lambda url: b"DOC")
    monkeypatch.setattr(F, "doc_to_text", lambda doc: calls.append(doc) or doc.with_suffix(".txt"))
    w = {"id": "x-doc", "kind": "url", "url": "https://example.org/a.doc", "format": "doc"}
    entry = F.fetch(w, tmp_path)
    assert (tmp_path / "x-doc.doc").read_bytes() == b"DOC" and calls == [tmp_path / "x-doc.doc"]
    assert entry["bytes"] == 3 and entry["url"] == "https://example.org/a.doc"


@pytest.mark.parametrize("err", [ConnectionResetError(104, "reset"), urllib.error.URLError("down"), TimeoutError(),
                                 http.client.IncompleteRead(b"")])
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


def _book(n):
    """A fake Shamela book of `n` pages, ids 1…n, each linking to the next."""
    return {i: ('<div class="nass" data-page-id="%d" data-page-num="%d"><p>ص %d</p></div>' % (i, i, i)
                + ('<button id="bu_load_next" data-next-id="%d">' % (i + 1) if i < n else ""))
            for i in range(1, n + 1)}


def test_shamela_fetch_resumes_after_a_crash(monkeypatch, tmp_path):
    """Pages are checkpointed as they arrive: a crash (or container restart) mid-book resumes at
    the next page, and the result is byte-identical to an uninterrupted fetch."""
    book, served, die_at = _book(4), [], {3}
    monkeypatch.setattr(fetch_mod.time, "sleep", lambda s: None)

    def get(url, backoff=()):
        page = int(url.rsplit("/", 1)[1])
        if page in die_at:
            die_at.clear()
            raise RuntimeError("container restarted")
        served.append(page)
        return book[page].encode()

    monkeypatch.setattr(fetch_mod, "_get", get)
    w = {"id": "shamela-1", "kind": "shamela", "book_id": 1}
    with pytest.raises(RuntimeError):
        fetch_mod.fetch(w, tmp_path)
    assert not (tmp_path / "shamela-1.txt").exists()
    resumed = fetch_mod.fetch(w, tmp_path)
    assert served == [1, 2, 3, 4]                      # pages 1–2 were not fetched twice
    assert not list(tmp_path.glob("*.part"))
    clean = tmp_path / "clean"
    assert fetch_mod.fetch(w, clean)["sha256"] == resumed["sha256"]


def test_merge_lock_keeps_derived_hashes_while_the_content_is_unchanged():
    old = {"witness": "w", "url": "u", "bytes": 3, "sha256": "aa", "ocr_sha256": "oo"}
    assert merge_lock(old, {"witness": "w", "url": "u", "bytes": 3, "sha256": "aa"}) == (old, False)
    new = {"witness": "w", "url": "u", "bytes": 4, "sha256": "bb"}
    assert merge_lock(old, new) == (new, True)  # derived hashes describe the old bytes: dropped
    assert merge_lock(None, new) == (new, False)


def test_concurrent_pins_are_not_lost(tmp_path, monkeypatch):
    """Two fetches pinning at once both land in lock.json (problem register PR-20)."""
    import json
    import threading
    from usul_corpus import __main__ as cli
    monkeypatch.setattr(cli, "CORPUS", tmp_path)
    (tmp_path / "lock.json").write_text('{"witnesses": {}}')
    ts = [threading.Thread(target=cli._pin, args=(f"w{i}", {"sha256": str(i)})) for i in range(8)]
    for t in ts:
        t.start()
    for t in ts:
        t.join()
    assert set(json.loads((tmp_path / "lock.json").read_text())["witnesses"]) == {f"w{i}" for i in range(8)}


def test_an_incomplete_read_is_retried_then_reported_as_a_connection_error(monkeypatch):
    """Audit (low): `http.client.IncompleteRead` escaped the source gate without a report."""
    import http.client
    calls = []

    def urlopen(req, timeout):
        calls.append(req)
        raise http.client.IncompleteRead(b"partial")

    monkeypatch.setattr(fetch_mod.urllib.request, "urlopen", urlopen)
    monkeypatch.setattr(fetch_mod.time, "sleep", lambda s: None)
    with pytest.raises(ConnectionError, match="IncompleteRead"):
        fetch_mod._get("https://example.invalid/")
    assert len(calls) == 5  # the first try and four retries


def test_a_checkpoint_cut_short_resumes_from_its_last_whole_page(monkeypatch, tmp_path):
    """Audit (low): a corrupt `.part` blocked every later fetch. A write cut short leaves a broken last
    line; the pages before it are kept and the rest is discarded."""
    book, served = _book(4), []
    monkeypatch.setattr(fetch_mod.time, "sleep", lambda s: None)

    def get(url, backoff=()):
        served.append(int(url.rsplit("/", 1)[1]))
        return book[served[-1]].encode()

    monkeypatch.setattr(fetch_mod, "_get", get)
    w = {"id": "shamela-1", "kind": "shamela", "book_id": 1}
    clean = fetch_mod.fetch(w, tmp_path / "clean")
    served.clear()
    part = tmp_path / "shamela-1.part"
    first = fetch_mod._checkpoint_line(fetch_mod.shamela_page_to_markdown(book[1]), 2)
    part.write_bytes(first.encode() + b'{"md": "\xd8')  # a second page whose write was cut short
    assert fetch_mod.fetch(w, tmp_path)["sha256"] == clean["sha256"]
    assert served == [2, 3, 4]
    # Review (#101): a readable line without its next page is no whole page either.
    served.clear()
    (tmp_path / "shamela-1.txt").unlink()
    part.write_bytes(first.encode() + b'{"md": "page"}\n')
    assert fetch_mod.fetch(w, tmp_path)["sha256"] == clean["sha256"]
    assert served == [2, 3, 4]


def _epub(pages: dict[str, str], spine: list[str]) -> bytes:
    import io
    import zipfile
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w") as z:
        z.writestr("OEBPS/content.opf", "<package><manifest>"
                   + "".join(f'<item id="{p}" href="xhtml/{p}.xhtml"/>' for p in pages)
                   + "</manifest><spine>" + "".join(f'<itemref idref="{p}"/>' for p in spine) + "</spine></package>")
        for p, body in pages.items():
            z.writestr(f"OEBPS/xhtml/{p}.xhtml", body)
    return buf.getvalue()


def _epub_page(text: str, part: int, page: int) -> str:
    return (f'<body><div dir="rtl" id="book-container"><hr/><a id="C1"></a>{text}</div><hr/>'
            f'<div class="center">الجزء: {part} ¦ الصفحة: {page}</div></body>')


def test_an_old_shamela_epub_reads_in_spine_order_as_markdown():
    """Old Shamela's epubs (the Nūr al-Islām gradings of the Sunan): one line per <br />, a page marker
    closing each page, pages in the spine's order, not the archive's."""
    from usul_corpus.fetch import shamela_epub_to_markdown
    epub = _epub({"P2": _epub_page("12 حدثنا &amp; قال<br /><br />تحقيق الألباني:<br />صحيح، الإرواء (88)", 1, 2),
                  "P1": _epub_page("(سنن ابن ماجة)<br />11 حدثنا", 1, 1), "info": "<body>الكتاب</body>"},
                 ["info", "P1", "P2"])
    assert shamela_epub_to_markdown(epub).splitlines() == [
        "#META#Header#End#", "# (سنن ابن ماجة)", "# 11 حدثنا", "PageV01P001",
        "# 12 حدثنا & قال", "# تحقيق الألباني:", "# صحيح، الإرواء (88)", "PageV01P002"]
    assert witness_url({"kind": "shamela_epub", "book_id": 810}) == "https://old.shamela.ws/epubs/008/810.epub"
    assert witness_url({"kind": "shamela_epub", "book_id": 1755}) == "https://old.shamela.ws/epubs/017/1755.epub"
