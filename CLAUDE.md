# usul-al-fiqh-deontic-circuits

## Plain-English companions

Every Lean module under `formal/lean/` and `formal/lean-mathlib/` has a companion at the same path under `docs/plain-english/`, with `.md` for `.lean`. A change that adds, renames, removes or changes the statements of a module updates its companion in the same PR:

- **Add:** write the companion, and add its row to `docs/plain-english/README.md` with Doc `pending` until a Claude Docs copy exists.
- **Change:** bring the companion's theorem table and prose in line with the module, and its Docs copy where one is linked.
- **Rename or remove:** move or delete the companion and its index row.

A companion opens with `# <Module> in Plain English`, then a `Source: [`<repo path>`](<relative path>)` line; follow [`Usul/Cat/Sheaf.md`](docs/plain-english/Usul/Cat/Sheaf.md) for the rest. `python -m pytest -q tests/test_plain_english.py` (from `pipeline/`) checks the bijection, titles, source links and index, but not that a companion's content matches its module.

## Sources are always cited

Every claim the corpus records about a text cites its source, down to the locus:

- a naṣṣ cites its witness and its place in it: a verse its sūra and āya (`src:<witness>#Qsss:aaa`), any other text its ḥadīth or masʾala `number`;
- a grade cites the entry it comes from (`{work, witness, number, verdict}`), or for the Ṣaḥīḥayn's standing the ḥadīth there (`{witness, number}`); a text with no grade says why (`ungraded`);
- a cited witness is registered in `corpus/registry.json` and pinned in `corpus/lock.json`, so the citation can be re-read.

Checks enforce it where they can (`mahall.check`, `test_mahall_grades.py`); new layers add the same. Docs and PR descriptions link the sources they report on.
