# R2 sample 1: candidate lane-B semantic audit

Base: `9862c8d3f8ef2603209c8faa4b074631f285ab92` (PR #68). All results remain
`candidate`. The existing Lean-authoritative typing and exported Prolog mirror are unchanged.

## Scope and receipts

`corpus/takhrij/r2_sample1_lane_b.json` classifies each of the 40 sampled record ids once.
`corpus/routing/r2_sample1_semantic_audit.json` retains the original blind situations, a review
of every proposed encoder, the source ruling, attribution, locator, witness hash and unit hash.
Full witness texts, not capped index excerpts, were read. Replaying the five segmenters against
actual cached bytes reproduced every record in each witness, including all sampled units.

Run `cd pipeline && python -m usul_corpus.r2_sample1` to regenerate the tranche report.
This command checks actual source bytes where available, and explicitly reports missing
witnesses when only LFS pointers are present. It rejects edited receipts and invented pages.
It does not claim to run Lean. The existing `takhrij`, `reconcile`, `worklist`, `docs`, and
`signature` commands regenerate the shared outputs; `make lean` checks the guards.

## Harb control

Harb `m00014`, pp. 183–184, says `أيهما كان قبل, فهي امرأته`: whichever marriage was
earlier stands. `RajabA10.simultaneousCombinationVoids` instead models structural priority
within a simultaneous combination: one item can validly be superimposed on another, without
the converse. Its `hasPrecedence` field is not a general temporal-order flag.

The original blind situation is preserved. This audit does not use its chronological cue
to fill that structural field. The case therefore needs `rule:chronological_marriage_priority`;
the guardians' relative priority also remains a separate unencoded issue. The supplemental
Lean controls show both Boolean evaluations, without claiming either is derived from Harb.

## Coverage limits and zero-coverage units

The generated report distinguishes three scoped component guards, two missing-fact cases
and 35 missing-rule cases. Component guards concern substitution in crowded prayer,
customary payment for a private professional service, and substitution for an unsafe ordinary
historical punishment method. They do not derive every procedural branch in their source units.
Their residual rules remain explicitly named in the case notes and audit.

The 29 initially untyped units are individually diagnosed. An empty blind situation is not
evidence that the source contains no facts: the itikaf/vow and wedding-feast permission passages
state facts that were omitted, while the encoder vocabulary still lacks their full decisions.
Wudu nullifiers, zakat timing, proportional fitr shares, marriage and idda conditions, inheritance
arithmetic, and medicinal/kunya reports need domain-specific rules, not invented Boolean values.
Fear of missing prayer time does not establish categorical inability to obtain water; the milk
oath passage leaves its original context unspecified. These are explicitly missing-fact cases.

Five Abu Dawud records have incomplete or absent numbered-page information in the pinned
witness. Their content hashes and stable ids locate them; no page number is fabricated.
Three replay-stable units bundle multiple questions and need finer lane-F review. They contain
actual rulings, so are not excluded as segmentation errors merely to improve coverage.

`routing_label: false` prevents all 40 triage records from becoming positive training or recall
labels. In particular, a gap's examined encoder and a component guard's encoder are not gold
labels for the entire chapter. Existing legacy routing labels retain their behavior. No source
typing, facts, or legal outcome was changed to improve retrieval.

## Reconciliation and integration state

`corpus/reconciliation/r2_sample1_pending.json` preserves source-attributed disagreements
and their receipts. They are not forced into `reconciliation/entries`: the existing checker
requires expressible `genuine_ikhtilaf` cases, which these selected encoders cannot represent.
No fabricated grades, jam, naskh, madhhab selection, or legal adoption is asserted.
The shared reconciliation report is regenerated over the bank without treating this queue as
resolved disputes. Agreements and differences in epistemic wording stay in the case records.

S0 and S2 are replayed and classified. S3 guards are generated; verification is a separate
build gate. S4 finds no need already fully supplied by the bank. S5 introduces no new principle
or closure requiring a new dossier entry. S6 retains the unexpressible disagreements as pending
evidence. S7 still requires later al-Insaf/mutamad checking; no `matches_madhhab` assertion is
added. S8 regenerates inspectable outputs. S9 retains candidate status throughout.

This is an annotation-and-triage contribution, not a claim that all S0–S9 proof and side-review
obligations are complete. The next work is domain readings for the named needs, finer segmentation
where flagged, and later source reconciliation. Coverage totals alone do not close those tasks.
