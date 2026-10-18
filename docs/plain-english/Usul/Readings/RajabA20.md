# Usul.Readings.RajabA20 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA20.lean`](../../../../formal/lean/Usul/Readings/RajabA20.lean)

Two of Ibn Rajab's qawāʿid (legal maxims) become yes/no rules. Heirs take a dead person's rights that fall due at death, were claimed, or attach to inherited property, and step into his binding obligations. A revocably divorced woman differs from wives on each listed point.

## 1. How the readings work

- **Qāʿida**: a general maxim from Ibn Rajab's Ḥanbalī *Taqrīr al-qawāʿid*, from the pinned witness `openiti-rajab-shamela21730`.
- **Reading**: a Boolean function of named facts. Status: candidate.
- Where the text reports a split («ففيه قولان في المذهب أشهرهما»), the reading takes the side marked better known. Others stay in `corpus/takhrij/rajab_m8_rajab_a20_furu.json`.

## 2. Rights the deceased held (qāʿida 144, first kind)

- **`accruesAtDeath`**: it falls due by his death (diya, qiṣāṣ for his life).
- **`claimedOrHeld`**: he claimed it in life, or held it.
- **`attachedToProperty`**: it attaches to property the heirs inherit (a pledge, a guarantee, a debt's term, return for a defect).

| Definition / Theorem | Plain English |
| --- | --- |
| `heirInherits` | The heirs take the right ⟺ any of the three holds. |
| `unclaimed_personal_right_not_inherited` | An unclaimed right of acquisition, or a non-property right, is not inherited. |
| `claimed_right_inherited` | A claimed right is always inherited. |
| `attached_right_passes` | A right attached to inherited property passes without any claim. |

## 3. Obligations the deceased owed (qāʿida 144, second kind)

| Definition / Theorem | Plain English |
| --- | --- |
| `heirStandsIn binding tendsToBinding` | The heir stands in the deceased's place ⟺ the obligation is binding (lāzim), or it is a permissible contract that tends to bindingness (a pledge or gift before delivery). |
| `lapsing_contract_no_heir` | A permissible contract that does not tend to bindingness (partnership, muḍāraba) lapses at death. |
| `binding_obligation_heir` | A binding obligation always falls to the heir. |

## 4. The revocably divorced woman (qāʿida 146)

| Definition / Theorem | Plain English |
| --- | --- |
| `wifeRuleApplies rajiyya listedPoint` | A wife's ruling applies ⟺ ¬(she is a rajʿiyya, revocably divorced in her ʿidda, ∧ the point is one the qāʿida lists). |
| `rajiyya_differs_on_listed_point` | On a listed point, the rajʿiyya does not take a wife's ruling. |
| `wife_takes_wife_rule` | A wife always takes a wife's ruling. |

## In one line

Heirs inherit rights born at death, claimed in life, or tied to the estate, and stand in for obligations that bind; and the rajʿiyya parts from wives exactly on the points the qāʿida lists.
