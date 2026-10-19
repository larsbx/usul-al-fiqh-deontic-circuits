# Usul.Cat.Deduction in Plain English

Source: [`formal/lean/Usul/Cat/Deduction.lean`](../../../../formal/lean/Usul/Cat/Deduction.lean)

Finding which qāʿida a farʿ falls under by its words fails when the words belong to the farʿ's chapter rather than its qāʿida. This module asks the question the other way round, as takhrīj al-uṣūl ʿalā al-furūʿ: given the ruling an authoritative position states, and the facts the text settles, which accepted readings could have produced that ruling?

## 1. The picture

- **Partial situations.** A situation may settle some facts and leave others open. One situation *refines* another when it settles everything the other does, the same way, and perhaps more. Settling a fact is a step along an arrow: an established state transition.
- **What a reading can still reach.** For a reading, `Reach s` is the set of rulings it could still give, as the open facts range over their values. Settling more facts can only shrink that set, so `Reach` behaves as a presheaf on partial situations: the situation-indexed counterpart of the spans in `Usul.Cat.Interval`.
- **Deduction.** A reading is *admissible* for an established ruling when that ruling is still in reach. If it is not, the situation carries an obstruction to deriving the ruling by that reading.

## 2. Definitions and theorems

| Definition / Theorem | Plain English |
| --- | --- |
| `Reading` | Partial situations with a refinement order, and for one reading the signatures that complete each situation; completing a finer situation completes the coarser one. |
| `Reading.Reach s a` | Some completion of `s` gives the ruling `a`. |
| `reach_antitone` | Settling more facts never brings a ruling into reach that was out of it. |
| `sound` | If a finer situation derives a ruling, the ruling is in reach from the coarser one. So the deduction never drops the reading a case truly falls under, when the typed facts are true. |
| `excluded_forever` | A ruling out of reach stays out of reach, however many more facts are settled. |
| `reach_common_refinement` | A situation refining two others reaches only what both reach. |
| `pair run` | The construction for a reading of two facts, each open until the text settles it. |
| `pair_total` | With both facts settled, exactly one ruling is in reach: the reading's own. |
| `idhn` | Ibn Rajab 23's reading: does the idhn of one who refuses lapse? |
| `idhn_permitted_refusal_excludes_lapse` | Once the text says the refusal was his to make, «the idhn lapses» is out of reach. |
| `idhn_forbidden_refusal_reaches_both` | Settling only that the refusal was forbidden leaves both rulings in reach; the kind of thing asked decides. |
| `idhn_lapse_excluded_under_refinement` | No further fact brings the lapse back. |

`pipeline/usul_corpus/deduction.py` computes the same sets for every encoder by trying every completion, and its tests replay these theorems.

## In one line

Start from the ruling and the facts the text gives, keep only the qawāʿid that can still produce that ruling from those facts, and know that a qāʿida set aside this way never comes back.
