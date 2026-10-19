# Usul.Readings.RajabA22 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA22.lean`](../../../../formal/lean/Usul/Readings/RajabA22.lean)

Two of Ibn Rajab's qawāʿid (legal maxims) become yes/no rules. Circumstances can carry a claim they support and defeat one they contradict. The wife's leaving the marriage is not valued in itself, so a mahr is charged for it only in two named cases, and never to the wife.

## 1. How the readings work

- **Qāʿida**: a general maxim from Ibn Rajab's Ḥanbalī *Taqrīr al-qawāʿid*, from the pinned witness `openiti-rajab-shamela21730`.
- **Reading**: a Boolean function of named facts. Status: candidate.
- Where the text reports a split, the reading takes the side the qāʿida marks («وأكثر الأصحاب»). Others stay in `corpus/takhrij/rajab_m8_rajab_a22_furu.json`.

## 2. The evidence of circumstances (qāʿida 151)

| Definition / Theorem | Plain English |
| --- | --- |
| `halCarriesClaim supports belies` | A claim is accepted on the strength of the circumstance (ḥāl) ⟺ the circumstance supports it and does not contradict it. |
| `supported_claim_accepted` | A supported, uncontradicted claim is accepted. |
| `belied_claim_rejected` | A claim the circumstance contradicts is always rejected. |
| `unsupported_claim_not_carried` | Without support, this qāʿida carries nothing; the general rule of claims applies. |

## 3. The exit of the buḍʿ (qāʿida 154)

The buḍʿ is the husband's marital right over his wife. Is its loss valued, so that whoever forces it owes him a mahr? Most aṣḥāb say no, and except the wife from the dispute.

| Definition / Theorem | Plain English |
| --- | --- |
| `budExitCharged chargedUnconsummated electsMahr wifeBears` | The exit carries a mahr ⟺ (the act fixed mahr on the husband for an unconsummated marriage, or the husband elects the mahr instead of his wife) and the one charged is not the wife. |
| `wife_never_charged` | The wife is never charged for her own exit. |
| `bare_exit_not_charged` | The bare exit carries nothing: it has no value in itself. |
| `fixed_half_charged` | Whoever fixed an unconsummated half on the husband owes it. |
| `elected_mahr_charged` | A husband who elects the mahr in place of his wife takes it. |

## In one line

Circumstance confirms what it supports and defeats what it contradicts, and a marriage's loss is charged as a mahr only when a third party fixed an unconsummated mahr or the husband chose the money, never against the wife.
