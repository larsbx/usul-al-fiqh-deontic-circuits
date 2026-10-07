"""CLI: fetch → build → validate.

    python -m usul_corpus fetch [--work ID] [--max-pages N] [--refresh]
    python -m usul_corpus build
    python -m usul_corpus validate
    python -m usul_corpus signature   # regenerate the Lean Σ-coverage check
    python -m usul_corpus takhrij     # regenerate the takhrīj guards and report
    python -m usul_corpus docs        # render the dossier and glossary pages from corpus/dossier
    python -m usul_corpus ocr [--work ID] [--pages A-B] [--jobs N]
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

from .fetch import fetch
from .hudud import extract_hudud
from .ocr import MODELS, OcrOptions, cache_dir, ocr_pdf, page_markdown, quality, tesseract_version
from .openiti import parse_markdown
from .records import hadd_record, qaida_records, sharh_record, unit_tags
from .segment import (
    audit_numbering,
    consensus_numbering,
    segment_headed,
    segment_index,
    segment_lines,
    segment_numbered,
)
from .verses import link_commentary, segment_verse_block

ROOT = Path(__file__).resolve().parents[2]
CORPUS = ROOT / "corpus"
CACHE = ROOT / ".cache" / "corpus"
DOSSIER = CORPUS / "dossier" / "refinements.json"
GLOSSARY = CORPUS / "dossier" / "glossary.json"
FETCHABLE = {"located", "located_ocr"}


def _load(p: Path) -> dict:
    return json.loads(p.read_text(encoding="utf-8")) if p.exists() else {}


def _dump(p: Path, obj: object) -> None:
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(obj, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def _works(only: str | None) -> list[dict]:
    works = _load(CORPUS / "registry.json")["works"]
    return [w for w in works if w["status"] in FETCHABLE and (only is None or w["id"] == only)]


def cmd_fetch(args: argparse.Namespace) -> int:
    lock = _load(CORPUS / "lock.json").get("witnesses", {})
    for work in _works(args.work):
        for w in work["witnesses"]:
            if w.get("quality") == "pdf_only" or (w.get("fetch") == "on_demand" and not args.work):
                continue
            lock[w["id"]] = entry = fetch(w, CACHE, args.max_pages, args.refresh)
            _dump(CORPUS / "lock.json", {"witnesses": dict(sorted(lock.items()))})
            print(f"{w['id']:40} {entry['bytes']:>10} B  {entry['sha256'][:12]}")
    return 0


def _pdf_witnesses(only: str | None) -> list[tuple[dict, dict]]:
    return [(work, w) for work in _works(only) for w in work["witnesses"] if w.get("format") == "pdf"]


def _page_range(spec: str) -> range:
    first, last = map(int, spec.split("-"))
    return range(first, last + 1)


def cmd_ocr(args: argparse.Namespace) -> int:
    """PDF witness → <id>.txt (mARkdown) in the cache + corpus/ocr/<id>.json (metrics only)."""
    lock = _load(CORPUS / "lock.json").get("witnesses", {})
    for work, w in _pdf_witnesses(args.work):
        cfg = w["ocr"]
        pdf = CACHE / f"{w['id']}.pdf"
        if not pdf.exists():
            print(f"skip {w['id']}: run fetch first", file=sys.stderr)
            continue
        seg = w.get("segmenter", work.get("segmenter", {}))
        opts = OcrOptions.from_config(cfg, anchor_step=seg.get("anchor_step"))
        pages = _page_range(args.pages) if args.pages else None
        work_dir = cache_dir(ROOT / ".cache" / "ocr" / w["id"], pdf, opts)
        chosen, passes, numbers_report = ocr_pdf(pdf, work_dir, ROOT / ".cache" / "tessdata", opts, pages, args.jobs)
        engines = opts.engines
        text = "#META#Header#End#\n" + "".join(page_markdown(p) for p in chosen)
        if pages:  # a diagnostic range never replaces the witness, its lock hash or its metrics
            out = CACHE / f"{w['id']}.p{pages.start}-{pages.stop - 1}.txt"
            out.write_text(text, encoding="utf-8")
            print(f"{w['id']:40} {len(chosen):>4} pages  → {out.name} (range only; witness untouched)")
            continue
        (CACHE / f"{w['id']}.txt").write_text(text, encoding="utf-8")
        by_engine = {e: quality(tuple(l for p in passes if p.engine == e for l in p.lines)) for e in engines}
        _dump(CORPUS / "ocr" / f"{w['id']}.json", {
            "witness": w["id"],
            "engine": tesseract_version(),
            "models": {e: MODELS[e][1] for e in (*engines, *(["arabic_script"] if opts.numbers else []))},
            "config": cfg,
            "numbers": numbers_report,
            "summary": {**quality(tuple(l for p in chosen for l in p.lines)),  # chosen pages
                        "pages": len(chosen),
                        "chosen": {e: sum(p.engine == e for p in chosen) for e in engines},
                        "by_engine": by_engine},
            "pages": [{"page": p.page, "engine": p.engine, **quality(p.lines)} for p in chosen],
        })
        lock[w["id"]] = {**lock.get(w["id"], {}), "ocr_sha256": hashlib.sha256(text.encode()).hexdigest()}
        _dump(CORPUS / "lock.json", {"witnesses": dict(sorted(lock.items()))})
        total = quality(tuple(l for p in chosen for l in p.lines))
        print(f"{w['id']:40} {len(chosen):>4} pages  mean conf {total['mean_conf']}  "
              f"low-confidence lines {total['low_conf_lines']}/{total['lines']}")
    return 0


SEGMENTERS = {
    "headed": lambda text, seg: segment_headed(parse_markdown(text), seg["marker"]),
    "lines": lambda text, seg: segment_lines(text, seg["marker"]),
    "numbered": lambda text, seg: segment_numbered(text, seg.get("anchor_step")),
    "verse_block": lambda text, seg: segment_verse_block(text),
}


def _segment(work: dict, w: dict, text: str) -> tuple[list[dict], tuple | None]:
    """Records for one witness, plus the numbered units when the segmenter yields any."""
    seg, witness = w.get("segmenter", work["segmenter"]), w["id"]
    if seg["kind"] == "hudud_brackets":
        hudud = extract_hudud(parse_markdown(text))
        return [hadd_record(work, witness, i, h) for i, h in enumerate(hudud, 1)], None
    units = SEGMENTERS[seg["kind"]](text, seg)
    records = [r for t, u in zip(unit_tags(units), units) for r in qaida_records(work, witness, seg["kind"], t, u)]
    return records, units


def _index(work: dict, witness: str, text: str) -> tuple[list[dict], tuple]:
    """Rules restated in the book's closing index: an extra witness with each rule's statement."""
    units = segment_index(text, work["segmenter"]["marker"])
    tags = unit_tags(units, prefix="i")
    return [r for t, u in zip(tags, units) for r in qaida_records(work, witness, "index", t, u)], units


def _commentary(work: dict, witness: str, text: str, units: tuple) -> tuple[list[dict], dict]:
    """Sharḥ records linked to the matn verses, plus their coverage for the audit."""
    links = link_commentary(text)
    linked = {l.number for l in links}
    return [sharh_record(work, witness, l) for l in links], {
        "printed_number_agrees": sum(not u.ocr_corrected for u in units),
        "commentary_linked": len(links),
        "commentary_unlinked": [u.number for u in units if u.number not in linked],
        "commentary_min_similarity": min((l.similarity for l in links), default=None),
    }


def cmd_build(_: argparse.Namespace) -> int:
    audit: dict[str, dict] = {}
    for work in (w for w in _works(None) if "segmenter" in w):
        expected = work.get("expected_units", {}).get("count")
        numbered: dict[str, tuple] = {}
        for w in work["witnesses"]:
            src = CACHE / f"{w['id']}.txt"
            if not src.exists():
                print(f"skip {w['id']}: not fetched{' or not OCR-ed' if w.get('format') == 'pdf' else ''}",
                      file=sys.stderr)
                continue
            text = src.read_text(encoding="utf-8")
            records, units = _segment(work, w, text)
            if work["segmenter"].get("index"):
                index_records, index_units = _index(work, w["id"], text)
                records += index_records
                audit[f"{w['id']}#index"] = {"work": work["id"], **audit_numbering(index_units, expected)}
                numbered[f"{w['id']}#index"] = index_units
            if units is None:
                audit[w["id"]] = {"work": work["id"], "found": len(records)}
            else:
                audit[w["id"]] = {"work": work["id"], **audit_numbering(units, expected)}
                if w.get("segmenter", work["segmenter"])["kind"] == "verse_block":
                    sharh, report = _commentary(work, w["id"], text, units)
                    records += sharh
                    audit[w["id"]] |= report
                numbered[w["id"]] = units
            path = CORPUS / "records" / f"{w['id']}.jsonl"
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("".join(json.dumps(r, ensure_ascii=False) + "\n" for r in records), encoding="utf-8")
            print(f"{w['id']:40} {len(records):>4} records")
        if len(numbered) > 1:
            audit[f"consensus:{work['id']}"] = consensus_numbering(numbered, expected)
    _dump(CORPUS / "audit.json", dict(sorted(audit.items())))
    return 0


SIGNATURE_LEAN = ROOT / "formal" / "lean" / "UsulTest" / "SignatureMap.lean"


def _link_matches(link: dict, r: dict) -> bool:
    if r["witness"] != link["witness"]:
        return False
    if "term_ar" in link:
        return r["record_type"] == "hadd" and r["term_ar"] == link["term_ar"]
    return r["record_type"] == "qaida" and r["number"] == link["qaida"]


def signature_lean(names: list[str]) -> str:
    checks = "\n".join(f"#check @{n}" for n in dict.fromkeys(names))
    return (
        "-- GENERATED by `python -m usul_corpus signature` from corpus/signature_map.json and\n"
        "-- corpus/proposals/*.json. Do not edit. Fails the build if a named Lean constant does not exist.\n"
        f"import Usul\n\n{checks}\n"
    )


def _lean_names() -> list[str]:
    """Lean constants named by the Σ map and by every catalogue proposal, in order."""
    sigma = [link["lean"] for link in _load(CORPUS / "signature_map.json")["links"]]
    proposals = [n for p in sorted((CORPUS / "proposals").glob("*.json")) for r in _load(p)["rules"] for n in r["lean"]]
    review = [n for p in sorted((CORPUS / "review").glob("*.json")) for n in _review_names(_load(p))]
    citations = [n for p in sorted((CORPUS / "citations").glob("*.json")) for ns in _load(p)["formalises"].values() for n in ns]
    dossier = [n for e in _load(DOSSIER)["entries"] for n in e["lean"]]
    glossary = [n for t in _load(GLOSSARY)["terms"] for n in t.get("lean", [])]
    return sigma + proposals + review + citations + dossier + glossary


def _review_names(reg: dict) -> list[str]:
    """Lean constants a review register relies on: its process, its pins, its transported laws."""
    return [*reg["process"]["lean"],
            *(n for q in reg["questions"] for n in q["pins"]),
            *(n for q in reg["questions"] for n in q.get("decision", {}).get("lean", [])),
            *(n for q in reg["questions"] for a in q.get("decision", {}).get("amendments", []) for n in a["lean"]),
            *(a["transported"] for q in reg["questions"] for a in q["analogies"] if a["kind"] == "internal")]


def cmd_takhrij(_: argparse.Namespace) -> int:
    """Generate the takhrīj guards and the mirror check, and write the coverage report."""
    from . import takhrij
    cases = takhrij.load(CORPUS)
    bad = {c["far"]: e for c in cases if (e := takhrij.check_case(c))}
    if bad:
        print(json.dumps(bad, ensure_ascii=False, indent=1))
        return 1
    tests = SIGNATURE_LEAN.parent
    (tests / "Takhrij.lean").write_text(takhrij.lean_file(cases), encoding="utf-8")
    (tests / "TakhrijMirror.lean").write_text(takhrij.mirror_file(), encoding="utf-8")
    rep = takhrij.report(cases)
    (CORPUS / "takhrij" / "report.json").write_text(json.dumps(rep, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(json.dumps({k: rep[k] for k in ("total", "coverage", "madhhab_coverage", "encoding_error", "ikhtilaf_matching_madhhab", "classes")}, ensure_ascii=False))
    return 0


def docs_pages() -> dict[Path, str]:
    """The generated documentation pages, keyed by path: the dossier and the glossary."""
    from .dossier import render_dossier, render_glossary
    records = {r["id"]: r for p in (CORPUS / "records").glob("*.jsonl") for r in map(json.loads, p.read_text(encoding="utf-8").splitlines())}
    glossary = _load(GLOSSARY)
    return {ROOT / "docs/architecture/dossier.md": render_dossier(_load(DOSSIER), records, {t["key"]: t for t in glossary["terms"]}),
            ROOT / "docs/glossary.md": render_glossary(glossary, records)}


def cmd_docs(_: argparse.Namespace) -> int:
    for path, text in docs_pages().items():
        path.write_text(text, encoding="utf-8")
    return 0


def cmd_signature(_: argparse.Namespace) -> int:
    SIGNATURE_LEAN.write_text(signature_lean(_lean_names()), encoding="utf-8")
    return 0


def cmd_validate(_: argparse.Namespace) -> int:
    import jsonschema  # test-time dependency only

    schemas = ROOT / "schemas"
    reg = jsonschema.Draft202012Validator(_load(schemas / "corpus_registry.schema.json"))
    rec = jsonschema.Draft202012Validator(_load(schemas / "usul_rule.schema.json"))
    registry = _load(CORPUS / "registry.json")
    errors = [f"registry: {e.message}" for e in reg.iter_errors(registry)]
    witnesses = {w["id"] for work in registry["works"] for w in work["witnesses"]}
    ids: set[str] = set()
    for path in sorted((CORPUS / "records").glob("*.jsonl")):
        for n, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            r = json.loads(line)
            errors += [f"{path.name}:{n}: {e.message}" for e in rec.iter_errors(r)]
            errors += [f"{path.name}:{n}: unknown witness {r['witness']}"] * (r["witness"] not in witnesses)
            errors += [f"{path.name}:{n}: duplicate id {r['id']}"] * (r["id"] in ids)
            ids.add(r["id"])
    records = [json.loads(l) for p in (CORPUS / "records").glob("*.jsonl") for l in p.read_text(encoding="utf-8").splitlines()]
    for link in _load(CORPUS / "signature_map.json")["links"]:
        hits = sum(_link_matches(link, r) for r in records)
        errors += [f"signature_map: {link['lean']} resolves to {hits} records (want 1)"] * (hits != 1)
    print("\n".join(errors) or f"ok: registry + {len(ids)} records + signature map")
    return 1 if errors else 0


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(prog="usul_corpus")
    sub = p.add_subparsers(required=True)
    f = sub.add_parser("fetch")
    f.add_argument("--work")
    f.add_argument("--max-pages", type=int)
    f.add_argument("--refresh", action="store_true")
    f.set_defaults(run=cmd_fetch)
    sub.add_parser("build").set_defaults(run=cmd_build)
    sub.add_parser("validate").set_defaults(run=cmd_validate)
    sub.add_parser("signature").set_defaults(run=cmd_signature)
    sub.add_parser("takhrij").set_defaults(run=cmd_takhrij)
    sub.add_parser("docs").set_defaults(run=cmd_docs)
    o = sub.add_parser("ocr")
    o.add_argument("--work")
    o.add_argument("--pages", help="PDF page range A-B (default: all)")
    o.add_argument("--jobs", type=int, default=4)
    o.set_defaults(run=cmd_ocr)
    args = p.parse_args(argv)
    return args.run(args)


if __name__ == "__main__":
    sys.exit(main())
