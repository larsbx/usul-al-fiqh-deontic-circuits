"""The roadmaps of the parallel tracks, kept consistent (`docs/roadmap-tracks.json`).

Structure, checked always (`check`): the hub links every track's roadmap; in each, milestone ids
are unique, every ``⟵`` dependency resolves (in its track, in another by its name, «uṣūl M5», or in
the hub, «existing Milestone 1b»), the dependencies are acyclic, a Mermaid DAG draws exactly the
headings' edges within the track (and may draw their edges from another), and a status row names a
milestone that exists. Each track's paths match a file, no file belongs to two tracks, and every
registry ``track`` is declared.

Change, checked against a base (`stale`): a change to a path a track owns updates that track's
roadmap, unless a commit in the range says why not with
a ``Roadmap-Unchanged: <reason>`` trailer. Paths no track owns need nothing.
"""

from __future__ import annotations

import json
import re
import subprocess
from functools import cache
from pathlib import Path

MANIFEST = "docs/roadmap-tracks.json"
ALIASES = {"uṣūl": "usul", "ḥadīth": "hadith"}       # how one roadmap names another track
_HEAD = re.compile(r"^#{3,4} ([A-Z]\d+) · .+? ⟵ (.+)$", re.M)
_DEP = re.compile(r"^(?:(\S+) )?([A-Z]\d+)(?: onward)?$")
_HUB = re.compile(r"^existing Milestones? (\d+[a-z]?)(?:[–-](\d+[a-z]?))?$")
_ROW = re.compile(r"^\| ([A-Z]\d+)\b", re.M)
_EDGE = re.compile(r"([A-Z]\d+)(?:\[[^\]]*\])? --> ([A-Z]\d+)")
_TRAILER = re.compile(r"^Roadmap-Unchanged:[ \t]*\S", re.M)


def load(root: Path) -> dict:
    return json.loads((root / MANIFEST).read_text(encoding="utf-8"))


def _deps(spec: str) -> list[str]:
    return [d.strip() for d in spec.split(",") if d.strip() not in ("", "—")]


def milestones(doc: str, prefix: str) -> dict[str, set[str]]:
    """Each milestone of the track and its dependencies within it."""
    return {m[1]: {d[2] for d in map(_DEP.match, _deps(m[2])) if d and not d[1]}
            for m in _HEAD.finditer(doc) if m[1].startswith(prefix)}


def cross(doc: str) -> set[tuple[str, str, str]]:
    """(milestone, other track, its milestone) for each dependency on another track."""
    return {(m[1], ALIASES.get(d[1], d[1]), d[2]) for m in _HEAD.finditer(doc)
            for d in map(_DEP.match, _deps(m[2])) if d and d[1]}


def _cycle(graph: dict[str, set[str]]) -> list[str] | None:
    done: set[str] = set()

    def visit(n: str, path: list[str]) -> list[str] | None:
        if n in path:
            return path[path.index(n):] + [n]
        if n in done:
            return None
        found = next((c for d in sorted(graph.get(n, ())) if (c := visit(d, path + [n]))), None)
        done.add(n)
        return found
    return next((c for n in sorted(graph) if (c := visit(n, []))), None)


def doc_errors(name: str, doc: str, prefix: str, hub: str = "") -> list[str]:
    """What is inconsistent in one track's roadmap."""
    errs, ids = [], [m[1] for m in _HEAD.finditer(doc) if m[1].startswith(prefix)]
    errs += [f"{name}: milestone {i} twice" for i in sorted({i for i in ids if ids.count(i) > 1})]
    graph = milestones(doc, prefix)
    for m in _HEAD.finditer(doc):
        for d in _deps(m[2]):
            dep, ref = _DEP.match(d), _HUB.match(d)
            if ref and hub and not all(re.search(rf"^## Milestone {r}\b", hub, re.M) for r in filter(None, ref.groups())):
                errs.append(f"{name}: {m[1]} depends on hub milestone {d!r}, which the hub lacks")
            elif not (dep or ref):
                errs.append(f"{name}: {m[1]} has an unreadable dependency {d!r}")
            elif dep and not dep[1] and dep[2] not in graph:
                errs.append(f"{name}: {m[1]} depends on unknown {dep[2]}")
    if c := _cycle(graph):
        errs.append(f"{name}: dependency cycle {' → '.join(c)}")
    if mer := re.search(r"```mermaid\n(.*?)```", doc, re.S):
        drawn, own = set(_EDGE.findall(mer[1])), {(d, m) for m, ds in graph.items() for d in ds}
        unstated, undrawn = drawn - own - {(d, m) for m, _, d in cross(doc)}, own - drawn   # drawing another track's edge is optional
        if unstated or undrawn:
            errs.append(f"{name}: the mermaid DAG differs from the headings: drawn only {sorted(unstated)}, "
                        f"stated only {sorted(undrawn)}")
    errs += [f"{name}: status row {r} names no milestone" for r in sorted(set(_ROW.findall(doc)))
             if r.startswith(prefix) and r not in graph]
    return errs


@cache
def _glob(pattern: str) -> re.Pattern:
    parts = re.split(r"(\*\*/?|\*)", pattern)
    return re.compile("".join(".*" if p.startswith("**") else "[^/]*" if p == "*" else re.escape(p) for p in parts))


def owners(tracks: dict, path: str) -> list[str]:
    return [t for t, v in tracks["tracks"].items() if any(_glob(g).fullmatch(path) for g in v["paths"])]


def overlaps(tracks: dict, files: list[str]) -> list[str]:
    """Each file answers to one roadmap: the files two tracks claim."""
    return [f"{f} is claimed by {' and '.join(os)}" for f in files if len(os := owners(tracks, f)) > 1]


def registry_tracks(root: Path) -> set[str]:
    return {w["track"] for w in json.loads((root / "corpus/registry.json").read_text(encoding="utf-8"))["works"] if "track" in w}


def check(root: Path) -> list[str]:
    """Every structural inconsistency across the roadmaps."""
    tr = load(root)
    hub = (root / tr["hub"]).read_text(encoding="utf-8")
    files = [p.relative_to(root).as_posix() for p in root.rglob("*") if p.is_file() and ".git" not in p.parts
             and ".lake" not in p.parts and ".cache" not in p.parts]
    docs = {t: (root / v["roadmap"]).read_text(encoding="utf-8") for t, v in tr["tracks"].items()}
    errs = [f"{tr['hub']} does not link {v['roadmap']}" for v in tr["tracks"].values()
            if v["roadmap"] != tr["hub"] and Path(v["roadmap"]).name not in hub]
    for t, v in tr["tracks"].items():
        if "prefix" in v:
            errs += doc_errors(t, docs[t], v["prefix"], hub)
            for m, other, d in sorted(cross(docs[t])):
                o = tr["tracks"].get(other, {})
                if d not in milestones(docs.get(other, ""), o.get("prefix", "?")):
                    errs.append(f"{t}: {m} depends on {other} {d}, which that roadmap lacks")
        errs += [f"{t}: path {g} matches no file" for g in v["paths"] if not any(_glob(g).fullmatch(f) for f in files)]
    errs += overlaps(tr, files)
    declared = {v.get("registry") for v in tr["tracks"].values()}
    errs += [f"corpus/registry.json: track {r!r} is not declared in {MANIFEST}" for r in sorted(registry_tracks(root) - declared)]
    return errs


def waived(messages: str) -> bool:
    return bool(_TRAILER.search(messages))


def stale(tracks: dict, changed: set[str], waived: bool) -> list[str]:
    """For each track whose paths changed while its roadmap did not: what changed."""
    if waived:
        return []
    missed: dict[str, list[str]] = {}
    for p in sorted(changed):
        for t in owners(tracks, p):
            if tracks["tracks"][t]["roadmap"] not in changed:
                missed.setdefault(t, []).append(p)
    return [f"{ps[0]}{f' and {len(ps) - 1} more' if len(ps) > 1 else ''} ({t}) changed, but "
            f"{tracks['tracks'][t]['roadmap']} did not" for t, ps in missed.items()]


def _git(root: Path, *args: str) -> str:
    return subprocess.run(["git", *args], cwd=root, check=True, capture_output=True, text=True).stdout


def changes(root: Path, base: str) -> tuple[set[str], str]:
    """The paths changed since the merge base with ``base`` (committed, staged, unstaged or new), and
    the messages of the commits since it."""
    mb = _git(root, "merge-base", base, "HEAD").strip()
    paths = _git(root, "diff", "--name-only", mb).split() + _git(root, "ls-files", "--others", "--exclude-standard").split()
    return set(paths), _git(root, "log", "--format=%B", f"{mb}..HEAD")
