# The categorical layer (`Usul.Cat`)

**Place in the stack.** Qawāʿid ([`schemata.md`](schemata.md)) are the foundation. Types come next ([`judgement.md`](judgement.md): `Usul.Judgement`, `Usul.Typing`). This layer is downstream of both. Its scales are Σ's (`Usul.Hukm`, `Usul.Signature`: the vocabulary below the qawāʿid), and its factorization is the qawāʿid's S1 shape `Factors`.

The roadmap (§0) gives category theory one job: **compositional specification, checked through
Lean statements**. `formal/lean/Usul/Cat/` is that layer. Like the rest of the kernel it does not
depend on Mathlib: it has a small core (`Basic`) and modules that each discharge a roadmap
claim. Vectors are in `formal/lean/UsulTest/Cat.lean`, `Obstructions.lean` and `Institutions.lean`.

| Module | Roadmap | Claim | Main results |
|---|---|---|---|
| `Basic` | §0 carrier | categories, opposites, thin categories of scales, functors, up-sets | `Functor.intoThin` (functor laws are free into a thin category), `Functor.ofMono` / `ofAnti`, `UpSet.comap` |
| `Scales` | §2.1, H7 | the sciences' scales are thin categories, and their seams are functors | `sigmaIso : hukmCat ≅ hukmCatᵒᵖ`, `gradeOfVerdict`, `hujja_upSet` |
| `Factor` | §2.5, M9 L-QIY-1 | ʿilla valid ⇔ ruling factors through the feature; naqḍ = witness against | `factors_iff_functor`, `factors_iff_exists`, `factorsOn_iff_extension`, `not_factorsOn_iff_naqd`, `qiyas_determined`, `unattested_free` |
| `Sheaf` | M10 | local verdicts glue iff they match; ikhtilāf is a named obstruction | `gluing`, `glue_unique`, `no_glue_iff_obstruction`, `glues_iff_obstructions_nil` |
| `Institution`, `Carriers` | M11 | carriers as institutions; a check in one carrier proves the statement in another when the model maps are onto | `Comorphism.comp`, `entails_iff`, `compile`, `initial`, `always_iff`, `entailsB_iff` |

## Scales

Each science that grades its judgements does so on a finite scale. A scale is a preorder, so its
category is thin: there is at most one arrow `a ⟶ b`, and it exists iff `rank a ≤ rank b`.

```text
hukmCat     Ḥ < K < M < N < W          (Hukm.valence)
gradeCat    wahm < shakk < ẓann < qaṭʿ  (Grade.rank)
verdictCat  mawḍūʿ < … < ṣaḥīḥ          (Hadith.Verdict.rank)
```

In a thin category the functor laws hold automatically, so a monotone map *is* a functor. Two
consequences:

* **σ is a duality.** *al-amr bi'l-shayʾ nahy ʿan ḍiddih* (`Hukm.σ`) is antitone, so it is a
  functor `hukmCat ⥤ hukmCatᵒᵖ`. Being involutive, it is an isomorphism of the scale with its
  opposite (`sigmaIso`), and it reflects the order as well (`sigma_reflects`). Ibāḥa is its only
  fixed object (`Hukm.σ_fixed_iff`).
* **The ḥadīth seam is a functor.** `Hadith.Verdict.grade` is monotone, so it is a functor
  `verdictCat ⥤ gradeCat`. *Ḥujja* is the pullback of the yaqīn threshold along it
  (`hujja_eq_comap`), and up-sets pull back to up-sets (`UpSet.comap`). So D4 admission is
  stable under upgrading a verdict (`hujja_upSet`); this follows from the seam's shape, not from
  a case split. The module reaches `Hadith.*` only through `Usul.Seam`, which keeps the H7
  firewall (`test_seam_is_the_only_import_edge`) intact.

## Qiyās as factorization (L-QIY-1)

`Schema.Factors H e` (S1) says that cases `e` cannot tell apart share the ruling. `Factor`
proves that this is the factorization in roadmap §2.5, in three forms:

```text
Factors H e  ⇔  ∃ Φ : ker e ⥤ disc β, Φ.obj = H     (functorial; ker e = thin groupoid of e-equal cases)
             ⇔  ∃ Ĥ, H = Ĥ ∘ e                       (global)

FactorsOn e known  ⇔  ∃ Ĥ, ∀ (a, r) ∈ known, Ĥ (e a) = r           (on the given cases)
                   ⇔  ∃ H, Factors H e ∧ Agrees H known
¬ FactorsOn e known  ⇔  Naqd e known                               (two given cases, same e, different ruling)
```

`factorsOnB` decides `FactorsOn` (`factorsOnB_iff`). Qiyās is evaluation of `Ĥ` at the farʿ:

* **Determined** (`qiyas_determined`): if the farʿ shares `e` with a given aṣl, every consistent
  factoring ruling gives the farʿ the aṣl's ruling.
* **Free** (`unattested_free`): if no given case shares the farʿ's `e`, then every value at the
  farʿ is the value of some consistent factoring ruling. Without an aṣl, the given cases fix
  nothing, and this is the formal content of farq.

L-QIY-2 (tamthīl ≡ shumūl) is already in `Usul.QiyasLimits.tamthil_iff_shumul`, so both M9 lemmas
now have Lean proofs. The Haskell laws on random finite case categories are still open.

## Sheaf semantics of the madhhab (M10)

This generalizes [`sheaf-context-site.md`](sheaf-context-site.md) from ADQ affect facts to uṣūl
verdicts.

```text
context      Ctx X := X → Prop             a set of situations; smaller = more constrained
verdict      Section β U := ∀ x, U x → β   a ruling at each situation of U
restriction  restrict : V ⊆ U → Section U → Section V   (functorial: restrict_id, restrict_comp)
cover        patches Uᵢ with ⋃ Uᵢ = U      a riwāya, wajh or qāʿida each speaks to its context
matching     sᵢ = sⱼ on Uᵢ ∩ Uⱼ
```

* **Gluing lemma** (`gluing`, `glue_unique`): a family glues to a verdict over `U` iff it is
  matching, and the glued verdict is unique.
* **Obstruction** (`no_glue_iff_obstruction`): a family fails to glue iff there is an
  `Obstruction`, two patches ruling differently at a shared situation. Ikhtilāf is recorded as
  this witness. It is not an error, and the encoding never resolves it.
* **Finite form** (`Patch`, `obstructions`, `glues_iff_obstructions_nil`): over a finite list of
  situations, `obstructions` emits `(patch, patch, situation)` records, and the list is empty iff
  the family glues.

Example (`UsulTest/Cat.lean`, Ibn Rajab Q2 farʿ 2): al-Mughnī's wajh in janāba and the ṣaḥīḥ for
the minor ḥadath rule differently in *different* contexts, and they glue. Adding the other janāba
wajh produces exactly one disagreement, at janāba, and it is emitted as an obstruction record.

### Every genuine ikhtilāf is an obstruction (M10 exit)

A takhrīj case's reported positions all speak to one situation, the farʿ. `Sheaf.positions` makes
each position a patch over that one point, and `positions_glue_iff` proves that they glue iff
they all agree. A `genuine_ikhtilaf` case is therefore exactly a case with an obstruction.

`python -m usul_corpus sheaf` (part of `make generated`) emits this for the whole bank:

* `corpus/sheaf/obstructions.json`: for each `genuine_ikhtilaf` case, one record per unordered
  pair of positions with different rulings. Every case is obstructed; the current totals are in
  the file's generated `summary`, and `test_every_ikhtilaf_is_obstructed` enforces the claim.
* `formal/lean/UsulTest/Obstructions.lean`: one `#guard` per case. It checks that the kernel's
  `obstructions` returns exactly twice the recorded pairs (ordered pairs). The kernel is the
  authority over the mirror, and a wrong count fails the build.

`pipeline/tests/test_sheaf.py` pins the record shape and checks that both outputs are generated.

Some positions are views the reading cannot express: their ruling lies outside the encoder's
range (`out`), as with murāḍāt, muhāyaʾa or the heirs' oaths against the `lots` reading of Ibn
Rajab's Q160. Such a position can never equal the case's expected ruling. Each record lists these
positions as `outside`. The summary separates `records_within_reading` (both positions
expressible: an ikhtilāf the reading could adjudicate) from the rest, which are gaps in the
reading's range rather than disagreements within it.

The records are typed by the types layer. Each carries its encoder's sort and question from
`corpus/types/encoders.json`. Two answers conflict only when they answer the same question
(`Judgement.Conflicts`), and only a `judgement`-sort encoder answers a khiṭāb. So the summary counts
`conflicts_of_khitab` (records within the reading on `judgement` encoders) apart from disagreements
on effect, dalāla, takyīf, epistemic and procedure encoders (`records_within_reading_by_sort`).

For set-valued verdicts the obstruction to gluing is a pairwise disagreement: a Čech 1-cochain
that does not vanish. The layer does not claim a cohomology group.

## Institutions across carriers (M11)

`Institution` packages a carrier's signatures (a category), sentences and models over each
signature, and satisfaction. The satisfaction condition `M' ⊨ σ(φ) ↔ M'|σ ⊨ φ` is a field: truth
does not depend on notation. A `Comorphism I J` translates signatures and sentences forward and
models backward, preserving satisfaction, and is natural in both. Comorphisms compose
(`Comorphism.comp`).

**Borrowing** (`Comorphism.entails_iff`): every comorphism preserves consequence. When every
source model is the reduct of some target model, it also reflects consequence. This is the
precise sense in which a TLC run or a QuickCheck property *proves* a Lean-side statement. Without
that surjectivity, a pass is evidence but not proof.

`Usul.Cat.Carriers` instantiates this on the fragment the three carriers share: finitely many
Boolean state variables, with renamings `Fin m → Fin n` as signature morphisms (`finSet`).

| Institution | Sentences | Models | Carrier |
|---|---|---|---|
| `propI` | Boolean formulas `Form n` | valuations | Lean state predicates |
| `traceI` | `now φ`, `always φ` (`□φ`), `step ψ w` (`[][ψ]_w`, i.e. `□(ψ ∨ UNCHANGED w)`, `ψ` over primed and unprimed vars) | finite behaviours | TLA+ within TLC's bounds |
| `execI` | `(Fin n → Bool) → Bool` | valuations | Haskell, `#eval` |

* `compile : propI ⥤ execI` maps a formula to its evaluator. `initial : propI ⥤ traceI` maps it to
  `Init`. Both model maps are onto (`compile_onto`, `initial_onto`), so borrowing is exact.
* An invariant `□φ` is not the image of a comorphism, because one valuation cannot stand for a
  behaviour. It reduces statewise instead (`always_iff`), which is what TLC checks.
* `entailsB` decides `propI` consequence by truth tables (`entailsB_iff`, complete via
  `mem_allVals`).

Fixtures (`UsulTest/Institutions.lean`) read `formal/tla/Taklif.tla` in this fragment:
* its `Init`, `OnlyMukallafBound`, `RukhsaNeedsSabab` and `BulughIrreversible` hold on a behaviour
  built from the spec's own actions (Init → Bulugh → Depart → TakeRukhsa → Arrive → LoseAql);
* two mutants each violate exactly one property;
* the satisfaction conditions of `propI`, `traceI` along the embedding of the subject signature
  (bulūgh, ʿaql), `compile` and `initial` are checked on every fixture and every valuation;
* the mukallaf sentence is `Subject.IsMukallaf` read on a valuation (the bridge to `Usul.Signature`);
* a binding duty entails mukallaf, decided in `propI` and transported to `traceI`.

**TLC replays the same behaviour.** `formal/fixtures/gen_taklif.py` holds it once, as full
`Taklif.tla` states (with `capable` and `bound`). It writes:
* `formal/tla/TaklifTrace.tla`, a trace-validation spec that `make tla` checks with the other
  specs: each step must be produced by the action it names (a mismatch deadlocks), the first state
  must satisfy `Init`, and the invariants and `BulughIrreversible` hold along the trace;
* `UsulTest/TaklifBehaviour.lean`, the same behaviour in the Boolean fragment. The abstraction
  reads `bound` as `bound ≠ {}` and drops `capable`; it is the model map from TLA+ states to `traceI`.

`make generated` regenerates both and rejects drift. A stale obligation (bound not rebound after
an incapacity) and a wrong initial state are each rejected by TLC (mutation-checked).

## Open

* **M10, beyond one point:** covers over several situations, such as context separations like
  the Q2 farʿ 2 vector, need the facts that separate the contexts. The bank records those per
  case, not per position.
* **M9 exit:** Haskell laws for L-QIY-1 in `semantic-categorical-oracle`.
* **M11, the rest:** mirror `execI` in `semantic-categorical-oracle` (Haskell), then register
  the contracts with their laws. Comorphisms for the richer fragments (sets such as
  `bound`, naturals such as `events`) extend `Form` with those sorts.
