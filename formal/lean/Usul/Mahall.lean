/-!
# Maḥall: the label graph from canonical texts to furūʿ and qawāʿid (PR-51)

A farʿ rules on a **maḥall**: an item (ʿayn), an act (fiʿl) or an issue (ḥāl). Maḥalls are
labels in a tree whose roots are the bābs. Each label is defined by the canonical text that names
it: an āya, a ḥadīth, or a reported ijmāʿ. A farʿ is also placed by its author under a qāʿida.
The **label graph** has four kinds of edge:

* `under f`: the qāʿida the text places the farʿ `f` under;
* `mahall f m`: `m` is a maḥall of `f`;
* `up l = some m`: `m` is the broader label of `l`;
* `defines n l`: the naṣṣ `n` defines the label `l`.

`Below l m` is the reflexive–transitive closure of `up`. A qāʿida's **footprint** is the set of
labels its furūʿ fall under, closed upwards. Its **grounds** are the nuṣūṣ that define some label
in the footprint. This module proves:

* **Characterisation** (`footprint_iff`): the footprint is the least up-closed set of labels
  containing the maḥall of every farʿ the qāʿida holds. The qāʿida is related to the labels
  exactly through its furūʿ.
* **Grounding** (`grounded`): a naṣṣ that defines any ancestor of a farʿ's maḥall grounds that
  farʿ's qāʿida. Every naṣṣ on the path from a farʿ up to its bāb leads back to its qāʿida.
* **Bāb** (`bab_in_footprint`): each qāʿida's footprint contains the bāb of each of its furūʿ.
* **Bridge** (`bridge`): two furūʿ with a common maḥall put a common label into the footprints of
  their two qawāʿid. A maḥall shared across qawāʿid connects them in the graph.

`Data` is the finite form the pipeline exports. `belowB`, `footprintB` and `groundsB` decide the
relations with fuel, and are proved sound (`belowB_sound`, `footprintB_sound`, `groundsB_sound`)
and complete (`belowB_complete`) for that graph. Each `#guard` in `UsulTest.MahallGraph`
evaluates one of them, so the soundness theorems carry the guards over to the relations above.
-/

namespace Usul.Mahall

/-- A label graph over furūʿ `F`, qawāʿid `Q`, labels `L` and nuṣūṣ `N`. -/
structure Graph (F Q L N : Type) where
  isFar : F → Prop
  under : F → Q
  mahall : F → L → Prop
  up : L → Option L
  defines : N → L → Prop

variable {F Q L N : Type}

/-- `Below g l m`: `m` is `l` or a broader label of it. -/
inductive Below (g : Graph F Q L N) : L → L → Prop
  | refl (l : L) : Below g l l
  | step {l m n : L} : g.up l = some m → Below g m n → Below g l n

/-- The labels a qāʿida's furūʿ fall under, closed upwards. -/
def footprint (g : Graph F Q L N) (q : Q) (l : L) : Prop :=
  ∃ f m, g.isFar f ∧ g.under f = q ∧ g.mahall f m ∧ Below g m l

/-- The nuṣūṣ that define some label of a qāʿida's footprint. -/
def grounds (g : Graph F Q L N) (q : Q) (n : N) : Prop :=
  ∃ l, footprint g q l ∧ g.defines n l

/-- A set of labels closed under `up`. -/
def UpClosed (g : Graph F Q L N) (S : L → Prop) : Prop :=
  ∀ l m, S l → g.up l = some m → S m

variable (g : Graph F Q L N)

theorem Below.trans {a b c : L} (h₁ : Below g a b) (h₂ : Below g b c) : Below g a c := by
  induction h₁ with
  | refl => exact h₂
  | step h _ ih => exact .step h (ih h₂)

theorem Below.snoc {a l m : L} (h : Below g a l) (hu : g.up l = some m) : Below g a m :=
  h.trans g (.step hu (.refl m))

/-- An up-closed set holding `a` holds everything above `a`. -/
theorem UpClosed.below {S : L → Prop} (hS : UpClosed g S) {a b : L} (h : Below g a b) (ha : S a) : S b := by
  induction h with
  | refl => exact ha
  | step hu _ ih => exact ih (hS _ _ ha hu)

theorem footprint_upClosed (q : Q) : UpClosed g (footprint g q) := by
  intro l m ⟨f, a, hf, hq, hm, hb⟩ hu
  exact ⟨f, a, hf, hq, hm, hb.snoc g hu⟩

theorem mahall_in_footprint {f : F} {m : L} (hf : g.isFar f) (hm : g.mahall f m) :
    footprint g (g.under f) m :=
  ⟨f, m, hf, rfl, hm, .refl m⟩

theorem footprint_least {q : Q} {S : L → Prop} (hS : UpClosed g S)
    (h : ∀ f m, g.isFar f → g.under f = q → g.mahall f m → S m) {l : L} (hl : footprint g q l) : S l := by
  obtain ⟨f, m, hf, hq, hm, hb⟩ := hl
  exact hS.below g hb (h f m hf hq hm)

/-- **Characterisation.** A label is in a qāʿida's footprint iff every up-closed set containing
the maḥalls of the qāʿida's furūʿ contains it. -/
theorem footprint_iff (q : Q) (l : L) :
    footprint g q l ↔ ∀ S : L → Prop, UpClosed g S →
      (∀ f m, g.isFar f → g.under f = q → g.mahall f m → S m) → S l := by
  constructor
  · intro hl S hS h
    exact footprint_least g hS h hl
  · intro h
    exact h (footprint g q) (footprint_upClosed g q) fun f m hf hq hm => hq ▸ mahall_in_footprint g hf hm

/-- **Grounding.** A naṣṣ that defines an ancestor of a farʿ's maḥall grounds the farʿ's qāʿida. -/
theorem grounded {f : F} {m l : L} {n : N} (hf : g.isFar f) (hm : g.mahall f m) (hb : Below g m l)
    (hn : g.defines n l) : grounds g (g.under f) n :=
  ⟨l, ⟨f, m, hf, rfl, hm, hb⟩, hn⟩

/-- **Bridge.** A maḥall shared by two furūʿ is common to the footprints of their qawāʿid. -/
theorem bridge {f f' : F} {m : L} (hf : g.isFar f) (hf' : g.isFar f') (hm : g.mahall f m)
    (hm' : g.mahall f' m) : ∃ l, footprint g (g.under f) l ∧ footprint g (g.under f') l :=
  ⟨m, mahall_in_footprint g hf hm, mahall_in_footprint g hf' hm'⟩

/-- The label reached by climbing `up` at most `n` times: the bāb, once `n` exceeds the depth. -/
def rootN : Nat → L → L
  | 0, l => l
  | n + 1, l => match g.up l with
    | none => l
    | some m => rootN n m

theorem below_rootN : ∀ (n : Nat) (l : L), Below g l (rootN g n l)
  | 0, l => .refl l
  | n + 1, l => by
    unfold rootN
    split
    · exact .refl l
    · next m h => exact .step h (below_rootN n m)

/-- **Bāb.** Each qāʿida's footprint holds the bāb of each of its furūʿ. -/
theorem bab_in_footprint {f : F} {m : L} (n : Nat) (hf : g.isFar f) (hm : g.mahall f m) :
    footprint g (g.under f) (rootN g n m) :=
  ⟨f, m, hf, rfl, hm, below_rootN g n m⟩

/-! ## The finite graph the pipeline exports -/

/-- A farʿ: its id, its qāʿida and its maḥall labels. -/
structure Far where
  id : String
  qaida : String
  labels : List String
deriving Repr

/-- The exported graph: furūʿ, `(label, broader)` pairs, and `(naṣṣ, label)` definitions. -/
structure Data where
  furu : List Far
  up : List (String × String)
  defines : List (String × String)

namespace Data

variable (d : Data)

def upB (l : String) : Option String := (d.up.find? (·.1 == l)).map (·.2)

def graph : Graph Far String String String where
  isFar f := f ∈ d.furu
  under f := f.qaida
  mahall f m := m ∈ f.labels
  up := d.upB
  defines n l := (n, l) ∈ d.defines

def belowB : Nat → String → String → Bool
  | 0, l, t => l == t
  | n + 1, l, t => l == t || match d.upB l with
    | some m => belowB n m t
    | none => false

def footprintB (n : Nat) (q l : String) : Bool :=
  d.furu.any fun f => f.qaida == q && f.labels.any fun m => d.belowB n m l

def groundsB (n : Nat) (q nass : String) : Bool :=
  d.defines.any fun p => p.1 == nass && d.footprintB n q p.2

theorem belowB_sound : ∀ (n : Nat) (l t : String), d.belowB n l t = true → Below d.graph l t
  | 0, l, t, h => by
    simp only [belowB, beq_iff_eq] at h
    exact h ▸ .refl l
  | n + 1, l, t, h => by
    simp only [belowB, Bool.or_eq_true, beq_iff_eq] at h
    rcases h with h | h
    · exact h ▸ .refl l
    · revert h
      cases hu : d.upB l with
      | none => simp
      | some m => exact fun h => .step hu (belowB_sound n m t h)

theorem belowB_succ : ∀ (n : Nat) (l t : String), d.belowB n l t = true → d.belowB (n + 1) l t = true
  | 0, l, t, h => by simp_all [belowB]
  | n + 1, l, t, h => by
    simp only [belowB, Bool.or_eq_true] at h ⊢
    rcases h with h | h
    · exact .inl h
    · refine .inr ?_
      revert h
      cases d.upB l with
      | none => simp
      | some m => exact belowB_succ n m t

theorem belowB_complete {l t : String} (h : Below d.graph l t) : ∃ n, d.belowB n l t = true := by
  induction h with
  | refl l => exact ⟨0, by simp [belowB]⟩
  | step hu _ ih =>
    obtain ⟨n, hn⟩ := ih
    refine ⟨n + 1, ?_⟩
    simp only [belowB, Bool.or_eq_true]
    refine .inr ?_
    simp only [graph] at hu
    rw [hu]
    exact hn

theorem footprintB_sound {n : Nat} {q l : String} (h : d.footprintB n q l = true) :
    footprint d.graph q l := by
  simp only [footprintB, List.any_eq_true, Bool.and_eq_true, beq_iff_eq] at h
  obtain ⟨f, hf, hq, m, hm, hb⟩ := h
  exact ⟨f, m, hf, hq, hm, d.belowB_sound n m l hb⟩

theorem groundsB_sound {n : Nat} {q nass : String} (h : d.groundsB n q nass = true) :
    grounds d.graph q nass := by
  simp only [groundsB, List.any_eq_true, Bool.and_eq_true, beq_iff_eq] at h
  obtain ⟨⟨a, l⟩, hp, ha, hf⟩ := h
  exact ⟨l, d.footprintB_sound hf, by simp only at ha; exact ha ▸ hp⟩

/-- The furūʿ of one qāʿida only: a cheaper graph to decide that qāʿida's footprint on. -/
def restrict (q : String) : Data := { d with furu := d.furu.filter (·.qaida == q) }

/-- `belowB` reads only `up`. -/
theorem belowB_up {e : Data} (he : e.up = d.up) : ∀ (n : Nat) (l t : String), e.belowB n l t = d.belowB n l t
  | 0, _, _ => rfl
  | n + 1, l, t => by
    have hu : e.upB l = d.upB l := by simp [upB, he]
    simp only [belowB, hu]
    cases d.upB l with
    | none => rfl
    | some m => simp only [belowB_up he n m t]

theorem footprintB_restrict (n : Nat) (q l : String) : (d.restrict q).footprintB n q l = d.footprintB n q l := by
  have hb := d.belowB_up (e := d.restrict q) rfl n
  simp only [footprintB, hb]
  simp only [restrict]
  induction d.furu with
  | nil => rfl
  | cons f fs ih =>
    by_cases h : (f.qaida == q) = true
    · simp [h, ih]
    · simp only [Bool.not_eq_true] at h
      simp [h, ih]

theorem groundsB_restrict (n : Nat) (q nass : String) :
    (d.restrict q).groundsB n q nass = d.groundsB n q nass := by
  simp only [groundsB, footprintB_restrict]
  rfl

/-- Every label climbs to a root (a label with no `up`) within `n` steps. -/
def rootedB (n : Nat) : Bool :=
  d.up.all fun p => (d.upB (rootN d.graph n p.1)).isNone

end Data

end Usul.Mahall
