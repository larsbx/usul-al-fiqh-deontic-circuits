# UsulTest.Cat in Plain English

Source: [`formal/lean/UsulTest/Cat.lean`](../../../formal/lean/UsulTest/Cat.lean)

The categorical layer (`Usul.Cat`) gives the expected answers on worked cases: the scales map correctly, a textbook qiyās (analogy) is forced by its ʿilla (ratio legis), a real ikhtilāf (disagreement) shows up as an obstruction, and typed encoders license qiyās between situations. Every check runs in the kernel at build time.

## 1. Scales

| Check | Plain English |
| --- | --- |
| `sigma.obj .wajib = .haram` | The scale's self-duality σ swaps wājib (obligatory) and ḥarām (forbidden). |
| `sigma.obj .mubah = .mubah` | It leaves mubāḥ (permitted) fixed. |
| `sigmaIso.inv_hom` | Applying σ twice returns the original ruling. |
| `gradeOfVerdict.obj .hasan = .zann` | A ḥasan ḥadīth verdict maps to the uṣūl grade ẓann (probable belief). |
| `hujja_upSet` | Upgrading a ḥasan verdict to ṣaḥīḥ keeps it ḥujja (a binding proof). |

## 2. The textbook qiyās of nabīdh on khamr

An illustrative case, not a corpus record. Four drinks: khamr (wine), nabīdh (date drink), water, milk.

- **`iskar`**: intoxication, the ʿilla. True of khamr and nabīdh.
- **`liquid`**: true of every drink, so it cannot separate rulings.
- **`given`**: cases ruled by naṣṣ (text): khamr ḥarām, water mubāḥ.

| Check | Plain English |
| --- | --- |
| `factorsOnB iskar given = true` | Intoxication is consistent with the given rulings. |
| `factorsOnB liquid given = false` | Liquidity is not: khamr and water are both liquid yet ruled differently. |
| `Naqd liquid given` | That failure is a naqḍ (counter-case), found in the given cases themselves. |
| `qiyas_determined` example | Any ruling that fits the given cases and depends only on intoxication makes nabīdh ḥarām. |

## 3. Ibn Rajab Q2, farʿ 2: washing hanging hair

From `rajab_m8_tranche4_furu.json`, q002.f002. Is washing the hair that hangs loose obligatory?

- **`mughni`**: al-Mughnī's wajh (view) for janāba: not obligatory.
- **`otherWajh`**: the other wajh for janāba: obligatory.
- **`asgharSahih`**: for the minor ḥadath, washed on the ṣaḥīḥ view.

| Check | Plain English |
| --- | --- |
| `obstructions … [mughni, asgharSahih] = []` | Different contexts, different rulings: no contradiction. |
| `glues_iff_obstructions_nil.2 rfl` | So the two glue into one ruling. |
| `obstructions … [mughni, otherWajh, asgharSahih]` | The two wujūh on janāba give one obstruction, listed both ways. |
| `¬ ∃ g, Glues …` | With both wujūh, no single ruling exists. |

## 4. Downstream of the types

| Check | Plain English |
| --- | --- |
| `qiyas itlaf rfl` | Two situations with the same itlāf (destruction) facts but a different hand (Q14) get the same itlāf ruling. The type licenses the qiyās. |
| `rajab16_reads_q28` | Ibn Rajab 16's substitute encoder reads at least what Q28's does: an arrow in `readsCat`. |
| `substitute.applies … = true` / `substituteAtObligation.applies … = false` | Knowing only whether the original is possible, Q28's encoder applies and 16's does not. |
| `¬ Reads substitute substituteAtObligation` | So there is no arrow back. |

## In one line

The category layer is pinned to concrete answers: σ and the grade map behave, qiyās on intoxication is forced, a two-view ikhtilāf is caught as an obstruction, and the type order runs only one way.
