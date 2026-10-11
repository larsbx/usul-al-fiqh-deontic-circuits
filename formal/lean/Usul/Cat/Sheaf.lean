import Usul.Cat.Basic

/-!
# M10: local verdicts, gluing, and ikhtilāf as obstruction

Generalizes `docs/architecture/sheaf-context-site.md` from ADQ affect facts to uṣūl verdicts.

* A **context** is a set of situations (`Ctx X := X → Prop`); a smaller context carries more
  constraints. Contexts ordered by inclusion form the site.
* A **local verdict** over `U` (`Section β U`) assigns a ruling to every situation in `U`. The
  verdicts form a presheaf: refining the context restricts the verdict (`restrict`), functorially
  (`restrict_id`, `restrict_comp`).
* A **cover** of `U` is a family of patches whose union is `U`: a riwāya, a wajh or a qāʿida
  each speaks to its own context.
* **Gluing lemma** (`gluing`, `glue_unique`): a family of local verdicts glues to exactly one
  verdict over `U` iff it is matching, i.e. the patches agree wherever they overlap. This is the
  sheaf condition for verdicts, proved for arbitrary sites; the finite one is below.
* **Obstruction**: a family fails to glue exactly when there is an `Obstruction`, two patches
  ruling differently at a shared situation (`no_glue_iff_obstruction`). That is how ikhtilāf
  is recorded: a named witness, never an error and never resolved by the encoding.

The finite, executable form (`Patch`, `obstructions`) is what fixtures run: on a finite list of
situations, `obstructions` lists every disagreement, and it is empty iff the induced family glues
(`glues_iff_obstructions_nil`).

For set-valued verdicts the obstruction to gluing is a pairwise disagreement (a Čech 1-cochain
that fails to vanish). Nothing here claims a cohomology group.
-/

namespace Usul.Cat.Sheaf

variable {X β : Type}

/-- A context: the situations it covers. -/
abbrev Ctx (X : Type) := X → Prop

/-- The site: contexts under inclusion. -/
def site (X : Type) : Cat :=
  Cat.thin (fun U V : Ctx X => ∀ x, U x → V x) (fun _ _ h => h) fun h k x hx => k x (h x hx)

/-- A local verdict over `U`. -/
def Section (β : Type) (U : Ctx X) : Type := ∀ x, U x → β

/-- Restriction to a refined context. -/
def restrict {U V : Ctx X} (h : ∀ x, V x → U x) (s : Section β U) : Section β V :=
  fun x hv => s x (h x hv)

theorem restrict_id {U : Ctx X} (s : Section β U) : restrict (fun _ h => h) s = s := rfl

theorem restrict_comp {U V W : Ctx X} (h₁ : ∀ x, V x → U x) (h₂ : ∀ x, W x → V x)
    (s : Section β U) : restrict h₂ (restrict h₁ s) = restrict (fun x hw => h₁ x (h₂ x hw)) s := rfl

/-- A cover of `U` by patches indexed by `ι`. -/
structure Cover (U : Ctx X) (ι : Type) where
  patch : ι → Ctx X
  sub : ∀ i x, patch i x → U x
  covers : ∀ x, U x → ∃ i, patch i x

variable {U : Ctx X} {ι : Type}

/-- The patches' verdicts agree on every overlap. -/
def Matching (c : Cover U ι) (s : ∀ i, Section β (c.patch i)) : Prop :=
  ∀ i j x (hi : c.patch i x) (hj : c.patch j x), s i x hi = s j x hj

/-- `g` restricts to each patch's verdict. -/
def Glues (c : Cover U ι) (s : ∀ i, Section β (c.patch i)) (g : Section β U) : Prop :=
  ∀ i x (hi : c.patch i x), g x (c.sub i x hi) = s i x hi

/-- An ikhtilāf witness: two patches rule differently at a shared situation. -/
structure Obstruction (c : Cover U ι) (s : ∀ i, Section β (c.patch i)) where
  i : ι
  j : ι
  x : X
  hi : c.patch i x
  hj : c.patch j x
  differ : s i x hi ≠ s j x hj

variable {c : Cover U ι} {s : ∀ i, Section β (c.patch i)}

theorem matching_of_glues {g : Section β U} (hg : Glues c s g) : Matching c s :=
  fun i j x hi hj => (hg i x hi).symm.trans (hg j x hj)

/-- Uniqueness: a cover determines the glued verdict. -/
theorem glue_unique {g g' : Section β U} (hg : Glues c s g) (hg' : Glues c s g') : g = g' := by
  funext x hx
  obtain ⟨i, hi⟩ := c.covers x hx
  exact (hg i x hi).trans (hg' i x hi).symm

/-- The gluing lemma: a matching family glues. -/
theorem gluing : Matching c s ↔ ∃ g, Glues c s g := by
  refine ⟨fun hm => ?_, fun ⟨_, hg⟩ => matching_of_glues hg⟩
  refine ⟨fun x hx => s (c.covers x hx).choose x (c.covers x hx).choose_spec, fun i x hi => ?_⟩
  exact hm _ i x _ hi

theorem no_glue_of_obstruction (o : Obstruction c s) : ¬ ∃ g, Glues c s g :=
  fun h => o.differ (gluing.2 h o.i o.j o.x o.hi o.hj)

/-- A family fails to glue exactly when it carries an ikhtilāf witness. -/
theorem no_glue_iff_obstruction : (¬ ∃ g, Glues c s g) ↔ Nonempty (Obstruction c s) := by
  refine ⟨fun h => ?_, fun ⟨o⟩ => no_glue_of_obstruction o⟩
  rw [← gluing] at h
  simp only [Matching, Classical.not_forall] at h
  obtain ⟨i, j, x, hi, hj, hne⟩ := h
  exact ⟨⟨i, j, x, hi, hj, hne⟩⟩

/-! ## Finite sites: patches and obstruction records -/

/-- A named patch: the situations it speaks to and its ruling there. -/
structure Patch (X β : Type) where
  name : String
  mem : X → Bool
  verdict : X → β

/-- The context covered by a list of patches over a finite list of situations. -/
def support (xs : List X) (ps : List (Patch X β)) : Ctx X := fun x => x ∈ xs ∧ ∃ p ∈ ps, p.mem x = true

/-- The cover induced by the patches, indexed by membership in the list. -/
def cover (xs : List X) (ps : List (Patch X β)) : Cover (support xs ps) {p // p ∈ ps} where
  patch p x := x ∈ xs ∧ p.1.mem x = true
  sub p _ h := ⟨h.1, p.1, p.2, h.2⟩
  covers _ h := let ⟨p, hp, hm⟩ := h.2; ⟨⟨p, hp⟩, h.1, hm⟩

/-- Each patch's verdict, as a local section. -/
def sections (xs : List X) (ps : List (Patch X β)) : ∀ i, Section β ((cover xs ps).patch i) :=
  fun p x _ => p.1.verdict x

/-- Every disagreement, as `(patch, patch, situation)` records. -/
def obstructions [DecidableEq β] (xs : List X) (ps : List (Patch X β)) : List (String × String × X) :=
  ps.flatMap fun p => ps.flatMap fun q =>
    (xs.filter fun x => p.mem x && q.mem x && p.verdict x != q.verdict x).map fun x => (p.name, q.name, x)

theorem obstructions_nil_iff [DecidableEq β] {xs : List X} {ps : List (Patch X β)} :
    obstructions xs ps = [] ↔
      ∀ p ∈ ps, ∀ q ∈ ps, ∀ x ∈ xs, p.mem x = true → q.mem x = true → p.verdict x = q.verdict x := by
  simp only [obstructions, List.flatMap_eq_nil_iff, List.map_eq_nil_iff, List.filter_eq_nil_iff,
    Bool.and_eq_true, bne_iff_ne, ne_eq]
  exact forall₂_congr fun p _ => forall₂_congr fun q _ => forall₂_congr fun x _ => by
    by_cases hp : p.mem x = true <;> by_cases hq : q.mem x = true <;> simp [hp, hq]

/-- The finite sheaf condition: the patches glue to one verdict iff no obstruction is recorded. -/
theorem glues_iff_obstructions_nil [DecidableEq β] {xs : List X} {ps : List (Patch X β)} :
    (∃ g, Glues (cover xs ps) (sections xs ps) g) ↔ obstructions xs ps = [] := by
  rw [← gluing, obstructions_nil_iff]
  constructor
  · intro hm p hp q hq x hx hpx hqx
    exact hm ⟨p, hp⟩ ⟨q, hq⟩ x ⟨hx, hpx⟩ ⟨hx, hqx⟩
  · intro h p q x hp hq
    exact h p.1 p.2 q.1 q.2 x hp.1 hp.2 hq.2

end Usul.Cat.Sheaf
