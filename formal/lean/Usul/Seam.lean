import Usul.Signature
import Hadith.Grade

/-!
# The seam: ḥadīth dalīls in the uṣūl track (al-Albānī track H7; decision D4, IQ-22)

This is the one import edge from the ḥadīth track into the uṣūl kernel. A ḥadīth offered as a
dalīl carries its place in Aḥmad's order (`DalilKind`) and al-Albānī's verdict on it
(`Hadith.Hukm`: a verdict on the riwāya scale, or mawḍūʿ). **Decision D4 (project owner, 2026-10-10): the ḥadīth gate applies to the
uṣūl track.** A ḥadīth is admitted only when its verdict is ḥujja, whatever slot it is offered in.

Aḥmad's fourth aṣl (*Iʿlām*: the non-fabricated ḍaʿīf before qiyās) keeps its place in the order
(`DalilKind.mursalDaif`), read with Ibn al-Qayyim's gloss: his ḍaʿīf is «قسم من أقسام الحسن».
So that slot admits the later ḥasan and above, and nothing the gate rejects
(`mursalDaif_admits_only_hasan_up`). A mawḍūʿ is never admitted (`mawdu_not_admitted`, D5).
-/

namespace Usul.Seam

open Hadith

/-- A ḥadīth offered as dalīl: its slot in Aḥmad's order and al-Albānī's verdict on it. -/
structure HadithDalil where
  kind    : DalilKind
  verdict : Hadith.Hukm
  deriving DecidableEq, Repr

/-- D4: the gate is `Hadith.Hukm.Hujja` (narrated and at least ḥasan), for every slot. -/
def admitted (d : HadithDalil) : Bool := decide d.verdict.Hujja

/-- Admitted exactly when its grade reaches yaqīn-for-action in the uṣūl kernel's scale. -/
theorem admitted_iff_yaqin (d : HadithDalil) : admitted d = true ↔ d.verdict.grade.IsYaqin := by
  simp [admitted, Hadith.Hukm.hujja_iff_yaqin]

/-- A ḍaʿīf ḥadīth is never admitted, in any slot. -/
theorem daif_not_admitted (k : DalilKind) : admitted ⟨k, Hadith.Hukm.marwi .daif⟩ = false := rfl

/-- A mawḍūʿ is not a dalīl in any slot: Aḥmad's fourth aṣl is the non-fabricated ḍaʿīf. -/
theorem mawdu_not_admitted (k : DalilKind) : admitted ⟨k, Hadith.Hukm.mawdu⟩ = false := rfl

/-- Aḥmad's fourth aṣl, as Ibn al-Qayyim glosses it: the slot admits ḥasan and above only. -/
theorem mursalDaif_admits_only_hasan_up (v : Hadith.Hukm) :
    admitted ⟨.mursalDaif, v⟩ = true ↔ Hadith.Hukm.marwi .hasan ≤ v := by
  exact ⟨of_decide_eq_true, decide_eq_true⟩

/-- al-Saʿdī Q24's cited ḥadīth («من سبق إلى ما لم يسبق إليه مسلم فهو أحق به»), ḍaʿīf in
al-Irwāʾ 1555 (`corpus/hadith/irwa_join.json`): not a dalīl under D4. -/
def q24Dalil : HadithDalil := ⟨.nass, Hadith.Hukm.marwi .daif⟩

theorem q24_dalil_not_admitted : admitted q24Dalil = false := rfl

end Usul.Seam
