# Hadith in Plain English

Source: [`formal/lean/Hadith.lean`](../../formal/lean/Hadith.lean)

The root of the ḥadīth-criticism track. Importing `Hadith` brings in the whole al-Albānī kernel: narrator grades, chains, routes, Ibn Ḥajar's classification tree, and the rules for conflicting critics.

## What it imports

- **`Hadith.Grade`**: the twelve narrator ranks of the *Taqrīb* and the five-step ḥadīth verdict scale.
- **`Hadith.Isnad`**: chains of narrators, tadlīs (concealed gaps), and the weakest-link verdict.
- **`Hadith.Turuq`**: combining several routes (ṭuruq) as a defeasible argument.
- **`Hadith.Nukhba`**: Ibn Ḥajar's *Nukhbat al-Fikar* classifications as total functions.
- **`Hadith.JarhTadil`**: resolving conflicting criticism (jarḥ) and praise (taʿdīl) of a narrator.

## In one line

One import gives the full formal toolkit for grading a ḥadīth from its narrators and routes.
