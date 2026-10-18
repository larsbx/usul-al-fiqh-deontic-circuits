# Usul.Qawaid in Plain English

Source: [`formal/lean/Usul/Qawaid.lean`](../../../formal/lean/Usul/Qawaid.lean)

Three legal maxims (qawāʿid) become precise rules. Certainty is not removed by doubt; obligation spreads to necessary means without ever demanding the impossible; and necessity lifts a prohibition only up to the need.

## 1. Certainty is not removed by doubt

The maxim *al-yaqīn lā yazūl bi'l-shakk*. Grades run wahm (fancy) < shakk (doubt) < ẓann (preponderant belief) < qaṭʿ (certainty).

- **`Held`**: a value held at a grade, with a flag for whether its preponderance (rujḥān) is known on evidence.
- **`IsYaqin`**: certain for acting. That means qaṭʿ, or a ẓann whose preponderance is known.
- **`Suspended`**: a ẓann whose preponderance is not known. Ibn Taymiyya: such a person "is suspended and has no view".
- **`strength`**: a suspended ẓann counts as shakk; otherwise its grade.
- **`update cur ev`**: new evidence replaces the current view only if it is not suspended and is at least as strong.
- **`updateByGrade`**: the earlier rule that compares grades alone.

| Theorem | Plain English |
| --- | --- |
| `strength_of_not_suspended` | An unsuspended view counts at its own grade. |
| `update_conservative` | When neither side is suspended, the new rule equals the old grade-only rule. |
| `suspended_inert` | A suspended challenger changes nothing. |
| `suspended_yields` | A suspended incumbent yields to any grounded view of at least shakk. |
| `update_strength_mono` | Updating never lowers the strength held. |
| `yaqin_la_yazul_bish_shakk` | **The maxim.** A certain view is not displaced by doubt. |

## 2. Necessary means and incapacity

The maxims *mā lā yatimm al-wājib illā bihi fa-huwa wājib* (what the obligatory cannot be done without is itself obligatory) and *lā wājib maʿa ʿajz* (no obligation with incapacity).

- **`Wajib`**: base obligations, closed under "a needs b": if a is obligatory and needs b, then b is obligatory.

| Theorem | Plain English |
| --- | --- |
| `closure_respects_capacity` | If every base obligation is feasible and the means of a feasible act are feasible, the closure never obliges the impossible. |

## 3. Necessity and its measure

The maxims *al-ḍarūra tubīḥ al-maḥẓūrāt* (necessity permits the prohibited) and *tuqaddar bi-qadarihā* (it is measured by its extent).

- **`daruraPermits need taken`**: taking an amount of something prohibited is allowed when taken ≤ need.

| Theorem | Plain English |
| --- | --- |
| `darura_bounded` | What necessity permits never exceeds the need. |
| `no_darura_no_permission` | With zero need, nothing may be taken. |

## In one line

Doubt cannot displace certainty, obligation reaches necessary means but never the impossible, and necessity permits exactly as much as it requires.
