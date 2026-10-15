---
name: derivation-tranche
description: Operating procedure for one shard of a takhrīj/derivation tranche (formalise qawāʿid as readings, annotate furūʿ or fatāwā as cases, guard them in Lean) or for one integration round over finished shards, in the usul-al-fiqh-deontic-circuits repo. Use whenever adding readings, encoders, takhrīj cases, dossier entries or reconciliation evidence, or when running or merging parallel lanes from docs/roadmap-parallel-derivation.md.
---

# Derivation tranche: shard and integrator procedure

The method is specified in `docs/architecture/derivation-method.md`; this is how to execute it. Read §2 (classes), §3 (S0–S9) and §4 (invariants) there before a first shard. Everything you produce is `candidate`. You never adopt a reading, rank a position or decide a register question.

## As a shard

1. **Claim.** Write `corpus/worklists/claims/<shard>.json` with `shard`, `lane`, the full `base_commit` (`git rev-parse HEAD`) and the obligation ids. Run `python -m pytest -q tests/test_shards.py` from `pipeline/`. Work only on claimed ids.
2. **Source.** Cache the witness (`python -m usul_corpus fetch --work <id>`) and confirm its lock hash. Every quote you use must be verbatim from it, with its page marker.
3. **Read (lane A).** Formalise each qāʿida from its own wording.
   - The reading goes in a new module `formal/lean/Usul/Readings/<Shard>.lean`. It imports the specific `Usul.*` modules it needs, never `Usul`.
   - Add link theorems to existing principles where the text draws the link.
   - Type the encoder in Lean (`formal/lean/Usul/Typing/`): its facts go into the type of the qāʿida that states them, extending an existing qāʿida type where the text builds on it, then `make lean` regenerates the Prolog export.
   - Register the encoder in `pipeline/usul_corpus/encoders/<shard>.py`: `ENCODERS = {name: dict(facts=…, out=…, lean=…, py=…, qawaid=[…], sadi=[…])}`, shaped like `takhrij.CORE`. Never edit `takhrij.CORE` or `Usul/Refinements.lean`, unless you are making a conservative refinement of an encoder they already hold, with its `*_conservative` theorem.
4. **Annotate.** One case per obligation, in your own suite file `corpus/takhrij/<suite>.json`. Each case records: facts within the encoder's domains, the ruling the text states, positions with their attributions, the class, `matches_madhhab`, and `needs` on gaps.
   - Do not force a case. If no reading fits, it is `missing_rule` or `missing_fact` with the need named.
   - Do not invent a gap where a reading is due (§4, invariant 7).
5. **Cite.** A closure or new principle gets a dossier entry in `corpus/dossier/entries/<shard>.json`, with verbatim excerpts, conditions, rationale, Lean constants, and `conservative` where it refines.
6. **Evidence (lanes C/D/E).** Graded, verbatim evidence goes to `corpus/reconciliation/entries/<shard>.json`. Positions are added to cases as `revisions`, never by editing a case.
7. **Gate locally.** Run `check_case` on your cases through `python -m usul_corpus takhrij`. Inspect the generated Lean, then discard the shared generated files with `git checkout -- ../formal/lean/UsulTest ../corpus/takhrij/report.json`. Also run `python -m pytest -q tests/test_dossier.py tests/test_reconcile.py tests/test_shards.py`, and the Lean build of your module where Lean is available.
8. **Hand back.** Commit only the files you own: your claim, suite, encoder module, Lean module and fragments. Do not commit regenerated shared outputs, and put no totals in the report. List what you could not decide as register questions.

## As the integrator

Follow `docs/architecture/derivation-method.md` §5.3 for one round:
- verify each contribution against its claim and base commit;
- merge in a fixed order;
- regenerate with `python -m usul_corpus takhrij`, `reconcile`, `worklist`, `routing`, `docs` and `signature`, and the type system's Prolog export with `make lean`;
- self-apply: the revisit queue must end empty;
- reconcile over the union;
- run `make all`;
- remove the merged shards' claims;
- report the regenerated figures and the batched register questions.

Collisions:
- **Duplicate principle:** keep both and prove them equivalent, or retire one through `revisions`.
- **Encoder name clash:** a build error by construction (`shards.merge_encoders`); rename in the later shard.

## Never

- Rewrite an annotated case: supersede through `revisit` or `revisions`.
- Sum counts by hand.
- Write `lock.json` from a long-running process.
- Mark anything `reviewed` or `accepted`.
- Close a policy point (a side of an uṣūl dispute) with a refinement: it goes to the register.
