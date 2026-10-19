# Usul.Readings.RajabA27 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA27.lean`](../../../../formal/lean/Usul/Readings/RajabA27.lean)

Two of Ibn Rajab's qawāʿid become yes/no rules. Qāʿida 40 asks whether a ruling on a thing survives when its owner changes; qāʿida 70 asks whether the specific agent of an act falls under its general object.

## 1. How the readings work

- **Qāʿida**: a general maxim from Ibn Rajab's Ḥanbalī *Taqrīr al-qawāʿid*, from the pinned witness `openiti-rajab-shamela21730`. Status: candidate.
- **Qāʿida 40** names two kinds. A ruling tied to one ownership (a lease, a loan for use, a bequest) falls when that ownership ends, «فإذا زال ذلك الملك سقط الحكم». A ruling tied to the ʿayn (the thing) itself as a binding right survives, and stands again when the thing returns, unless the right-holder consented to its lapse.
- **Qāʿida 70** reports a khilāf and names its murajjaḥ (preferred side): «والمرجح فيه التخصيص إلا مع التصريح بالدخول أو قرائن تدل عليه». By default the agent is outside the general term of his own act.
- The records' other positions stay recorded in `corpus/takhrij/rajab_m8_rajab_a27_furu.json`.

## 2. Qāʿida 40

| Definition / Theorem | Plain English |
| --- | --- |
| `survivesOwnershipChange tiedToAin holderConsented` | The ruling survives the change of owner ⟺ it is tied to the thing itself and the right-holder did not consent to its lapse. |
| `one_ownership_falls` | First kind: a ruling on one ownership falls with it and does not come back. |
| `bound_to_ain_survives` | Second kind: a binding right in the thing survives and returns with it. |
| `consent_lapses` | Even the second kind lapses with the right-holder's consent. |
| `lease_as_settled_substitute` | Link to qāʿida 16, which the text draws: a lessee whose right moved to the refund keeps it there, and the lease does not return. |
| `agrees_with_q24` | Not drawn by the text: without consent the two kinds match qāʿida 24's right on the property against a right on its owner. |

## 3. Qāʿida 70

| Definition / Theorem | Plain English |
| --- | --- |
| `agentIncluded explicitInclusion qarinaInclusion` | The agent falls under the general term ⟺ he is expressly included, or a qarīna (indicator) shows he is meant. |
| `takhsis_by_default` | With neither, the mention of the agent takes him out (takhṣīṣ, specification). |
| `explicit_includes` | Express inclusion brings him in. |
| `qarina_includes` | An indicator of inclusion brings him in. |
| `specifies_a_general_term` | Link to Ibn al-Laḥḥām's generality reading, which the text draws: in «من دخل داري» the particle is general, yet the speaker is not covered. |

## In one line

A right fixed in the thing itself follows the thing through every change of owner unless its holder gives it up, and whoever performs an act is not caught by its general object unless he is named or the context includes him.
