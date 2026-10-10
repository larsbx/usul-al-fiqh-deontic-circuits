import Hadith.Isnad
import Usul.Grounded
import Usul.Qawaid

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

/-- Best ṭarīq. The unit is the bottom of the scale; a file with no ṭarīq at all is not on the
scale, and `judgeH` sends it to the mawḍūʿ branch. -/
def best (ts : List Tariq) : Verdict := ts.foldr (fun t v => t.verdict.join v) .daifJiddan

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


/-! ## Rulings: a critic's ḥukm or a matn criterion caps the judgement (decisions D2, D5)

Every qarīna case of the H4 tranches is a crossing into the mawḍūʿ branch: what moves it is a
critic's ruling («باطل منكر», «هو موضوع») or a criterion on the matn, never a rule over
grades and routes. Such a ruling is an argument of the same AF, with a ceiling (a `Hukm`): when
it is in the grounded extension the judgement is capped at the ceiling, and a jawāb that defeats
it removes the cap. A ruling only ever lowers (`judgeR_le`), and with no rulings `judgeR` is
`judge` on the riwāya branch. The
kind (`hukm` / `matn`) is kept for reporting: cases decided this way are counted apart from
rule-derived ones, so the share that rests on a critic's judgement stays visible. -/

inductive RulingKind where
  | hukm | matn
  deriving DecidableEq, Repr

structure Ruling where
  arg     : Nat          -- its index in the AF
  kind    : RulingKind
  ceiling : Hukm
  deriving DecidableEq, Repr

/-- Apply every ruling that survives (is in the grounded set `g`). -/
def capWith (g : List Nat) (rs : List Ruling) (h : Hukm) : Hukm :=
  rs.foldr (fun r acc => if g.contains r.arg then r.ceiling.meet acc else acc) h

def judgeR (ts : List Tariq) (n : Nat) (att : List (Nat × Nat)) (rs : List Ruling) : Hukm :=
  capWith (Usul.Grounded.grounded n att) rs (.marwi (judge ts n att))

theorem judgeR_nil (ts : List Tariq) (n : Nat) (att : List (Nat × Nat)) :
    judgeR ts n att [] = .marwi (judge ts n att) := rfl

theorem capWith_le (g : List Nat) (rs : List Ruling) (h : Hukm) : capWith g rs h ≤ h := by
  induction rs with
  | nil => exact Hukm.le_refl' h
  | cons r rs ih =>
    simp only [capWith, List.foldr_cons]
    split
    · exact Hukm.le_trans' (Hukm.meet_le_right _ _) ih
    · exact ih

/-- A ruling only lowers: it never raises a verdict the rules gave. -/
theorem judgeR_le (ts : List Tariq) (n : Nat) (att : List (Nat × Nat)) (rs : List Ruling) :
    judgeR ts n att rs ≤ .marwi (judge ts n att) :=
  capWith_le _ _ _

/-- A surviving ruling bounds the judgement by its ceiling. -/
theorem capWith_le_ceiling {g : List Nat} {rs : List Ruling} {r : Ruling} (hr : r ∈ rs)
    (hg : g.contains r.arg = true) (h : Hukm) : capWith g rs h ≤ r.ceiling := by
  induction rs with
  | nil => cases hr
  | cons x xs ih =>
    simp only [capWith, List.foldr_cons]
    rcases List.mem_cons.1 hr with rfl | hm
    · simp only [hg, ite_true]; exact Hukm.meet_le_left _ _
    · split
      · exact Hukm.le_trans' (Hukm.meet_le_right _ _) (ih hm)
      · exact ih hm

theorem Hukm.meet_eq_or (a b : Hukm) : a.meet b = a ∨ a.meet b = b := by
  unfold Hukm.meet; split <;> simp

/-- The mawḍūʿ branch is reached only through the start value or a surviving ruling whose
ceiling is mawḍūʿ. -/
theorem capWith_eq_mawdu {g : List Nat} {rs : List Ruling} {h : Hukm} (e : capWith g rs h = .mawdu) :
    h = .mawdu ∨ ∃ r ∈ rs, g.contains r.arg = true ∧ r.ceiling = .mawdu := by
  induction rs with
  | nil => exact .inl e
  | cons x xs ih =>
    simp only [capWith, List.foldr_cons] at e
    split at e
    · rcases Hukm.meet_eq_or x.ceiling _ with m | m <;> rw [m] at e
      · exact .inr ⟨x, List.mem_cons_self .., ‹_›, e⟩
      · rcases ih e with h0 | ⟨r, hr, hg, hc⟩
        · exact .inl h0
        · exact .inr ⟨r, List.mem_cons_of_mem _ hr, hg, hc⟩
    · rcases ih e with h0 | ⟨r, hr, hg, hc⟩
      · exact .inl h0
      · exact .inr ⟨r, List.mem_cons_of_mem _ hr, hg, hc⟩

/-- Worked: a forgery ruling sends two weak routes to the mawḍūʿ branch; a jawāb that defeats it
restores the rule-derived verdict. -/
example : judgeR twoWeak 2 [] [⟨1, .hukm, .mawdu⟩] = .mawdu := by decide
example : judgeR twoWeak 3 [(2, 1)] [⟨1, .hukm, .mawdu⟩] = .marwi .hasan := by decide


/-! ## Li-dhātihi vs li-ghayrihi

*Nuzha*: the lifted ḥadīth «منحط عن رتبة الحسن لذاته، وربما توقف بعضهم عن إطلاق اسم الحسن عليه».
The four-valued verdict keeps one ḥasan; `Basis` records how it was reached, and `refinedRank`
places the lifted grade strictly below the same grade reached by itself. -/

inductive Basis where
  | dhati | ghayri
  deriving DecidableEq, Repr

def basis (ts : List Tariq) (liftStands : Bool) : Basis :=
  if liftStands ∧ Liftable ts then .ghayri else .dhati

theorem bump_ne_of_liftable {ts : List Tariq} (h : Liftable ts) : bump (best ts) ≠ best ts := by
  rcases h.1 with h | h <;> rw [h] <;> decide

/-- A verdict is li-ghayrihi exactly when aggregation moved it off the best single route. -/
theorem ghayri_iff (ts : List Tariq) (b : Bool) :
    basis ts b = .ghayri ↔ aggregate ts b ≠ best ts := by
  unfold basis aggregate
  by_cases h : b = true ∧ Liftable ts
  · simp only [h, and_self, ite_true, ne_eq, true_iff]; exact bump_ne_of_liftable h.2
  · simp only [h, ite_false, ne_eq, not_true_eq_false, iff_false]; decide

/-- The *Nuzha*'s ordering: same verdict, li-ghayrihi below li-dhātihi. -/
def refinedRank (v : Verdict) (b : Basis) : Nat := 2 * v.rank + (if b = .dhati then 1 else 0)

theorem ghayri_below_dhati (v : Verdict) : refinedRank v .ghayri < refinedRank v .dhati := by
  simp [refinedRank]

/-- The refinement never reorders different verdicts. -/
theorem refinedRank_respects {v w : Verdict} (h : v.rank < w.rank) (b c : Basis) :
    refinedRank v b < refinedRank w c := by
  unfold refinedRank; split <;> split <;> omega

example : basis twoWeak true = .ghayri := by decide


/-! ## The muʿtabar follower: «فوقه أو مثله لا دونه» (decision D3)

The *Nuzha* requires the follower to be at least as good as the narrator it follows. Two readings:
* `lax`: any independent supporting route qualifies (the rule as first encoded);
* `strict`: the strongest route (best verdict, then the best weakest-narrator rank) must have an
  independent supporter whose weakest narrator is no worse than its own.
Routes carry their `Isnad.floor` beside them. `strict` never lifts where `lax` does not
(`strict_le_lax`), and `lax` is exactly `judge` (`judgeI_lax`). -/

inductive Itibar where
  | lax | strict
  deriving DecidableEq, Repr

/-- The route a lift would build on: best verdict, then lowest floor (first wins ties). -/
def baseRoute (rs : List (Tariq × Nat)) : Option (Tariq × Nat) :=
  let b := best (rs.map Prod.fst)
  (rs.filter (·.1.verdict == b)).foldl
    (fun acc r => match acc with
      | none => some r
      | some a => if r.2 < a.2 then some r else some a) none

def mutabar : Itibar → List (Tariq × Nat) → Bool
  | .lax, _ => true
  | .strict, rs => match baseRoute rs with
    | none => false
    | some b => rs.any fun r => r.1.madar != b.1.madar && decide (Verdict.daif ≤ r.1.verdict) && decide (r.2 ≤ b.2)

def judgeI (pol : Itibar) (rs : List (Tariq × Nat)) (n : Nat) (att : List (Nat × Nat)) : Verdict :=
  let ts := rs.map Prod.fst
  aggregate ts ((Usul.Grounded.grounded n att).contains 0 && mutabar pol rs)

theorem judgeI_lax (rs : List (Tariq × Nat)) (n : Nat) (att : List (Nat × Nat)) :
    judgeI .lax rs n att = judge (rs.map Prod.fst) n att := by
  simp [judgeI, judge, mutabar]

theorem aggregate_mono_flag (ts : List Tariq) : aggregate ts false ≤ aggregate ts true := by
  unfold aggregate; simp only [Bool.false_eq_true, false_and, ite_false]; split
  · exact le_bump _
  · exact Verdict.le_refl' _

/-- The strict reading never lifts where the lax one does not. -/
theorem strict_le_lax (rs : List (Tariq × Nat)) (n : Nat) (att : List (Nat × Nat)) :
    judgeI .strict rs n att ≤ judgeI .lax rs n att := by
  unfold judgeI
  cases (Usul.Grounded.grounded n att).contains 0 <;> cases mutabar .strict rs <;>
    simp [mutabar] <;> first | exact Verdict.le_refl' _ | exact aggregate_mono_flag _

/-- Worked: a ṣadūq-yahim route (floor 5) followed only by a majhūl route (floor 9) lifts under
`lax` but not under `strict`; two majhūl routes lift under both (decision D1 untouched). -/
example : judgeI .lax [(⟨.daif, 1⟩, 5), (⟨.daif, 2⟩, 9)] 1 [] = .hasan := by decide
example : judgeI .strict [(⟨.daif, 1⟩, 5), (⟨.daif, 2⟩, 9)] 1 [] = .daif := by decide
example : judgeI .strict [(⟨.daif, 1⟩, 9), (⟨.daif, 2⟩, 9)] 1 [] = .hasan := by decide


/-! ### D3 decided: strict, checked against the dogfooded bank

The uṣūl track's bank decides displacement with `Usul.Qawaid.update` (al-Saʿdī Q11/Q52): a
challenger displaces the incumbent only at equal or greater strength, and a weaker one never does
(Ibn Rajab 159, `Usul.Refinements.zahirPrevails`). Here the incumbent is the base route's tawaqquf
and the challenger is the follower: «فوقه أو مثله لا دونه» is that rule read on the *Taqrīb*
scale, which is `strict`. On the bank's own four-grade scale every iʿtibār martaba is shakk, so the
bank cannot separate the readings there (`bank_scale_blind_in_itibar`): it is neutral, and gives
no support to `lax`. -/

/-- The bank: a weaker challenger leaves the incumbent in place. -/
theorem bank_weaker_never_displaces {V : Type} (cur ev : Usul.Qawaid.Held V)
    (h : ¬ cur.strength ≤ ev.strength) : Usul.Qawaid.update cur ev = cur := by
  simp [Usul.Qawaid.update, h]

/-- The same rule here: a follower weaker than the base does not make the file muʿtabar. -/
theorem strict_weaker_follower_never_lifts (a b : Nat) (h : a < b) :
    mutabar .strict [(⟨.daif, 0⟩, a), (⟨.daif, 1⟩, b)] = false := by
  have hb : ¬ b < a := by omega
  have hba : ¬ b ≤ a := by omega
  have d1 : ¬ (Verdict.daif ≤ Verdict.daifJiddan) := by decide
  have d2 : Verdict.daif ≤ Verdict.daif := by decide
  simp [mutabar, baseRoute, best, Verdict.join, hb, hba, d1, d2]

/-- …while `lax` lets it through: the reading the bank rules out. -/
theorem lax_weaker_follower_lifts (a b : Nat) :
    mutabar .lax [(⟨.daif, 0⟩, a), (⟨.daif, 1⟩, b)] = true := rfl

/-- The bank's scale is too coarse here: every iʿtibār martaba grades as shakk. -/
theorem bank_scale_blind_in_itibar (m : Martaba) (h5 : 5 ≤ m.rank) (h9 : m.rank ≤ 9) :
    m.verdict.grade = .shakk := by
  cases m <;> simp_all [Martaba.rank, Martaba.verdict, Verdict.grade]

/-- The project default (decision D3, 2026-10-09). -/
def Itibar.default : Itibar := .strict

/-! ## The judgement on a matn (decision D5)

A file with no isnād at all (لا أصل له) is on the mawḍūʿ branch; any route puts it on the riwāya
branch, at the verdict the rules give. Only a surviving ruling moves a narrated matn across. -/

/-- The kernel as recorded in the H4 tranches, without rulings. -/
def judgeH (pol : Itibar) (rs : List (Tariq × Nat)) (n : Nat) (att : List (Nat × Nat)) : Hukm :=
  if rs.isEmpty then .mawdu else .marwi (judgeI pol rs n att)

/-- …and with them (D2). -/
def judgeRI (pol : Itibar) (rs : List (Tariq × Nat)) (n : Nat) (att : List (Nat × Nat))
    (rulings : List Ruling) : Hukm :=
  capWith (Usul.Grounded.grounded n att) rulings (judgeH pol rs n att)

/-- Rules alone fabricate nothing: without rulings, mawḍūʿ means there is no route. -/
theorem judgeH_mawdu_iff (pol : Itibar) (rs : List (Tariq × Nat)) (n : Nat) (att : List (Nat × Nat)) :
    judgeH pol rs n att = .mawdu ↔ rs = [] := by
  unfold judgeH; cases rs <;> simp

/-- **D5.** A matn reaches the mawḍūʿ branch only by a finding: no isnād at all, or a surviving
ruling (a critic's ḥukm bi'l-waḍʿ, naqd al-matn) whose ceiling is mawḍūʿ. A kadhdhāb route alone
is sāqiṭ (`Isnad.saqit_of_kadhdhab`). -/
theorem mawdu_only_by_finding {pol : Itibar} {rs : List (Tariq × Nat)} {n : Nat}
    {att : List (Nat × Nat)} {rulings : List Ruling} (e : judgeRI pol rs n att rulings = .mawdu) :
    rs = [] ∨ ∃ r ∈ rulings, (Usul.Grounded.grounded n att).contains r.arg = true ∧ r.ceiling = .mawdu :=
  (capWith_eq_mawdu e).imp_left (judgeH_mawdu_iff pol rs n att).1

theorem judgeRI_lax {rs : List (Tariq × Nat)} (h : rs ≠ []) (n : Nat) (att : List (Nat × Nat))
    (rulings : List Ruling) :
    judgeRI .lax rs n att rulings = judgeR (rs.map Prod.fst) n att rulings := by
  cases rs with
  | nil => exact absurd rfl h
  | cons _ _ => simp [judgeRI, judgeR, judgeH, judgeI_lax]

end Hadith
