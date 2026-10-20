# HadithTest.Seam in Plain English

Source: [`formal/lean/HadithTest/Seam.lean`](../../../formal/lean/HadithTest/Seam.lean)

Ḥadīth cited by the legal-maxim (qawāʿid) books cross into uṣūl reasoning only if al-Albānī's verdict reaches ḥujja (usable as proof). This generated file checks, for each cited ḥadīth, whether it passes that seam, and that the uṣūl theorems built on it exist.

## 1. How a check reads

- Each ḥadīth is matched to its al-Albānī verdict in *Irwāʾ al-Ghalīl*, with the qawāʿid entry that cites it. The file is generated from `corpus/hadith/irwa_join.json`.
- **`#guard decide (Verdict.Hujja v)`**: true means the verdict grades as ẓann (preponderant belief) and passes. False means it falls below and does not.
- **`#check`** lines confirm the uṣūl constants that rest on that ḥadīth still exist.

## 2. What passes (11 guards)

| Ḥadīth | Verdict | Cited in |
| --- | --- | --- |
| wuḍūʾ after camel meat (*Irwāʾ* 118) | ṣaḥīḥ | Ibn al-Laḥḥām q45 |
| a hundred camels for a believer's life (2248) | ṣaḥīḥ | Ibn al-Laḥḥām q36 |
| freeing Ṣafiyya as her dower (1856) | ṣaḥīḥ | Ibn Rajab q56 |
| two sheep for a boy's ʿaqīqa (1166) | ṣaḥīḥ | Ibn Rajab q147 |
| praying alone behind the row (541) | ṣaḥīḥ | Ibn ʿUthaymīn q71 |
| "Muslims are bound by their conditions" | ṣaḥīḥ | al-Saʿdī Q22 |
| "settlement is permitted between Muslims" (1425) | ḥasan | al-Saʿdī Q22 |
| "whoever vows to obey God, let him obey" | ṣaḥīḥ | al-Saʿdī Q47 |
| "no harm and no reciprocal harm" | ṣaḥīḥ | al-Saʿdī |
| "actions are by intentions" | ṣaḥīḥ | al-Saʿdī Q57 |
| "whoever does a deed not in our matter, it is rejected" (276) | ṣaḥīḥ | al-Saʿdī |

## 3. What does not pass (2 guards)

Both wordings of "whoever is first to what no one preceded him to, it is his" (*Irwāʾ* 1553, 1555) are ḍaʿīf. Al-Saʿdī cites them for Q24, the first claimant's priority. The checks pin that they fail the seam, and that `Usul.Seam.q24_dalil_not_admitted` and `daif_not_admitted` exist to record it.

## 4. Theorems the seam leans on

The `#check` lines cover `Usul.Sadi.q22_valid_iff_preserves_prohibition`, the Q24 priority results in `Usul.Muamalat`, the Q47 vow results, the Q57 intention results in `Usul.Kulliyyat`, and `Usul.Seam.admitted_iff_yaqin`.

## Why it matters

A legal maxim is only as strong as its textual proof. These checks keep visible which maxims stand on a ḥadīth that passes, and which, like Q24, must stand on something else.

## In one line

Thirteen cited ḥadīth are checked at the seam: eleven pass as ḥujja, two weak ones for al-Saʿdī's Q24 do not, and the dependent uṣūl theorems are confirmed to exist.
