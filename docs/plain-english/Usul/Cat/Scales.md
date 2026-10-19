# Usul.Cat.Scales in Plain English

Source: [`formal/lean/Usul/Cat/Scales.lean`](../../../../formal/lean/Usul/Cat/Scales.lean)

The kernel's three scales become categories, and the links between them become functors. The five-ruling scale is its own mirror image, with permission (ibāḥa) as the only fixed point. Being usable as proof (ḥujja) is a threshold on ḥadīth verdicts, obtained by pulling back the certainty threshold along the seam.

## 1. The three scales

| Science | Category | Order |
| --- | --- | --- |
| fiqh (obligation, taklīf) | `hukmCat` | ḥarām < makrūh < mubāḥ < mandūb < wājib |
| uṣūl (certainty) | `gradeCat` | wahm < shakk < ẓann < qaṭʿ |
| ḥadīth (al-Albānī) | `verdictCat` | mawḍūʿ < ḍaʿīf jiddan < ḍaʿīf < ḥasan < ṣaḥīḥ |

The rulings are forbidden, disliked, permitted, recommended and obligatory. The certainty grades are unlikely, doubtful, preponderant belief and certain.

## 2. σ: the mirror of the rulings

- **σ**: the ruling on *omitting* an act. "Commanding a thing is forbidding its opposite" (al-amr bi'l-shayʾ nahy ʿan ḍiddih): omitting the obligatory is forbidden, omitting the recommended is disliked, and so on.
- **`sigma`**: σ reverses the scale, so it is a functor from `hukmCat` to its opposite.
- **`sigmaOp`**: the same map read the other way.
- **`sigmaIso`**: together they make the scale isomorphic to its own opposite: the taklīfī scale is self-dual.
- Permission is the only ruling σ leaves fixed (`Hukm.σ_fixed_iff`, proved in `Usul.Hukm`).

| Theorem | Plain English |
| --- | --- |
| `sigma_reflects` | a ≤ b ⟺ σ b ≤ σ a. The order of acts is read off the order of their omissions. |

## 3. The ḥadīth seam

- **`gradeOfVerdict`**: al-Albānī's verdict mapped to its certainty grade. Order-preserving, so a functor. It is the single edge from the ḥadīth track into the uṣūl kernel, reached through `Usul.Seam`.

| Theorem | Plain English |
| --- | --- |
| `isYaqin_upSet` | The yaqīn (certainty) floor, "ẓann or better", is an up-set of grades. |
| `hujja_eq_comap` | A verdict is ḥujja ⟺ its grade reaches the yaqīn floor. Ḥujja is the pullback of yaqīn along the seam. |
| `hujja_upSet` | Ḥujja is upward closed: upgrading a verdict never loses admission. |

The last result follows from the shape of the seam, not from checking cases.

## In one line

The rulings scale mirrors itself under "the ruling on omission", and ḥadīth admission is the certainty threshold pulled back along a functor, so it can only improve as a verdict improves.
