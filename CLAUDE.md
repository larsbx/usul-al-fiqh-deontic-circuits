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

## Roadmaps move with their tracks

The work runs in parallel tracks, each with a roadmap; [`docs/roadmap-tracks.json`](docs/roadmap-tracks.json) names them and the paths each owns, and [`docs/roadmap.md`](docs/roadmap.md#tracks) links them all.

- Each path belongs to one track. A change to it updates that track's roadmap in the same PR: its milestone entry and its status row.
- A change that leaves the roadmap true as it stands (a refactor, a typo) says so in a commit trailer: `Roadmap-Unchanged: <reason>`.
- A new milestone is a `#### <Id> · <Name> ⟵ <deps>` heading; a dependency on another track names it («uṣūl M5»). Where a roadmap draws a Mermaid DAG, draw the new edges too.
- A new track, or a new directory a track owns, goes in `docs/roadmap-tracks.json`, under one track only.

`python -m usul_corpus roadmap --base origin/main` (from `pipeline/`) checks both the structure and the change. CI runs it on every PR (`.github/workflows/roadmap.yml`); the Stop hook in `.claude/settings.json` runs it before a session ends; `git config core.hooksPath .githooks` adds it as a pre-push hook.
