"""The stack: qawāʿid (the foundation) → types (defined by the qawāʿid) → categories (downstream).

Read off the Lean import graph of `formal/lean/Usul`: nothing below the categories imports them,
only the types layer and the categories import the types, and the categories do reach the types.
"""

from pathlib import Path

LEAN = Path(__file__).resolve().parents[2] / "formal/lean"


def _imports() -> dict[str, set[str]]:
    files = [LEAN / "Usul.lean", *(LEAN / "Usul").rglob("*.lean")]
    return {f.relative_to(LEAN).with_suffix("").as_posix().replace("/", "."):
            {l.split()[1] for l in f.read_text(encoding="utf-8").splitlines() if l.startswith("import ")}
            for f in files}


def is_types(m: str) -> bool:
    return m in ("Usul.Typing", "Usul.Judgement", "Usul.DerivedTypes") or m.startswith("Usul.Typing.")


def is_categories(m: str) -> bool:
    return m == "Usul.Cat" or m.startswith("Usul.Cat.")


IMPORTS = _imports()


def test_nothing_below_imports_the_categories():
    assert not [(m, i) for m, deps in IMPORTS.items() if m != "Usul" and not is_categories(m)
                for i in deps if is_categories(i)]


def test_only_types_and_categories_import_the_types():
    assert not [(m, i) for m, deps in IMPORTS.items() if m != "Usul" and not (is_types(m) or is_categories(m))
                for i in deps if is_types(i)]


def test_the_categories_reach_the_types():
    assert any(is_types(i) for m, deps in IMPORTS.items() if is_categories(m) for i in deps)
    assert "Usul.Cat.Typing" in IMPORTS["Usul.Cat"]
