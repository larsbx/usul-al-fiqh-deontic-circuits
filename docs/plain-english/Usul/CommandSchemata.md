# Usul.CommandSchemata in Plain English

Source: [`formal/lean/Usul/CommandSchemata.lean`](../../../formal/lean/Usul/CommandSchemata.lean)

Ibn al-Laḥḥām's rule 43 reports competing positions on what counts as a "command" (amr). Each reported position becomes an explicit input, and each schema returns what that position says. Where a position does not answer a question, the result is "unsettled"; the code never invents an answer. Naming something a command, literally or figuratively, is kept apart from assigning the act its ruling.

## 1. Vocabulary

- **`CommandUsage`**: how a reading names the expression: `literal`, `figurative`, `notLiteral`, or `unsettled` (the position gives no answer).
- A **reading** is an input, not an adopted position. Sources and open questions are in `lahham_m5_commands_plan.json`.

## 2. Writing and gesture (43.f001)

- **`nonverbalUsage`**: al-Qāḍī, as reported, denies that writing or gesture is literally a command. The *Jāmiʿ*'s argument makes writing literal but says nothing about gesture.

| Theorem | Plain English |
| --- | --- |
| `writing_does_not_settle_gesture` | The writing argument leaves gesture unsettled. |
| `writing_readings_differ` | The two readings disagree on writing. |

## 3. The Prophet's act (43.f003)

- **`propheticActUsage`**: Abū al-Barakāt's report says figurative. A Mālikī/Shāfiʿī report says literal. The author's own view is literal only if following the Prophet's act (al-taʾassī) is established.

| Theorem | Plain English |
| --- | --- |
| `author_inference_needs_imitation` | Without established imitation, the author's view is unsettled. |
| `author_inference_with_imitation` | With it, literal. |

## 4. Explicit obligation words (43.f004)

- **`ObligationExpression`**: a bare command, an unqualified threat, the word "wujūb", or the word "farḍ".
- **`obligationIsNass`**: for Abū al-Barakāt, the last three are decisive text (naṣṣ). For al-Qāḍī, none are.
- **`obligationStatus`**: decisive text ⇒ wājib. Otherwise the default command rule `Dalala.amrStatus`: wājib unless an indication says otherwise.

| Theorem | Plain English |
| --- | --- |
| `bare_command_conservative` | A bare command follows the existing default under either reading. |
| `qadi_retains_defeasibility` | Under al-Qāḍī's reading every expression stays open to an indication. |
| `nass_blocks_reinterpretation` | Decisive text gives wājib whatever indication is supplied. |
| `explicit_readings_differ` | With an indication of recommendation, the two readings give different rulings for "wujūb". |

## 5. Intended recommendation or permission (43.f007)

- **`IntendedRuling`**: recommendation (mandūb) or permission (mubāḥ).
- **`intendedUsage`**: how each of four reports names a command meant as recommendation or permission. The Karkhī/Rāzī and Abū al-Barakāt reports each speak to one ruling only; for the other they stay unsettled.
- **`intendedCommand`**: pairs that naming with the intended ruling.

| Theorem | Plain English |
| --- | --- |
| `naming_preserves_intended_ruling` | Every reading keeps the intended ruling. Only the naming differs. |
| `permission_reports_stay_distinct` | Al-Qāḍī's report and his later argument disagree on permission. |
| `recommendation_report_does_not_settle_permission` | The Karkhī/Rāzī report says nothing about permission. |

## In one line

Each reported position on what a "command" is becomes an explicit input with its own answer, unanswered questions stay unsettled, and naming never changes the ruling.
