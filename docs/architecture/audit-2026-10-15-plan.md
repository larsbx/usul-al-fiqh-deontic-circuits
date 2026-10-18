# Audit of 57a3b1c and repair plan (2026-10-15)

The second audit of the day, after the first audit's six findings were fixed (PRs #87, #89). Every finding below was reproduced by mutation or recomputation; the scripts are not committed. The problem register (`problem-register.md`, PR-33 to PR-40) tracks each one to closure.

**Baseline at 57a3b1c.** `make source-verify`: 4,467 verified, 542 excluded. `USUL_REQUIRE=swipl,islamqa pytest`: 5,396 passed, 653 skipped (PR-40). `make integration`: 69 passed; `make integration-external`: 3 passed; `make validate generated`: clean. The Python mirror matches `Usul.Tarjih` clause by clause, and the generated guards cover all 596 entries under all four policies.

## Findings

| Register | Sev | Finding | Reproduction |
|---|---|---|---|
| PR-33 | A | A position ruling of the wrong type passes every check and changes a resolution. `check_case` never checks a position's ruling against its encoder's `out`, and `reconcile.py` compares rulings with Python `==` (`0 == False`), not `takhrij.code` (PR #90's typed identity). | q043.f005, `positions[0].ruling` `true` → `0`: `check_case` and `reconcile.check` pass; `resolve` tawaqquf → `('tarjih', 0)` |
| PR-34 | A | A ruling with a proof beats a ruling with none, and nothing records where the missing side's proofs were sought. Of the 235 tarjīḥ, 104 are won only because every losing ruling cites no proof (23 against the reading, 93 without `searched`); 106 have at least one losing ruling without proof (24, 95). In all, 103 weighed entries have an unproven ruling and no `searched` (95 tarjīḥ, 4 jamʿ, 4 tawaqquf). | q043.f005, delete position 1's proofs: checks pass; tawaqquf → tarjīḥ |
| PR-35 | B | The quotation key and its boundaries: the ligature «ﻻ» and other code points outside U+0621–U+064A carry no key; a match need not start or end on a word boundary; a negation just before the excerpt is not checked; the qualifier guard misses hamza-less «الا» and a qualifier after a dash or quotation mark. Live: al-Iqnāʿ v04:p060 (`rajab-a25.json` evidence) stops before «- لكن قال الموفق…»; 15 excerpts end and 4 start mid-word. | `check_quote` passes «قال ﻻ يجوز البيع» against «قال يجوز البيع», «يجوز البيع» against «قال لا يجوز البيع», «يجوز البي» against «يجوز البيع إلا …» |
| PR-36 | A | Weighing data is not checked against what it claims: unknown keys in `weighing/*.json` are dropped on load; a murajjiḥ is not tied to the tiers it can decide; no check backs the docs' "no qaṭʿī text and no certain ijmāʿ"; duplicate proofs and advantages, and advantages between equal rulings, pass. | q012.f002 `advantages` → `advantage`: tarjīḥ → tawaqquf; q043.f005 tier qiyas → ijma, or a `sahihayn` advantage between two qiyāsāt: tawaqquf → tarjīḥ |
| PR-37 | A | Ledger grades, evidence and proofs refer to case positions by index, and nothing pins the index to the position. | reversing every two-position case at once changes 224 resolutions; `check` rejects 8 cases (jamʿ, naskh and side-check consistency), and 221 of the changes fall in cases it accepts |
| PR-38 | B | Routing recall is measured with folds by record, so a test farʿ's qāʿida and siblings train the model. | 0.537 / 0.804 / 0.858 published; folds grouped by qāʿida: 0.286 / 0.508 / 0.592; out-of-domain recall@1 0.00, the prior's |
| PR-39 | C | Stale figures and unchecked generated files: 6/8 stated/applied advantages (5/9), 83 residues (80), "all three" policies (four), the roadmap's 561 tarjīḥ, 745 pending furūʿ and old routing figures, judgement.md's encoder counts; `type-aware.json` fails its own `--check` with the answers present, and the fatāwā takhrīj report lacks banks a21–a25; `make generated` checks neither. | recomputation from `report.json`, generators' `--check` |
| PR-40 | B | 653 verbatim checks still skip in CI: their witnesses (the dossier's 346, al-Albānī methodology's 102, al-Qawāʿid al-Jāmiʿa's 30, …) are outside the required set. | `pytest -rs` |

Low (folded into the items above where they touch the same code): proof excerpts are bounded less strictly than evidence (`minLength` 1, no excerpt-limit test); jamʿ is checked against the default policy only; `matches_madhhab` is optional on ikhtilāf; a derivable case may carry disagreeing positions; a corrupt `.part` checkpoint blocks CI until the cache is purged; `http.client.IncompleteRead` escapes the source gate without a report.

Outside the repository: branch protection with required checks on `main`. Until the four checks are required, none of these gates blocks a merge.

## Plan

One PR per step, test-first, each validated by the full gate set before it merges. Data changes go through the repo's generators, never by hand.

1. **Typed rulings (PR-33).** `check_case` requires every position's ruling to be in its encoder's `out`, or an explicit `outside` marker (the 36 q160 `lots` rulings take it). `reconcile.py` compares and deduplicates rulings by `takhrij.code`. Test: the q043.f005 mutation fails both validators.
2. **Unproven sides (PR-34).** `reconcile.check` requires a non-empty `searched` on every weighed entry in which some reported ruling cites no proof; `report.json` gains `tarjih_against_unproven`. The 103 entries without one get `searched` from their weighing batch's own search record, or are pinned as open in a list that may only shrink; nothing is invented. Docs disclose the figure.
3. **Quotation boundaries (PR-35).** NFKC before keying; reject Arabic-block letters outside the key; require word boundaries at both ends; flag a negation immediately before the excerpt; normalise the qualifier tail (hamza, dashes, quotation marks). Re-run `source-verify`; extend or re-cut every excerpt it then rejects, from the witness itself.
4. **Weighing integrity (PR-36).** Reject unknown weighing keys; `uniqueItems` on proofs and advantages; reject advantages between equal rulings; map each murajjiḥ to the tiers it applies to and check it (mirrored in Lean); a test pins zero qaṭʿī and ijmāʿ proofs until a reviewed claim exists; proof excerpt limits as for evidence; jamʿ checked under every policy.
5. **Pinned positions (PR-37).** Each ledger and weighing entry records a digest of its case's ordered positions (ruling and holder), checked on load.
6. **Routing honesty (PR-38).** Report qāʿida-grouped recall as the headline, record-level as within-qāʿida; out-of-domain beside its prior.
7. **Figures and generated files (PR-39).** Correct the figures; add `signature_routing --check` and `fatawa-takhrij --check` to `make generated`.
8. **Remaining verbatim checks (PR-40).** Add the dossier's, the ḥadīth methodology's and al-Saʿdī's witnesses to the required set, as PR-06 did for the foundation.
9. **Hygiene.** `matches_madhhab` required on ikhtilāf; positions on non-ikhtilāf cases agree with `expected`; a corrupt `.part` is discarded; `HTTPException` is retried and reported.

Steps 1 and 2 come first: each can change a ruling. Step 3 next: it can certify a quotation its source qualifies.

## Progress

- Step 1 (PR-33): closed by PR #92, which also landed the interim position receipts of step 5 (PR-37, partly closed).
- Step 2 (PR-34): the `searched` gate and the `tarjih_against_unproven` report; 103 entries pinned in `corpus/reconciliation/unsearched.json` until their searches are recorded.
- Step 3 (PR-35): the stricter quotation gate, and 77 excerpts extended from their witnesses; 59 that followed a negation await evidence review ([repairs](pr35-quote-repairs-2026-10-18.md)).
- Step 4a (PR-36): weighing keys, duplicates, same-ruling advantages, the qaṭʿī/ijmāʿ pin, proof excerpt limits and jamʿ under every policy; step 4b (murajjiḥ to tier, mirrored in Lean) follows separately.
- Step 4b (PR-36): murajjiḥ domains in `Usul.Tarjih` and its Python mirror; only q159.f035's rejected `dariHadd`, applied between qiyāsāt, falls outside, changing the `all` policy only.
