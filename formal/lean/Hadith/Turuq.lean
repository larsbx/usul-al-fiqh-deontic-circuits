import Hadith.Isnad
import Usul.Grounded

/-!
# Ṭuruq: aggregation as defeasible evidence (al-Albānī track §2.3, H5)

al-Albānī's central rule: ḍaʿīf + ḍaʿīf (independent, not shadīd) → ḥasan li-ghayrihi, and
ḥasan + support → ṣaḥīḥ li-ghayrihi. This is the contested axiom: the *manhaj al-mutaqaddimīn*
reading (Ibn Rajab, *Sharḥ ʿIlal al-Tirmidhī*) is that early critics judged by qarāʾin, so a
bare count of ṭuruq does not compose. The rule is therefore **not** a sound inference rule here.
It is an *argument* (index 0 of a finite AF) that objections attack:

* ʿilla khafiyya, shudhūdh against an awthaq, a hidden common madār, the qarīna of a critic's
  explicit iʿlāl: each is an attacker of the lift;
* a jawāb (e.g. the madār shown to differ, the ʿilla shown not qādiḥa) attacks its objection.

The lift stands iff argument 0 is in the grounded extension (`Usul.Grounded`, proved against
`Usul.Dung`). The guards of the rule itself (`Liftable`) are proved to be the conservative
part: shadīd ṭuruq are inert, one madār never lifts, and a lift moves exactly one rung.
-/

namespace Hadith

/-- One ṭarīq after chain evaluation: its verdict and the *madār* (the link where its weakness
or its common narrator sits). Distinct madār is the independence condition. -/
structure Tariq where
  verdict : Verdict
  madar   : Nat
  deriving DecidableEq, Repr

/-- Best ṭarīq (the unit is mawḍūʿ: no ṭarīq, no ḥadīth). -/
def best (ts : List Tariq) : Verdict := ts.foldr (fun t v => t.verdict.join v) .mawdu

/-- Independent supporting madār: ṭuruq at least ḍaʿīf, counted once per madār. -/
def supports (ts : List Tariq) : List Nat :=
  ((ts.filter fun t => decide (Verdict.daif ≤ t.verdict)).map (·.madar)).eraseDups

/-- The rule's own guard: the best is ḍaʿīf or ḥasan, with ≥ 2 independent supports. -/
def Liftable (ts : List Tariq) : Prop :=
  (best ts = .daif ∨ best ts = .hasan) ∧ 2 ≤ (supports ts).length
instance (ts : List Tariq) : Decidable (Liftable ts) := inferInstanceAs (Decidable (_ ∧ _))

/-- One rung: ḍaʿīf → ḥasan li-ghayrihi, ḥasan → ṣaḥīḥ li-ghayrihi. -/
def bump : Verdict → Verdict
  | .daif => .hasan
  | .hasan => .sahih
  | v => v

/-- The verdict given whether the lift argument survives its objections. -/
def aggregate (ts : List Tariq) (liftStands : Bool) : Verdict :=
  if liftStands ∧ Liftable ts then bump (best ts) else best ts

/-- The full judgement: the lift is argument 0 of an AF on `0..n-1` with attacks `att`. -/
def judge (ts : List Tariq) (n : Nat) (att : List (Nat × Nat)) : Verdict :=
  aggregate ts ((Usul.Grounded.grounded n att).contains 0)

/-! ## Guards of the rule -/

theorem bump_rank_le (v : Verdict) : (bump v).rank ≤ v.rank + 1 := by cases v <;> decide
theorem le_bump (v : Verdict) : v ≤ bump v := by cases v <;> decide

/-- Aggregation never lowers the best ṭarīq and never climbs more than one rung. -/
theorem best_le_aggregate (ts : List Tariq) (b : Bool) : best ts ≤ aggregate ts b := by
  unfold aggregate; split
  · exact le_bump _
  · exact Verdict.le_refl' _

theorem aggregate_rank_le (ts : List Tariq) (b : Bool) :
    (aggregate ts b).rank ≤ (best ts).rank + 1 := by
  unfold aggregate; split
  · exact bump_rank_le _
  · exact Nat.le_succ _

/-- *Taqwiya laysa ʿalā iṭlāqihi*: a shadīd best ṭarīq is never lifted, whatever the count. -/
theorem aggregate_of_shadid {ts : List Tariq} (h : (best ts).Shadid) (b : Bool) :
    aggregate ts b = best ts := by
  have : ¬ Liftable ts := fun ⟨hb, _⟩ => by rcases hb with hb | hb <;> rw [hb] at h <;> exact absurd h (by decide)
  simp [aggregate, this]

/-- One madār never lifts: repeated ṭuruq through a single weak narrator are one ṭarīq. -/
theorem not_liftable_of_one_madar {ts : List Tariq} (h : (supports ts).length ≤ 1) :
    ¬ Liftable ts := fun ⟨_, h2⟩ => absurd (Nat.le_trans h2 h) (by decide)

theorem best_cons (t : Tariq) (ts : List Tariq) : best (t :: ts) = t.verdict.join (best ts) := rfl

/-- Adding a shadīd ṭarīq changes neither the supports nor whether the rule applies. -/
theorem supports_cons_shadid {t : Tariq} (ht : t.verdict.Shadid) (ts : List Tariq) :
    supports (t :: ts) = supports ts := by
  have : decide (Verdict.daif ≤ t.verdict) = false := by
    cases hv : t.verdict <;> simp_all [Verdict.Shadid, Verdict.rank] <;> decide
  simp [supports, this]

theorem liftable_cons_shadid {t : Tariq} (ht : t.verdict.Shadid) (ts : List Tariq) :
    Liftable (t :: ts) ↔ Liftable ts := by
  unfold Liftable; rw [supports_cons_shadid ht, best_cons]
  have : (t.verdict.join (best ts) = .daif ↔ best ts = .daif) ∧
         (t.verdict.join (best ts) = .hasan ↔ best ts = .hasan) := by
    cases hv : t.verdict <;> cases hb : best ts <;> simp_all [Verdict.Shadid, Verdict.rank] <;>
      first | decide | (simp [Verdict.join, instLEVerdict, Verdict.rank])
  rw [this.1, this.2]

/-! ## Defeasibility: worked AFs (non-monotonicity and reinstatement)

Two independent ḍaʿīf ṭuruq. With no objection the lift stands (ḥasan li-ghayrihi); an
ʿilla (argument 1) defeats it; a jawāb (argument 2) reinstates it. This is the shape of a
tarājuʿ: the verdict is not monotone in the evidence file. -/

def twoWeak : List Tariq := [⟨.daif, 1⟩, ⟨.daif, 2⟩]
def sameMadar : List Tariq := [⟨.daif, 1⟩, ⟨.daif, 1⟩]

example : judge twoWeak 1 [] = .hasan := by decide
example : judge twoWeak 2 [(1, 0)] = .daif := by decide
example : judge twoWeak 3 [(1, 0), (2, 1)] = .hasan := by decide
example : judge sameMadar 1 [] = .daif := by decide
example : judge (⟨.daifJiddan, 3⟩ :: ⟨.daifJiddan, 4⟩ :: []) 1 [] = .daifJiddan := by decide

/-- Non-monotonicity, stated: there is a file and an added objection that lowers the verdict. -/
theorem judge_not_monotone :
    ∃ ts n att n' att', att ⊆ att' ∧ (judge ts n' att').rank < (judge ts n att).rank :=
  ⟨twoWeak, 1, [], 2, [(1, 0)], List.nil_subset _, by decide⟩

end Hadith
