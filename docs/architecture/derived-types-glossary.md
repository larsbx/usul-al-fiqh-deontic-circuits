# Source terminology → derived Lean types

This mapping accompanies `Usul/DerivedTypes.lean`. The machine-readable glossary is
`corpus/dossier/derived_types.json`; each entry names its source-glossary term,
source locators, al-Saʿdī rule records, and the limit of what the type certifies.
The source glossary and normalized Q-number catalogue remain candidate records.
Compound names below are engineering names, not expressions attributed to an author.

| Source vocabulary | Derived type | Operational meaning |
|---|---|---|
| sharṭ / māniʿ / arkān (Q8) | `Admitted g` | Conditions of this gate hold and its impediments are absent. |
| taklīf / sabab / sharṭ / māniʿ | `Applicable w` | Exactly the premises required by `applies`. |
| yaqīn / known preponderance (Q11, IQ-21) | `CertainHeld V` | `Held.IsYaqin`, not merely the grade floor. |
| tawaqquf (IQ-21) | `GroundedHeld V` | Not suspended; does not imply certainty. |
| ḍarūra and its quantitative limit | `NecessityAllowance need` | Amount does not exceed supplied need; necessity itself remains to be established. |
| riḍā / ʿilm (Q45) | `CoherentRequirement` | Knowledge required implies consent required. |
| tarāḍī / motives (Q12/Q51) | `AdmittedDeal` | The existing consent-and-motive gate holds. |
| preference among competing benefits/harms (Q33) | `OptimalChoice` | Available maximum on the given scale. |
| ʿilla / manāṭ / irrelevant distinction (Q58) | `FactoredRuling` | Explicit evaluator through a sufficient feature. |
| dawarān | `ObservedDawaran` | Co-variation restricted to known cases. |
| qiyās / taḥqīq al-manāṭ / naqḍ | `AdmittedQiyas` | Existing argument gate holds. |
| agreement and dependence on the ʿilla | `CertifiedTransfer H` | Conditional transfer for the specified ruling assignment H. |

## Source qualifications that constrain abstraction

`Admitted` is deliberately narrower than **ṣaḥīḥ**. Ibn ʿUthaymīn's definition
relates validity to effects, and the source discussion requires complete conditions
and absent impediments (`src:shamela-9942/v01:p013`). A model gate certifies only
its listed predicates. `Applicable` wraps a taklīf API; the existing source glossary
distinguishes waḍʿī effects that can concern a child or madman.

Certainty for acting follows the adopted IQ-21 reading. A non-suspended judgement
can still be wahm or shakk. Keep `CertainHeld` distinct from `GroundedHeld`.
The tawaqquf locator is `src:openiti-majmufatawa-shamela7289/v13:p120`.

Q45's normalized source text emends OCR **عمله** to **علمه**. The catalogue says
this needs checking against the scan. The coherent subtype certifies the existing
Lean reading; it does not admit that emendation. `normalizeRequirement` explicitly
changes the unsupported knowledge requirement rather than silently validating it.

The source vocabulary does not make every `Factors` instance a juristic ʿilla.
Ibn Qudāma identifies ʿilla as manāṭ (`src:openiti-rawda-shamela12010/v02:p144`);
Ibn ʿUthaymīn requires a legally recognized suitable meaning
(`src:shamela-9942/v01:p071`). These commitments are not inferred from a factorization.

Dawarān yields presumptive support in the source discussion
(`src:openiti-kawkab-shamela12019/v04:p193`). The existing `dawaran_not_unique`
counterexample prevents converting `ObservedDawaran` into `CertifiedTransfer`.
`qiyas_sound` additionally requires `Agrees` and `Factors`; the new record retains both.
`gate_consistent` guarantees agreement only on description-positive known cases,
so it cannot manufacture the stronger `Agrees` premise.

Q41's tadākhul is supported by same-kind/same-purpose conditions in al-Saʿdī;
Ibn Rajab adds qualifications in q18. Generic `Covers` is directional and is not
automatically an equivalence relation. A future `DischargePlan` should carry the
chosen relation and coverage proof; quotienting needs separate equivalence proofs.

## Implementation and next obligations

The first layer is additive: subtypes, certified choice, a coherent-requirement
constructor, application wrapper, one executable liability factorization, and
three distinct stages of qiyās. No existing rule or scholarly-policy parameter changes.
`certifyChoice_erases` establishes that forgetting its certificate recovers `best`.
`CertifiedTransfer.conclusion` reuses the existing conditional soundness theorem.

Next: introduce typed discharge plans; wrap bounded taking under Q46 with evidence
of evident cause and refusal; add source-admission certificates separately from
mathematical certificates. Nominal monetary/temporal units require new domain
decisions and should not be inferred from today's unlabelled Nat representations.
