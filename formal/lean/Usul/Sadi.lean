import Usul.Qawaid

/-!
# al-Saʿdī, *al-Qawāʿid wa'l-Uṣūl al-Jāmiʿa* — formal readings (roadmap M3)

Each section names the rule number (`Qnn`) of the Dār al-Waṭan edition (60 rules;
count confirmed in `corpus/audit.json`). Statements are readings, not the text: the
catalogue `corpus/proposals/sadi_qawaid.json` carries the Arabic, the gloss and the
record locators. Every reading is a candidate until reviewed.
-/

namespace Usul.Sadi

open Usul

/-! ## Q1 — the Lawgiver commands only pure or preponderant benefit, forbids only pure or
preponderant harm -/

/-- Benefit and harm of an act, on a common scale. -/
structure Weighing where
  benefit : Nat
  harm    : Nat

/-- Q1 as a constraint on a ruling assignment. -/
def Q01 {Act : Type} (ruling : Act → Hukm) (w : Act → Weighing) : Prop :=
  ∀ a, ((ruling a).mode = .talabFil → (w a).harm < (w a).benefit) ∧
       ((ruling a).mode = .talabTark → (w a).benefit < (w a).harm)

/-- Under Q1 an act whose benefit and harm balance is neither demanded nor forbidden:
it is mubāḥ. -/
theorem q01_balanced_is_mubah {Act : Type} {ruling : Act → Hukm} {w : Act → Weighing}
    (h : Q01 ruling w) (a : Act) (hb : (w a).benefit = (w a).harm) : ruling a = .mubah := by
  have ⟨hf, ht⟩ := h a
  cases hr : ruling a with
  | mubah => rfl
  | wajib | mandub => simp [hr, Hukm.mode] at hf; omega
  | haram | makruh => simp [hr, Hukm.mode] at ht; omega

/-! ## Q2 — means take the ruling of their ends (closure under necessary means) -/

theorem q02_means_of_wajib {Act : Type} {needs : Act → Act → Prop} {base : Act → Prop}
    {a b : Act} (h : Qawaid.Wajib needs base a) (hn : needs a b) : Qawaid.Wajib needs base b :=
  .means h hn

/-! ## Q4 — obligation follows capacity; no obligation with inability, no prohibition
with necessity -/

/-- The operative status of a ruling given capacity and necessity (ḍarūra). -/
def operative (capable darura : Bool) : Hukm → Hukm
  | .wajib => if capable then .wajib else .mubah
  | .haram => if darura then .mubah else .haram
  | h => h

theorem q04_no_wajib_with_inability (d : Bool) (h : Hukm) : operative false d h ≠ .wajib := by
  cases h <;> cases d <;> simp [operative]

theorem q04_no_haram_with_necessity (c : Bool) (h : Hukm) : operative c true h ≠ .haram := by
  cases h <;> cases c <;> simp [operative]

/-- Capacity and no necessity: the ruling stands as given. -/
theorem q04_ordinary_case (h : Hukm) : operative true false h = h := by
  cases h <;> rfl

/-- Relief only ever loosens: the operative status is never *more* binding. -/
theorem q04_relief_never_binds (c d : Bool) (h : Hukm) :
    (operative c d h).binding = true → h.binding = true := by
  cases h <;> cases c <;> cases d <;> simp [operative, Hukm.binding]

/-! ## Q6 — in ʿibādāt the default is prohibition, in ʿādāt permission -/

/-- A ruling is the dalīl's when there is one, else the domain default. -/
def ruled (d : Domain) (dalil : Option Hukm) : Hukm := dalil.getD d.default

theorem q06_no_worship_without_dalil : ruled .ibada none = .haram := rfl
theorem q06_customs_permitted_by_default : ruled .ada none = .mubah := rfl
theorem q06_dalil_prevails (d : Domain) (h : Hukm) : ruled d (some h) = h := rfl

/-! ## Q8 — rulings hold only with their conditions and pillars present and impediments
absent -/

structure Gate (α : Type) where
  conds       : List (α → Prop)
  impediments : List (α → Prop)

def Gate.Holds {α : Type} (g : Gate α) (x : α) : Prop :=
  (∀ c ∈ g.conds, c x) ∧ (∀ m ∈ g.impediments, ¬ m x)

theorem q08_missing_condition {α : Type} {g : Gate α} {x : α} {c : α → Prop}
    (hc : c ∈ g.conds) (h : ¬ c x) : ¬ g.Holds x :=
  fun hg => h (hg.1 c hc)

theorem q08_present_impediment {α : Type} {g : Gate α} {x : α} {m : α → Prop}
    (hm : m ∈ g.impediments) (h : m x) : ¬ g.Holds x :=
  fun hg => hg.2 m hm h

/-! ## Q11 / Q52 — what was stays as it was, certainty is not removed by doubt; but strong
indications (qarāʾin) prevail over the presumption -/

theorem q11_yaqin {V : Type} (cur ev : Qawaid.Held V) (hy : cur.IsYaqin)
    (hs : ev.grade = .shakk) : Qawaid.update cur ev = cur :=
  Qawaid.yaqin_la_yazul_bish_shakk cur ev hy hs

theorem q52_strong_qarina_prevails {V : Type} (asl q : Qawaid.Held V)
    (hq : q.Suspended = false) (h : asl.strength ≤ q.strength) : Qawaid.update asl q = q := by
  simp [Qawaid.update, hq, h]

/-! ## Q16 — justice is obligatory in everything, generosity recommended -/

inductive Conduct where
  | adl | fadl
  deriving DecidableEq, Repr

def Conduct.status : Conduct → Hukm
  | .adl => .wajib
  | .fadl => .mandub

theorem q16_adl_binding_fadl_not : Conduct.adl.status.binding = true ∧ Conduct.fadl.status.binding = false :=
  ⟨rfl, rfl⟩

/-! ## Q22 / Q23 — settlement and stipulations are valid unless they make the forbidden
permitted or the permitted forbidden -/

/-- A settlement or stipulation that turns `before` into `after` for some act. -/
def Voids (before after : Hukm) : Prop :=
  (before = .haram ∧ after ≠ .haram) ∨ (before ≠ .haram ∧ after = .haram)

theorem q22_valid_iff_preserves_prohibition (before after : Hukm) :
    ¬ Voids before after ↔ (before = .haram ↔ after = .haram) := by
  unfold Voids
  cases before <;> cases after <;> simp

/-! ## Q27 — omitting a command out of ignorance or forgetfulness does not discharge it;
committing a prohibition out of ignorance or forgetfulness is excused -/

inductive Breach where
  | omitCommand | commitProhibited
  deriving DecidableEq, Repr

/-- Is the liability discharged when the breach was excused (jahl / nisyān)? -/
def dischargedByExcuse : Breach → Bool
  | .omitCommand => false        -- the command must still be performed
  | .commitProhibited => true    -- the act is forgiven, the worship stands

theorem q27_asymmetry :
    dischargedByExcuse .omitCommand = false ∧ dischargedByExcuse .commitProhibited = true :=
  ⟨rfl, rfl⟩

/-! ## Q28 — the substitute stands in for the original, but only when the original is
impossible -/

def useSubstitute (originalPossible : Bool) : Bool := !originalPossible

theorem q28_substitute_only_when_needed (p : Bool) : useSubstitute p = true ↔ p = false := by
  cases p <;> simp [useSubstitute]

/-- The original and the substitute that stands in for it. -/
inductive Means where
  | original | substitute
  deriving DecidableEq, Repr

/-- What a means permits: whatever the original permits, by either means. -/
def permits {Act : Type} (byOriginal : Act → Bool) : Means → Act → Bool := fun _ => byOriginal

/-- Q28's first half: «يستباح به ما يستباح بالماء من العبادات وغيرها، وأنه يقوم مقامه في كل شيء».
Once in use, the substitute permits exactly what the original permits (tayammum and water: furūq F51). -/
theorem q28_stands_in_everything {Act : Type} (byOriginal : Act → Bool) (a : Act) :
    permits byOriginal .substitute a = permits byOriginal .original a := rfl

/-! ## Q33 — when benefits crowd, the higher is preferred; when harms crowd and one must be
done, the lighter -/

/-- The first element of maximal key. -/
def best {α : Type} (key : α → Int) : List α → Option α
  | [] => none
  | x :: xs =>
    match best key xs with
    | none => some x
    | some b => if key b ≤ key x then some x else some b

theorem best_mem {α : Type} (key : α → Int) : ∀ {xs : List α} {b : α}, best key xs = some b → b ∈ xs
  | [], _, h => by simp [best] at h
  | x :: xs, b, h => by
    simp only [best] at h
    split at h
    · simp_all
    · split at h
      · simp_all
      · next b' hb _ => simp at h; subst h; exact List.mem_cons_of_mem _ (best_mem key hb)

theorem best_cons_ne_none {α : Type} (key : α → Int) (z : α) (zs : List α) :
    best key (z :: zs) ≠ none := by
  simp only [best]
  split
  · simp
  · split <;> simp

theorem best_max {α : Type} (key : α → Int) : ∀ {xs : List α} {b : α},
    best key xs = some b → ∀ y ∈ xs, key y ≤ key b
  | [], _, h => by simp [best] at h
  | x :: xs, b, h => by
    intro y hy
    simp only [best] at h
    cases hb : best key xs with
    | none =>
      rw [hb] at h; simp at h; subst h
      cases xs with
      | nil => simp at hy; subst hy; exact Int.le_refl _
      | cons z zs => exact absurd hb (best_cons_ne_none key z zs)
    | some b' =>
      rw [hb] at h
      have ih := best_max key hb
      by_cases hle : key b' ≤ key x
      · simp [hle] at h; subst h
        cases List.mem_cons.mp hy with
        | inl e => subst e; exact Int.le_refl _
        | inr hy => have := ih y hy; omega
      · simp [hle] at h; subst h
        cases List.mem_cons.mp hy with
        | inl e => subst e; omega
        | inr hy => exact ih y hy

/-- Q33a: among crowding benefits, the chosen one is the greatest. -/
theorem q33_higher_benefit {α : Type} (benefit : α → Nat) {xs : List α} {b : α}
    (h : best (fun x => (benefit x : Int)) xs = some b) : ∀ y ∈ xs, benefit y ≤ benefit b :=
  fun y hy => Int.ofNat_le.mp (best_max _ h y hy)

/-- Q33b: among crowding harms, the chosen one is the lightest. -/
theorem q33_lighter_harm {α : Type} (harm : α → Nat) {xs : List α} {b : α}
    (h : best (fun x => -(harm x : Int)) xs = some b) : ∀ y ∈ xs, harm b ≤ harm y :=
  fun y hy => Int.ofNat_le.mp (Int.neg_le_neg_iff.mp (best_max _ h y hy))

/-! ## Q38 — a prohibition aimed at the act of worship itself or at its condition voids it;
one aimed at something external does not (the act is valid, the transgression sinful) -/

inductive ProhibitionTarget where
  | essence | condition | external
  deriving DecidableEq, Repr

def validDespiteProhibition : ProhibitionTarget → Bool
  | .external => true
  | _ => false

theorem q38_voids_iff_intrinsic (t : ProhibitionTarget) :
    validDespiteProhibition t = false ↔ t ≠ .external := by
  cases t <;> simp [validDespiteProhibition]

/-! ## Q40 — the whole command is due; whoever can do part must do that part, unless the
part is a pure means or not worship by itself -/

def obligedParts {P : Type} (parts : List P) (can pureMeans : P → Bool) : List P :=
  parts.filter (fun p => can p && !pureMeans p)

theorem q40_only_capable_parts {P : Type} (parts : List P) (can pureMeans : P → Bool) :
    ∀ p ∈ obligedParts parts can pureMeans, can p = true := by
  intro p hp
  simp [obligedParts, List.mem_filter] at hp
  exact hp.2.1

theorem q40_every_capable_part {P : Type} (parts : List P) (can pureMeans : P → Bool) (p : P)
    (hp : p ∈ parts) (hc : can p = true) (hm : pureMeans p = false) :
    p ∈ obligedParts parts can pureMeans := by
  simp [obligedParts, List.mem_filter, hp, hc, hm]

/-! ## Q58 — the ruling turns on its ʿilla, in presence and absence (qiyās; roadmap §2.5) -/

/-- The ruling depends only on the feature `e` (the ʿilla). -/
def DependsOn {Case F : Type} (H : Case → Hukm) (e : Case → F) : Prop :=
  ∀ x y, e x = e y → H x = H y

/-- Qiyās soundness: a farʿ sharing the aṣl's ʿilla shares its ruling. -/
theorem q58_qiyas {Case F : Type} {H : Case → Hukm} {e : Case → F}
    (hd : DependsOn H e) {asl far : Case} (h : e far = e asl) : H far = H asl :=
  hd far asl h

/-- Factorisation: the ruling depends only on its ʿilla iff it factors through it. -/
theorem q58_factors {Case F : Type} (H : Case → Hukm) (e : Case → F) :
    DependsOn H e ↔ ∃ G : F → Hukm, ∀ x, H x = G (e x) := by
  constructor
  · intro hd
    classical
    refine ⟨fun f => if h : ∃ x, e x = f then H (Classical.choose h) else default, fun x => ?_⟩
    have hx : ∃ y, e y = e x := ⟨x, rfl⟩
    simp only [hx, dite_true]
    exact (hd _ _ (Classical.choose_spec hx)).symm
  · rintro ⟨G, hG⟩ x y hxy
    rw [hG x, hG y, hxy]

/-- Naqḍ: a counterexample to dependence — same ʿilla, different ruling. -/
theorem q58_naqd {Case F : Type} {H : Case → Hukm} {e : Case → F} {x y : Case}
    (he : e x = e y) (hH : H x ≠ H y) : ¬ DependsOn H e :=
  fun hd => hH (hd x y he)

/-! ## Q59 / Q60 — generality (ʿumūm) markers -/

inductive Context where
  | affirmation | negation | prohibition | condition | question
  deriving DecidableEq, Repr

inductive NounForm where
  | nakira                 -- indefinite noun
  | particle               -- man, mā, ayy, matā
  | definiteAl             -- al- of genus/exhaustion
  | singularAnnexed        -- al-mufrad al-muḍāf
  deriving DecidableEq, Repr

/-- Q59: an indefinite is general after negation, prohibition or condition; Q60: the
particles, generic al- and the annexed singular are general in any context. In plain
affirmation the indefinite is absolute (muṭlaq), not general (cf. Manẓūma v. 98). -/
def IsGeneral : NounForm → Context → Bool
  | .nakira, .negation | .nakira, .prohibition | .nakira, .condition => true
  | .nakira, _ => false
  | _, _ => true

theorem q59_nakira_general_in_negation : IsGeneral .nakira .negation = true := rfl
theorem q59_nakira_absolute_in_affirmation : IsGeneral .nakira .affirmation = false := rfl
theorem q60_markers_general (f : NounForm) (c : Context) (h : f ≠ .nakira) : IsGeneral f c = true := by
  cases f <;> cases c <;> simp_all [IsGeneral]

end Usul.Sadi
