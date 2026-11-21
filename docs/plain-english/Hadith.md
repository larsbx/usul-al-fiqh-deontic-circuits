# Hadith in Plain English

Source: [`formal/lean/Hadith.lean`](../../formal/lean/Hadith.lean)

Importing `Hadith` brings in the classical criteria, the project’s al-Albānī
profile, and modules for transmission, corroboration and conflicting critical
assessments.

## What it imports

- **`Hadith.ClassicalCriteria`** records the intrinsic criteria and the
  qualifying-follower condition on Ibn Ḥajar’s sixth narrator rank.
- **`Hadith.Grade`**: the twelve narrator ranks of the *Taqrīb* and the five-step ḥadīth verdict scale.
- **`Hadith.Isnad`**: chains of narrators, tadlīs (concealed gaps), and the weakest-link verdict.
- **`Hadith.Turuq`**: combining several routes (ṭuruq) as a defeasible argument.
- **`Hadith.Nukhba`**: Ibn Ḥajar's *Nukhbat al-Fikar* classifications as total functions.
- **`Hadith.JarhTadil`**: resolving conflicting criticism (jarḥ) and praise (taʿdīl) of a narrator.
