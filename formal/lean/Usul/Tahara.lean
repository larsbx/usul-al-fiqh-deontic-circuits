import Usul.Seam
import Usul.Refinements

/-!
# What exits from the front passage, by its Arabic names (the textual foundation applied)

The English «semen» covers what the fuqahāʾ keep apart, and the rulings differ. So no derivation
runs on the English word: a case names al-manī (المني), al-madhy (المذي), al-wadī (الودي) or
al-bawl (البول), and each ruling below rests on its dalīl in `corpus/nusus/foundation.json`
(the Qurʾān as pinned in `tanzil-quran-simple`, the ḥadīth as pinned in the collections and
graded by al-Albānī, the gate being `Seam.admitted`). The division itself is the one al-Saʿdī
reports (F120): «منه نجس لا يعفى عن يسيره، ويوجب غسله، ونقض الوضوء به وهو البول. ومنه نجس ينقض
الوضوء ويوجب غسله، وغسل الذكر والأنثيين منه وهو المذي، ومنه طاهر يوجب الغسل وهو المني».

* al-manī: ṭāhir, «كنت أفرك المني من ثوب رسول الله ﷺ فيصلي فيه» (Abū Dāwūd 372; Irwāʾ 180, ṣaḥīḥ);
  it obliges ghusl, «وَإِن كُنتُمْ جُنُبًا فَاطَّهَّرُوا» (al-Māʾida 6), «فإذا فضخت الماء فاغتسل» (Abū
  Dāwūd 206; Irwāʾ 125, ṣaḥīḥ), «نعم إذا رأت الماء» (al-Bukhārī 282; Irwāʾ 126, ṣaḥīḥ).
* al-madhy: najis, washed, and it obliges wuḍūʾ only: «يغسل ذكره ويتوضأ» (Muslim 303; Irwāʾ 108,
  ṣaḥīḥ), «إذا رأيت المذي فاغسل ذكرك، وتوضأ وضوءك للصلاة» (Abū Dāwūd 206).
* al-wadī: as al-madhy, on the athar of Ibn ʿAbbās only («وأما المذي والودي فقال: اغسل ذكرك أو
  مذاكيرك وتوضأ وضوءك للصلاة»), which al-Albānī marks «هذا موقوف» (*Tamām al-Minna*). Its support
  is recorded as an athar, below a marfūʿ naṣṣ, and the register says so.
-/

namespace Usul.Tahara

/-- What exits, by its Arabic name. -/
inductive Kharij where
  | bawl | madhy | wady | maniyy
  deriving DecidableEq, Repr

/-- The ṭahāra it obliges: wuḍūʾ or ghusl. -/
inductive Purification where
  | wudu | ghusl
  deriving DecidableEq, Repr

/-- Najis: all but al-manī («ومنه طاهر … وهو المني»; ʿĀʾisha's fark). -/
def Kharij.najis : Kharij → Bool
  | .maniyy => false
  | _ => true

/-- Ghusl for al-manī («فإذا فضخت الماء فاغتسل»), wuḍūʾ for the rest («يغسل ذكره ويتوضأ»). -/
def Kharij.obliges : Kharij → Purification
  | .maniyy => .ghusl
  | _ => .wudu

/-- The English «semen» conflates al-manī with al-madhy, and they differ on both rulings. -/
theorem semen_conflates :
    Kharij.maniyy.najis ≠ Kharij.madhy.najis ∧ Kharij.maniyy.obliges ≠ Kharij.madhy.obliges := by
  decide

/-- Al-madhy and al-wadī agree in both rulings (the athar); al-manī agrees with neither. -/
theorem madhy_wady_alike : Kharij.madhy.najis = Kharij.wady.najis ∧ Kharij.madhy.obliges = Kharij.wady.obliges :=
  ⟨rfl, rfl⟩

/-- Every marfūʿ ḥadīth these rulings rest on is ṣaḥīḥ in al-Albānī's verdict, so it passes the
gate (D4) in the naṣṣ slot. -/
theorem nass_admitted : Seam.admitted ⟨.nass, .sahih⟩ = true := rfl

/-- Ibn Rajab 15.f001 turns on the name. Wetness found on waking, with no ghusl because it is
taken as al-madhy: had it been al-manī the garment would be ṭāhir anyway; as al-madhy it would be
najis, and Q15 does not carry that consequence into the garment's own presumption of ṭahāra. -/
theorem q15_f001_turns_on_the_name :
    Kharij.maniyy.obliges = .ghusl ∧ Kharij.madhy.najis = true ∧ Refinements.consequenceCarries true = false :=
  ⟨rfl, rfl, rfl⟩

end Usul.Tahara
