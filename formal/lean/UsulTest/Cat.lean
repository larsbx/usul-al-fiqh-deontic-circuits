import Usul.Cat

/-!
Vectors for the categorical layer (`Usul.Cat`). Each is checked by the kernel at build time.
-/

namespace UsulTest.Cat

open Usul Usul.Cat Usul.Cat.Sheaf Usul.Qiyas

/-! ## Scales -/

example : sigma.obj .wajib = .haram := rfl
example : sigma.obj .mubah = .mubah := rfl
example (h : Hukm) : sigmaIso.inv.obj (sigmaIso.hom.obj h) = h := sigmaIso.inv_hom h
example : gradeOfVerdict.obj .hasan = .zann := rfl

/-- Upgrading a ḥasan verdict to ṣaḥīḥ keeps it ḥujja. -/
example (h : Hadith.Verdict.hasan.Hujja) : Hadith.Verdict.sahih.Hujja :=
  hujja_upSet (a := .hasan) (b := .sahih) ⟨by decide⟩ h

/-! ## L-QIY-1: the textbook qiyās of nabīdh on khamr (illustrative, not a corpus record) -/

inductive Drink | khamr | nabidh | water | milk
  deriving DecidableEq, Repr

/-- Iskār, the ʿilla. -/
def iskar : Drink → Bool | .khamr | .nabidh => true | _ => false

/-- Being a liquid: true of every case, so not a candidate that can separate rulings. -/
def liquid : Drink → Bool := fun _ => true

/-- Cases ruled by naṣṣ: khamr ḥarām, water mubāḥ. -/
def given : Known Drink Hukm := [(.khamr, .haram), (.water, .mubah)]

example : factorsOnB iskar given = true := rfl

/-- Liquidity meets a naqḍ in the given cases themselves. -/
example : factorsOnB liquid given = false := rfl

example : Naqd liquid given :=
  not_factorsOn_iff_naqd.1 fun h => absurd (factorsOnB_iff.2 h) (by decide)

/-- Every ruling consistent with the given cases that factors through iskār forbids nabīdh. -/
example {H : Drink → Hukm} (hf : Schema.Factors H iskar) (ha : Agrees H given) : H .nabidh = .haram :=
  qiyas_determined (asl := (.khamr, .haram)) hf ha (by simp [given]) rfl

/-! ## M10: Ibn Rajab Q2, farʿ 2 (`rajab_m8_tranche4_furu.json`, q002.f002)

Washing (al-ghasl) the hanging hair in the ghusl and the wuḍūʾ. In janāba: two wujūh, al-Mughnī's (not obligatory, «طردا للقاعدة») and the
other (obligatory taʿabbudan). In the minor ḥadath it is washed «على الصحيح». Verdict: is
its ghasl obligatory? -/

inductive Hadath | janaba | asghar
  deriving DecidableEq, Repr

def mughni : Patch Hadath Bool := ⟨"al-Mughnī", (· == .janaba), fun _ => false⟩
def otherWajh : Patch Hadath Bool := ⟨"the other wajh", (· == .janaba), fun _ => true⟩
def asgharSahih : Patch Hadath Bool := ⟨"al-ṣaḥīḥ (minor ḥadath)", (· == .asghar), fun _ => true⟩

def situations : List Hadath := [.janaba, .asghar]

/-- Different contexts, different rulings: no contradiction, the family glues. -/
example : obstructions situations [mughni, asgharSahih] = [] := rfl

example : ∃ g, Glues (cover situations [mughni, asgharSahih]) (sections situations [mughni, asgharSahih]) g :=
  glues_iff_obstructions_nil.2 rfl

/-- The two wujūh on the same context: the ikhtilāf is recorded as an obstruction at janāba. -/
example : obstructions situations [mughni, otherWajh, asgharSahih] =
    [("al-Mughnī", "the other wajh", .janaba), ("the other wajh", "al-Mughnī", .janaba)] := rfl

example : ¬ ∃ g, Glues (cover situations [mughni, otherWajh, asgharSahih])
    (sections situations [mughni, otherWajh, asgharSahih]) g :=
  fun h => absurd (glues_iff_obstructions_nil.1 h) (by simp [obstructions, situations, mughni, otherWajh, asgharSahih])

end UsulTest.Cat
