import Usul.Signature
import Hadith.Grade

/-!
# The seam: ḥadīth dalīls in the uṣūl track (al-Albānī track H7; decision D4, IQ-22)

This is the one import edge from the ḥadīth track into the uṣūl kernel. A ḥadīth offered as a
dalīl carries its place in Aḥmad's order (`DalilKind`) and al-Albānī's verdict on it
(`Hadith.Verdict`). **Decision D4 (project owner, 2026-10-10): the ḥadīth gate applies to the
uṣūl track.** A ḥadīth is admitted only when its verdict is ḥujja, whatever slot it is offered in.

Aḥmad's fourth aṣl (*Iʿlām*: the non-fabricated ḍaʿīf before qiyās) keeps its place in the order
(`DalilKind.mursalDaif`), read with Ibn al-Qayyim's gloss: his ḍaʿīf is «قسم من أقسام الحسن».
So that slot admits the later ḥasan and above, and nothing the gate rejects
(`mursalDaif_admits_only_hasan_up`).
-/

namespace Usul.Seam

open Hadith

/-- A ḥadīth offered as dalīl: its slot in Aḥmad's order and al-Albānī's verdict on it. -/
structure HadithDalil where
  kind    : DalilKind
  verdict : Verdict
  deriving DecidableEq, Repr

/-- D4: the gate is `Verdict.Hujja`, for every slot. -/
def admitted (d : HadithDalil) : Bool := decide d.verdict.Hujja

/-- Admitted exactly when its grade reaches yaqīn-for-action in the uṣūl kernel's scale. -/
theorem admitted_iff_yaqin (d : HadithDalil) : admitted d = true ↔ d.verdict.grade.IsYaqin := by
  simp [admitted, Verdict.hujja_iff_yaqin]

/-- A ḍaʿīf ḥadīth is never admitted, in any slot. -/
theorem daif_not_admitted (k : DalilKind) : admitted ⟨k, .daif⟩ = false := rfl

/-- Aḥmad's fourth aṣl, as Ibn al-Qayyim glosses it: the slot admits ḥasan and above only. -/
theorem mursalDaif_admits_only_hasan_up (v : Verdict) :
    admitted ⟨.mursalDaif, v⟩ = true ↔ Verdict.hasan ≤ v := by
  exact ⟨of_decide_eq_true, decide_eq_true⟩

/-- al-Saʿdī Q24's cited ḥadīth («من سبق إلى ما لم يسبق إليه مسلم فهو أحق به»), ḍaʿīf in
al-Irwāʾ 1555 (`corpus/hadith/irwa_join.json`): not a dalīl under D4. -/
def q24Dalil : HadithDalil := ⟨.nass, .daif⟩

theorem q24_dalil_not_admitted : admitted q24Dalil = false := rfl

end Usul.Seam
