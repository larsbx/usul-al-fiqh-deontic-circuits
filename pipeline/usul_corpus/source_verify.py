"""Fail-closed replay of a declared subset, using the existing registry and locks.

The required subset is every witness cited by the active reconciliation ledger, and every witness
the textual foundation (`nusus/foundation.json`) is checked against in test_nusus.py,
and every istidlāl witness in the qawāʿid dossier.
All paged ref/excerpt pairs in corpus JSON using those witnesses are replayed.
Other references are inventoried as excluded, never silently counted as passes.
This is source fidelity under the existing Arabic-letters comparison, not review.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import re
from collections import Counter
from pathlib import Path

from . import arabic, fetch, nusus, reconcile, texts

REF = re.compile(r"src:([a-z0-9-]+)/(v\d+:p\d+)\Z")
WID = re.compile(r"src:([a-z0-9-]+)(?:/|#|$)")


def excerpts(corpus: Path):
    """Retain file and JSON pointer, including duplicates in contribution shards."""
    def walk(obj, pointer):
        if isinstance(obj, dict):
            if "excerpt_ar" in obj and "ref" in obj:
                yield pointer, obj
            for k, v in obj.items():
                yield from walk(v, pointer + "/" + k.replace("~", "~0").replace("/", "~1"))
        elif isinstance(obj, list):
            for i, v in enumerate(obj):
                yield from walk(v, pointer + f"/{i}")
    for path in sorted(corpus.rglob("*.json")):
        for pointer, item in walk(json.loads(path.read_text(encoding="utf-8")), ""):
            yield {"path": path.relative_to(corpus).as_posix(), "pointer": pointer,
                   "ref": item["ref"], "excerpt_ar": item["excerpt_ar"]}


def check_quote(text: str, excerpt: str, locator: str) -> str | None:
    """Match an occurrence ending at the declared closing-page marker.

    Like arabic.locate, compare arabic.quote_key: Arabic letters (including
    negations) and standalone numerals, ignoring punctuation, diacritics, page
    markers and footnote anchors. Unlike locate, search every occurrence so a
    repeated passage cannot borrow the first occurrence's page or qualifier.
    """
    needle = arabic.quote_key(excerpt)
    if not arabic.letters(excerpt):
        return "empty Arabic quotation"
    text, indices, flat = arabic._indexed(text)
    start = flat.find(needle)
    matched = []
    while start >= 0:
        end = indices[start + len(needle) - 1] + 1
        page = arabic._PAGE.search(text, end)
        if page and locator == f"v{page[1]}:p{page[2]}":
            # Page and paragraph markup cannot hide an immediately following qayd.
            tail = re.sub(r"PageV\d+P\d+|ms\d+|[#~|]", " ", text[end:end + 160])
            tail = arabic._DIACRITICS.sub("", tail)
            matched.append(bool(nusus.QUALIFIER.match(tail)))
        start = flat.find(needle, start + 1)
    if not matched:
        return "quotation absent at declared page"
    if any(matched):
        return "quotation stops before qualifier at declared page"
    return None


def required_witnesses(corpus: Path) -> set[str]:
    ledger = reconcile.load(corpus)  # same base-plus-shards view as tests and generators
    ids = set()
    for entry in ledger["entries"]:
        for item in entry.get("evidence", []) + entry.get("proofs", []) + entry.get("advantages", []):
            match = REF.fullmatch(item["ref"])
            if not match:
                raise ValueError(f"invalid required evidence locator: {item['ref']}")
            ids.add(match[1])
    dossier = corpus / "dossier/qawaid_adilla.json"
    if dossier.exists():
        for entry in json.loads(dossier.read_text(encoding="utf-8"))["entries"]:
            for dalil in entry["adilla"]:
                item = dalil["istidlal"]
                match = REF.fullmatch(item["ref"])
                if not match or match[1] != item["witness"]:
                    raise ValueError(f"invalid required istidlāl locator/witness: {item['ref']}")
                ids.add(item["witness"])
    if not ids:
        raise ValueError("required reconciliation evidence set is empty")
    return ids | nusus.witnesses(corpus)


def _matches(data: bytes, lock: dict) -> bool:
    return len(data) == lock.get("bytes") and hashlib.sha256(data).hexdigest() == lock.get("sha256")


def _pin(lock: dict) -> str:
    return json.dumps({k: lock.get(k) for k in ("url", "bytes", "sha256")}, sort_keys=True)


def restore_locked_ocr(wid: str, witness: dict, lock: dict, cache: Path) -> None:
    """Reproduce an existing OCR pin with the repository's pinned models. Never re-pin.

    Verify the fetched PDF before OCR, and the derived text before publishing it
    into the source cache. No corpus files or extraction metrics are rewritten.
    """
    from . import ocr
    cache.mkdir(parents=True, exist_ok=True)
    pdf = cache / f"{wid}.pdf"
    if pdf.exists() and not _matches(pdf.read_bytes(), lock):
        pdf.unlink()
    if not pdf.exists():
        fetch.fetch(witness, cache)  # candidate lock deliberately ignored
    data = pdf.read_bytes()
    if len(data) != lock.get("bytes") or hashlib.sha256(data).hexdigest() != lock.get("sha256"):
        raise ValueError("OCR source PDF differs from lock")
    opts = ocr.OcrOptions.from_config(witness["ocr"], anchor_step=witness.get("segmenter", {}).get("anchor_step"))
    work = ocr.cache_dir(cache.parent / "source-ocr" / wid, pdf, opts)
    chosen, _, _ = ocr.ocr_pdf(pdf, work, cache.parent / "tessdata", opts, jobs=min(4, os.cpu_count() or 1))
    text = "#META#Header#End#\n" + "".join(ocr.page_markdown(page) for page in chosen)
    if hashlib.sha256(text.encode("utf-8")).hexdigest() != lock["ocr_sha256"]:
        raise ValueError("regenerated OCR text differs from existing ocr_sha256; lock unchanged")
    (cache / f"{wid}.txt").write_text(text, encoding="utf-8")


def locked_text(wid: str, witness: dict, lock: dict, corpus: Path, cache: Path,
                fetch_source: bool) -> str:
    """Reuse restore/fetch, but never call the lock-writing fetch CLI or _pin.

    Adapted from PR #51's verify_evidence full-source URL/size/hash check.
    Direct texts use the source pin; OCR uses its separate existing derived-text pin.
    """
    if witness.get("format", "text") == "pdf":
        # The existing OCR lock pins the exact derived text independently of the PDF.
        # Never re-run the lock-writing OCR command while verifying evidence.
        if lock.get("url") != fetch.witness_url(witness):
            raise ValueError("registered URL differs from source lock")
        digest = lock.get("ocr_sha256", "")
        if not re.fullmatch(r"[0-9a-f]{64}", digest):
            raise ValueError("required PDF witness lacks a pinned OCR text derivation")
        path = cache / f"{wid}.txt"
        if fetch_source and path.exists() and hashlib.sha256(path.read_bytes()).hexdigest() != digest:
            path.unlink()
        if not path.exists() and fetch_source:
            restore_locked_ocr(wid, witness, lock, cache)
        if not path.exists():
            raise ValueError("required locked OCR witness unavailable; run make source-verify-fetch")
        data = path.read_bytes()
        if hashlib.sha256(data).hexdigest() != digest:
            raise ValueError("derived OCR text differs from lock (including LFS pointers)")
        return data.decode("utf-8")
    if witness.get("format", "text") != "text":
        raise ValueError("required witness needs a separately pinned text derivation")
    if lock.get("url") != fetch.witness_url(witness):
        raise ValueError("registered URL differs from source lock")
    if witness["kind"] == "openiti" and not re.fullmatch(r"[0-9a-f]{40}", witness["commit"]):
        raise ValueError("OpenITI witness must pin a full commit SHA")
    path = cache / f"{wid}.txt"
    if fetch_source and path.exists() and not _matches(path.read_bytes(), lock):
        path.unlink()  # a restored cache of an earlier pin; only the fetched bytes are judged below
    if not path.exists():
        texts.restore(wid, {wid: lock}, corpus / "texts", cache)
    if not path.exists() and fetch_source:
        # fetch resumes an interrupted Shamela walk from `<wid>.part`; a checkpoint restored from a
        # cache of an earlier pin would splice its pages in, so it resumes only under its own pin.
        part, pin = cache / f"{wid}.part", cache / f"{wid}.part.pin"
        if part.exists() and not (pin.exists() and pin.read_text(encoding="utf-8") == _pin(lock)):
            part.unlink()
        pin.write_text(_pin(lock), encoding="utf-8")
        fetch.fetch(witness, cache)  # its returned candidate lock is deliberately discarded
        pin.unlink()
    if not path.exists():
        raise ValueError("required locked witness unavailable")
    data = path.read_bytes()
    if not _matches(data, lock):
        raise ValueError("full source bytes differ from lock (including LFS pointers)")
    return data.decode("utf-8")


def verify(corpus: Path, cache: Path, fetch_source: bool = False) -> dict:
    report = {"schema_version": 1, "scope": "reconciliation-foundation-istidlal-witnesses-v3",
              "comparison": "Arabic letters and standalone numerals; exact letter forms; closing-page locator",
              "status": "failed", "witnesses": [], "checks": [], "errors": [],
              "outside_scope": ["JSONL records and non-ref quotation fields", "Quran aya, hadith number and Albani verdict replay (witnesses provisioned here; replayed by test_nusus.py)",
                                "interpretive relevance, formal correctness and scholarly validation"]}
    registry = json.loads((corpus / "registry.json").read_text(encoding="utf-8"))
    witnesses = {w["id"]: {"segmenter": work.get("segmenter", {}), **w}
                 for work in registry["works"] for w in work["witnesses"]}
    locks = json.loads((corpus / "lock.json").read_text(encoding="utf-8"))["witnesses"]
    try:
        required = required_witnesses(corpus)
    except (ValueError, KeyError) as exc:
        report["errors"].append(str(exc))
        return report
    rows = list(excerpts(corpus))
    # Group verification to bound the memory used by large full-witness indexes.
    for wid in sorted(required):
        receipt = {"witness": wid, "status": "failed"}
        report["witnesses"].append(receipt)
        text = None
        try:
            if wid not in witnesses or wid not in locks:
                raise ValueError("required witness lacks registry entry or source lock")
            text = locked_text(wid, witnesses[wid], locks[wid], corpus, cache, fetch_source)
            receipt.update({k: locks[wid][k] for k in ("url", "bytes", "sha256")})
            if witnesses[wid].get("format") == "pdf":
                receipt["ocr_sha256"] = locks[wid]["ocr_sha256"]
                receipt["verification"] = "pinned OCR text; PDF bytes and OCR interpretation not replayed"
            receipt["status"] = "verified"
        except (ValueError, OSError, KeyError, subprocess.SubprocessError) as exc:
            receipt["error"] = str(exc)
            report["errors"].append(f"{wid}: {exc}")
        for row in rows:
            match = WID.match(str(row["ref"]))
            if not match or match[1] != wid:
                continue
            out = {k: row[k] for k in ("path", "pointer", "ref")}
            out["excerpt_sha256"] = hashlib.sha256(row["excerpt_ar"].encode()).hexdigest()
            parsed = REF.fullmatch(row["ref"])
            if not parsed:
                out.update(status="excluded", reason="non-page locator: separate anchor replay required")
            elif text is None:
                out.update(status="failed", reason="required source integrity not established")
            else:
                error = check_quote(text, row["excerpt_ar"], parsed[2])
                out.update(status="failed" if error else "verified")
                if error:
                    out["reason"] = error
            report["checks"].append(out)
        arabic._indexed.cache_clear()
    for row in rows:
        match = WID.match(str(row["ref"]))
        if not match or match[1] not in required:
            report["checks"].append({k: row[k] for k in ("path", "pointer", "ref")} | {
                "status": "excluded", "reason": "witness outside required evidence subset; no fidelity result"})
    report["checks"].sort(key=lambda x: (x["path"], x["pointer"]))
    report["counts"] = dict(Counter(x["status"] for x in report["checks"]))
    if not report["errors"] and not report["counts"].get("failed") and report["counts"].get("verified"):
        report["status"] = "verified_required_subset"
    return report


def main(argv=None) -> int:
    root = Path(__file__).resolve().parents[2]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--corpus", type=Path, default=root / "corpus")
    parser.add_argument("--cache", type=Path, default=root / ".cache/corpus")
    parser.add_argument("--fetch-source", action="store_true")
    parser.add_argument("--report", type=Path, default=root / ".cache/source-verification.json")
    args = parser.parse_args(argv)
    try:
        report = verify(args.corpus, args.cache, args.fetch_source)
    except (ValueError, OSError, KeyError, TypeError) as exc:
        report = {"status": "failed", "errors": [str(exc)]}
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({k: v for k, v in report.items() if k not in ("witnesses", "checks")}, ensure_ascii=False))
    return 0 if report["status"] == "verified_required_subset" else 1


if __name__ == "__main__":
    raise SystemExit(main())
