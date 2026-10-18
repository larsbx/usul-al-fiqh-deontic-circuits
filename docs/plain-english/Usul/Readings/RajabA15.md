# Usul.Readings.RajabA15 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA15.lean`](../../../../formal/lean/Usul/Readings/RajabA15.lean)

Two of Ibn Rajab's qawāʿid (legal maxims) become yes/no rules. An intention can widen or narrow wording but cannot restrict an absolute term or except from an explicit text. Liability for an injury's spread follows the victim's state at the injury.

## 1. How the readings work

- **Qāʿida**: a general maxim from Ibn Rajab's Ḥanbalī *Taqrīr al-qawāʿid*, from the pinned witness `openiti-rajab-shamela21730`.
- **Reading**: a Boolean function of named facts. Status: candidate.
- Where the text poses a question («على وجهين», «على روايتين»), the reading takes one side and names its ground. The other side stays in `corpus/takhrij/rajab_m8_rajab_a15_furu.json`.

## 2. What intention can do to wording (qāʿida 125)

The qāʿida has four aqsām (divisions). Intention generalising the specific, and specifying the general, are undisputed. Restricting an absolute (taqyīd), and excepting from an explicit text, are disputed. The reading says intention does not govern in those two.

| Definition / Theorem | Plain English |
| --- | --- |
| `intentionGoverns restrictsAbsolute exceptsFromText` | The intention governs the wording ⟺ it neither restricts an absolute nor excepts from an explicit text. |
| `undisputed_aqsam` | In the two undisputed aqsām, the intention governs. |
| `restriction_barred` | Restricting an absolute never takes effect by bare intention. Ground: it adds to the meaning. |
| `text_exception_barred` | Excepting from an explicit text never takes effect by bare intention. Ground: intention bends a word only toward what it can bear. |

## 3. Injury and its spread (qāʿida 128)

The victim's protected status may differ between the injury (jināya) and its spread to death (sirāya). Of four aqsām, the text settles three. In the fourth, guaranteed at injury but not at spread, the reading keeps liability, because the spread follows the injury.

| Definition / Theorem | Plain English |
| --- | --- |
| `spreadFollowsInjury guaranteedAtInjury _guaranteedAtSpread` | The spread is guaranteed (maḍmūn) ⟺ the victim was guaranteed at the injury. |
| `unguaranteed_injury_barred` | An unguaranteed injury makes the spread unguaranteed, by agreement. |
| `fourth_qism_guaranteed` | The fourth qism: liability does not fall. |
| `measuredAtInjury` | In the first qism (guaranteed in both states, amounts differ), the amount is measured at the injury. Outside it there is nothing to measure. |
| `measure_needs_both` | The measure question arises only when both states are guaranteed. |
| `measure_implies_spread_guaranteed` | Both readings rest on one ground: a measure taken at the injury implies the spread is guaranteed. |

The file notes open research questions. RQ-05 records a textual variant (a missing «لا») bearing on one example; RQ-02 records the choice between Q128's two riwāyas. Neither function settles them.

## In one line

Intention may stretch or narrow a word but not add a restriction or cut into an explicit text, and an injury's spread inherits the victim's protected status at the moment of injury.
