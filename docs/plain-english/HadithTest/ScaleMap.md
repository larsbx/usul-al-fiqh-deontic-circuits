# HadithTest.ScaleMap in Plain English

Source: [`formal/lean/HadithTest/ScaleMap.lean`](../../../formal/lean/HadithTest/ScaleMap.lean)

The ḥadīth corpus links each quoted rule in `corpus/hadith/*.json` to a Lean name. This generated file checks that every one of those 46 names exists, so the build fails if a rename leaves the corpus pointing at nothing.

## 1. What is checked

- **Narrator ranks (12)**: every `Hadith.Martaba` constructor, from `sahabi` to `kadhdhab`.
- **Tadlīs tiers (5)**: `Hadith.Tier.t1` to `t5`.
- **Route and tadlīs rules**: `Hadith.judge`, `Hadith.acceptsTadlis`, `Hadith.liftable_cons_shadid`, `Hadith.Verdict.hujja_iff_yaqin`.
- **Nukhba classes**: the four `Kathra` classes (mutawātir, mashhūr, ʿazīz, gharīb), the four `SaqtName` gap names, and all ten `Taan` causes.
- **Repair**: `Hadith.Nukhba.liftable` and `liftable_in_itibar`.
- **Jarḥ wa-taʿdīl**: `not_counting_ignored`, `qarina_only_in_tarjih`, `jarh_alone_wounds`, `qati_jarh_wins`, `qati_tadil_wins`.

## Why it matters

The corpus cites the formal kernel by name. These checks keep the citations honest: the file is regenerated from the corpus, and the build fails if a cited constant disappears.

## In one line

Forty-six `#check` lines prove every Lean name the ḥadīth corpus cites still exists.
