# HadithTest in Plain English

Source: [`formal/lean/HadithTest.lean`](../../formal/lean/HadithTest.lean)

The root of the ḥadīth test suite. Building `HadithTest` checks every regression vector and generated guard for the ḥadīth kernel in one step.

## What it imports

- **`HadithTest.Chains`**: synthetic vectors pinning the chain and route rules.
- **`HadithTest.ScaleMap`**: existence checks for every Lean name the ḥadīth corpus refers to.
- **`HadithTest.Daifa`**: generated guards for the first 45 entries of al-Albānī's *al-Ḍaʿīfa*.
- **`HadithTest.Seam`**: generated guards that ḥadīth cited by the qawāʿid books pass, or fail, the seam into uṣūl reasoning.

## In one line

One import runs the whole ḥadīth test suite: synthetic rules, real *al-Ḍaʿīfa* entries, name checks and the seam.
