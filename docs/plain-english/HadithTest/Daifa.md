# HadithTest.Daifa in Plain English

Source: [`formal/lean/HadithTest/Daifa.lean`](../../../formal/lean/HadithTest/Daifa.lean)

The first 45 entries of al-Albānī's *Silsilat al-Aḥādīth al-Ḍaʿīfa* are encoded as data and replayed through the kernel. Each check confirms the kernel reproduces al-Albānī's verdict, either by its rules alone or with the critic's cited ruling. The file is generated from `corpus/hadith/daifa_tranche*.json`.

## 1. How an entry is checked

- Each route is a chain of narrator links, graded with `Isnad.verdict`, paired with its worst-narrator `Isnad.floor`.
- **`judgeI .strict`** runs the route aggregation under the strict follower reading (the project default).
- **`judgeRI .strict`** adds the critic's rulings (decision D2): a ḥukm or a criterion on the text, capping the verdict.
- Some entries add a **`JarhTadil.judge`** check on a disputed narrator.

## 2. Entries by kind

Each entry is tagged with how the verdict is reached. The file holds 67 guards over 45 entries.

| Kind | Count | Plain English |
| --- | --- | --- |
| derivable | 33 | The rules alone reproduce al-Albānī's verdict. |
| qarina | 11 | The rules give a weaker-than-final verdict; a cited ruling lowers it to al-Albānī's (11 `judgeRI` guards). |
| missing_rule | 1 | The kernel cannot yet express the reason; the guard records what it does give. |

## 3. Representative checks

- **No source at all** (14 entries, e.g. 3, 4, 6, 7: "lā aṣl lahu", it has no basis): an empty route list gives mawḍūʿ.
- **A liar in the chain** (e.g. 10, 16, 27): one kadhdhāb makes the entry mawḍūʿ by rule.
- **Matrūk narrator** (14, 37): ḍaʿīf jiddan by rule. Entry 14 adds a jarḥ check: three explained criticisms against one praise from a critic not relied on ⇒ majrūḥ.
- **Tadlīs** (13): a tier-4 narrator saying "from" makes an otherwise reliable chain ḍaʿīf.
- **Rulings** (1, 12, 18, 29 and others): the rules give ḍaʿīf or ḍaʿīf jiddan; the critic's "bāṭil" or "mawḍūʿ" ruling caps it at mawḍūʿ.
- **Objections that block a lift** (2, 24, 43): with the cited objections the entry stays ḍaʿīf. Without them, entries 24 and 43 would lift to ḥasan under both follower readings. Entry 2 would lift only under the lax reading, and needs rulings to reach mawḍūʿ.
- **Missing rule** (8, "no basis as the Prophet's own words"): the kernel gives ḍaʿīf; it cannot yet state "authentic only as a Companion's saying".

## Why it matters

These checks test the kernel against a real critic's published verdicts. They also keep visible how much depends on a critic's judgement rather than on the rules, and where the rules fall short.

## In one line

Forty-five real *al-Ḍaʿīfa* entries replay through the kernel: 33 follow from the rules alone, 11 need the critic's cited ruling, and one marks a rule the kernel still lacks.
