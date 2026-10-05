import Usul.Hukm

/-!
# Signature Σ (roadmap §2.1–2.2, M2)

Ḥudūd are distinguishing predicates (*tamyīz*), not essences (roadmap §0.1).
-/

namespace Usul

/-- A subject of address. Capacities are data; *mukallaf* is a refinement, not a flag. -/
structure Subject where
  baligh : Bool
  aqil   : Bool
  deriving DecidableEq, Repr

/-- *Shart al-taklīf*: bulūgh and ʿaql (Ibn al-Laḥḥām, qāʿida 2: «شرط التكليف العقل وفهم الخطاب»). -/
def Subject.IsMukallaf (s : Subject) : Prop := s.baligh = true ∧ s.aqil = true

instance (s : Subject) : Decidable s.IsMukallaf := inferInstanceAs (Decidable (_ ∧ _))

abbrev Mukallaf := { s : Subject // s.IsMukallaf }

/-- Epistemic grade: qaṭʿ > ẓann ghālib > shakk > wahm. -/
inductive Grade where
  | wahm | shakk | zann | qat
  deriving DecidableEq, Repr

namespace Grade
def rank : Grade → Nat | wahm => 0 | shakk => 1 | zann => 2 | qat => 3
instance : LE Grade := ⟨fun a b => a.rank ≤ b.rank⟩
instance : LT Grade := ⟨fun a b => a.rank < b.rank⟩
instance (a b : Grade) : Decidable (a ≤ b) := inferInstanceAs (Decidable (a.rank ≤ b.rank))
instance (a b : Grade) : Decidable (a < b) := inferInstanceAs (Decidable (a.rank < b.rank))
/-- *Yaqīn* is qaṭʿ or prevailing ẓann (both count as knowledge for ʿamal). -/
def IsYaqin (g : Grade) : Prop := zann ≤ g
instance (g : Grade) : Decidable g.IsYaqin := inferInstanceAs (Decidable (zann ≤ g))
end Grade

/-- Sources of evidence, in Aḥmad's order of resort as reported in *Iʿlām al-Muwaqqiʿīn*:
naṣṣ ≻ undisputed fatwā of a ṣaḥābī ≻ the ṣaḥābī view closest to naṣṣ ≻ mursal/ḍaʿīf ≻ qiyās;
istiṣḥāb is the fallback default. Ijmāʿ ranks with naṣṣ. -/
inductive DalilKind where
  | nass | ijma | fatwaSahabi | aqrabSahabi | mursalDaif | qiyas | istishab
  deriving DecidableEq, Repr

/-- Lower number = resorted to first. -/
def DalilKind.resort : DalilKind → Nat
  | .nass => 0 | .ijma => 0 | .fatwaSahabi => 1 | .aqrabSahabi => 2
  | .mursalDaif => 3 | .qiyas => 4 | .istishab => 5

theorem DalilKind.qiyas_after_athar (k : DalilKind) (h : k ≠ .qiyas ∧ k ≠ .istishab) :
    k.resort < DalilKind.qiyas.resort := by
  cases k <;> simp_all [resort]

/-- Domain sort for the default (*al-aṣl*): ʿādāt vs ʿibādāt. -/
inductive Domain where
  | ada | ibada
  deriving DecidableEq, Repr

/-- *al-aṣl fī'l-ashyāʾ al-ibāḥa* / *al-aṣl fī'l-ʿibādāt al-tawqīf*. -/
def Domain.default : Domain → Hukm
  | .ada => .mubah
  | .ibada => .haram

/-- Waḍʿī preconditions as a dependent gate: a ḥukm attaches only given sabab, sharṭ and no māniʿ. -/
structure Wad (Act : Type) where
  sabab : Act → Subject → Prop
  shart : Act → Subject → Prop
  mani  : Act → Subject → Prop

/-- A ḥukm can be *applied* only with evidence of every waḍʿī condition and of taklīf. -/
def applies {Act : Type} (w : Wad Act) (ruling : Act → Hukm) (a : Act) (s : Subject)
    (_ : w.sabab a s) (_ : w.shart a s) (_ : ¬ w.mani a s) (_ : s.IsMukallaf) : Hukm :=
  ruling a

/-- Non-mukallafs are outside taklīf: there is no way to call `applies` for them. -/
theorem no_taklif_without_mukallaf (s : Subject) (h : s.aqil = false) : ¬ s.IsMukallaf := by
  intro ⟨_, ha⟩; simp_all

end Usul
