# Usul.Readings.RajabA31 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA31.lean`](../../../../formal/lean/Usul/Readings/RajabA31.lean)

Two of Ibn Rajab's typological qawāʿid become rules. Qāʿida 87 says which holdings can be transferred, and on what terms; qāʿida 88 says what use may be made of a public road, its ground and its air.

## 1. How the readings work

- **Qāʿida**: a general maxim from Ibn Rajab's Ḥanbalī *Taqrīr al-qawāʿid*, from the pinned witness `openiti-rajab-shamela21730`. Status: candidate.
- **Qāʿida 87**: «فيما يقبل النقل والمعاوضة من الحقوق المالية والأملاك». The kinds of holding come from its own wording: full milk (ownership); milk al-manfaʿa (owning a benefit); the rights that repel harm from amlāk, such as shufʿa (pre-emption); and ikhtiṣāṣ (a holder's exclusive claim, with milk al-intifāʿ and ḥaqq al-tamalluk). Where it says «وفي جوازه بعوض خلاف», the reading withholds.
- **Qāʿida 88** sorts uses by harm, by whether the thing is lasting (building, planting, digging) or passing (sitting, stopping an animal), by whose benefit it serves, and by the imām's leave. Where it reports two ṭuruq (ways of reporting the khilāf), the reading takes the one the qāʿida words by the leave.
- The records' other positions stay recorded in `corpus/takhrij/rajab_m8_rajab_a31_furu.json`.

## 2. Qāʿida 87

| Definition / Theorem | Plain English |
| --- | --- |
| `Holding` | The four kinds: full milk, milk al-manfaʿa, a right that repels harm, ikhtiṣāṣ. |
| `transferValid holding lazim higher iwad` | Full milk always transfers; a benefit transfers under a lāzim (binding) title and never by a contract higher than it; a harm-repelling right never; ikhtiṣāṣ under a binding title and only without ʿiwaḍ (consideration). |
| `tamm_transfers` | Full milk passes «بالعوض وغيره». |
| `manfaa_same_contract` | A benefit held by a binding contract passes by the same contract, for ʿiwaḍ too. |
| `manfaa_not_higher` | Never by a higher contract: «دون ما هو أعلى منه». |
| `harm_right_never` | Rights that repel harm are never transferred: «فلا يصح النقل فيها بحال». |
| `ikhtisas_free` | A binding ikhtiṣāṣ passes without ʿiwaḍ to one who takes the holder's place. |
| `not_lazim_no_transfer` | A benefit or ikhtiṣāṣ not held by a binding title does not pass at all. |
| `iwad_only_for_ikhtisas` | The ʿiwaḍ matters only for ikhtiṣāṣ. |
| `excepted_benefit_leasable` | Link to qāʿida 32: a benefit the seller excepted is his to lease. |

## 3. Qāʿida 88

| Definition / Theorem | Plain English |
| --- | --- |
| `Layer` | Where the use is: the surface, the ground below, or the air. |
| `roadUseAllowed layer harmful permanent forAll leave` | No harm, and then: in the air only with leave; elsewhere a passing use, or a lasting public one with leave. |
| `harm_bars` | Harm to passers, or a narrow road, bars every use: «فلا يجوز بكل حال». |
| `below_as_surface` | The ground below is judged as the surface. |
| `private_permanent_barred` | A lasting thing for one person's benefit is barred, leave or none. |
| `public_permanent_by_leave` | A lasting thing for the public is allowed exactly with the imām's leave. |
| `passing_use_allowed` | A harmless passing use is allowed, as «الأكثرون» hold. |
| `air_needs_leave` | The air is used only by the imām's leave. |
| `allowed_use_inflicts_no_harm` | Link to the lā ḍarar qāʿida of the kulliyyāt: an allowed use harms no one. |

## In one line

What you fully own you can transfer; a benefit passes only as far as the title you hold it by, a right that guards against harm never passes, and a public road may be used without harm, only lastingly for the public good and with the imām's leave.
