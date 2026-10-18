import Usul.Hukm
import Usul.Cat.Sheaf

/-!
# Interval-valued verdicts: what a position fixes, and no more

`Usul.Cat.Sheaf` glues point verdicts: a patch rules exactly one `Hukm` at each situation, and two
patches match only when their rulings are equal. Many positions fix less than a point. «يجوز» fixes
only that the act is not ḥarām; an amr whose strength is in dispute fixes only ṭalab al-fiʿl, mandūb
or wājib. Forcing either to a point adds precision the source does not have, and the point checker
then reports an ikhtilāf that is not there (*yajūz* beside *yustaḥabb*).
See `docs/architecture/hukm-interval-verdicts.md`.

* A **span** is a nonempty interval `[lo, hi]` of the valence chain Ḥ < K < M < N < W. A point
  verdict is a span with `lo = hi` (`point`). The khiṭāb's modes are spans (`talabFil`,
  `talabTark`, and `point mubah` for takhyīr), as are «يجوز» (`permitted`) and the
  uninformative `any`.
* Two spans **meet** when they share a status (`meets_iff_exists`). On points, meeting is
  equality (`meets_point`), so nothing the point checker accepts is lost.
* **Helly in one dimension** (`helly`): spans that pairwise meet share a status, namely the
  greatest lower end (`maxLo`). Obstruction therefore stays pairwise, as in `Sheaf`.
* **Finite gluing** (`iglues_iff`): interval patches admit one point verdict consistent with all
  of them iff `iobstructions` is empty. On point patches `iobstructions` is exactly
  `Sheaf.obstructions` (`iobstructions_ofPatch`).
* **Suspension** (tawaqquf) is not a verdict. A position that suspends speaks to no situation, so
  it is a hole in the cover, never `mubah` (`stances`).
* `Span.σ` carries a span to the span of the omission. It reverses the interval because σ
  reverses the order (`mem_σ`).

The chain order is used only through comparisons; nothing here adds or averages valences.
-/

namespace Usul.Cat.Interval

open Usul Usul.Cat.Sheaf

/-- A nonempty interval of the valence chain. -/
structure Span where
  lo : Hukm
  hi : Hukm
  le : lo.valence ≤ hi.valence

namespace Span

/-- `h` lies in the span. -/
def Mem (h : Hukm) (s : Span) : Prop := s.lo.valence ≤ h.valence ∧ h.valence ≤ s.hi.valence

instance (h : Hukm) (s : Span) : Decidable (Mem h s) := inferInstanceAs (Decidable (_ ∧ _))

/-- The span of exactly one status. -/
def point (h : Hukm) : Span := ⟨h, h, Nat.le_refl _⟩

/-- Every status: the position fixes nothing. -/
def any : Span := ⟨.haram, .wajib, by decide⟩

/-- «يجوز»: not ḥarām. -/
def permitted : Span := ⟨.makruh, .wajib, by decide⟩

/-- Not wājib. -/
def notObligatory : Span := ⟨.haram, .mandub, by decide⟩

/-- Ṭalab al-fiʿl of unknown strength: mandūb or wājib. -/
def talabFil : Span := ⟨.mandub, .wajib, by decide⟩

/-- Ṭalab al-tark of unknown strength: makrūh or ḥarām. -/
def talabTark : Span := ⟨.haram, .makruh, by decide⟩

theorem mem_point {a h : Hukm} : Mem a (point h) ↔ a = h :=
  ⟨fun ⟨l, r⟩ => Hukm.valence_injective (Nat.le_antisymm r l), fun e => e ▸ ⟨Nat.le_refl _, Nat.le_refl _⟩⟩

theorem mem_any (h : Hukm) : Mem h any := by cases h <;> decide

theorem mem_permitted (h : Hukm) : Mem h permitted ↔ h ≠ .haram := by cases h <;> decide

theorem mem_notObligatory (h : Hukm) : Mem h notObligatory ↔ h ≠ .wajib := by cases h <;> decide

theorem mem_talabFil (h : Hukm) : Mem h talabFil ↔ h.mode = .talabFil := by cases h <;> decide

theorem mem_talabTark (h : Hukm) : Mem h talabTark ↔ h.mode = .talabTark := by cases h <;> decide

/-- Takhyīr is the one mode that fixes a point. -/
theorem mem_takhyir (h : Hukm) : Mem h (point .mubah) ↔ h.mode = .takhyir := by cases h <;> decide

/-- The span of the omission: σ reverses the order, so the ends swap. -/
def σ (s : Span) : Span :=
  ⟨Hukm.σ s.hi, Hukm.σ s.lo, by
    rw [Hukm.σ_valence, Hukm.σ_valence]; have := s.le; have := Hukm.valence_le_four s.hi; omega⟩

theorem mem_σ {h : Hukm} {s : Span} : Mem (Hukm.σ h) (σ s) ↔ Mem h s := by
  simp only [Mem, σ, Hukm.σ_valence]
  have := Hukm.valence_le_four h; have := Hukm.valence_le_four s.lo
  have := Hukm.valence_le_four s.hi; omega

/-- The two spans share a status. -/
def Meets (s t : Span) : Prop := s.lo.valence ≤ t.hi.valence ∧ t.lo.valence ≤ s.hi.valence

instance (s t : Span) : Decidable (Meets s t) := inferInstanceAs (Decidable (_ ∧ _))

theorem meets_iff_exists {s t : Span} : Meets s t ↔ ∃ h, Mem h s ∧ Mem h t := by
  refine ⟨fun ⟨l, r⟩ => ?_, fun ⟨_, ⟨a, b⟩, c, d⟩ => ⟨by omega, by omega⟩⟩
  have := s.le; have := t.le
  by_cases hst : s.lo.valence ≤ t.lo.valence
  · exact ⟨t.lo, ⟨hst, r⟩, Nat.le_refl _, t.le⟩
  · exact ⟨s.lo, ⟨Nat.le_refl _, s.le⟩, by omega, l⟩

theorem meets_comm {s t : Span} : Meets s t ↔ Meets t s := ⟨fun ⟨a, b⟩ => ⟨b, a⟩, fun ⟨a, b⟩ => ⟨b, a⟩⟩

/-- On points, meeting is equality: the point checker's verdicts are kept. -/
theorem meets_point {a b : Hukm} : Meets (point a) (point b) ↔ a = b := by
  rw [meets_iff_exists]
  exact ⟨fun ⟨_, ha, hb⟩ => (mem_point.1 ha).symm.trans (mem_point.1 hb),
    fun e => ⟨a, mem_point.2 rfl, mem_point.2 e⟩⟩

/-- σ preserves meeting: a disagreement over an act is one over its omission. -/
theorem meets_σ {s t : Span} : Meets (σ s) (σ t) ↔ Meets s t := by
  simp only [Meets, σ, Hukm.σ_valence]
  have := Hukm.valence_le_four s.lo; have := Hukm.valence_le_four s.hi
  have := Hukm.valence_le_four t.lo; have := Hukm.valence_le_four t.hi; omega

end Span

open Span

/-! ## Helly in one dimension -/

/-- The greatest lower end of a list of spans (`haram` for none). -/
def maxLo : List Span → Hukm
  | [] => .haram
  | s :: l => if s.lo.valence ≤ (maxLo l).valence then maxLo l else s.lo

theorem le_maxLo : ∀ {l : List Span}, ∀ s ∈ l, s.lo.valence ≤ (maxLo l).valence
  | t :: l, s, hs => by
    have ih := @le_maxLo l
    unfold maxLo
    split
    · rcases List.mem_cons.1 hs with rfl | hs
      · assumption
      · exact ih s hs
    · rcases List.mem_cons.1 hs with rfl | hs
      · exact Nat.le_refl _
      · have := ih s hs; omega

theorem maxLo_cases : ∀ l : List Span, maxLo l = .haram ∨ ∃ t ∈ l, maxLo l = t.lo
  | [] => .inl rfl
  | t :: l => by
    unfold maxLo
    split
    · rcases maxLo_cases l with h | ⟨u, hu, h⟩
      · exact .inl h
      · exact .inr ⟨u, List.mem_cons_of_mem _ hu, h⟩
    · exact .inr ⟨t, List.mem_cons_self .., rfl⟩

/-- Spans that pairwise meet share a status: the greatest lower end. -/
theorem helly {l : List Span} (h : ∀ s ∈ l, ∀ t ∈ l, Meets s t) : ∀ s ∈ l, Mem (maxLo l) s := by
  intro s hs
  refine ⟨le_maxLo s hs, ?_⟩
  rcases maxLo_cases l with e | ⟨t, ht, e⟩
  · rw [e]; exact Nat.zero_le _
  · rw [e]; exact (h s hs t ht).2

/-! ## Finite sites with interval patches -/

/-- A named patch whose ruling at each situation it speaks to is a span. -/
structure IPatch (X : Type) where
  name : String
  mem : X → Bool
  span : X → Span

variable {X : Type}

/-- Every pair of patches whose spans fail to meet at a shared situation. -/
def iobstructions (xs : List X) (ps : List (IPatch X)) : List (String × String × X) :=
  ps.flatMap fun p => ps.flatMap fun q =>
    (xs.filter fun x => p.mem x && q.mem x && !decide (Meets (p.span x) (q.span x))).map
      fun x => (p.name, q.name, x)

theorem iobstructions_nil_iff {xs : List X} {ps : List (IPatch X)} :
    iobstructions xs ps = [] ↔
      ∀ p ∈ ps, ∀ q ∈ ps, ∀ x ∈ xs, p.mem x = true → q.mem x = true → Meets (p.span x) (q.span x) := by
  simp only [iobstructions, List.flatMap_eq_nil_iff, List.map_eq_nil_iff, List.filter_eq_nil_iff]
  exact forall₂_congr fun p _ => forall₂_congr fun q _ => forall₂_congr fun x _ => by
    by_cases hp : p.mem x = true <;> by_cases hq : q.mem x = true <;> simp [hp, hq]

/-- `g` refines every patch: at each situation a patch speaks to, `g` lies in its span. -/
def IGlues (xs : List X) (ps : List (IPatch X)) (g : X → Hukm) : Prop :=
  ∀ p ∈ ps, ∀ x ∈ xs, p.mem x = true → Span.Mem (g x) (p.span x)

/-- The finite sheaf condition for spans: one point verdict refines every patch iff no pair fails
to meet. Helly makes the pairwise check enough. -/
theorem iglues_iff {xs : List X} {ps : List (IPatch X)} :
    (∃ g, IGlues xs ps g) ↔ iobstructions xs ps = [] := by
  rw [iobstructions_nil_iff]
  constructor
  · rintro ⟨g, hg⟩ p hp q hq x hx hpx hqx
    exact meets_iff_exists.2 ⟨g x, hg p hp x hx hpx, hg q hq x hx hqx⟩
  · intro h
    refine ⟨fun x => maxLo ((ps.filter fun p => p.mem x).map fun p => p.span x), ?_⟩
    intro p hp x hx hpx
    refine helly ?_ _ (List.mem_map.2 ⟨p, List.mem_filter.2 ⟨hp, hpx⟩, rfl⟩)
    intro s hs t ht
    obtain ⟨p', hp', rfl⟩ := List.mem_map.1 hs
    obtain ⟨q', hq', rfl⟩ := List.mem_map.1 ht
    obtain ⟨hp', hpx'⟩ := List.mem_filter.1 hp'
    obtain ⟨hq', hqx'⟩ := List.mem_filter.1 hq'
    exact h p' hp' q' hq' x hx hpx' hqx'

/-- A point patch, read as an interval patch. -/
def IPatch.ofPatch (p : Patch X Hukm) : IPatch X := ⟨p.name, p.mem, fun x => point (p.verdict x)⟩

/-- Conservativity: on point verdicts the interval checker finds exactly what `Sheaf` finds. -/
theorem iobstructions_ofPatch {xs : List X} {ps : List (Patch X Hukm)} :
    iobstructions xs (ps.map IPatch.ofPatch) = obstructions xs ps := by
  simp only [iobstructions, obstructions, List.flatMap_map, IPatch.ofPatch, meets_point]
  rfl

/-! ## A takhrīj case: spans and suspensions

As in `Sheaf.positions`, each reported position is a patch over the one-point site. A position
that suspends (tawaqquf) contributes no patch: it is not a ruling of ibāḥa. -/

/-- A span's name: its two ends. -/
def Span.name (s : Span) : String := s!"{reprStr s.lo}..{reprStr s.hi}"

/-- The positions of one case; `none` is a suspension. -/
def stances (rs : List (Option Span)) : List (IPatch Unit) :=
  rs.filterMap fun r => r.map fun s => ⟨s.name, fun _ => true, fun _ => s⟩

/-- A case's positions glue iff every two rulings meet; suspensions never obstruct. -/
theorem stances_glue_iff {rs : List (Option Span)} :
    iobstructions [()] (stances rs) = [] ↔ ∀ a ∈ rs.filterMap id, ∀ b ∈ rs.filterMap id, Meets a b := by
  rw [iobstructions_nil_iff]
  simp only [stances, List.mem_filterMap, Option.map_eq_some_iff, id, List.mem_singleton,
    forall_exists_index, and_imp]
  constructor
  · intro h a o ho hoa b o' ho' hob
    exact h _ o ho a hoa rfl _ o' ho' b hob rfl () trivial rfl rfl
  · intro h p o ho a hoa hp q o' ho' b hob hq _ _ _ _
    subst hp hq
    exact h a o ho hoa b o' ho' hob

end Usul.Cat.Interval
