# Usul.Cat.Factor in Plain English

Source: [`formal/lean/Usul/Cat/Factor.lean`](../../../../formal/lean/Usul/Cat/Factor.lean)

An ʿilla (effective cause) is valid exactly when the ruling factors through it: cases that share the ʿilla share the ruling. Qiyās (analogy) is then reading off that factored ruling at the new case. When a new case shares its ʿilla with a known case, its ruling is fixed. When it shares with none, the known cases fix nothing, which is the formal content of farq (distinguishing).

## 1. Vocabulary

- **Ruling `H`**: assigns a verdict to each case.
- **Feature `e`**: the candidate ʿilla, read off each case.
- **`Factors H e`**: cases with the same feature get the same ruling (from `Usul.Schema`).
- **`ker e`**: the cases the feature cannot tell apart, as a thin category: x ⟶ y ⟺ e x = e y.
- **Known cases**: a finite list of cases ruled by text (naṣṣ) or consensus (ijmāʿ).
- **aṣl / farʿ**: the known source case and the new case.

## 2. Global factorization

| Theorem | Plain English |
| --- | --- |
| `factors_iff_functor` | H factors through e ⟺ H is a functor from `ker e` to the discrete category of rulings. |
| `factors_iff_exists` | H factors through e ⟺ H = Ĥ ∘ e for some Ĥ on features. Off the features that occur, Ĥ is arbitrary. |
| `hat_unique` | Ĥ is unique on every feature that occurs. |

## 3. Factorization on the given cases

- **`FactorsOn e known`**: no two known cases share the feature yet differ in ruling.
- **`Naqd e known`**: a naqḍ (counterexample): two known cases with the same feature and different rulings.
- **`factorsOnB`**: the computable check over the list.

| Theorem | Plain English |
| --- | --- |
| `factorsOnB_iff` | The check returns true ⟺ the feature is consistent with the known cases. |
| `not_factorsOn_iff_naqd` | Inconsistency ⟺ an explicit naqḍ exists. |
| `factorsOn_iff_exists` | **Main result (L-QIY-1).** Consistent ⟺ some Ĥ on features reproduces every known ruling. |
| `factorsOn_iff_extension` | Consistent ⟺ some total ruling agrees with the known cases and factors through the feature. |
| `FactorsOn.refine` | A finer feature stays consistent. |

## 4. Qiyās as evaluation

| Theorem | Plain English |
| --- | --- |
| `qiyas_determined` | If the farʿ shares the feature with a known aṣl, every consistent ruling gives it the aṣl's ruling. |
| `unattested_free` | If no known case shares the farʿ's feature, every possible ruling at the farʿ is allowed by some consistent extension. |

## In one line

An ʿilla is valid ⟺ the ruling factors through it, failure is a concrete naqḍ, and qiyās fixes a new case's ruling only when a known case shares its ʿilla.
