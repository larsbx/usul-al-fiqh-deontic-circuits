# Usul.Readings.RajabA24 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA24.lean`](../../../../formal/lean/Usul/Readings/RajabA24.lean)

Ibn Rajab's qāʿida 156 becomes a yes/no rule: who caused a separation before consummation decides whether the named mahr is halved or falls. Where the text reports two riwāyas, the reading pins one side as a named constant.

## 1. How the reading works

- **Qāʿida**: a general maxim from Ibn Rajab's Ḥanbalī *Taqrīr al-qawāʿid*, from the pinned witness `openiti-rajab-shamela21730`.
- **Reading**: a Boolean function of named facts. Status: candidate.
- The other riwāya stays in `corpus/takhrij/rajab_m8_rajab_a24_furu.json`.

## 2. The rule

- **`byHusband`, `byStranger`, `byWife`**: the separation comes, at least in part, from that side.
- **`harmFasakh`**: an annulment the husband holds for harm from her (her defect, a lapsed condition).
- **`mixedTakesHalf`**: the pinned side for a separation from the wife together with the husband or a stranger. It is `true`: the mahr is halved, the first riwāya named.

| Definition / Theorem | Plain English |
| --- | --- |
| `mahrHalved` | Without a harm annulment: if the wife took part, halved ⟺ husband or stranger also took part (the pinned side); otherwise halved ⟺ husband or stranger caused it. A harm annulment drops the mahr. |
| `harm_fasakh_drops` | The husband's annulment for harm from her always drops the mahr. |
| `wife_alone_drops` | Separation from the wife alone drops it. |
| `husband_alone_halves` | From the husband alone halves it. |
| `stranger_alone_halves` | From a stranger alone halves it. |
| `compulsory_drops` | A separation from no party's side (the compulsory kind) does not halve it. |
| `mixed_takes_pinned` | A mixed separation takes exactly the pinned constant. |

## In one line

Before consummation, the husband's or a stranger's act halves the mahr, the wife's alone or a harm annulment voids it, and a mixed case follows a single pinned riwāya that can be changed in one place.
