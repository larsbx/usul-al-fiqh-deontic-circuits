"""Maḥall: the item, act or issue each farʿ rules on, defined by a canonical text (PR-51).

Every case has a **maḥall**, the thing its ruling falls on. It may be an item (ʿayn: water, a dog,
a pledged house), an act (fiʿl: prayer, sale, vow) or an issue (ḥāl: doubt, ignorance,
compulsion). A maḥall is a **label** in a tree rooted in the bābs of fiqh. Each label is defined
by the canonical text that names it: a Qurʾānic āya, a ḥadīth from the six books, or a reported
ijmāʿ. The text is quoted verbatim from its pinned witness. A label no canonical text names is
recorded ``unanchored``, with the reason.

Data (write-isolated fragments, one per shard):

- ``corpus/mahall/abwab.json``: the roots, the bābs.
- ``corpus/mahall/labels/<shard>.json``: ``{id, ar, en, kind, broader, nass: [...] | unanchored}``.
- ``corpus/mahall/furu/<shard>.json``: ``{far, label, term_ar, also?: [{label, term_ar}]}``.
  ``term_ar`` is the case's own words for the maḥall, verbatim.

The **label graph** has these nodes and edges:

- nodes: furūʿ, labels, qawāʿid and nuṣūṣ;
- farʿ → qāʿida: the text's own placement;
- farʿ → label: its maḥall;
- label → label: broader;
- naṣṣ → label: defines.

``Usul.Mahall`` proves how the edges compose. A qāʿida's footprint is the up-closure of its
furūʿ's maḥalls. Every naṣṣ defining an ancestor of a farʿ's maḥall grounds that farʿ's
qāʿida. ``UsulTest/MahallGraph.lean`` checks the concrete graph against these definitions.
"""

from __future__ import annotations

import json
import re
from functools import cache
from pathlib import Path

from . import nusus

DIR = "mahall"
KINDS = ("item", "act", "issue")
QURAN = "tanzil-quran-simple"
SUNNAH = {"openiti-bukhari-shamela1681", "openiti-muslim-shamela1727", "openiti-abudawud-shamela1726",
          "openiti-tirmidhi-shamela7895", "openiti-nasai-shamela829", "openiti-ibnmaja-shamela1198"}
IJMA = {"openiti-ibnqudama-mughni-shamela8463"}
NASS = {"quran": {QURAN}, "sunnah": SUNNAH, "athar": SUNNAH, "ijma": IJMA}
REF = re.compile(r"^src:([a-z0-9-]+)(?:#Q(\d{3}):(\d{3}))?$")
IJMA_MARK = re.compile(r"إجماع|أجمع|اجماع|اجمع|بلا خلاف|لا خلاف|لا نعلم.{0,30}خلاف|لا يختلف|اتفق|اتفاق")
LABEL = re.compile(r"^[a-z]+(?:\.[a-z0-9_]+)*$")
MAX = 200
SOURCES = ("ibn_rajab.taqrir_qawaid.openiti_rajab_shamela21730", "ibn_lahham.qawaid_fawaid.openiti_lahham_shamela8526")


def _fragments(corpus: Path, sub: str, key: str) -> list[dict]:
    return [e for p in sorted((corpus / DIR / sub).glob("*.json"))
            for e in json.loads(p.read_text(encoding="utf-8"))[key]]


def load(corpus: Path) -> tuple[list[dict], list[dict], list[dict]]:
    """(abwab, labels, furūʿ entries)."""
    abwab = json.loads((corpus / DIR / "abwab.json").read_text(encoding="utf-8"))["abwab"]
    return abwab, _fragments(corpus, "labels", "labels"), _fragments(corpus, "furu", "entries")


def records(corpus: Path) -> dict[str, dict]:
    """Every farʿ of the segmented qawāʿid works, by id."""
    out = {}
    for w in ("openiti-rajab-shamela21730", "openiti-lahham-shamela8526"):
        for line in (corpus / "records" / f"{w}.jsonl").read_text(encoding="utf-8").splitlines():
            r = json.loads(line)
            if r.get("record_type") == "far":
                out[r["id"]] = r
    return out


def cases(corpus: Path) -> set[str]:
    """The furūʿ that need a maḥall: every annotated takhrīj case drawn from the qawāʿid works."""
    from . import takhrij
    return {c["far"] for c in takhrij.load(corpus) if c["far"].startswith(SOURCES)}


def parents(abwab: list[dict], labels: list[dict]) -> dict[str, list[str]]:
    """label → its broader labels. A maḥall may sit under several (debt under sale and loan); a bāb
    under none."""
    return {b["id"]: [] for b in abwab} | {l["id"]: list(l["broader"]) for l in labels}


def ancestors(up: dict[str, list[str]], l: str) -> set[str] | None:
    """``l`` and every label above it; None on a cycle or a dangling parent."""
    out: set[str] = set()

    def climb(x: str, path: frozenset[str]) -> bool:
        if x not in up or x in path:
            return False
        out.add(x)
        return all(climb(y, path | {x}) for y in up[x])
    return out if climb(l, frozenset()) else None


def roots(up: dict[str, list[str]], l: str) -> set[str]:
    """The bābs a label descends from."""
    return {a for a in ancestors(up, l) or () if not up[a]}


def qid(author: str, n: int) -> str:
    """A qāʿida's short id: ``r013`` (Ibn Rajab), ``l043`` (Ibn al-Laḥḥām), ``s028`` (al-Saʿdī)."""
    return {"Ibn Rajab": "r", "Ibn al-Laḥḥām": "l", "al-Saʿdī": "s"}[author] + f"{n:03d}"


def encoder_qawaid(encoder: str) -> list[str]:
    """The qawāʿid an encoder reads: its Ibn Rajab or Ibn al-Laḥḥām qawāʿid and al-Saʿdī's."""
    from . import takhrij
    e = takhrij.ENCODERS[encoder]
    return sorted({short(q) for q in e["qawaid"]} | {qid("al-Saʿdī", n) for n in e.get("sadi", [])})


def links(corpus: Path) -> dict[str, dict[str, list[str]]]:
    """farʿ → the qawāʿid the bank ties it to, by provenance:

    - ``placed``: the qāʿida its author files it under;
    - ``read``: its encoder's qawāʿid, al-Saʿdī's included;
    - ``typed``: the qawāʿid cited by the types whose facts that encoder reads;
    - ``co``: those of its co-annotations.

    A farʿ may turn on several qawāʿid, a type may cite several, and several types may cite one."""
    from . import deduction, scope, takhrij
    export = (corpus.parent / "examples/v41_types.pl").read_text(encoding="utf-8")
    statement = dict(re.findall(r"^qaida_type\((\w+), '((?:[^']|'')*)'\)\.", export, re.M))
    owner: dict[str, set[str]] = {}
    for t, f in re.findall(r"^type_field\((\w+), (\w+), ", export, re.M):
        owner.setdefault(f, set()).add(t)
    reads = deduction.reads(export)
    of_encoder = encoder_qawaid
    of_types = lambda e: sorted({qid(a, n) for f in reads.get(e, []) for t in owner.get(f, ())
                                 for a, n in scope.cited(t, statement.get(t, ""))})
    co: dict[str, set[str]] = {}
    for p in sorted((corpus / "takhrij/co").glob("*.json")):
        for c in json.loads(p.read_text(encoding="utf-8"))["cases"]:
            co.setdefault(c["far"], set()).update(of_encoder(c["encoder"]))
    recs = records(corpus)
    return {c["far"]: {"placed": [short(recs[c["far"]]["qaida"])], "read": of_encoder(c["encoder"]),
                       "typed": of_types(c["encoder"]), "co": sorted(co.get(c["far"], ()))}
            for c in takhrij.load(corpus) if c["far"].startswith(SOURCES)}


def under(link: dict[str, list[str]]) -> list[str]:
    """Every qāʿida a farʿ is tied to, whatever the provenance."""
    return sorted({q for qs in link.values() for q in qs})


def check(corpus: Path) -> list[str]:
    """Structure: well-formed labels, each under one or more broader labels without a cycle and
    under its own bāb among others, each defined or unanchored with a reason; every case given
    exactly one primary maḥall (and up to two more), named in its own words."""
    abwab, labels, entries = load(corpus)
    errs, seen = [], {}
    for l in labels:
        if l["id"] in seen or l["id"] in {b["id"] for b in abwab}:
            errs.append(f"{l['id']}: declared twice")
        seen[l["id"]] = l
        if not LABEL.fullmatch(l["id"]):
            errs.append(f"{l['id']}: bad id")
        if l.get("kind") not in KINDS:
            errs.append(f"{l['id']}: kind must be one of {KINDS}")
        if not (str(l.get("ar", "")).strip() and str(l.get("en", "")).strip()):
            errs.append(f"{l['id']}: needs ar and en")
        if ("nass" in l) == ("unanchored" in l) or ("nass" in l and not l["nass"]):
            errs.append(f"{l['id']}: needs exactly one of a non-empty nass and unanchored")
        for n in l.get("nass", []):
            m = REF.fullmatch(n.get("ref", ""))
            if n.get("kind") not in NASS or not m or m[1] not in NASS[n["kind"]] or bool(m[2]) != (n["kind"] == "quran"):
                errs.append(f"{l['id']}: bad nass ref {n.get('kind')} {n.get('ref')!r}")
            if not 2 <= len(n.get("excerpt_ar", "").split()) or len(n.get("excerpt_ar", "")) > MAX:
                errs.append(f"{l['id']}: a nass excerpt is two words to {MAX} characters")
            if n.get("kind") == "ijma" and not IJMA_MARK.search(n.get("excerpt_ar", "")):
                errs.append(f"{l['id']}: an ijmāʿ excerpt must state the agreement")
            graded = [k for k in ("albani", "sahihayn", "ungraded") if k in n]
            if n.get("sahihayn") and n["kind"] != "sunnah":
                errs.append(f"{l['id']}: only a ḥadīth (sunnah) has the Ṣaḥīḥayn's standing")
            if graded and n["kind"] not in ("sunnah", "athar") or len(graded) > 1:
                errs.append(f"{l['id']}: a ḥadīth or athar carries at most one of albani, sahihayn, ungraded")
            if (type(n.get("number")) is int) != (n.get("kind") != "quran"):
                errs.append(f"{l['id']}: a ḥadīth, athar or ijmāʿ cites its number in its witness; a verse its āya")
            for c in ([n["albani"]] if "albani" in n else []) + n.get("weaker_routes", []):
                if set(c) != {"work", "witness", "number", "verdict"} or c["verdict"] not in nusus.VERDICT.values():
                    errs.append(f"{l['id']}: bad albani citation {c}")
            if "sahihayn" in n and n["sahihayn"] != {"witness": m and m[1], "number": n.get("number")}:
                errs.append(f"{l['id']}: the Ṣaḥīḥayn standing cites the anchor's own ḥadīth {n['sahihayn']}")
    up = parents(abwab, labels)
    for l in labels:
        if not isinstance(l.get("broader"), list) or not l["broader"]:
            errs.append(f"{l['id']}: broader is a non-empty list")
    for l in up:
        if ancestors(up, l) is None:
            errs.append(f"{l}: on a cycle or under an unknown label")
        elif l.split(".")[0] not in roots(up, l):
            errs.append(f"{l}: not under its own bāb {l.split('.')[0]}")
    recs, need, done = records(corpus), cases(corpus), set()
    for e in entries:
        f = e["far"]
        if f in done:
            errs.append(f"{f}: given twice")
        done.add(f)
        if f not in recs:
            errs.append(f"{f}: not a farʿ")
            continue
        for x in [e] + e.get("also", []):
            if x["label"] not in up:
                errs.append(f"{f}: unknown label {x['label']}")
            if not x.get("term_ar") or len(x["term_ar"]) > 80 or x["term_ar"] not in recs[f]["case_ar"]:
                errs.append(f"{f}: term {x.get('term_ar')!r} is not verbatim in the case")
    errs += [f"{f}: no maḥall" for f in sorted(need - done)]
    return errs


@cache
def _witness(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def verify(nass: dict, cache_dir: Path) -> str | None:
    """None when the excerpt is verbatim (letters only) in its witness: within the cited āya
    for the Qurʾān, anywhere in the collection otherwise."""
    m = REF.fullmatch(nass["ref"])
    text = _witness(cache_dir / f"{m[1]}.txt")
    if m[2]:
        a = nusus.aya(text, int(m[2]), int(m[3]))
        if a is None:
            return f"no āya {m[2]}:{m[3]}"
        return None if nusus.key(nass["excerpt_ar"]) in nusus.key(a) else f"not in āya {m[2]}:{m[3]}"
    return None if nusus.find(text, nass["excerpt_ar"]) is not None else f"not in {m[1]}"


def footprint(corpus: Path) -> dict[str, list[str]]:
    """qāʿida → the up-closure of the maḥalls of every farʿ tied to it (``Usul.Mahall.footprint``)."""
    abwab, labels, entries = load(corpus)
    up, tied, out = parents(abwab, labels), links(corpus), {}
    for e in entries:
        for q in under(tied[e["far"]]):
            for x in [e] + e.get("also", []):
                out.setdefault(q, set()).update(ancestors(up, x["label"]))
    return {q: sorted(v) for q, v in sorted(out.items())}


GRAPH = "mahall/graph.json"
LEAN = "MahallGraph.lean"
FUEL = 16


def short(i: str) -> str:
    """``r013.f010`` for Ibn Rajab's q013.f010, ``l043.f001`` for Ibn al-Laḥḥām's; a qāʿida ``r013``."""
    return ("r" if i.startswith(SOURCES[0]) else "l") + re.search(r"\.q(\d{3}(?:\.f\w+)?)$", i)[1]


def export(corpus: Path) -> dict:
    """The graph in the form ``Usul.Mahall.Data`` takes: short ids, nuṣūṣ numbered by first use,
    and per qāʿida its footprint and grounds."""
    abwab, labels, entries = load(corpus)
    from . import grading
    nass: dict[tuple[str, str], str] = {}
    meta: dict[str, dict] = {}
    for l in sorted(labels, key=lambda l: l["id"]):
        for n in l.get("nass", []):
            v = nass.setdefault((n["ref"], n["excerpt_ar"]), f"n{len(nass) + 1:04d}")
            meta.setdefault(v, {"ref": n["ref"], "excerpt_ar": n["excerpt_ar"], "kind": n["kind"],
                                **{k: n[k] for k in ("number", "albani", "weaker_routes", "sahihayn", "ungraded") if k in n},
                                "hujja": grading.hujja(n)})
    defines = sorted({(nass[n["ref"], n["excerpt_ar"]], l["id"]) for l in labels for n in l.get("nass", [])})
    fp, tied = footprint(corpus), links(corpus)
    grounds = {q: sorted({n for n, l in defines if l in set(v)}) for q, v in fp.items()}
    hujja = {q: [n for n in v if meta[n]["hujja"]] for q, v in grounds.items()}
    return {"schema_version": 1, "status": "candidate", "generated_by": "python -m usul_corpus mahall",
            "fuel": FUEL,
            "labels": sorted([b["id"] for b in abwab] + [l["id"] for l in labels]),
            "furu": [{"id": short(e["far"]), "qawaid": under(tied[e["far"]]), "links": tied[e["far"]],
                      "labels": [x["label"] for x in [e] + e.get("also", [])]} for e in sorted(entries, key=lambda e: short(e["far"]))],
            "up": sorted([l["id"], b] for l in labels for b in l["broader"]),
            "nass": meta, "defines": [list(p) for p in defines], "footprint": fp, "grounds": grounds,
            "grounds_hujja": hujja}


def _s(x: str) -> str:
    return json.dumps(x, ensure_ascii=False)


def _list(xs) -> str:
    return "[" + ", ".join(_s(x) for x in xs) + "]"


def _chunks(name: str, ty: str, items: list[str], n: int = 100) -> tuple[list[str], str]:
    """Defs of at most ``n`` list items each (a long list literal exceeds the elaborator's depth), and
    their concatenation."""
    parts = [items[i:i + n] for i in range(0, len(items), n)] or [[]]
    defs = [f"def {name}{k} : List {ty} := [\n  " + ",\n  ".join(p) + "]\n" for k, p in enumerate(parts)]
    return defs, " ++ ".join(f"{name}{k}" for k in range(len(parts)))


def lean_file(g: dict) -> str:
    """``UsulTest/MahallGraph.lean``: the graph as ``Usul.Mahall.Data``; guards that every label is
    rooted and that each qāʿida's footprint and grounds are exactly the pipeline's."""
    fd, furu = _chunks("furu", "Far", [f"⟨{_s(f['id'])}, {_list(f['qawaid'])}, {_list(f['labels'])}⟩" for f in g["furu"]])
    ud, up = _chunks("up", "(String × String)", [f"({_s(a)}, {_s(b)})" for a, b in g["up"]])
    dd, df = _chunks("defines", "(String × String)", [f"({_s(a)}, {_s(b)})" for a, b in g["defines"]])
    graded = [f"({_s(n)}, .{m['albani']['verdict']})" for n, m in g["nass"].items() if "albani" in m]
    vd, verdicts = _chunks("verdicts", "(String × Hadith.Verdict)", graded)
    pd, proof = _chunks("proof", "String", [_s(n) for n, m in g["nass"].items()
                                              if m["kind"] in ("quran", "ijma") or m.get("sahihayn")])
    lines = [f"-- GENERATED by `python -m usul_corpus mahall` from corpus/mahall. Do not edit.",
             "import Usul.Mahall", "import Usul.Seam", "", "namespace UsulTest.MahallGraph", "open Usul.Mahall", "",
             *fd, *ud, *dd, *vd, *pd,
             "/-- The label graph: each case's maḥall, the label tree, and the nuṣūṣ defining labels",
             f"(`corpus/{GRAPH}` holds each naṣṣ's reference and excerpt). -/",
             f"def data : Data where\n  furu := {furu}\n  up := {up}\n  defines := {df}", "",
             "/- Every upward path ends at a bāb within the fuel: the label graph has no cycle, and",
             "`belowB` at that fuel decides `Below`. -/",
             f"#guard data.rootedB {g['fuel']}", "",
             "/- Each qāʿida's footprint and grounds are exactly the pipeline's lists (`exactB_sound`). -/"]
    lines += ["", "/-- al-Albānī's verdict on each graded ḥadīth or athar (`corpus/mahall/graph.json`). -/",
              f"def verdicts : List (String × Hadith.Verdict) := {verdicts}", "",
              "/-- Texts that are proof without a verdict of his: the Qurʾān, a reported ijmāʿ, and the",
              "Ṣaḥīḥayn where his works do not grade the ḥadīth. -/",
              f"def proof : List String := {proof}", "",
              "/-- A text is ḥujja when it is `proof`, or a ḥadīth `Usul.Seam.admitted` admits on al-Albānī's",
              "verdict. An ungraded ḥadīth is not. -/",
              "def hujja (n : String) : Bool :=",
              "  proof.contains n || match verdicts.lookup n with",
              "    | some v => Usul.Seam.admitted ⟨.nass, v⟩",
              "    | none => false", ""]
    for q, v in g["footprint"].items():
        lines.append(f"#guard data.exactB {g['fuel']} {_s(q)} {_list(v)} {_list(g['grounds'][q])}")
    lines += ["", "/- Each qāʿida's grounds through the ḥujja gate are exactly the pipeline's (`exactB_sound`,",
              "`grounds_gated`): each is ḥujja by `Usul.Seam.admitted` and grounds the qāʿida. -/"]
    for q, v in g["footprint"].items():
        lines.append(f"#guard (data.gated hujja).exactB {g['fuel']} {_s(q)} {_list(v)} {_list(g['grounds_hujja'][q])}")
    return "\n".join(lines + ["", "end UsulTest.MahallGraph", ""])
