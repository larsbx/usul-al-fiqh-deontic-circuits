# PR #49 merged-evidence consistency audit (2026-10-10)

Scope: M8 tranche 8 at merge commit `3ca9fd9c0954eaad30517ab61dfb13417756ccd8`. This is separate from the reconciliation review queue and its PR #51 audit. Current main has subsequently added tranches 9 and 10; their totals must not be replaced with this historical snapshot.

| Claim | Original PR summary | Authoritative merge |
|---|---:|---:|
| Reconciliation entries | 146 | 144 |
| Active-ledger evidence items | 368 | 359 |
| jamʿ | 15 | 15 |
| tarjīḥ | 123 | 121 |
| tawaqquf | 8 | 8 |
| Against reading | 63 | 61 |
| Supporting reading | — | 75 |
| Tranche madhhab matches among ikhtilāf | 6 | 8 |
| Tranche madhhab coverage | — | 0.852 (23/27) |
| Aggregate madhhab coverage | 0.675 | 0.680 |

The tranche still contains 27 candidate annotations: 15 derivable and 12 genuine ikhtilāf, with zero encoding errors and no new gaps. Four new contradictions and twelve later-source evidence items remain active, rather than six contradictions and twenty-one items. Three new residues remain: q014.f000, q019.f001 and q019.f005.

## Why q014.f001 and q014.f002 leave the contradiction ledger

[Review finding](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/pull/49#discussion_r4238027606) identified a false exclusivity between nonattachment and required abstention. [Correction 781ebb5](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/commit/781ebb5e956bbb8fb78a53642e9f3cab31e116b1) defines `Attach.abstain` as their composite and changes `attachTo false` to that value. It does not imply that either divorce or manumission occurs.

Both candidate annotations retain their IDs, facts, source notes, genuine-ikhtilāf classification and alternative positions. Their expected result becomes `abstain`, with `matches_madhhab = true`. This removes them from `reconcile.candidates`, which selects genuine ikhtilāf without a madhhab match. Their ordinary takhrīj guards remain, now checking `attachTo false == .abstain`; only their contradiction-resolution guards disappear.

Replaying each original entry with its unchanged grades and nine combined evidence items yields `tarjih abstain` and `for_reading`. Changing only the expected reading back to `neither` recreates `against_reading`. Thus the exclusion follows from the corrected interpretation, not missing annotations. The distinct harmless purification case q014.f000 still expects `each` and remains a residue.

## Evidence preservation and governance

The correction removed five evidence items for f001 and four for f002 from the active ledger. They remain recoverable from parent commit `861de806496d9a7e35138bbc7779d79af913e475`. [The historical evidence record](../../corpus/reconciliation/history/pr49-q014-resolved.json) preserves the complete original entries, including grades, verbatim excerpts, references, position indices, notes and evidence for alternative positions. These are historical support, not active contradictions, and do not increase generated ledger totals.

The original [review](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/pull/49#discussion_r4238046215), source witnesses and candidate status remain intact. The PR description was corrected with an explicit post-merge note retaining the original published totals. The merged takhrīj, roadmap and reconciliation documentation already contain the corrected tranche-8 figures.

## Validation

At the merge snapshot, `reconcile.report` exactly reproduces the committed 144-entry report, including the worklist and review list. Both reconciliation and takhrīj Lean guard generators reproduce their committed files. Original archived evidence resolves to the composite interpretation for both corrected cases.

On main `9def50992a994d71df63dc3eaca10b790bdcd33a`, the focused consistency tests plus existing non-cache reconciliation tests pass: 13 passed. The current generated report and reconciliation guards also reproduce exactly. The focused regression retains q014.f000 as a negative control and verifies tranche counts, retained alternatives, archive replay and generator consistency without fixing later global totals at 144.

Command: `PYTHONPATH=pipeline python -m pytest pipeline/tests/test_pr49_consistency.py pipeline/tests/test_reconcile.py -q -k 'not verbatim'`.

These checks verify generated Lean text; a fresh Lean compilation and cached-witness verbatim replay were not performed in this environment. No generator, interpretation, active ledger or generated report changes are required.
