"""Fetch pinned witnesses into a local cache and record a content lock.

Every witness is normalised to OpenITI mARkdown (or plain text for OCR) so the
downstream parser is shared (one reader, many sources).
"""

from __future__ import annotations

import contextlib
import hashlib
import html
import http.client
import json
import re
import time
import urllib.error
import urllib.parse
import urllib.request
import zipfile
from io import BytesIO
from pathlib import Path

USER_AGENT = "usul-corpus-pipeline/1 (research; +https://github.com/larsbx/usul-al-fiqh-deontic-circuits)"
SHAMELA_DELAY_S = 0.5

_NASS = re.compile(r'<div class="nass[^"]*" data-page-id="(\d+)" data-page-num="(\d+)">(.*?)</div>', re.S)
_NEXT = re.compile(r'id="bu_load_next" data-next-id="(\d+)"')
_PARA = re.compile(r"<p>(.*?)</p>", re.S)
_HEADING = re.compile(r'^\s*(?:<span[^>]*>\s*</span>\s*)*<span class="c4">(.*?)</span>', re.S)
_TAG = re.compile(r"<[^>]+>")
_COPY_BUTTON = re.compile(r'<a href="#p\d+"[^>]*>.*?</a>', re.S)


def witness_url(w: dict) -> str:
    kind = w["kind"]
    if kind == "openiti":
        return f"https://raw.githubusercontent.com/OpenITI/{w['repo']}/{w['commit']}/{w['path']}"
    if kind == "archive":
        return f"https://archive.org/download/{w['item']}/{urllib.parse.quote(w['file'])}"
    if kind == "shamela":
        return f"https://shamela.ws/book/{w['book_id']}/{w.get('pages', [1])[0]}"
    if kind == "shamela_epub":
        return f"https://old.shamela.ws/epubs/{w['book_id'] // 100:03d}/{w['book_id']}.epub"
    if kind == "url":
        return w["url"]
    if kind == "zadapps":
        return f"{w['base']}/{w['folder']}/{w['file']}"
    raise ValueError(f"no URL scheme for witness kind {kind!r}")


def _text(fragment: str) -> str:
    return " ".join(html.unescape(_TAG.sub("", _COPY_BUTTON.sub("", fragment))).split())


def shamela_page_to_markdown(page_html: str) -> str:
    """One Shamela reader page → mARkdown: ### headings, # paragraphs, closing page marker."""
    m = _NASS.search(page_html)
    if not m:
        return ""

    def line(p: str) -> str:
        heading = _HEADING.match(p)
        return f"### | {_text(heading.group(1))}" if heading else f"# {_text(p)}"

    lines = [line(p) for p in _PARA.findall(m.group(3)) if _text(p)]
    return "\n".join([*lines, f"PageV01P{int(m.group(2)):03d}"])  # OpenITI: marker closes the page


_SPINE = re.compile(r'<itemref idref="([^"]+)"')
_ITEM = re.compile(r'<item id="([^"]+)" href="([^"]+)"')
_CONTAINER = re.compile(r'id="book-container">(.*?)</div>', re.S)
_EPUB_PAGE = re.compile(r"الجزء: (\d+) ¦ الصفحة: (\d+)")


def shamela_epub_to_markdown(epub: bytes) -> str:
    """An old Shamela epub → mARkdown: its pages in spine order, a ``#`` line per ``<br />`` line and
    the page marker closing each page (as `shamela_page_to_markdown`). Pages without a text body
    (the info page) are left out."""
    z = zipfile.ZipFile(BytesIO(epub))
    opf = z.read("OEBPS/content.opf").decode()
    href = dict(_ITEM.findall(opf))
    out = ["#META#Header#End#"]
    for page in (z.read(f"OEBPS/{href[i]}").decode() for i in _SPINE.findall(opf)):
        body, num = _CONTAINER.search(page), _EPUB_PAGE.search(page)
        if not (body and num):
            continue
        out += [f"# {t}" for t in map(_text, re.split(r"<br\s*/?>", body.group(1))) if t]
        out.append(f"PageV{int(num[1]):02d}P{int(num[2]):03d}")
    return "\n".join(out) + "\n"


def next_page_id(page_html: str) -> int | None:
    m = _NEXT.search(page_html)
    return int(m.group(1)) if m else None


def _get(url: str, backoff: tuple[int, ...] = (2, 4, 8, 16)) -> bytes:
    """GET with exponential backoff on transient failures: 5xx, network errors, timeouts, connection
    resets (a reset mid-book used to abort an hours-long Shamela fetch) and a response cut short
    (`http.client.IncompleteRead`), which is reported as a `ConnectionError` once the retries run out."""
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return r.read()
    except (urllib.error.URLError, TimeoutError, ConnectionError, http.client.HTTPException) as e:
        transient = not isinstance(e, urllib.error.HTTPError) or e.code >= 500
        if not (transient and backoff):
            if isinstance(e, http.client.HTTPException):
                raise ConnectionError(f"{url}: {e!r}") from e
            raise
        time.sleep(backoff[0])
        return _get(url, backoff[1:])


def _checkpoint_line(md: str, next_page: int | None) -> str:
    return json.dumps({"md": md, "next": next_page}, ensure_ascii=False) + "\n"


def _checkpoint(part: Path | None) -> list[dict]:
    """The pages a checkpoint holds, up to its first unreadable line: a write cut short leaves a broken
    tail, which is discarded (and the file truncated to the whole pages) so the walk resumes after them."""
    if not (part and part.exists()):
        return []
    raw, done = part.read_bytes().split(b"\n"), []
    for line in raw:
        try:
            d = json.loads(line.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError):
            break
        if not (isinstance(d, dict) and isinstance(d.get("md"), str) and "next" in d and (d["next"] is None or type(d["next"]) is int)):
            break
        done.append(d)
    if len(done) != len([l for l in raw if l]):
        part.write_text("".join(_checkpoint_line(d["md"], d["next"]) for d in done), encoding="utf-8")
    return done


def _shamela(w: dict, max_pages: int | None, part: Path | None = None) -> bytes:
    """Walk the reader page by page. With `part`, each page is checkpointed as one JSON line
    (markdown + next page id), so an interrupted fetch resumes where it stopped."""
    done = _checkpoint(part)
    out = [d["md"] for d in done]
    page: int | None = done[-1]["next"] if done else w.get("pages", [1])[0]
    with (part.open("a", encoding="utf-8") if part else contextlib.nullcontext()) as log:
        while page is not None and (max_pages is None or len(out) < max_pages):
            body = _get(f"https://shamela.ws/book/{w['book_id']}/{page}").decode()
            out.append(shamela_page_to_markdown(body))
            page = next_page_id(body)
            if log:
                log.write(_checkpoint_line(out[-1], page))
                log.flush()
            time.sleep(SHAMELA_DELAY_S)
    return ("#META#Header#End#\n" + "\n".join(out) + "\n").encode()


def doc_to_text(doc: Path) -> Path:
    """A Word witness → UTF-8 text beside it (`<id>.txt`), by LibreOffice. The lock pins the .doc."""
    import subprocess
    subprocess.run(["soffice", "--headless", "--convert-to", "txt:Text (encoded):UTF8", str(doc), "--outdir", str(doc.parent)],
                   check=True, capture_output=True, timeout=300)
    return doc.with_suffix(".txt")


def fetch(w: dict, cache: Path, max_pages: int | None = None, refresh: bool = False) -> dict:
    """Fetch one witness into ``cache`` and return its lock entry."""
    path = cache / f"{w['id']}.{'txt' if w.get('format', 'text') == 'text' else w['format']}"
    if refresh or not path.exists():
        path.parent.mkdir(parents=True, exist_ok=True)
        part = path.with_suffix(".part") if max_pages is None else None  # full fetches only
        if refresh and part:
            part.unlink(missing_ok=True)
        data = _shamela(w, max_pages, part) if w["kind"] == "shamela" else \
            shamela_epub_to_markdown(_get(witness_url(w))).encode() if w["kind"] == "shamela_epub" else _get(witness_url(w))
        path.write_bytes(data)
        if part:
            part.unlink(missing_ok=True)
        if w.get("format") == "doc":
            doc_to_text(path)
    data = path.read_bytes()
    return {
        "witness": w["id"],
        "url": witness_url(w),
        "bytes": len(data),
        "sha256": hashlib.sha256(data).hexdigest(),
    }


def merge_lock(old: dict | None, new: dict) -> tuple[dict, bool]:
    """The lock entry after a fetch, and whether the content changed. Unchanged bytes keep the old
    entry whole (derived hashes such as ``ocr_sha256`` included); changed bytes drop them."""
    if old is None:
        return new, False
    if old["sha256"] == new["sha256"]:
        return old, False
    return new, True
