"""The recorded method names only things that exist (docs/architecture/derivation-method.md, the
derivation-tranche skill, and the roadmap that applies them). A rename that leaves the method
pointing at nothing fails here."""

import importlib
import re
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
DOCS = ("docs/architecture/derivation-method.md", ".claude/skills/derivation-tranche/SKILL.md", "docs/roadmap-parallel-derivation.md")
_TICK = re.compile(r"`([^`\n]+)`")
_PATH = re.compile(r"^(?:corpus|pipeline|formal|docs|schemas|\.claude)/[\w./-]+$")
_LEAN_DEF = re.compile(r"^\s*(?:@\[[^\]]*\]\s*)?(?:private\s+|protected\s+|noncomputable\s+)*(?:def|theorem|lemma|abbrev|structure|inductive|instance|class)\s+([\w.']+)", re.M)


def _ticked(doc: str) -> list[str]:
    return _TICK.findall((ROOT / doc).read_text(encoding="utf-8"))


def _subcommands() -> set[str]:
    return set(re.findall(r'add_parser\("([\w-]+)"', (ROOT / "pipeline/usul_corpus/__main__.py").read_text(encoding="utf-8")))


def _tests() -> set[str]:
    return {m for p in (ROOT / "pipeline/tests").glob("test_*.py") for m in re.findall(r"^def (test_\w+)", p.read_text(encoding="utf-8"), re.M)}


def _lean_names() -> set[str]:
    return {n.split(".")[-1] for p in (ROOT / "formal/lean").rglob("*.lean") if ".lake" not in p.parts
            for n in _LEAN_DEF.findall(p.read_text(encoding="utf-8"))}


@pytest.mark.parametrize("doc", DOCS)
def test_method_names_resolve(doc):
    tests, cmds, lean = _tests(), _subcommands(), _lean_names()
    missing = []
    for t in _ticked(doc):
        for name in re.findall(r"\btest_\w+(?!\w*\.py)\b", t):  # a test function
            missing += [name] * (name not in tests)
        for f in re.findall(r"\b(test_\w+\.py)", t):  # a test file
            missing += [f] * (not (ROOT / "pipeline/tests" / f).exists())
        for cmd in re.findall(r"python -m usul_corpus ([\w-]+)", t):
            missing += [f"usul_corpus {cmd}"] * (cmd not in cmds)
        if re.fullmatch(r"Usul(?:\.\w+)+", t):
            module = ROOT / "formal/lean" / (t.replace(".", "/") + ".lean")
            missing += [t] * (not module.exists() and t.split(".")[-1] not in lean)
        if m := re.fullmatch(r"(takhrij|shards|reconcile|m8_worklist|reception|mentions|qa|hadith)\.(\w+)", t):
            missing += [t] * (not hasattr(importlib.import_module(f"usul_corpus.{m[1]}"), m[2]))
        if _PATH.match(t) and not any(c in t for c in "<*…"):
            missing += [t] * (not (ROOT / t).exists())
    assert missing == [], f"{doc} names what does not exist: {missing}"
