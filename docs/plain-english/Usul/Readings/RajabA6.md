# Usul.Readings.RajabA6 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA6.lean`](../../../../formal/lean/Usul/Readings/RajabA6.lean)

Three of Ibn Rajab's qawāʿid (legal maxims) become yes/no rules: discharging another's duty without leave, handing over found property by description, and what must be given freely. Two qawāʿid state two kinds each, so each kind gets its own reading.

## 1. How the readings work

- **Qāʿida**: a general maxim from Ibn Rajab's Ḥanbalī *Taqrīr al-qawāʿid*, read from the pinned witness `openiti-rajab-shamela21730`.
- **Reading**: a Boolean function of named facts. Status: candidate.
- **Takhrīj suite**: `corpus/takhrij/rajab_m8_rajab_a6_furu.json` tests the readings against the furūʿ (particular cases).

## 2. Performing what another must render (qāʿida 96)

| Definition / Theorem | Plain English |
| --- | --- |
| `ownedDischarge wilaya distinct` | First kind, the thing belongs to the one who owes it: the act counts and no liability arises ⟺ the performer had authority (wilāya), or the thing was set apart by itself. |
| `unownedDischarge recipientDetermined` | Second kind, the thing is not his: it counts ⟺ the recipient is determined. The undetermined case is left to its khilāf (disagreement). |
| `wilaya_suffices` | With wilāya it counts, even for a debt with nothing set apart. |
| `without_wilaya_distinct_decides` | Without wilāya, being set apart alone decides. |

The owner's later ratification is not read here.

## 3. Handing over by description (qāʿida 98)

| Definition / Theorem | Plain English |
| --- | --- |
| `byDescription described ownerUnknown ownerHand` | A claimant who describes the thing receives it ⟺ he described it, its owner is unknown, and no hand from the owner's side holds it. |
| `owner_hand_bars` | An established hand from the owner's side always bars it. |

## 4. What must be given freely (qāʿida 99)

| Definition / Theorem | Plain English |
| --- | --- |
| `freeAyn needed harmless` | A needed thing must be given without payment ⟺ it is needed and giving it does no harm, being easy and plentiful. |
| `freeBenefit needed` | A needed benefit must be given without payment. No further condition is stated. |
| `ayn_implies_benefit` | The benefit rule is the weaker condition: whenever a thing must be given freely, so must a benefit. |

## In one line

Another's duty is discharged by one with authority or with a set-apart thing; found goods go to a describer only when no owner's hand is present; and need alone makes a benefit free, while a thing also needs to be harmless to give.
