"""Fetch pinned witnesses into a local cache and record a content lock.

Every witness is normalised to OpenITI mARkdown (or plain text for OCR) so the
downstream parser is shared (one reader, many sources).
"""

from __future__ import annotations

import contextlib
import hashlib
import html
import json
import re
import time
import urllib.error
import urllib.parse
import urllib.request
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


def next_page_id(page_html: str) -> int | None:
    m = _NEXT.search(page_html)
    return int(m.group(1)) if m else None


def _get(url: str, backoff: tuple[int, ...] = (2, 4, 8, 16)) -> bytes:
    """GET with exponential backoff on transient failures: 5xx, network errors, timeouts and
    connection resets (a reset mid-book used to abort an hours-long Shamela fetch)."""
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return r.read()
    except (urllib.error.URLError, TimeoutError, ConnectionError) as e:
        transient = not isinstance(e, urllib.error.HTTPError) or e.code >= 500
        if not (transient and backoff):
            raise
        time.sleep(backoff[0])
        return _get(url, backoff[1:])


def _shamela(w: dict, max_pages: int | None, part: Path | None = None) -> bytes:
    """Walk the reader page by page. With `part`, each page is checkpointed as one JSON line
    (markdown + next page id), so an interrupted fetch resumes where it stopped."""
    done = [json.loads(l) for l in part.read_text(encoding="utf-8").splitlines()] if part and part.exists() else []
    out = [d["md"] for d in done]
    page: int | None = done[-1]["next"] if done else w.get("pages", [1])[0]
    with (part.open("a", encoding="utf-8") if part else contextlib.nullcontext()) as log:
        while page is not None and (max_pages is None or len(out) < max_pages):
            body = _get(f"https://shamela.ws/book/{w['book_id']}/{page}").decode()
            out.append(shamela_page_to_markdown(body))
            page = next_page_id(body)
            if log:
                log.write(json.dumps({"md": out[-1], "next": page}, ensure_ascii=False) + "\n")
                log.flush()
            time.sleep(SHAMELA_DELAY_S)
    return ("#META#Header#End#\n" + "\n".join(out) + "\n").encode()


def fetch(w: dict, cache: Path, max_pages: int | None = None, refresh: bool = False) -> dict:
    """Fetch one witness into ``cache`` and return its lock entry."""
    path = cache / f"{w['id']}.{'pdf' if w.get('format') == 'pdf' else 'txt'}"
    if refresh or not path.exists():
        path.parent.mkdir(parents=True, exist_ok=True)
        part = path.with_suffix(".part") if max_pages is None else None  # full fetches only
        if refresh and part:
            part.unlink(missing_ok=True)
        data = _shamela(w, max_pages, part) if w["kind"] == "shamela" else _get(witness_url(w))
        path.write_bytes(data)
        if part:
            part.unlink(missing_ok=True)
    data = path.read_bytes()
    return {
        "witness": w["id"],
        "url": witness_url(w),
        "bytes": len(data),
        "sha256": hashlib.sha256(data).hexdigest(),
    }
