# usul-al-fiqh-deontic-circuits

## Plain-English companions

Every Lean module under `formal/lean/` and `formal/lean-mathlib/` has a companion at the same path under `docs/plain-english/`, with `.md` for `.lean`. A change that adds, renames, removes or changes the statements of a module updates its companion in the same PR:

- **Add:** write the companion, and add its row to `docs/plain-english/README.md` with Doc `pending` until a Claude Docs copy exists.
- **Change:** bring the companion's theorem table and prose in line with the module, and its Docs copy where one is linked.
- **Rename or remove:** move or delete the companion and its index row.

A companion opens with `# <Module> in Plain English`, then a `Source: [`<repo path>`](<relative path>)` line; follow [`Usul/Cat/Sheaf.md`](docs/plain-english/Usul/Cat/Sheaf.md) for the rest. `python -m pytest -q tests/test_plain_english.py` (from `pipeline/`) checks the bijection, titles, source links and index, but not that a companion's content matches its module.
