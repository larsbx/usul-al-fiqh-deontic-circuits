# Usul.Taarud in Plain English

Source: [`formal/lean/Usul/Taarud.lean`](../../../formal/lean/Usul/Taarud.lean)

When two proofs conflict (taʿāruḍ), resolution runs in a fixed order: reconcile them if possible, else take the later one as abrogating, else prefer the stronger, else suspend judgement. This is Ibn ʿUthaymīn's procedure from *al-Uṣūl*, written as a function that always gives an answer.

## 1. The procedure

- **`Conflict`**: what each stage can offer for a given conflict. It has an optional result for jamʿ (reconciliation), naskh (abrogation, when the chronology is known), and tarjīḥ (preference).
- **`Resolution`**: the outcome: jamʿ, naskh or tarjīḥ with its result, or tawaqquf (suspension).
- **`resolve`**: take the first stage that offers something, in the order jamʿ, naskh, tarjīḥ. If none does, suspend.

## 2. The theorems

| Theorem | Plain English |
| --- | --- |
| `resolve_jam_first` | If reconciliation is possible, it wins, whatever the later stages offer. |
| `resolve_naskh_before_tarjih` | With no reconciliation, a known abrogation wins over preference. |
| `resolve_tawaqquf_iff` | Suspension ⟺ every earlier stage fails. |

## In one line

Conflicting proofs are reconciled if possible, then abrogated, then weighed, and only when all three fail does the scholar suspend judgement.
