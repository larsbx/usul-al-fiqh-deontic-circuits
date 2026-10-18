# Usul.Readings.RajabA5 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA5.lean`](../../../../formal/lean/Usul/Readings/RajabA5.lean)

Three of Ibn Rajab's qawāʿid (legal maxims) on liability and disposal become yes/no rules. They settle when a second receiver is liable, when someone who acted in error bears the loss, and when an absent owner's property may be given in charity without a judge.

## 1. How the readings work

- **Qāʿida**: a general maxim from Ibn Rajab's Ḥanbalī *Taqrīr al-qawāʿid*.
- **Reading**: a Boolean function of the facts the qāʿida names. Status: candidate.

## 2. Receiving from one who holds by right (qāʿida 94)

| Definition | Plain English |
| --- | --- |
| `secondReceiverLiable handoverPermitted firstTrustee` | The second receiver is liable ⟺ the first could not lawfully hand it over, or the first was not a trustee (amīn). |

Ibn Rajab's derived view, that only the first is liable, is held as a position.

## 3. Destroying another's property in error (qāʿida 95)

- **`externalCause`**: he relied on an apparent cause from someone else.
- **`basisVoid`**: the basis he relied on proved unfit; **`rulingOverturned`**: a ruling built on it was undone.
- **`asOwner`**: he took it as his own. **`negligent`**: he fell short.

| Definition / Theorem | Plain English |
| --- | --- |
| `errorActorLiable` | If another's cause misled him, he is not liable. Else, if the basis was void, he is liable ⟺ a ruling on it was undone. Else he is liable ⟺ he took it as owner or was negligent. |
| `externalCause_frees` | An apparent cause from another always frees the actor. |

## 4. An absent owner's property (qāʿida 97)

| Definition / Theorem | Plain English |
| --- | --- |
| `disposeWithoutJudge ownerKnown trivial despaired` | He may give it in charity for the owner without the judge's permission ⟺ the owner is unknown, or it is trifling, or the owner's return is despaired of. |
| `unknownOwner_without_judge` | An unknown owner's property may always be given in charity without the judge. |

## In one line

A second receiver is liable unless a trustee lawfully passed the thing on; an error-maker is freed by another's misleading cause; and an absent owner's goods go to charity without a judge only when he is unknown, the amount is trifling, or he is past hope.
