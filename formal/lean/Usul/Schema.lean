import Usul.Sadi
import Usul.Taarud

/-!
# Schemata: the structure under the readings (roadmap M3 → M6)

Most of al-Saʿdī's rules are not independent axioms but instances of a few shapes. Each
shape is stated here once, over arbitrary types, with

* its **laws** (what any instance satisfies), and
* a **transport** theorem: the shape is preserved along a map between domains, so a rule
  read in one bāb carries its structure to any other bāb it is applied to (takhrīj,
  qiyās of rules, M6 institutions).

| Schema | Shape | Laws | Transport |
|---|---|---|---|
| S1 `Factors` / `Ignores` | a ruling ignores a feature | `post`, `refine`, `qiyas` | `pullback` |
| S2 `first` / `resolveD` | priority of sources, first defined wins | monoid hom `first_append`, `first_conservative` | `first_map` (naturality) |
| S3 `Gate` algebra | conditions ∧ ¬impediments | `holds_meet`, `holds_ofBools` | `holds_comap` |
| S4 `Closure` | least set from seeds, closed under a step | `extensive`, `least`, `mono`, `idem` | `map` |
| S5 `Inert` | events that leave a state unchanged | `inert_fold` | — (pointwise) |
| S6 `burdenOf` | proof on whoever departs from the presumption | `burden_factors`, `burden_after_update` | via S1 |
| S7 `Covers` / `reps` | one performance per merge class | `reps_covers`, `reps_length_le`, `reps_sub` | `Covers.map` |
| S8 `Optimal` | choose a best option on one scale | `best_optimal`, `best_eq_none_iff`, `Optimal.key_unique`, `Optimal.restrict` | `Optimal.mono`, `Optimal.map` |

Instances already in the kernel are proved here (Q2 `Wajib`, Q4 `operative`, Q6 `ruled`,
Q11 `update`, Q28 `useSubstitute`, Q33 `best`, Q40 `obligedParts`, Q58 `DependsOn`, taʿāruḍ
`resolve`); the rest are proved in `Usul.Muamalat` and `Usul.Kulliyyat`. Which interpretive
commitment each instance makes is recorded, as open questions for review, in
`corpus/review/sadi_interpretive_questions.json`.
-/

namespace Usul.Schema

open Usul

/-! ## S1 — invariance: the ruling depends only on a feature -/

/-- `H` depends only on the feature `e`: cases equal on `e` get equal rulings. -/
def Factors {α F β : Type} (H : α → β) (e : α → F) : Prop :=
  ∀ x y, e x = e y → H x = H y

namespace Factors

variable {α α' F F' β γ : Type} {H : α → β} {e : α → F}

theorem of_eq (G : F → β) (h : ∀ x, H x = G (e x)) : Factors H e :=
  fun x y hxy => by rw [h x, h y, hxy]

/-- Every consequence computed from the ruling inherits its invariance. -/
theorem post (g : β → γ) (hf : Factors H e) : Factors (g ∘ H) e :=
  fun x y h => congrArg g (hf x y h)

/-- Transport: reading the cases of another domain through `φ` preserves invariance. -/
theorem pullback (φ : α' → α) (hf : Factors H e) : Factors (H ∘ φ) (e ∘ φ) :=
  fun x y h => hf (φ x) (φ y) h

/-- A finer feature (one that determines `e`) is also sufficient. -/
theorem refine {e' : α → F'} (k : F' → F) (he : ∀ x, e x = k (e' x)) (hf : Factors H e) :
    Factors H e' :=
  fun x y h => hf x y (by rw [he x, he y, h])

/-- Qiyās: a farʿ sharing the aṣl's feature shares its ruling. -/
theorem qiyas (hf : Factors H e) {asl far : α} (h : e far = e asl) : H far = H asl :=
  hf far asl h

end Factors

/-- Q58's `DependsOn` is S1 at codomain `Hukm`. -/
theorem dependsOn_iff_factors {Case F : Type} (H : Case → Hukm) (e : Case → F) :
    Sadi.DependsOn H e ↔ Factors H e := Iff.rfl

/-- A two-argument ruling that ignores its second argument (intent, belief, a claim of error,
harm received, …). -/
def Ignores {α ι β : Type} (H : α → ι → β) : Prop := ∀ a i j, H a i = H a j

theorem ignores_iff_factors {α ι β : Type} (H : α → ι → β) :
    Ignores H ↔ Factors (fun p : α × ι => H p.1 p.2) Prod.fst := by
  constructor
  · intro h ⟨a, i⟩ ⟨b, j⟩ hab
    dsimp only at hab; subst hab; exact h a i j
  · intro h a i j; exact h (a, i) (a, j) rfl

/-! ## S2 — priority of sources: the first defined source decides -/

/-- The first defined value in a priority-ordered list of sources. -/
def first {α : Type} : List (Option α) → Option α
  | [] => none
  | some a :: _ => some a
  | none :: xs => first xs

/-- Resolve by priority, falling back to `d` when every source is silent. -/
def resolveD {α : Type} (xs : List (Option α)) (d : α) : α := (first xs).getD d

section Priority

variable {α β : Type}

/-- `first` is a monoid homomorphism from `(List, ++)` to `(Option, orElse)`. -/
theorem first_append : ∀ (xs ys : List (Option α)), first (xs ++ ys) = (first xs).orElse fun _ => first ys
  | [], _ => rfl
  | some _ :: _, _ => rfl
  | none :: xs, ys => first_append xs ys

/-- Conservativity: appending lower-priority sources never overrides a decision. -/
theorem first_conservative {xs : List (Option α)} {a : α} (h : first xs = some a)
    (ys : List (Option α)) : first (xs ++ ys) = some a := by
  rw [first_append, h]; rfl

theorem first_eq_none_iff : ∀ {xs : List (Option α)}, first xs = none ↔ ∀ o ∈ xs, o = none
  | [] => by simp [first]
  | some _ :: _ => by simp [first]
  | none :: xs => by simp [first, first_eq_none_iff (xs := xs)]

theorem first_mem : ∀ {xs : List (Option α)} {a : α}, first xs = some a → some a ∈ xs
  | [], _, h => by simp [first] at h
  | some b :: _, _, h => by simp [first] at h; simp [h]
  | none :: xs, _, h => List.mem_cons_of_mem _ (first_mem (xs := xs) h)

/-- Transport (naturality): translating every source translates the decision. -/
theorem first_map (f : α → β) : ∀ xs : List (Option α), first (xs.map (Option.map f)) = (first xs).map f
  | [] => rfl
  | some _ :: _ => rfl
  | none :: xs => first_map f xs

theorem resolveD_head (a : α) (xs : List (Option α)) (d : α) : resolveD (some a :: xs) d = a := rfl

theorem resolveD_default {xs : List (Option α)} (d : α) (h : ∀ o ∈ xs, o = none) : resolveD xs d = d := by
  simp [resolveD, first_eq_none_iff.2 h]

theorem resolveD_map (f : α → β) (xs : List (Option α)) (d : α) :
    f (resolveD xs d) = resolveD (xs.map (Option.map f)) (f d) := by
  simp only [resolveD, first_map]; cases first xs <;> rfl

end Priority

/-- Taʿāruḍ resolution is S2: jamʿ, then naskh, then tarjīḥ, defaulting to tawaqquf. -/
theorem taarud_is_priority {P : Type} (c : Conflict P) :
    resolve c = resolveD [c.jam.map .jam, c.naskh.map .naskh, c.tarjih.map .tarjih] .tawaqquf := by
  rcases c with ⟨j, n, t⟩
  cases j <;> cases n <;> cases t <;> rfl

/-- Q6 is S2: the dalīl, defaulting to the domain's presumption. -/
theorem ruled_is_priority (d : Domain) (dalil : Option Hukm) :
    Sadi.ruled d dalil = resolveD [dalil] d.default := by
  cases dalil <;> rfl

/-! ## S3 — the algebra of gates (Q8): conditions and impediments -/

end Usul.Schema

namespace Usul.Sadi.Gate

variable {α β : Type}

def top : Gate α := ⟨[], []⟩

/-- Joining two gates: both sets of conditions, both sets of impediments. -/
def meet (g h : Gate α) : Gate α := ⟨g.conds ++ h.conds, g.impediments ++ h.impediments⟩

/-- Read a gate on another domain through `φ`. -/
def comap (φ : β → α) (g : Gate α) : Gate β :=
  ⟨g.conds.map (· ∘ φ), g.impediments.map (· ∘ φ)⟩

/-- A gate from Boolean conditions and impediments. -/
def ofBools (conds impediments : List (α → Bool)) : Gate α :=
  ⟨conds.map (fun c x => c x = true), impediments.map (fun m x => m x = true)⟩

theorem holds_top (x : α) : (top : Gate α).Holds x := ⟨by simp [top], by simp [top]⟩

theorem holds_meet {g h : Gate α} {x : α} : (g.meet h).Holds x ↔ g.Holds x ∧ h.Holds x := by
  simp only [Gate.Holds, meet, List.mem_append]
  constructor
  · rintro ⟨hc, hm⟩
    exact ⟨⟨fun c h' => hc c (.inl h'), fun m h' => hm m (.inl h')⟩,
      ⟨fun c h' => hc c (.inr h'), fun m h' => hm m (.inr h')⟩⟩
  · rintro ⟨⟨gc, gm⟩, ⟨hc, hm⟩⟩
    exact ⟨fun c h' => h'.elim (gc c) (hc c), fun m h' => h'.elim (gm m) (hm m)⟩

/-- Adding conditions or impediments only narrows (the shape of Q29's qualifiers). -/
theorem meet_narrows {g h : Gate α} {x : α} (hx : (g.meet h).Holds x) : g.Holds x :=
  (holds_meet.1 hx).1

/-- Transport: a gate read through `φ` holds exactly where the original holds. -/
theorem holds_comap {g : Gate α} {φ : β → α} {y : β} : (g.comap φ).Holds y ↔ g.Holds (φ y) := by
  simp only [Gate.Holds, comap, List.mem_map]
  constructor
  · rintro ⟨hc, hm⟩
    exact ⟨fun c h' => hc (c ∘ φ) ⟨c, h', rfl⟩, fun m h' => hm (m ∘ φ) ⟨m, h', rfl⟩⟩
  · rintro ⟨hc, hm⟩
    refine ⟨?_, ?_⟩
    · rintro _ ⟨c, h', rfl⟩; exact hc c h'
    · rintro _ ⟨m, h', rfl⟩; exact hm m h'

theorem comap_meet (g h : Gate α) (φ : β → α) : (g.meet h).comap φ = (g.comap φ).meet (h.comap φ) := by
  simp [comap, meet]

theorem holds_ofBools {cs ms : List (α → Bool)} {x : α} :
    (ofBools cs ms).Holds x ↔ cs.all (· x) = true ∧ ms.any (· x) = false := by
  simp [Gate.Holds, ofBools, List.all_eq_true, List.any_eq_false]

end Usul.Sadi.Gate

namespace Usul.Schema

open Usul

/-! ## S4 — closure: the least set containing the seeds and closed under a step -/

inductive Closure {α : Type} (step : α → α → Prop) (seed : α → Prop) : α → Prop
  | seed {a} : seed a → Closure step seed a
  | step {a b} : Closure step seed a → step a b → Closure step seed b

namespace Closure

variable {α β : Type} {step step' : α → α → Prop} {seed seed' : α → Prop}

theorem extensive {a : α} (h : seed a) : Closure step seed a := .seed h

/-- Leastness: whatever contains the seeds and is closed under the step contains the closure. -/
theorem least (P : α → Prop) (hs : ∀ a, seed a → P a) (hc : ∀ a b, P a → step a b → P b) :
    ∀ a, Closure step seed a → P a := by
  intro a h
  induction h with
  | seed h => exact hs _ h
  | step _ hab ih => exact hc _ _ ih hab

theorem mono (hs : ∀ a, seed a → seed' a) (hst : ∀ a b, step a b → step' a b) :
    ∀ a, Closure step seed a → Closure step' seed' a :=
  least _ (fun a h => .seed (hs a h)) (fun _ _ h hab => .step h (hst _ _ hab))

theorem idem {a : α} : Closure step (Closure step seed) a ↔ Closure step seed a :=
  ⟨least _ (fun _ h => h) (fun _ _ h hab => .step h hab) a, .seed⟩

/-- Transport: a map that preserves seeds and steps carries the closure along. -/
theorem map (f : α → β) {stepB : β → β → Prop} {seedB : β → Prop}
    (hs : ∀ a, seed a → seedB (f a)) (hst : ∀ a b, step a b → stepB (f a) (f b))
    {a : α} (h : Closure step seed a) : Closure stepB seedB (f a) := by
  induction h with
  | seed h => exact .seed (hs _ h)
  | step _ hab ih => exact .step ih (hst _ _ hab)

end Closure

/-- Q2 (*mā lā yatimm al-wājib illā bihi*) is S4: obligation closed under necessary means. -/
theorem wajib_is_closure {Act : Type} (needs : Act → Act → Prop) (base : Act → Prop) (a : Act) :
    Qawaid.Wajib needs base a ↔ Closure needs base a := by
  constructor
  · intro h
    induction h with
    | base hb => exact .seed hb
    | means _ hn ih => exact .step ih hn
  · intro h
    induction h with
    | seed hb => exact .base hb
    | step _ hn ih => exact .means ih hn

/-! ## S5 — inert events: what leaves a state as it was -/

/-- Event `e` leaves every state satisfying `P` unchanged. -/
def Inert {S E : Type} (step : S → E → S) (P : S → Prop) (e : E) : Prop :=
  ∀ s, P s → step s e = s

theorem inert_fold {S E : Type} (step : S → E → S) (P : S → Prop) (s : S) (hs : P s) :
    ∀ es : List E, (∀ e ∈ es, Inert step P e) → es.foldl step s = s
  | [], _ => rfl
  | e :: es, h => by
    simp only [List.foldl]
    rw [h e (by simp) s hs]
    exact inert_fold step P s hs es (fun e' he' => h e' (by simp [he']))

/-- Q11 is S5: on a certain judgement, doubts are inert, however many arrive. -/
theorem yaqin_doubts_inert {V : Type} (cur : Qawaid.Held V) (hy : cur.IsYaqin)
    (evs : List (Qawaid.Held V)) (hs : ∀ e ∈ evs, e.grade = .shakk) :
    evs.foldl Qawaid.update cur = cur := by
  refine inert_fold Qawaid.update (fun c => c.IsYaqin) cur hy evs ?_
  intro e he c hc
  exact Qawaid.yaqin_la_yazul_bish_shakk c e hc (hs e he)

/-! ## S6 — burden of proof follows the presumption -/

inductive Proof where
  | bayyina | yamin
  deriving DecidableEq, Repr

/-- A claim agreeing with the operative presumption is taken with an oath; one departing
from it needs evidence. -/
def burdenOf {V : Type} [DecidableEq V] (presumption claim : V) : Proof :=
  if claim = presumption then .yamin else .bayyina

section Burden

variable {V : Type} [DecidableEq V]

theorem burden_agrees (p : V) : burdenOf p p = .yamin := by simp [burdenOf]

theorem burden_departs {p c : V} (h : c ≠ p) : burdenOf p c = .bayyina := by simp [burdenOf, h]

/-- The burden depends only on whether the claim agrees with the presumption, not on who
makes it: roles (claimant, denier, trustee) are derived, not primitive. -/
theorem burden_factors :
    Factors (fun pc : V × V => burdenOf pc.1 pc.2) (fun pc => decide (pc.2 = pc.1)) :=
  Factors.of_eq (fun b => if b then .yamin else .bayyina) fun ⟨p, c⟩ => by
    by_cases h : c = p <;> simp [burdenOf, h]

/-- With Q52: an indication strong enough to displace the presumption moves the burden. -/
theorem burden_after_update (cur ev : Qawaid.Held V) (he : ev.Suspended = false)
    (h : cur.strength ≤ ev.strength) (c : V) :
    burdenOf (Qawaid.update cur ev).value c = burdenOf ev.value c := by
  rw [Sadi.q52_strong_qarina_prevails cur ev he h]

end Burden

/-! ## S7 — merging: one performance per class of a merge relation -/

/-- `done` discharges `owed`: every owed act is merged into some performed one. -/
def Covers {α : Type} (r : α → α → Prop) (done owed : List α) : Prop :=
  ∀ o ∈ owed, ∃ d ∈ done, r d o

/-- Representatives: keep an act only if no kept act already discharges it. -/
def reps {α : Type} (r : α → α → Prop) [DecidableRel r] : List α → List α
  | [] => []
  | x :: xs => if (reps r xs).any (fun y => decide (r y x)) then reps r xs else x :: reps r xs

section Merge

variable {α β : Type} {r : α → α → Prop} [DecidableRel r]

/-- For a reflexive merge relation, the representatives discharge everything owed. -/
theorem reps_covers (hr : ∀ a, r a a) : ∀ xs : List α, Covers r (reps r xs) xs
  | [] => by simp [Covers]
  | x :: xs => by
    intro o ho
    have ih := reps_covers hr xs
    simp only [reps]
    split
    · next h =>
      rcases List.mem_cons.1 ho with rfl | ho
      · simpa [List.any_eq_true] using h
      · exact ih o ho
    · rcases List.mem_cons.1 ho with rfl | ho
      · exact ⟨o, by simp, hr o⟩
      · obtain ⟨d, hd, hdo⟩ := ih o ho
        exact ⟨d, by simp [hd], hdo⟩

theorem reps_length_le : ∀ xs : List α, (reps r xs).length ≤ xs.length
  | [] => Nat.le_refl 0
  | x :: xs => by
    have := reps_length_le xs
    simp only [reps]; split <;> simp <;> omega

theorem reps_sub : ∀ (xs : List α), ∀ d ∈ reps r xs, d ∈ xs
  | [] => by simp [reps]
  | x :: xs => by
    intro d hd
    have ih := reps_sub xs
    simp only [reps] at hd; split at hd
    · exact List.mem_cons_of_mem _ (ih d hd)
    · rcases List.mem_cons.1 hd with rfl | hd
      · simp
      · exact List.mem_cons_of_mem _ (ih d hd)

omit [DecidableRel r] in
/-- Transport: a map preserving the merge relation preserves discharge. -/
theorem Covers.map {r' : β → β → Prop} (f : α → β) (hr : ∀ a b, r a b → r' (f a) (f b))
    {done owed : List α} (h : Covers r done owed) : Covers r' (done.map f) (owed.map f) := by
  intro o ho
  obtain ⟨o', ho', rfl⟩ := List.mem_map.1 ho
  obtain ⟨d, hd, hdo⟩ := h o' ho'
  exact ⟨f d, List.mem_map_of_mem hd, hr _ _ hdo⟩

end Merge

/-! ## S8 — optimisation: choose a best option on one scale -/

/-- `b` is an available option and no option scores higher. -/
def Optimal {α : Type} (key : α → Int) (xs : List α) (b : α) : Prop :=
  b ∈ xs ∧ ∀ y ∈ xs, key y ≤ key b

section Optimisation

variable {α β : Type} {key : α → Int} {xs : List α} {b b' : α}

/-- Q33's `best` always returns an optimal option. -/
theorem best_optimal (h : Sadi.best key xs = some b) : Optimal key xs b :=
  ⟨Sadi.best_mem key h, Sadi.best_max key h⟩

/-- A choice exists exactly when some option does. -/
theorem best_eq_none_iff : Sadi.best key xs = none ↔ xs = [] := by
  cases xs with
  | nil => simp [Sadi.best]
  | cons z zs => simp [Sadi.best_cons_ne_none key z zs]

/-- Optimal options are equally good: the scale, not the tie-break, carries the ruling. -/
theorem Optimal.key_unique (h : Optimal key xs b) (h' : Optimal key xs b') : key b = key b' :=
  Int.le_antisymm (h'.2 b h.1) (h.2 b' h'.1)

/-- Removing options other than the chosen one never unseats it. -/
theorem Optimal.restrict {ys : List α} (h : Optimal key xs b) (hs : ∀ y ∈ ys, y ∈ xs) (hb : b ∈ ys) :
    Optimal key ys b :=
  ⟨hb, fun y hy => h.2 y (hs y hy)⟩

/-- Transport along the scale: any monotone re-scaling keeps the optimum (lighter harm is
the antitone case, via negation). -/
theorem Optimal.mono (g : Int → Int) (hg : ∀ a c, a ≤ c → g a ≤ g c) (h : Optimal key xs b) :
    Optimal (g ∘ key) xs b :=
  ⟨h.1, fun y hy => hg _ _ (h.2 y hy)⟩

/-- Transport along the options: a renaming of options carries the optimum. -/
theorem Optimal.map (f : α → β) {k : β → Int} (h : Optimal (k ∘ f) xs b) : Optimal k (xs.map f) (f b) :=
  ⟨List.mem_map_of_mem h.1, fun y hy => by
    obtain ⟨x, hx, rfl⟩ := List.mem_map.1 hy
    exact h.2 x hx⟩

end Optimisation

/-! ## Kernel instances of S2, S3 and S8 -/

/-- Q4 is S3 twice: capability is a condition of obligation, necessity an impediment of
prohibition. -/
theorem operative_is_gate (c d : Bool) :
    (Sadi.operative c d .wajib = .wajib ↔ (Sadi.Gate.ofBools [Prod.fst] []).Holds (c, d)) ∧
    (Sadi.operative c d .haram = .haram ↔ (Sadi.Gate.ofBools [] [Prod.snd]).Holds (c, d)) := by
  simp only [Sadi.Gate.holds_ofBools]
  cases c <;> cases d <;> simp [Sadi.operative]

/-- Q28 is S2: the original when possible, the substitute otherwise. -/
theorem substitute_is_priority (p : Bool) :
    Sadi.useSubstitute p = resolveD [if p then some false else none] true := by
  cases p <;> rfl

/-- Q40 is S3 per part: capability is the condition, being a pure means (wasīla maḥḍa) the impediment. -/
theorem obligedParts_is_gate {P : Type} (parts : List P) (can pureMeans : P → Bool) (p : P) :
    p ∈ Sadi.obligedParts parts can pureMeans ↔ p ∈ parts ∧ (Sadi.Gate.ofBools [can] [pureMeans]).Holds p := by
  rw [Sadi.Gate.holds_ofBools]
  simp [Sadi.obligedParts, List.mem_filter]

/-- Q33 is S8, for benefits and (antitone) for harms. -/
theorem q33_is_optimal {α : Type} (benefit harm : α → Nat) {xs : List α} {b h : α}
    (hb : Sadi.best (fun x => (benefit x : Int)) xs = some b)
    (hh : Sadi.best (fun x => -(harm x : Int)) xs = some h) :
    Optimal (fun x => (benefit x : Int)) xs b ∧ Optimal (fun x => -(harm x : Int)) xs h :=
  ⟨best_optimal hb, best_optimal hh⟩

end Usul.Schema
