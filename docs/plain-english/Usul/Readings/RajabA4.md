# Usul.Readings.RajabA4 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA4.lean`](../../../../formal/lean/Usul/Readings/RajabA4.lean)

Four of Ibn Rajab's qawāʿid (legal maxims) on joined property, growth and possession become yes/no rules. They decide when a joined part is bought out at value, when growth follows the property, and when a hand over another's property is liable. The file gives definitions only.

## 1. How the readings work

- **Qāʿida**: a general maxim from Ibn Rajab's Ḥanbalī *Taqrīr al-qawāʿid*.
- **Reading**: a Boolean function of the facts the qāʿida names. Status: candidate.
- Where a farʿ (particular case) turns on a fact the statement leaves implicit, that fact becomes an input, quoted from the farʿ.

## 2. Property joined to another's (qāʿida 77)

| Definition | Plain English |
| --- | --- |
| `takenOverAtValue wrongful separableWithoutHarm` | The owner of the principal may take over the joined part at its value ⟺ it was not added by transgression and cannot be separated without harm. |

A buyer from a usurper is not uprooted for free. The usurper's own planting is.

## 3. Attached growth (qāʿida 81)

| Definition | Plain English |
| --- | --- |
| `attachedGrowthFollows revertsToTransferor securityOrLiability` | Attached growth follows the property ⟺ the property reverts to the one it came from, or the question is one of security or liability. |
| `cutSaleVoid leftUntilRipe` | A crop bought on condition of cutting, but left until it ripens, voids the sale (the better-known riwāya). |

The manṣūṣ view that growth does not follow is held as a position, not as the reading.

## 4. Hands over another's property (qawāʿid 90 and 92)

Ibn Rajab names three kinds of hand (possession). One can establish ownership and so bears no liability. One neither owns nor is liable. The transgressing hand owns nothing and is liable.

| Definition | Plain English |
| --- | --- |
| `seizingHandLiable canOwn transgressing` | The hand is liable ⟺ it cannot establish ownership and it transgresses. |
| `liableWithOwnerHand ownerControlRemoved` | A hand alongside the owner's is liable ⟺ the owner's use and control were removed (the qāʿida's al-aẓhar). |

## In one line

Joined parts are bought out only from an innocent, harmed owner; growth follows property on reversion or for security; and a hand over another's goods is liable when it transgresses without any power to own, or displaces the owner.
