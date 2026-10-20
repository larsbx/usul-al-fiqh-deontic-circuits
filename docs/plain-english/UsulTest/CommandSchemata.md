# UsulTest.CommandSchemata in Plain English

Source: [`formal/lean/UsulTest/CommandSchemata.lean`](../../../formal/lean/UsulTest/CommandSchemata.lean)

Independent checks on the candidate command schemata for Ibn al-Laḥḥām 43 (the bare command, amr). Each reading gives the answer its source reports, and none of them is adopted as a ruling.

## 1. Writing and gesture

| Check | Plain English |
| --- | --- |
| `nonverbalUsage .qadiReported …` | On al-Qāḍī's reported view, neither writing nor gesture is literally a command. |
| `nonverbalUsage .jamiWriting .writing == .literal` | The Jāmiʿ's argument makes writing a literal command. |
| `nonverbalUsage .jamiWriting .gesture == .unsettled` | It says nothing about gesture, so that stays open. |

## 2. Naming the Prophet's act

| Check | Plain English |
| --- | --- |
| `propheticActUsage .abuBarakat true == .figurative` | Abū al-Barakāt's report: figurative. |
| `propheticActUsage .literalReport true == .literal` | The other report: literal. |
| `propheticActUsage .authorConditional …` | The author's view is literal if imitation is established, otherwise unsettled. |

## 3. Explicit obligation expressions

| Check | Plain English |
| --- | --- |
| `obligationStatus .qadi .unqualifiedThreat (some .mandub) == .mandub` | For al-Qāḍī, a qarīna (contextual indication) can turn a threat to mandūb (recommended). |
| `obligationStatus .abuBarakat .unqualifiedThreat (some .mandub) == .wajib` | For Abū al-Barakāt the threat is naṣṣ: it stays wājib. |
| `… .wujubLabel …`, `… .fardLabel …` | The same split for the words wujūb and farḍ. |
| `obligationStatus .abuBarakat .bareCommand (some .mandub) == .mandub` | A bare command is reinterpretable on either reading. |
| `bare_command_conservative` | For a bare command, both readings agree with the existing default `Dalala.amrStatus`. |

## 4. Intended recommendation or permission

| Check | Plain English |
| --- | --- |
| `intendedUsage .qadiReport .permission == .literal` | Al-Qāḍī's report: literal. |
| `intendedUsage .qadiArgument .permission == .figurative` | His own argument: figurative. The text notes the tension. |
| `intendedUsage .karkhiRazi .permission == .unsettled` | The Karkhī/Rāzī report covers recommendation only. |
| `intendedUsage .abuBarakat .recommendation == .unsettled` | Abū al-Barakāt's report covers permission only. |
| `intendedCommand … .ruling` checks | Permission gives mubāḥ and recommendation mandūb, whatever the reading. |
| `naming_preserves_intended_ruling` | Readings differ only in naming; the ruling is the same for all. |

## In one line

The command readings are kept faithful to their sources: they disagree only where the reports do, leave open what the reports leave open, and never change the bare-command default or the intended ruling.
