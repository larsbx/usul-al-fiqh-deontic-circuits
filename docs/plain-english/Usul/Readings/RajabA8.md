# Usul.Readings.RajabA8 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA8.lean`](../../../../formal/lean/Usul/Readings/RajabA8.lean)

Two of Ibn Rajab's qawāʿid (legal maxims) on vagueness become yes/no rules. They decide when consent to the unknown binds, when a contract or report on a vague object holds, and when a lot picks out the one truly entitled.

## 1. How the readings work

- **Qāʿida**: a general maxim from Ibn Rajab's Ḥanbalī *Taqrīr al-qawāʿid*.
- **Reading**: a Boolean function of named facts. Status: candidate.
- Where the statement leaves a question to khilāf (disagreement), the reading returns the side the statement does not establish. The other side is held as a position on the farʿ (particular case).

## 2. Consent to the unknown (qāʿida 104)

| Definition | Plain English |
| --- | --- |
| `unknownConsentBinds vaguenessAdmitted` | Consent to something unknown in amount, kind or description binds ⟺ the commitment is a contract or annulment that admits vagueness. Otherwise there is khilāf, and the qāʿida does not make it bind. |

## 3. Vague objects (qāʿida 105)

- **Inshāʾāt**: acts that create a legal effect (sales, gifts, divorces).
- **Ikhbārāt**: reports (claims, testimony, confessions).

| Definition / Theorem | Plain English |
| --- | --- |
| `vagueInshaValid bindingTransfer equalMixed` | An inshāʾ on a vague object is valid ⟺ it is not a binding transfer, or the vague object is one of equal mixed units (a measure from a heap). |
| `vagueReportAccepted religiousOrAgainstSelf` | A vague report is accepted ⟺ it is a religious report or obliges the reporter himself. |
| `sharedNameValid vagueValid intendedSpecific witnessingRequired` | A shared name that does not pick one thing out: if a specific one was meant inwardly, it is valid ⟺ no witnesses are required; else it is treated as explicitly vague. |
| `sharedName_unintended_is_vague` | With nothing meant inwardly, a shared name is exactly the vague case. |
| `lotDistinguishes specificInFact` | Where the right fell on one specific person we cannot identify, a lot (qurʿa) singles him out. |

## In one line

Vagueness is tolerated where the act's nature allows it (non-binding transfers, equal units, self-binding reports), an inward intention cures a shared name unless witnesses are needed, and a lot finds a hidden but real entitlement.
