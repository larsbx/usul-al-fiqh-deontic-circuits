"""Every cached witness the verbatim tests read is the one `corpus/lock.json` pins (problem register
PR-10): a changed or substituted file fails here instead of silently passing the excerpt checks."""

import hashlib
import json
from pathlib import Path

import pytest

from usul_corpus.__main__ import CACHE

ROOT = Path(__file__).parents[2]
LOCK = json.loads((ROOT / "corpus/lock.json").read_text(encoding="utf-8"))["witnesses"]
FORMAT = {w["id"]: w.get("format", "text") for work in json.loads((ROOT / "corpus/registry.json").read_text())["works"]
          for w in work["witnesses"]}


@pytest.mark.parametrize("wid", sorted(LOCK), ids=str)
def test_cached_witness_matches_its_pin(wid):
    ext = {"doc": "doc", "pdf": "pdf"}.get(FORMAT.get(wid, "text"), "txt")
    path = CACHE / f"{wid}.{ext}"
    if not path.exists():
        pytest.skip(f"{wid} not cached")
    assert hashlib.sha256(path.read_bytes()).hexdigest() == LOCK[wid]["sha256"]


def _sourced_excerpts():
    import re
    def walk(o, f):
        if isinstance(o, dict):
            m = re.match(r"src:([a-z0-9-]+)", str(o.get("ref", "")))
            if "excerpt_ar" in o and m:
                yield f, m.group(1), o["excerpt_ar"]
            for v in o.values():
                yield from walk(v, f)
        elif isinstance(o, list):
            for v in o:
                yield from walk(v, f)
    for p in sorted((ROOT / "corpus").rglob("*.json")):
        if p.name not in ("lock.json", "registry.json"):
            yield from walk(json.loads(p.read_text(encoding="utf-8")), p.relative_to(ROOT).as_posix())


def test_no_sourced_excerpt_stops_before_its_qualifier():
    """Every excerpt in the corpus that names its witness: none ends where the text goes on with
    «إلا», «لكن», «ما لم», «بخلاف» … (problem register PR-07)."""
    from usul_corpus.nusus import cut_before_qualifier
    texts, bad = {}, []
    for f, w, ex in _sourced_excerpts():
        if w not in texts:
            p = CACHE / f"{w}.txt"
            texts[w] = p.read_text(encoding="utf-8") if p.exists() else None
        if texts[w] is not None and cut_before_qualifier(texts[w], ex):
            bad.append((f, w, ex[:40]))
    assert not bad, bad


def test_every_cached_witness_is_pinned():
    """A registered witness present in the cache has a pin: a lost pin (PR-20) fails here."""
    cached = [w for w in FORMAT if (CACHE / f"{w}.txt").exists()]
    assert [w for w in cached if w not in LOCK] == []


TARJIH_EN = r"\b(stronger|strongest|sounder|soundest|prefer\w*|more correct|aṣaḥḥ|al-ṣaḥīḥ|rājiḥ)\b"
TARJIH_AR = "أصح|الصحيح|أقوى|أظهر|الأشهر|المشهور|الراجح|المختار|أولى|الصواب|أجود|ضعيف|المنصوص|اختار|رجح|قوي|أشبه"


def test_a_note_claims_no_tarjih_its_source_lacks():
    """An English note that says a view is sounder, stronger or preferred answers to a tarjīḥ word in
    its source paragraph (up to the next «ومنها»): «على وجهين» alone ranks nothing (PR-22, q068.f007).
    A sentence saying none is preferred makes no claim."""
    import re
    from usul_corpus import nusus
    recs = {r["id"]: r for p in (ROOT / "corpus/records").glob("*.jsonl")
            for r in map(json.loads, p.read_text(encoding="utf-8").splitlines())}
    bad = []
    for p in sorted((ROOT / "corpus/takhrij").glob("*_furu.json")):
        for c in json.loads(p.read_text(encoding="utf-8"))["cases"]:
            s = " ".join([c.get("note", "")] + [x["who"] for x in c.get("positions") or []])
            r = recs.get(c["far"])
            claims = [x for x in re.split(r"[.;]", s) if re.search(TARJIH_EN, x, re.I) and not re.search(r"\b(neither|no|none|not)\b", x)]
            if not (r and claims):
                continue
            w = CACHE / f"{r['locator'][4:].split('/')[0]}.txt"
            if not w.exists():
                continue
            text = w.read_text(encoding="utf-8")
            k = nusus.find(text, r["case_ar"][:60])
            para = re.split(r"#\s*\(?ومنها", text[k + 1:k + 2000])[0] if k is not None else ""
            if not re.search(TARJIH_AR, para):
                bad.append(c["far"])
    assert not bad, bad


def test_no_annotation_is_doubled():
    """A quote or parenthetical repeated back to back is an edit applied twice, not the source
    (PR-25: a re-run substitution whose new text contained its old one)."""
    import re
    twice = re.compile(r"(«[^»]{4,}»|\([^()]{6,}\))[ ,;:]*\1")
    bad = [(p.name, m.group(0)) for p in sorted((ROOT / "corpus").rglob("*.json")) if p.name != "lock.json"
           for m in twice.finditer(p.read_text(encoding="utf-8"))]
    assert not bad, bad
