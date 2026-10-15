import Usul.Cat.Basic
import Usul.Seam

/-!
# The sciences' scales as categories, and the seams between them as functors

Three scales carry the kernel's judgements, each a thin category (`Cat.scale`):

| Science | Scale | Rank |
|---|---|---|
| fiqh (taklīf) | `hukmCat` : Ḥ < K < M < N < W | `Hukm.valence` |
| uṣūl (epistemics) | `gradeCat` : wahm < shakk < ẓann < qaṭʿ | `Grade.rank` |
| ḥadīth (al-Albānī) | `verdictCat` : mawḍūʿ < … < ṣaḥīḥ | `Verdict.rank` |

Results:

* `sigma` : *al-amr bi'l-shayʾ nahy ʿan ḍiddih* is a contravariant functor, and with its
  opposite it is an isomorphism `hukmCat ≅ hukmCatᵒᵖ` (`sigmaIso`): the taklīfī scale is
  self-dual, and ibāḥa is the only self-dual point (`Hukm.σ_fixed_iff`).
* `gradeOfVerdict` : the one edge from the ḥadīth track into the uṣūl kernel
  (`Hadith.Verdict.grade`) is a functor. It is reached through `Usul.Seam`, the only module
  allowed to import the ḥadīth track (H7).
* `hujja_upSet` : being ḥujja is an up-set of verdicts, obtained by pulling back the yaqīn
  threshold of the grade scale along that functor (`hujja_eq_comap`). Admission under D4 is
  therefore stable under upgrading a verdict, a fact of the seam's shape, not of a case split.
-/

namespace Usul.Cat

open Usul

def hukmCat : Cat := Cat.scale Hukm.valence
def gradeCat : Cat := Cat.scale Grade.rank
def verdictCat : Cat := Cat.scale Hadith.Verdict.rank

/-! ## σ: the self-duality of the taklīfī scale -/

/-- σ reverses valence (`Hukm.σ_antitone`): a functor `hukmCat ⥤ hukmCatᵒᵖ`. -/
def sigma : Functor hukmCat hukmCat.op := Functor.ofAnti Hukm.σ fun h => Hukm.σ_antitone h

/-- The same map read on the opposite side: `hukmCatᵒᵖ ⥤ hukmCat`. -/
def sigmaOp : Functor hukmCat.op hukmCat :=
  Functor.intoThin (Cat.scale_thin _) Hukm.σ fun g => ⟨Hukm.σ_antitone g.down⟩

/-- σ is an isomorphism of the scale with its opposite. -/
def sigmaIso : ObjIso hukmCat hukmCat.op := ⟨sigma, sigmaOp, Hukm.σ_σ, Hukm.σ_σ⟩

/-- σ also *reflects* the order: the valence comparison is read off the omissions. -/
theorem sigma_reflects (a b : Hukm) : a ≤ b ↔ Hukm.σ b ≤ Hukm.σ a :=
  ⟨Hukm.σ_antitone, fun h => by simpa using Hukm.σ_antitone h⟩

/-! ## The ḥadīth seam -/

/-- al-Albānī's verdict to the uṣūl grade (`Hadith.Verdict.grade_mono`): a functor. -/
def gradeOfVerdict : Functor verdictCat gradeCat :=
  Functor.ofMono Hadith.Verdict.grade fun h => Hadith.Verdict.grade_mono h

/-- The yaqīn floor is the threshold `ẓann` of the grade scale. -/
theorem isYaqin_upSet : UpSet gradeCat Grade.IsYaqin :=
  UpSet.threshold Grade.rank Grade.zann.rank

/-- Ḥujja is the pullback of yaqīn along the seam. -/
theorem hujja_eq_comap (v : Hadith.Verdict) : v.Hujja ↔ (gradeOfVerdict.obj v).IsYaqin :=
  Hadith.Verdict.hujja_iff_yaqin v

/-- Ḥujja is upward closed in the verdict scale. -/
theorem hujja_upSet : UpSet verdictCat Hadith.Verdict.Hujja :=
  fun f h => (hujja_eq_comap _).2 (UpSet.comap gradeOfVerdict isYaqin_upSet f ((hujja_eq_comap _).1 h))

end Usul.Cat
