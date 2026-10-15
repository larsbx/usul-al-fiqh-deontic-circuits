"""CLI: fetch → build → validate.

    python -m usul_corpus fetch [--work ID] [--max-pages N] [--refresh]
    python -m usul_corpus build
    python -m usul_corpus validate
    python -m usul_corpus signature   # regenerate the Lean Σ-coverage check
    python -m usul_corpus takhrij     # regenerate the takhrīj guards and report
    python -m usul_corpus reconcile   # resolve apparent contradictions (ledger → Lean guards, report)
    python -m usul_corpus worklist [--check]     # obligation inventories (M8 and units)
    python -m usul_corpus m5-commands [--fetch-source]  # replay candidate capability receipts
    python -m usul_corpus docs        # render the dossier and glossary pages from corpus/dossier
    python -m usul_corpus reception   # count the citers' citations of each cited work (cached citers only)
    python -m usul_corpus mentions [--review N] [--import FILE] # citation-mention dataset → .cache/mentions
    python -m usul_corpus texts       # stage verified public-domain witness texts into corpus/texts (Git LFS)
    python -m usul_corpus ocr [--work ID] [--pages A-B] [--jobs N]
    python -m usul_corpus fatawa [--lang L] [--refresh]   # IslamQA offline dumps → data/islamqa/answers/*.jsonl.gz
    python -m usul_corpus labels      # candidate ḥukm labels + splits for the Arabic answers → data/islamqa/labels
    python -m usul_corpus bank-review # review the labels with the deontic-circuits bank; fill the review sample
    python -m usul_corpus oracle      # export the weighted training set; evaluate the baseline oracles
    python -m usul_corpus fatawa-takhrij  # check the IslamQA takhrīj tranches; regenerate their Lean guards and report
    python -m usul_corpus fatawa-prolog   # write the tranches as Prolog cases; run the oracle and report (needs swipl)
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from collections import Counter
from pathlib import Path

from . import furuq, hadith, nusus, tanaqud
from .fatawa import answers, fold, snapshot_witnesses, write_jsonl_gz
from .labels import label, merge_review, report, review_sample
from .bank_review import STAGES, en_vote, lean_guards, review as bank_review
from .oracle import NaiveBayes, Retriever, confidence, evaluate, features
from .fetch import fetch, merge_lock
from .texts import publishable, restore, stage
from .hudud import extract_hudud
from .ocr import MODELS, OcrOptions, cache_dir, ocr_pdf, page_markdown, quality, tesseract_version
from .openiti import parse_markdown
from .records import hadd_record, qaida_records, sharh_record, unit_tags
from .units import UNIT_SEGMENTERS
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
ISLAMQA = ROOT / "data" / "islamqa"
DOSSIER = CORPUS / "dossier" / "refinements.json"


def load_dossier() -> dict:
    """The committed dossier plus every shard's entries (``corpus/dossier/entries/*.json``)."""
    from .shards import with_fragments
    return with_fragments(_load(DOSSIER), DOSSIER.parent / "entries", key="id")
GLOSSARY = CORPUS / "dossier" / "glossary.json"
TEXTS = CORPUS / "texts"
FETCHABLE = {"located", "located_ocr"}


def _load(p: Path) -> dict:
    return json.loads(p.read_text(encoding="utf-8")) if p.exists() else {}


def _dump(p: Path, obj: object) -> None:
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(obj, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def _works(only: str | None) -> list[dict]:
    works = _load(CORPUS / "registry.json")["works"]
    return [w for w in works if w["status"] in FETCHABLE and (only is None or w["id"] == only)]


def _pin(wid: str, entry: dict) -> None:
    """Merge one witness's pin into lock.json, re-reading it under an exclusive lock so that a
    concurrent fetch cannot overwrite another's pin (problem register PR-20)."""
    import fcntl
    path = CORPUS / "lock.json"
    with open(path.with_suffix(".json.lk"), "w") as guard:
        fcntl.flock(guard, fcntl.LOCK_EX)
        lock = _load(path).get("witnesses", {})
        lock[wid] = entry
        tmp = path.with_suffix(".json.tmp")
        tmp.write_text(json.dumps({"witnesses": dict(sorted(lock.items()))}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        tmp.replace(path)


def cmd_fetch(args: argparse.Namespace) -> int:
    changed = []
    for work in _works(args.work):
        for w in work["witnesses"]:
            if w.get("quality") == "pdf_only" or (w.get("fetch") == "on_demand" and not args.work):
                continue
            lock = _load(CORPUS / "lock.json").get("witnesses", {})
            if not args.refresh and not (CACHE / f"{w['id']}.txt").exists():
                restore(w["id"], lock, TEXTS, CACHE)  # a committed public-domain text saves the download
            entry, drift = merge_lock(lock.get(w["id"]), fetch(w, CACHE, args.max_pages, args.refresh))
            changed += [w["id"]] * drift
            _pin(w["id"], entry)  # read-modify-write under a file lock: neither a stale nor a concurrent fetch loses a pin (PR-20)
            print(f"{w['id']:40} {entry['bytes']:>10} B  {entry['sha256'][:12]}{'  CHANGED since pinned' if drift else ''}")
    if changed:
        print(f"content changed since pinned (see git diff corpus/lock.json): {', '.join(changed)}", file=sys.stderr)
    return 1 if changed else 0


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
    if seg["kind"] in UNIT_SEGMENTERS:
        cut, record = UNIT_SEGMENTERS[seg["kind"]]
        return [record(work, witness, i, u) for i, u in enumerate(cut(text, seg), 1)], None
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


def unit_audit(records: list[dict]) -> dict:
    """Audit fields for unit records: the answered share, the printed numbering, the ranks."""
    if not records or records[0]["record_type"] not in ("fatwa", "masala", "bab"):
        return {}
    if records[0]["record_type"] == "bab":
        return {"ranks": dict(sorted(Counter(r["rank"] for r in records).items()))}
    out = {"answered": sum(r["answer_ar"] is not None for r in records)} if records[0]["record_type"] == "fatwa" else {}
    nums = [r["number"] for r in records if r.get("number")]
    if nums:
        have = set(nums)
        out["numbering"] = {"numbered": len(nums), "first": min(nums), "last": max(nums), "duplicates": len(nums) - len(have),
                            "missing": [n for n in range(min(nums), max(nums) + 1) if n not in have]}
    return out


def merge_audit(previous: dict[str, dict], fresh: dict[str, dict], skipped: dict[str, str]) -> dict[str, dict]:
    """The new audit: fresh entries, except that a skipped witness (id → work) keeps its previous
    entries and a work with a skipped witness keeps its previous consensus."""
    works = set(skipped.values())
    kept = {k: v for k, v in previous.items()
            if k.split("#")[0] in skipped or (k.startswith("consensus:") and k[len("consensus:"):] in works)}
    return dict(sorted(({k: v for k, v in fresh.items() if k not in kept} | kept).items()))


def cmd_build(_: argparse.Namespace) -> int:
    audit: dict[str, dict] = {}
    skipped: dict[str, str] = {}
    for work in (w for w in _works(None) if "segmenter" in w):
        expected = work.get("expected_units", {}).get("count")
        numbered: dict[str, tuple] = {}
        for w in work["witnesses"]:
            src = CACHE / f"{w['id']}.txt"
            if not src.exists():
                print(f"skip {w['id']}: not fetched{' or not OCR-ed' if w.get('format') == 'pdf' else ''}; previous audit kept",
                      file=sys.stderr)
                skipped[w["id"]] = work["id"]
                continue
            text = src.read_text(encoding="utf-8")
            records, units = _segment(work, w, text)
            if work["segmenter"].get("index"):
                index_records, index_units = _index(work, w["id"], text)
                records += index_records
                audit[f"{w['id']}#index"] = {"work": work["id"], **audit_numbering(index_units, expected)}
                numbered[f"{w['id']}#index"] = index_units
            if units is None:
                audit[w["id"]] = {"work": work["id"], "found": len(records), **unit_audit(records)}
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
    _dump(CORPUS / "audit.json", merge_audit(_load(CORPUS / "audit.json"), audit, skipped))
    return 0


SIGNATURE_LEAN = ROOT / "formal" / "lean" / "UsulTest" / "SignatureMap.lean"


def _link_matches(link: dict, r: dict) -> bool:
    if r["witness"] != link["witness"]:
        return False
    if "term_ar" in link:
        return r["record_type"] == "hadd" and r["term_ar"] == link["term_ar"]
    return r["record_type"] == "qaida" and r["number"] == link["qaida"]


SCALE_LEAN = ROOT / "formal" / "lean" / "HadithTest" / "ScaleMap.lean"
DAIFA_LEAN = ROOT / "formal" / "lean" / "HadithTest" / "Daifa.lean"
SEAM_LEAN = ROOT / "formal" / "lean" / "HadithTest" / "Seam.lean"
TANAQUD_LEAN = ROOT / "formal" / "lean" / "UsulTest" / "TanaqudTable.lean"
FURUQ_LEAN = ROOT / "formal" / "lean" / "UsulTest" / "FuruqTable.lean"
NUSUS_LEAN = ROOT / "formal" / "lean" / "UsulTest" / "NususTable.lean"
_SOURCES = {"Usul": "corpus/signature_map.json and\n-- corpus/proposals/*.json", "Hadith": "corpus/hadith/*.json"}


def signature_lean(names: list[str], lib: str = "Usul") -> str:
    checks = "\n".join(f"#check @{n}" for n in dict.fromkeys(names))
    return (
        f"-- GENERATED by `python -m usul_corpus signature` from {_SOURCES[lib]}. Do not edit."
        " Fails the build if a named Lean constant does not exist.\n"
        f"import {lib}\n\n{checks}\n"
    )


def hadith_lean_names() -> list[str]:
    """Lean constants linked from the al-Albānī track's scales, in order."""
    return [i["lean"] for p in sorted((CORPUS / "hadith").glob("kernel_scales*.json"))
            for s in _load(p)["scales"] for i in s["items"] if "lean" in i]


def _lean_names() -> list[str]:
    """Lean constants named by the Σ map and by every catalogue proposal, in order."""
    sigma = [link["lean"] for link in _load(CORPUS / "signature_map.json")["links"]]
    proposals = [n for p in sorted((CORPUS / "proposals").glob("*.json")) for r in _load(p)["rules"] for n in r["lean"]]
    review = [n for p in sorted((CORPUS / "review").glob("*.json")) for n in _review_names(_load(p))]  # IQ and research registers
    bank = [n for d in ("tanaqud", "furuq") for p in sorted((CORPUS / d).glob("*.json")) for n in _bank_names(_load(p))]
    citations = [n for p in sorted((CORPUS / "citations").glob("*.json")) for ns in _load(p)["formalises"].values() for n in ns]
    dossier = [n for e in load_dossier()["entries"] for n in e["lean"]]
    glossary = [n for t in _load(GLOSSARY)["terms"] for n in t.get("lean", [])]
    m8 = [n for p in sorted((CORPUS / "worklists").glob("*_plan.json"))
          for q in _load(p)["selection"] for n in q["reading"]]
    return sigma + proposals + review + bank + citations + dossier + glossary + m8


def _bank_names(reg: dict) -> list[str]:
    """Lean constants a register of the bank applied to itself names: its module's, and each entry's."""
    return [*reg["lean"], *(n for e in reg.get("pairs", []) + reg.get("proved_earlier", []) + reg.get("items", [])
                             for n in e.get("lean", []) + e.get("grounds", []))]


def _review_names(reg: dict) -> list[str]:
    """Lean constants a review register relies on: its process, its pins, its transported laws.
    The research register has no process: only its pins."""
    if reg.get("register") == "research":
        return [n for q in reg["questions"] for n in q["pins"]]
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


def cmd_reconcile(args: argparse.Namespace) -> int:
    """Run every apparent contradiction through the kernel's taʿāruḍ procedure."""
    from . import reconcile, takhrij
    cases, ledger = takhrij.load(CORPUS), reconcile.load(CORPUS)
    if args.draft:
        print(json.dumps(reconcile.draft(cases, ledger), ensure_ascii=False, indent=1))
        return 0
    if errs := reconcile.check(cases, ledger, load_dossier()):
        print("\n".join(errs), file=sys.stderr)
        return 1
    (SIGNATURE_LEAN.parent / "Reconcile.lean").write_text(reconcile.lean_file(cases, ledger), encoding="utf-8")
    rep = reconcile.report(cases, ledger)
    _dump(CORPUS / reconcile.REPORT, rep)
    print(json.dumps({k: rep[k] for k in ("entries", "stages", "standing")}, ensure_ascii=False))
    return 0


def cmd_worklist(args: argparse.Namespace) -> int:
    """Regenerate (or ``--check``) every obligation inventory: Ibn Rajab's M8 worklist with its scope
    paragraphs, and the unit inventory of the line-segmented witnesses."""
    from . import takhrij, units
    from .m8_worklist import OUTPUT, render, scoped_documents
    try:
        text = render(CORPUS)
        files = {CORPUS / OUTPUT: text, **scoped_documents(ROOT, json.loads(text)),
                 CORPUS / units.INVENTORY: units.render(CORPUS, {c["far"] for c in takhrij.load(CORPUS)})}
    except ValueError as e:
        print(f"worklist: {e}", file=sys.stderr)
        return 1
    if args.check:
        stale = [str(p.relative_to(ROOT)) for p, content in files.items()
                 if not p.exists() or p.read_text(encoding="utf-8") != content]
        if stale:
            print(f"worklists stale ({', '.join(stale)}): run python -m usul_corpus worklist", file=sys.stderr)
            return 1
    else:
        for p, content in files.items():
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(content, encoding="utf-8")
    print(json.dumps(json.loads(text)["summary"]))
    print(json.dumps(json.loads(files[CORPUS / units.INVENTORY])["summary"]))
    return 0


def cmd_routing(args: argparse.Namespace) -> int:
    """Regenerate (or ``--check``) the routing index, and its out-of-domain report where the IslamQA
    answers are fetched (Git LFS)."""
    from . import routing
    files = {CORPUS / routing.INDEX: routing.render(CORPUS)}
    answers = ROOT / routing.ANSWERS
    if answers.exists() and answers.stat().st_size > 1000:
        files[CORPUS / routing.OOD] = routing.render_ood(ROOT)
    if args.check:
        stale = [str(p.relative_to(ROOT)) for p, c in files.items() if not p.exists() or p.read_text(encoding="utf-8") != c]
        if stale:
            print(f"routing stale ({', '.join(stale)}): run python -m usul_corpus routing", file=sys.stderr)
            return 1
    else:
        for p, c in files.items():
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(c, encoding="utf-8")
    print(json.dumps(json.loads(files[CORPUS / routing.INDEX])["recall"]))
    return 0


def cmd_typed_routing(args: argparse.Namespace) -> int:
    """For each set with committed situations: write them as Prolog, route by type, and write its
    report (a test set) or its lane-B proposals (a proposal set) (needs swipl)."""
    from . import typed_routing as tr
    stale = []

    def emit(path: str, text: str) -> bool:
        if args.check:
            current = (ROOT / path).read_text(encoding="utf-8") if (ROOT / path).exists() else None
            stale.extend([path] if current != text else [])
        else:
            (ROOT / path).write_text(text, encoding="utf-8")
        return path not in stale

    for ts in [*tr.present(ROOT), *tr.present(ROOT, tr.PROPOSALS)]:
        if not emit(ts.prolog, tr.prolog_file(ts, json.loads((ROOT / ts.situations).read_text(encoding="utf-8")))):
            continue
        cov = tr.coverage(ROOT, ts)
        if isinstance(ts, tr.TestSet):
            r = tr.report(ROOT, ts, cov)
            emit(ts.report, json.dumps(r, ensure_ascii=False, indent=2) + "\n")
            print(json.dumps({"set": ts.name, **{k: r[k] for k in ("cases", "recall", "lexical_recall", "hybrid_recall")}}))
        else:
            r = tr.proposals(ROOT, ts, cov)
            emit(ts.proposals, json.dumps(r, ensure_ascii=False, indent=2) + "\n")
            print(json.dumps({"set": ts.name, **{k: r[k] for k in ("units", "typed", "encoders_proposed_by_type")}}))
    if stale:
        print(f"typed routing stale ({', '.join(stale)}): run python -m usul_corpus typed-routing", file=sys.stderr)
        return 1
    return 0


def cmd_m5_commands(args: argparse.Namespace) -> int:
    from . import m5_commands
    plan = _load(CORPUS / m5_commands.PLAN)
    try:
        m5_commands.validate(plan, CORPUS)
        if args.fetch_source:
            data = m5_commands.fetch_locked_source(plan, CORPUS, CACHE)
        else:
            data = (CACHE / f"{m5_commands.WITNESS}.txt").read_bytes()
        m5_commands.validate_source(plan, data)
    except (ValueError, KeyError, OSError) as e:
        print(f"m5-commands: {e}", file=sys.stderr)
        return 1
    print(f"ok: {len(plan['fixtures'])} M5 capability fixtures + full locked source; four original command gaps remain open")
    return 0


def docs_pages() -> dict[Path, str]:
    """The generated documentation pages, keyed by path: the dossier and the glossary."""
    from .dossier import render_dossier, render_glossary
    records = {r["id"]: r for p in (CORPUS / "records").glob("*.jsonl") for r in map(json.loads, p.read_text(encoding="utf-8").splitlines())}
    glossary = _load(GLOSSARY)
    from .reception import render_counts
    titles = {w["id"]: (w["title_tr"], w.get("reception", {}).get("genre", "")) for w in _load(CORPUS / "registry.json")["works"]}
    titles |= {a["id"]: (a["name_tr"], "") for a in _load(CORPUS / "reception" / "authors.json")["authors"]}
    return {ROOT / "docs/architecture/dossier.md": render_dossier(load_dossier(), records, {t["key"]: t for t in glossary["terms"]}),
            ROOT / "docs/glossary.md": render_glossary(glossary, records, "Qurʾān: " + _load(CORPUS / "nusus/foundation.json")["attribution"]["quran"]),
            ROOT / "docs/architecture/reception-counts.md": render_counts(_load(CORPUS / "reception" / "report.json"), titles)}


def cmd_docs(_: argparse.Namespace) -> int:
    for path, text in docs_pages().items():
        path.write_text(text, encoding="utf-8")
    return 0


def cmd_reception(_: argparse.Namespace) -> int:
    from .reception import authors, build
    rep = build(_load(CORPUS / "registry.json"), CACHE, authors(CORPUS / "reception" / "authors.json"))
    _dump(CORPUS / "reception" / "report.json", rep)
    for work, c in sorted({**rep["counts"], **rep["authors"]}.items(), key=lambda kv: -kv[1]["total"]):
        print(f"{work:40} {c['total']:>6}  {c['by_scholar']}")
    print(f"missing citers: {rep['missing'] or 'none'}", file=sys.stderr)
    return 0


MENTIONS = ROOT / ".cache" / "mentions"
GOLD = CORPUS / "mentions" / "gold.jsonl"


def _mention_tasks() -> tuple:
    from .mentions import Task
    from .reception import authors, lexicon
    return (Task("work", lexicon(_load(CORPUS / "registry.json")["works"]), cue_single=True),
            Task("author", authors(CORPUS / "reception" / "authors.json"), cue_single=False))


def cmd_mentions(args: argparse.Namespace) -> int:
    """Candidates + rule/gold labels per task → .cache/mentions; review queue; committed summary."""
    from .mentions import candidates, choices, merge_gold, read_gold, review_queue, summary, with_gold, write_gold, write_jsonl
    tasks = {t.name: t for t in _mention_tasks()}
    gold = read_gold(GOLD)
    if args.import_:
        reviewed = [json.loads(l) for l in Path(args.import_).read_text(encoding="utf-8").splitlines() if l.strip()]
        for name, task in tasks.items():
            gold = merge_gold(gold, (r for r in reviewed if r["id"].startswith(f"{name}:")), task)
        write_gold(GOLD, gold)
    citers = [x["id"] for w in _load(CORPUS / "registry.json")["works"]
              if w.get("reception", {}).get("role") == "citer" for x in w["witnesses"]]
    texts = {wid: (CACHE / f"{wid}.txt").read_text(encoding="utf-8") for wid in citers if (CACHE / f"{wid}.txt").exists()}
    rows = {name: with_gold([r for wid, text in sorted(texts.items()) for r in candidates(task, wid, text)], gold)
            for name, task in tasks.items()}
    for name, rs in rows.items():
        write_jsonl(MENTIONS / f"{name}.jsonl", rs)
        for split in ("train", "dev", "test"):
            write_jsonl(MENTIONS / f"{name}.{split}.jsonl",
                        ({**r, "text": f"{r['left']} [[{r['surface']}]] {r['right']}"}
                         for r in rs if r["split"] == split and r["label"] is not None))
        write_jsonl(MENTIONS / f"review-{name}.jsonl",
                    ({**r, "choices": list(choices(tasks[name], r["surface"]))} for r in review_queue(rs, args.review)))
    seen = {r["id"] for rs in rows.values() for r in rs}
    rep = {"citers": sorted(texts), "missing": sorted(set(citers) - set(texts)),
           "gold": len(gold), "gold_unmatched": sorted(set(gold) - seen), **summary(rows)}
    _dump(CORPUS / "mentions" / "summary.json", rep)
    print(json.dumps({k: {x: v[x] for x in ("candidates", "by_source")} for k, v in rep.items() if k in tasks}, ensure_ascii=False))
    print(f"dataset and review queues → {MENTIONS.relative_to(ROOT)}", file=sys.stderr)
    return 0


def cmd_texts(_: argparse.Namespace) -> int:
    """Copy every verified, cached public-domain witness text into corpus/texts."""
    rep = stage(publishable(_load(CORPUS / "registry.json")), _load(CORPUS / "lock.json")["witnesses"], CACHE, TEXTS)
    print(json.dumps({k: len(v) for k, v in rep.items()}))
    for k in ("missing", "mismatch"):
        if rep[k]:
            print(f"{k}: {', '.join(rep[k])}", file=sys.stderr)
    return 1 if rep["mismatch"] else 0


def cmd_signature(_: argparse.Namespace) -> int:
    from .shards import readings_index
    readings = ROOT / "formal" / "lean" / "Usul" / "Readings"
    (readings.parent / "Readings.lean").write_text(readings_index(readings), encoding="utf-8")
    SIGNATURE_LEAN.write_text(signature_lean(_lean_names()), encoding="utf-8")
    SCALE_LEAN.write_text(signature_lean(hadith_lean_names(), "Hadith"), encoding="utf-8")
    DAIFA_LEAN.write_text(hadith.daifa_lean(CORPUS), encoding="utf-8")
    SEAM_LEAN.write_text(hadith.seam_lean(_load(CORPUS / "hadith" / "irwa_join.json")["links"]), encoding="utf-8")
    TANAQUD_LEAN.write_text(tanaqud.table_lean(tanaqud.registers(CORPUS)), encoding="utf-8")
    FURUQ_LEAN.write_text(furuq.table_lean(CORPUS), encoding="utf-8")
    NUSUS_LEAN.write_text(nusus.table_lean(nusus.load(CORPUS), _load(GLOSSARY), [i for t in furuq.tranches(CORPUS) for i in t["items"]]), encoding="utf-8")
    return 0


def cmd_fatawa(args: argparse.Namespace) -> int:
    """Pinned IslamQA snapshot (committed under data/islamqa/raw, fetched if absent) → answers, sha256-checked."""
    import gzip

    raw = ISLAMQA / "raw"
    for w in snapshot_witnesses(_load(CORPUS / "fatawa" / "sources.json")["dump"]):
        if args.lang not in (None, w["lang"]):
            continue
        entry = fetch(w, raw, refresh=args.refresh)
        if entry["sha256"] != w["sha256"]:
            print(f"{w['id']}: sha256 {entry['sha256']} != pinned {w['sha256']}", file=sys.stderr)
            return 1
        with gzip.open(raw / f"{w['id']}.ndjson.gz", "rt", encoding="utf-8") as f:
            records = answers(fold(map(json.loads, f)))
        out = ISLAMQA / "answers" / f"{w['id']}.jsonl.gz"
        write_jsonl_gz(out, records)
        print(f"{w['id']:12} {len(records):>6} answers  → {out.relative_to(ROOT)}")
    return 0


def cmd_labels(_: argparse.Namespace) -> int:
    """Arabic answers → candidate labels (LFS) + counts report and a stratified review sample (committed)."""
    import gzip

    with gzip.open(ISLAMQA / "answers" / "islamqa-ar.jsonl.gz", "rt", encoding="utf-8") as f:
        recs = [json.loads(l) for l in f]
    labels = [label(r) for r in recs]
    write_jsonl_gz(ISLAMQA / "labels" / "islamqa-ar.labels.jsonl.gz", labels)
    rep = report(labels)
    _dump(CORPUS / "fatawa" / "labels_report.json", rep)
    review = CORPUS / "fatawa" / "review" / "labels-sample.jsonl"
    old = [json.loads(l) for l in review.read_text(encoding="utf-8").splitlines()] if review.exists() else []
    sample = merge_review(review_sample(labels, {r["id"]: r["title"] for r in recs}), old)
    review.parent.mkdir(parents=True, exist_ok=True)
    review.write_text("".join(json.dumps(x, ensure_ascii=False) + "\n" for x in sample), encoding="utf-8")
    print(f"{rep['labelled']}/{rep['total']} labelled  {rep['hukm']}")
    return 0


def cmd_bank_review(_: argparse.Namespace) -> int:
    """Bank verdict per candidate label (LFS), English cross-check report, triage of the review sample (gold stays human)."""
    import gzip

    def read(p: Path) -> list[dict]:
        with gzip.open(p, "rt", encoding="utf-8") as f:
            return [json.loads(l) for l in f]

    en = {r["id"]: en_vote((r.get("summary") or "") + " " + (r["answer"] or "")) for r in read(ISLAMQA / "answers" / "islamqa-en.jsonl.gz")}
    labels = read(ISLAMQA / "labels" / "islamqa-ar.labels.jsonl.gz")
    verdicts = [{"id": l["id"], "candidate": l["hukm"], **bank_review(l, en.get(l["id"]))} for l in labels]
    # The conflicts of the bare reading, followed round by round (docs/architecture/fatawa-labels.md#conflicts).
    rounds = [("R0 bare reading", frozenset()), ("R1 reading", frozenset({"roles"})), ("R2 jamʿ σ", frozenset({"roles", "didd"})),
              ("R3 jamʿ scope", frozenset({"roles", "didd", "scope"})), ("R4 tarjīḥ", STAGES - {"act"}), ("R5 act", STAGES)]
    clash = lambda v: v["class"] in ("conflict", "ikhtilaf")  # noqa: E731
    base = [l for l in labels if l["hukm"] and clash(bank_review(l, None, frozenset()))]
    by_round = {name: sum(clash(bank_review(l, None, st)) for l in base) for name, st in rounds}
    write_jsonl_gz(ISLAMQA / "labels" / "islamqa-ar.bank.jsonl.gz", verdicts)

    labelled = [v for v in verdicts if v["candidate"]]
    voted = [v for v in labelled if v["en"]]
    classes = ("confirmed", "consistent", "rejected", "misread", "ikhtilaf", "conflict", "no_reading")
    rep = {
        "labelled": len(labelled),
        "class": {c: sum(v["class"] == c for v in labelled) for c in classes},
        "class_by_hukm": {h: dict(Counter(v["class"] for v in labelled if v["candidate"] == h)) for h in ("wajib", "mandub", "mubah", "makruh", "haram")},
        "english_agreement_by_class": {c: {"agree": sum(v["en"] == v["candidate"] for v in voted if v["class"] == c),
                                           "voted": sum(v["class"] == c for v in voted)} for c in classes},
        "priority": dict(Counter(v["priority"] for v in labelled)),
        "omission_perspective": sum(v["act"] == "omission" for v in labelled),
        "english_agreement_by_matches_question": {
            str(flag): {"agree": sum(en.get(l["id"]) == l["hukm"] for l in labels if l["hukm"] and en.get(l["id"]) and l["matches_question"] is flag),
                        "voted": sum(1 for l in labels if l["hukm"] and en.get(l["id"]) and l["matches_question"] is flag)}
            for flag in (True, False)},
        "conflicts_by_round": by_round,
    }
    _dump(CORPUS / "fatawa" / "bank_review_report.json", rep)

    by_id = {v["id"]: v for v in verdicts}
    review = CORPUS / "fatawa" / "review" / "labels-sample.jsonl"
    sample = [json.loads(l) for l in review.read_text(encoding="utf-8").splitlines()]
    for x in sample:
        v = by_id[x["id"]]
        x |= {"bank": {k: v[k] for k in ("class", "set", "steps", "en")}, "priority": v["priority"]}
    review.write_text("".join(json.dumps(x, ensure_ascii=False) + "\n" for x in sample), encoding="utf-8")
    (ROOT / "formal/lean/UsulTest/FatawaBank.lean").write_text(lean_guards(), encoding="utf-8")
    print(json.dumps({k: rep[k] for k in ("class", "priority")}, ensure_ascii=False))
    print("review sample priority:", dict(Counter(x["priority"] for x in sample)))
    return 0


def cmd_oracle(_: argparse.Namespace) -> int:
    """Weighted training set (LFS) and baseline oracle report on dev and test (question text only)."""
    import gzip
    from collections import Counter

    def read(p: Path) -> list[dict]:
        with gzip.open(p, "rt", encoding="utf-8") as f:
            return [json.loads(l) for l in f]

    answers = {r["id"]: r for r in read(ISLAMQA / "answers" / "islamqa-ar.jsonl.gz")}
    verdicts = {v["id"]: v for v in read(ISLAMQA / "labels" / "islamqa-ar.bank.jsonl.gz")}
    rows = [{"id": l["id"], "split": l["split"], "title": answers[l["id"]]["title"], "question": answers[l["id"]].get("question"),
             "hukm": l["hukm"], "weight": round(confidence(l, verdicts[l["id"]]), 4), "basis": l["basis"],
             "bank": verdicts[l["id"]]["class"], "matches_question": l["matches_question"]}
            for l in read(ISLAMQA / "labels" / "islamqa-ar.labels.jsonl.gz") if l["hukm"]]
    write_jsonl_gz(ISLAMQA / "train" / "islamqa-ar.jsonl.gz", rows)

    docs = lambda split: [(r["id"], r["hukm"], r["weight"], features(r)) for r in rows if r["split"] == split]  # noqa: E731
    train = [d for d in docs("train") if d[2] > 0]
    retriever, bayes = Retriever(train), NaiveBayes(train)
    majority = Counter(h for _, h, *_ in train).most_common(1)[0][0]
    report: dict = {"train": len(train), "majority": majority, "splits": {}}
    for split in ("dev", "test"):
        ev = docs(split)
        hits = [retriever.predict(f) for *_, f in ev]
        predictions = {"majority": [majority] * len(ev), "retriever": [h["hukm"] for h in hits],
                       "naive_bayes": [bayes.predict(f) for *_, f in ev]}
        subsets = {"all": [True] * len(ev), "high_confidence": [w >= 0.7 for _, _, w, _ in ev]}
        report["splits"][split] = {
            sub: {name: evaluate([p for p, m in zip(ps, mask) if m], [d[1] for d, m in zip(ev, mask) if m])
                  for name, ps in predictions.items()}
            for sub, mask in subsets.items()}
        report["splits"][split]["retriever_abstaining"] = {
            str(tau): evaluate([h["hukm"] if h["score"] >= tau else None for h in hits], [d[1] for d in ev])
            for tau in (0.2, 0.3, 0.5)}
    _dump(CORPUS / "fatawa" / "oracle_report.json", report)
    for split, r in report["splits"].items():
        print(split, {k: round(v["accuracy"], 3) for k, v in r["all"].items()}, "| high:",
              {k: round(v["accuracy"], 3) for k, v in r["high_confidence"].items()})
    return 0


def cmd_fatawa_takhrij(_: argparse.Namespace) -> int:
    """IslamQA cases for the bank's encoders: check them against the kernel and their answers, guard them in Lean."""
    import gzip

    from . import fatawa_takhrij, takhrij
    with gzip.open(ISLAMQA / "answers" / "islamqa-ar.jsonl.gz", "rt", encoding="utf-8") as f:
        answers = {r["id"]: r for r in map(json.loads, f)}
    cases = fatawa_takhrij.load(CORPUS)
    if bad := fatawa_takhrij.check(cases, answers):
        print(json.dumps(bad, ensure_ascii=False, indent=1))
        return 1
    (SIGNATURE_LEAN.parent / "FatawaTakhrij.lean").write_text(fatawa_takhrij.lean_file(cases), encoding="utf-8")
    rep = takhrij.report(cases)
    _dump(CORPUS / "fatawa" / "takhrij" / "report.json", rep)
    print(json.dumps({k: rep[k] for k in ("total", "coverage", "encoding_error", "classes")}, ensure_ascii=False))
    return 0


def cmd_fatawa_prolog(_: argparse.Namespace) -> int:
    """The takhrīj cases as Prolog facts and fixture vectors; the oracle's agreement with the texts."""
    from . import fatawa_prolog, fatawa_takhrij
    cases, facts = fatawa_takhrij.load(CORPUS), fatawa_prolog.load_facts(CORPUS)
    if errs := fatawa_prolog.check(cases, facts):
        print("\n".join(errs))
        return 1
    records = fatawa_prolog.merge(cases, facts)
    (ROOT / fatawa_prolog.CASES).write_text(fatawa_prolog.prolog_file(records), encoding="utf-8")
    rep = fatawa_prolog.report(records, fatawa_prolog.run(ROOT))
    _dump(CORPUS / "fatawa" / "prolog" / "report.json", rep)
    print(json.dumps({k: rep[k] for k in ("total", "per_encoder")}, ensure_ascii=False))
    return 0


def cmd_validate(_: argparse.Namespace) -> int:
    import jsonschema  # test-time dependency only
    from . import m5_commands

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
    try:
        m5_commands.validate(_load(CORPUS / m5_commands.PLAN), CORPUS)
    except (ValueError, KeyError, OSError) as e:
        errors.append(f"m5-commands: {e}")
    print("\n".join(errors) or f"ok: registry + {len(ids)} records + signature map + M5 receipts")
    return 1 if errors else 0


def parser() -> argparse.ArgumentParser:
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
    rc = sub.add_parser("reconcile", help="resolve the bank's apparent contradictions by its own taʿāruḍ procedure")
    rc.add_argument("--draft", action="store_true", help="print draft ledger entries for unledgered contradictions")
    rc.set_defaults(run=cmd_reconcile)
    for name in ("worklist", "m8-worklist"):  # m8-worklist: the name before the unit inventory
        m = sub.add_parser(name, help="regenerate or --check the obligation inventories")
        m.add_argument("--check", action="store_true")
        m.set_defaults(run=cmd_worklist)
    tr = sub.add_parser("typed-routing", help="route the blind-typed sets by type: reports and lane-B proposals (needs swipl)")
    tr.add_argument("--check", action="store_true")
    tr.set_defaults(run=cmd_typed_routing)
    r = sub.add_parser("routing", help="regenerate or --check the encoder routing index (P0.6)")
    r.add_argument("--check", action="store_true")
    r.set_defaults(run=cmd_routing)
    m5 = sub.add_parser("m5-commands", help="check candidate command capabilities and source receipts")
    m5.add_argument("--fetch-source", action="store_true", help="restore the full pinned witness without repinning")
    m5.set_defaults(run=cmd_m5_commands)
    sub.add_parser("docs").set_defaults(run=cmd_docs)
    sub.add_parser("reception").set_defaults(run=cmd_reception)
    sub.add_parser("texts").set_defaults(run=cmd_texts)
    mn = sub.add_parser("mentions")
    mn.add_argument("--review", type=int, default=300, help="rows per task in the review queue")
    mn.add_argument("--import", dest="import_", metavar="FILE", help="reviewed JSONL rows to merge into the gold labels")
    mn.set_defaults(run=cmd_mentions)
    sub.add_parser("labels").set_defaults(run=cmd_labels)
    sub.add_parser("bank-review").set_defaults(run=cmd_bank_review)
    sub.add_parser("oracle").set_defaults(run=cmd_oracle)
    sub.add_parser("fatawa-takhrij").set_defaults(run=cmd_fatawa_takhrij)
    sub.add_parser("fatawa-prolog").set_defaults(run=cmd_fatawa_prolog)
    fa = sub.add_parser("fatawa")
    fa.add_argument("--lang")
    fa.add_argument("--refresh", action="store_true")
    fa.set_defaults(run=cmd_fatawa)
    o = sub.add_parser("ocr")
    o.add_argument("--work")
    o.add_argument("--pages", help="PDF page range A-B (default: all)")
    o.add_argument("--jobs", type=int, default=4)
    o.set_defaults(run=cmd_ocr)
    return p


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    return args.run(args)


if __name__ == "__main__":
    sys.exit(main())
