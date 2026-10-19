# Usul.Readings.RajabA3 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA3.lean`](../../../../formal/lean/Usul/Readings/RajabA3.lean)

Two of Ibn Rajab's qawāʿid (legal maxims) on rights in property become yes/no rules. An owner's disposal stands unless a right has settled in the very thing. Whoever frees his own property by damaging another's is liable, unless the sufferer was negligent or gave permission.

## 1. How the readings work

- **Qāʿida**: a general maxim from Ibn Rajab's Ḥanbalī *Taqrīr al-qawāʿid*.
- **Reading**: a Boolean function of the facts the qāʿida names. Status: candidate, awaiting review.

## 2. Disposing of a thing a right attaches to (qāʿida 53)

A right of God or of a person may attach to a thing, as a debt or zakat might. The owner's act on it still stands, unless the right has *settled* there.

- **`demanded`**: the right-holder demanded it or took it.
- **`fixedInAyn`**: the thing itself is what he is owed, and cannot be turned aside.

| Definition / Theorem | Plain English |
| --- | --- |
| `disposalStands demanded fixedInAyn` | The owner's act stands ⟺ ¬(demanded ∧ fixed in the thing). |
| `bare_attachment_stands` | With no demand, the act always stands. A bare attachment never blocks it. |
| `unfixed_demand_stands` | A demand for a right not fixed in the thing (the jānī's arsh, the zakat) blocks nothing. |

## 3. Damaging another's property to free one's own (qāʿida 78)

| Definition / Theorem | Plain English |
| --- | --- |
| `lossLiable causesLoss sufferedNegligent emptyingPermitted` | He is liable (ḍamān) ⟺ the freeing causes a loss, the sufferer was not negligent, and the sufferer did not permit the emptying. |
| `negligent_sufferer_not_liable` | If the sufferer was negligent, there is no liability, whatever else holds. |

The qāʿida reports two wujūh (views) on a bare permission to occupy. The reading leaves that open: such a permission is not an input.

## In one line

A disposal stands unless a demanded right sits in the thing itself; damage done to free one's own property is owed unless the sufferer was at fault or consented.
