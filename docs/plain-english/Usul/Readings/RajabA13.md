# Usul.Readings.RajabA13 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA13.lean`](../../../../formal/lean/Usul/Readings/RajabA13.lean)

Four of Ibn Rajab's qawāʿid (legal maxims) on general and specific wording become yes/no rules. They settle when a specific item is singled out of a general one, how special titles and combined attributes count, and when custom or a prompting cause restricts a general word.

## 1. How the readings work

- **Qāʿida**: a general maxim from Ibn Rajab's Ḥanbalī *Taqrīr al-qawāʿid*, from the pinned witness `openiti-rajab-shamela21730`.
- **Reading**: a Boolean function of named facts. Status: candidate.
- Qāʿida 119 carries two attached qawāʿid, and each gets its own reading. Where the text says «فيه وجهان» (two views), the reading takes one and names its ground; the other stays in `corpus/takhrij/rajab_m8_rajab_a13_furu.json`.

## 2. The specific within the general (qāʿida 119)

- **`connected`**: the general and the specific are in one connected utterance.
- **`revocable`**: the speaker may retract it (a bequest, a governor's appointment).

| Definition / Theorem | Plain English |
| --- | --- |
| `specificSingledOut connected revocable` | The specific is singled out with its own ruling ⟺ the utterance is connected, or the act is revocable. |
| `connected_singles_out` | In one connected utterance, it is always singled out. |
| `revocable_singles_out` | In a revocable act, the specific is preferred absolutely. |
| `separate_irrevocable_stand` | Two separate irrevocable utterances (two admissions, two contracts) both stand; neither retracts the other. |

## 3. The two attached qawāʿid

| Definition / Theorem | Plain English |
| --- | --- |
| `takesOnlyBySpecial specialTitle` | One entitled by a special title (a named bequest, inheritance) and also a member of a general class (the poor) takes by the special title only. Aḥmad states this. |
| `special_title_is_q119_instance` | This is qāʿida 119 applied to a revocable bequest. |
| `entitlementMultiplies combinedAttributes singleJiha` | Several entitling attributes in one person multiply his entitlement ⟺ they do not all lead to one head (jiha) of entitlement. |
| `single_jiha_never_multiplies` | Attributes leading to one head never multiply. |
| `no_combination_no_multiplying` | Without combined attributes, nothing multiplies. |

## 4. Kinship, custom and cause (qawāʿid 120, 122, 124)

| Definition / Theorem | Plain English |
| --- | --- |
| `doubleKinshipPreferred doubleKinship` | Q120: one with two kinships (the full brother) is preferred over one with a single kinship, even if the second gives no right by itself. |
| `customRestricts customaryUsage` | Q122: a general term is restricted by custom, per the manṣūṣ. |
| `causeRestricts promptingCause` | Q124: a general word said on a prompting cause is restricted to that cause. The reading takes the wajh the authors of al-Mughnī and al-Muḥarrar call sound. |
| `no_cause_general` | Without such a cause, the word stays general. |

## In one line

The specific stands apart from the general in one breath or in a revocable act, a special title excludes the general share, attributes multiply only across different heads, and both custom and the prompting cause narrow a general word.
