/-!
# Maḥall: the label graph from canonical texts to furūʿ and qawāʿid (PR-51)

A farʿ rules on a **maḥall**: an item (ʿayn), an act (fiʿl) or an issue (ḥāl). Maḥalls are
labels under broader labels, up to the bābs. Each label is defined by the canonical texts that
name it: āyāt, aḥādīth, or a reported ijmāʿ.

None of these links is one-to-one in the bank, so each edge is a relation:

* `under f q`: the farʿ `f` is tied to the qāʿida `q`. The tie may come from the author's placement, from the qawāʿid its encoder reads, from the qawāʿid cited by the types that encoder reads, or from a co-annotation. A farʿ may turn on several qawāʿid, a type may cite several, and several types may cite one qāʿida.
* `mahall f m`: `m` is a maḥall of `f`. A farʿ may rule on more than one.
* `up l m`: `m` is a broader label of `l`. A label may sit under several labels; debt, for instance, sits under both sale and loan.
* `defines n l`: the naṣṣ `n` defines the label `l`. A label may be defined by several nuṣūṣ, and one naṣṣ may define several labels.

`Below l m` is the reflexive–transitive closure of `up`. A qāʿida's **footprint** is the set of
labels that the furūʿ tied to it fall under, closed upwards. Its **grounds** are the nuṣūṣ that
define some label in the footprint. This module proves:

* **Characterisation** (`footprint_iff`): the footprint is the least up-closed set of labels
  containing the maḥall of every farʿ tied to the qāʿida. The qāʿida reaches the labels and
  the texts only through its furūʿ.
* **Grounding** (`grounded`): a naṣṣ that defines any ancestor of a farʿ's maḥall grounds
  every qāʿida the farʿ is tied to.
* **Shared farʿ** (`shared_far`): a farʿ tied to two qawāʿid puts each maḥall and everything
  above it into both footprints.
* **Bridge** (`bridge`): two furūʿ with a common maḥall put that label into the footprints of
  all their qawāʿid.

`Data` is the finite form the pipeline exports. `belowB`, `footprintB` and `groundsB` decide the
relations with fuel. They are proved sound (`belowB_sound`, `footprintB_sound`, `groundsB_sound`),
and `belowB` is also proved complete (`belowB_complete`). `exactB_sound` shows a list to be
exactly a footprint. The `#guard`s in `UsulTest.MahallGraph` evaluate these procedures, and the
soundness theorems carry each guard over to the relations above.
-/

namespace Usul.Mahall

/-- A label graph over furūʿ `F`, qawāʿid `Q`, labels `L` and nuṣūṣ `N`. -/
structure Graph (F Q L N : Type) where
  isFar : F → Prop
  under : F → Q → Prop
  mahall : F → L → Prop
  up : L → L → Prop
  defines : N → L → Prop

variable {F Q L N : Type}

/-- `Below g l m`: `m` is `l` or a label above it. -/
inductive Below (g : Graph F Q L N) : L → L → Prop
  | refl (l : L) : Below g l l
  | step {l m n : L} : g.up l m → Below g m n → Below g l n

/-- The labels the furūʿ tied to a qāʿida fall under, closed upwards. -/
def footprint (g : Graph F Q L N) (q : Q) (l : L) : Prop :=
  ∃ f m, g.isFar f ∧ g.under f q ∧ g.mahall f m ∧ Below g m l

/-- The nuṣūṣ that define some label of a qāʿida's footprint. -/
def grounds (g : Graph F Q L N) (q : Q) (n : N) : Prop :=
  ∃ l, footprint g q l ∧ g.defines n l

/-- A set of labels closed under `up`. -/
def UpClosed (g : Graph F Q L N) (S : L → Prop) : Prop :=
  ∀ l m, S l → g.up l m → S m

variable (g : Graph F Q L N)

theorem Below.trans {a b c : L} (h₁ : Below g a b) (h₂ : Below g b c) : Below g a c := by
  induction h₁ with
  | refl => exact h₂
  | step h _ ih => exact .step h (ih h₂)

theorem Below.snoc {a l m : L} (h : Below g a l) (hu : g.up l m) : Below g a m :=
  h.trans g (.step hu (.refl m))

/-- An up-closed set holding `a` holds everything above `a`. -/
theorem UpClosed.below {S : L → Prop} (hS : UpClosed g S) {a b : L} (h : Below g a b) (ha : S a) : S b := by
  induction h with
  | refl => exact ha
  | step hu _ ih => exact ih (hS _ _ ha hu)

theorem footprint_upClosed (q : Q) : UpClosed g (footprint g q) := by
  intro l m ⟨f, a, hf, hq, hm, hb⟩ hu
  exact ⟨f, a, hf, hq, hm, hb.snoc g hu⟩

theorem mahall_in_footprint {f : F} {q : Q} {m : L} (hf : g.isFar f) (hq : g.under f q) (hm : g.mahall f m) :
    footprint g q m :=
  ⟨f, m, hf, hq, hm, .refl m⟩

theorem footprint_least {q : Q} {S : L → Prop} (hS : UpClosed g S)
    (h : ∀ f m, g.isFar f → g.under f q → g.mahall f m → S m) {l : L} (hl : footprint g q l) : S l := by
  obtain ⟨f, m, hf, hq, hm, hb⟩ := hl
  exact hS.below g hb (h f m hf hq hm)

/-- **Characterisation.** A label is in a qāʿida's footprint iff every up-closed set containing
the maḥalls of the furūʿ tied to the qāʿida contains it. -/
theorem footprint_iff (q : Q) (l : L) :
    footprint g q l ↔ ∀ S : L → Prop, UpClosed g S →
      (∀ f m, g.isFar f → g.under f q → g.mahall f m → S m) → S l := by
  constructor
  · intro hl S hS h
    exact footprint_least g hS h hl
  · intro h
    exact h (footprint g q) (footprint_upClosed g q) fun f m hf hq hm => mahall_in_footprint g hf hq hm

/-- **Grounding.** A naṣṣ that defines an ancestor of a farʿ's maḥall grounds each qāʿida the
farʿ is tied to. -/
theorem grounded {f : F} {q : Q} {m l : L} {n : N} (hf : g.isFar f) (hq : g.under f q) (hm : g.mahall f m)
    (hb : Below g m l) (hn : g.defines n l) : grounds g q n :=
  ⟨l, ⟨f, m, hf, hq, hm, hb⟩, hn⟩

/-- **Shared farʿ.** A farʿ tied to two qawāʿid puts its maḥall, and all above it, into both. -/
theorem shared_far {f : F} {q q' : Q} {m l : L} (hf : g.isFar f) (hq : g.under f q) (hq' : g.under f q')
    (hm : g.mahall f m) (hb : Below g m l) : footprint g q l ∧ footprint g q' l :=
  ⟨⟨f, m, hf, hq, hm, hb⟩, ⟨f, m, hf, hq', hm, hb⟩⟩

/-- **Bridge.** A maḥall shared by two furūʿ is common to the footprints of their qawāʿid. -/
theorem bridge {f f' : F} {q q' : Q} {m : L} (hf : g.isFar f) (hf' : g.isFar f') (hq : g.under f q)
    (hq' : g.under f' q') (hm : g.mahall f m) (hm' : g.mahall f' m) : footprint g q m ∧ footprint g q' m :=
  ⟨mahall_in_footprint g hf hq hm, mahall_in_footprint g hf' hq' hm'⟩

/-! ## The finite graph the pipeline exports -/

/-- A farʿ: its id, the qawāʿid it is tied to, and its maḥall labels. -/
structure Far where
  id : String
  qawaid : List String
  labels : List String
deriving Repr

/-- The exported graph: furūʿ, `(label, broader)` pairs, and `(naṣṣ, label)` definitions. -/
structure Data where
  furu : List Far
  up : List (String × String)
  defines : List (String × String)

/-- The broader labels of `l` in a list of `(label, broader)` pairs. -/
def ups (up : List (String × String)) (l : String) : List String :=
  up.filterMap fun p => if p.1 == l then some p.2 else none

theorem mem_ups {up : List (String × String)} {l m : String} : m ∈ ups up l ↔ (l, m) ∈ up := by
  simp only [ups, List.mem_filterMap]
  constructor
  · rintro ⟨⟨a, b⟩, h, he⟩
    by_cases hal : a = l
    · simp [hal] at he; exact he ▸ hal ▸ h
    · simp [beq_iff_eq, hal] at he
  · intro h
    exact ⟨(l, m), h, by simp⟩

/-- `belowL up n l t`: `t` is reached from `l` by at most `n` steps up. It reads only `up`. -/
def belowL (up : List (String × String)) : Nat → String → String → Bool
  | 0, l, t => l == t
  | n + 1, l, t => l == t || (ups up l).any fun m => belowL up n m t

/-- Every upward path from `l` ends within `n` steps. -/
def heightL (up : List (String × String)) : Nat → String → Bool
  | 0, l => (ups up l).isEmpty
  | n + 1, l => (ups up l).all (heightL up n)

namespace Data

variable (d : Data)

def graph : Graph Far String String String where
  isFar f := f ∈ d.furu
  under f q := q ∈ f.qawaid
  mahall f m := m ∈ f.labels
  up l m := (l, m) ∈ d.up
  defines n l := (n, l) ∈ d.defines

def belowB : Nat → String → String → Bool := belowL d.up

def footprintB (n : Nat) (q l : String) : Bool :=
  d.furu.any fun f => f.qawaid.contains q && f.labels.any fun m => d.belowB n m l

def groundsB (n : Nat) (q nass : String) : Bool :=
  d.defines.any fun p => p.1 == nass && d.footprintB n q p.2

theorem belowB_sound : ∀ (n : Nat) (l t : String), d.belowB n l t = true → Below d.graph l t
  | 0, l, t, h => by
    simp only [belowB, belowL, beq_iff_eq] at h
    exact h ▸ .refl l
  | n + 1, l, t, h => by
    simp only [belowB, belowL, Bool.or_eq_true, beq_iff_eq, List.any_eq_true] at h
    rcases h with h | ⟨m, hm, hb⟩
    · exact h ▸ .refl l
    · exact .step (mem_ups.mp hm) (belowB_sound n m t hb)

theorem belowB_complete {l t : String} (h : Below d.graph l t) : ∃ n, d.belowB n l t = true := by
  induction h with
  | refl l => exact ⟨0, by simp [belowB, belowL]⟩
  | @step l m _ hu _ ih =>
    obtain ⟨n, hn⟩ := ih
    refine ⟨n + 1, ?_⟩
    simp only [belowB, belowL, Bool.or_eq_true, List.any_eq_true]
    exact .inr ⟨m, mem_ups.mpr hu, hn⟩

theorem footprintB_sound {n : Nat} {q l : String} (h : d.footprintB n q l = true) :
    footprint d.graph q l := by
  simp only [footprintB, List.any_eq_true, Bool.and_eq_true, List.contains_iff_mem] at h
  obtain ⟨f, hf, hq, m, hm, hb⟩ := h
  exact ⟨f, m, hf, hq, hm, d.belowB_sound n m l hb⟩

theorem groundsB_sound {n : Nat} {q nass : String} (h : d.groundsB n q nass = true) :
    grounds d.graph q nass := by
  simp only [groundsB, List.any_eq_true, Bool.and_eq_true, beq_iff_eq] at h
  obtain ⟨⟨a, l⟩, hp, ha, hf⟩ := h
  exact ⟨l, d.footprintB_sound hf, by simp only at ha; exact ha ▸ hp⟩

/-- The furūʿ tied to one qāʿida only: a cheaper graph to decide that qāʿida's footprint on. -/
def restrict (q : String) : Data := { d with furu := d.furu.filter (·.qawaid.contains q) }

theorem footprintB_restrict (n : Nat) (q l : String) : (d.restrict q).footprintB n q l = d.footprintB n q l := by
  simp only [footprintB, belowB, restrict]
  induction d.furu with
  | nil => rfl
  | cons f fs ih => by_cases h : f.qawaid.contains q = true <;> simp_all

theorem groundsB_restrict (n : Nat) (q nass : String) :
    (d.restrict q).groundsB n q nass = d.groundsB n q nass := by
  simp only [groundsB, footprintB_restrict]
  rfl

/-! ### Exactness by the characterisation

To show that a list `S` is exactly a qāʿida's footprint, it is enough to show three things:

* every label in `S` is in the footprint;
* `S` is up-closed;
* `S` holds the maḥalls of the furūʿ tied to the qāʿida.

The last two give the converse by `footprint_least`. This is linear in `S`, where deciding every
label is not. The grounds follow the same way. -/

def upClosedB (S : List String) : Bool :=
  S.all fun l => (ups d.up l).all S.contains

def holdsB (q : String) (S : List String) : Bool :=
  d.furu.all fun f => !f.qawaid.contains q || f.labels.all S.contains

def groundsClosedB (S G : List String) : Bool :=
  d.defines.all fun p => !S.contains p.2 || G.contains p.1

/-- `S` is the footprint of `q` and `G` its grounds, decided on `q`'s furūʿ alone. -/
def exactB (n : Nat) (q : String) (S G : List String) : Bool :=
  S.all ((d.restrict q).footprintB n q) && G.all ((d.restrict q).groundsB n q) &&
    d.upClosedB S && d.holdsB q S && d.groundsClosedB S G

theorem footprint_sub {q : String} {S : List String} (hu : d.upClosedB S = true) (hh : d.holdsB q S = true)
    {l : String} (hl : footprint d.graph q l) : l ∈ S := by
  refine footprint_least d.graph (S := (· ∈ S)) ?_ ?_ hl
  · intro a b ha hab
    simp only [upClosedB, List.all_eq_true, List.contains_iff_mem] at hu
    exact hu a ha b (mem_ups.mpr hab)
  · intro f m hf hq hm
    simp only [holdsB, List.all_eq_true, Bool.or_eq_true, Bool.not_eq_true', List.contains_iff_mem] at hh
    rcases hh f hf with h | h
    · simp only [graph] at hq
      simp [hq] at h
    · exact h m hm

theorem exactB_sound {n : Nat} {q : String} {S G : List String} (h : d.exactB n q S G = true) :
    (∀ l, footprint d.graph q l ↔ l ∈ S) ∧ (∀ x, grounds d.graph q x ↔ x ∈ G) := by
  simp only [exactB, Bool.and_eq_true, List.all_eq_true] at h
  obtain ⟨⟨⟨⟨hS, hG⟩, hu⟩, hh⟩, hc⟩ := h
  have fp : ∀ l, footprint d.graph q l ↔ l ∈ S := fun l =>
    ⟨d.footprint_sub hu hh, fun hl => d.footprintB_sound (by rw [← d.footprintB_restrict]; exact hS l hl)⟩
  refine ⟨fp, fun x => ⟨?_, fun hx => d.groundsB_sound (by rw [← d.groundsB_restrict]; exact hG x hx)⟩⟩
  rintro ⟨l, hl, hd⟩
  simp only [groundsClosedB, List.all_eq_true, Bool.or_eq_true, Bool.not_eq_true'] at hc
  rcases hc (x, l) hd with h | h
  · have : l ∈ S := (fp l).mp hl
    simp [this] at h
  · simpa using h

/-- Every upward path from every label ends within `n` steps: no label is its own ancestor. -/
def rootedB (n : Nat) : Bool :=
  d.up.all fun p => heightL d.up n p.1

end Data

end Usul.Mahall
