import Init

/-!
# Guard factorization for Islamic Deontic Algebra

This appendix is integrated as `UsulTest.IDAGuardedContext` and supplies a
mathematical model. The abstract theorem can be instantiated on a subtype of
admitted repository snapshots.  Its concrete witness below establishes a counterexample
for the explicitly defined toy target language only; it does not assert that
both witnesses pass the repository's registry or admission checker.

`Key` may contain seven scope coordinates; `X` may contain additional data.
Thus injectivity of a projection on all of `X` is not required.  Recovery of
the complete key, or an equivalent preservation proof, is required to recover
every exact-key test.
-/

namespace IDAContextDescent

universe u v w

def Image {X : Type u} {Y : Type v} (e : X → Y) :=
  { y : Y // ∃ x : X, e x = y }

def toImage {X : Type u} {Y : Type v} (e : X → Y) (x : X) : Image e :=
  ⟨e x, ⟨x, rfl⟩⟩

def FiberConstant {X : Type u} {Y : Type v} {R : Type w}
    (e : X → Y) (j : X → R) : Prop :=
  ∀ x y, e x = e y → j x = j y

def DescendsToImage {X : Type u} {Y : Type v} {R : Type w}
    (e : X → Y) (j : X → R) : Prop :=
  ∃ g : Image e → R, ∀ x, g (toImage e x) = j x

/-- General set-theoretic descent. The backward direction uses choice to pick
one preimage of each point in the image; no extension outside the image is
needed. This standard lemma is used to formulate the IDA guard criterion. -/
theorem descends_iff_fiberConstant {X : Type u} {Y : Type v} {R : Type w}
    (e : X → Y) (j : X → R) :
    DescendsToImage e j ↔ FiberConstant e j := by
  constructor
  · rintro ⟨g, hg⟩ x y hxy
    calc
      j x = g (toImage e x) := (hg x).symm
      _ = g (toImage e y) := congrArg g (Subtype.ext hxy)
      _ = j y := hg y
  · intro h
    classical
    refine ⟨fun y => j (Classical.choose y.property), ?_⟩
    intro x
    exact h _ x (Classical.choose_spec (toImage e x).property)

/-- Maps out of the image are uniquely determined by their values on projected
inputs. Function extensionality supplies equality of the whole maps. -/
theorem descended_map_unique {X : Type u} {Y : Type v} {R : Type w}
    (e : X → Y) (g h : Image e → R)
    (agree : ∀ x, g (toImage e x) = h (toImage e x)) : g = h := by
  funext y
  obtain ⟨x, hx⟩ := y.property
  have imageEq : toImage e x = y := Subtype.ext hx
  rw [← imageEq]
  exact agree x

def AllScopeTestsPreserved {X : Type u} {Y : Type v} {Key : Type w}
    (e : X → Y) (κ : X → Key) : Prop :=
  ∀ q x y, e x = e y → (κ x = q ↔ κ y = q)

/-- Preserving all exact-key tests is precisely constancy of the key on each
projection fiber. This direction of the criterion needs no classical choice. -/
theorem all_scope_tests_iff_key_fiberConstant
    {X : Type u} {Y : Type v} {Key : Type w}
    (e : X → Y) (κ : X → Key) :
    AllScopeTestsPreserved e κ ↔ FiberConstant e κ := by
  constructor
  · intro h x y hxy
    exact ((h (κ x) x y hxy).mp rfl).symm
  · intro h q x y hxy
    rw [h x y hxy]

/-- Main guard factorization criterion. The codomain of the recovered key is
the full key type, not an erasure of the target or one of its coordinates. -/
theorem scope_guard_descent_criterion
    {X : Type u} {Y : Type v} {Key : Type w}
    (e : X → Y) (κ : X → Key) :
    AllScopeTestsPreserved e κ ↔ DescendsToImage e κ := by
  exact (all_scope_tests_iff_key_fiberConstant e κ).trans
    (descends_iff_fiberConstant e κ).symm

/-- Exact output values must be handled separately from scope identity.
`R` is fixed here; heterogeneous questions require a tagged result type. -/
theorem paired_fiberConstant_iff
    {X : Type u} {Y : Type v} {Key R : Type w}
    (e : X → Y) (κ : X → Key) (j : X → R) :
    FiberConstant e (fun x => (κ x, j x)) ↔
      FiberConstant e κ ∧ FiberConstant e j := by
  constructor
  · intro h
    constructor
    · intro x y hxy
      exact congrArg Prod.fst (h x y hxy)
    · intro x y hxy
      exact congrArg Prod.snd (h x y hxy)
  · rintro ⟨hk, hj⟩ x y hxy
    exact Prod.ext (hk x y hxy) (hj x y hxy)

/-- Joint scope-and-output factorization, for a fixed result type `R`. -/
theorem guarded_output_descent_criterion
    {X : Type u} {Y : Type v} {Key R : Type w}
    (e : X → Y) (κ : X → Key) (j : X → R) :
    DescendsToImage e (fun x => (κ x, j x)) ↔
      AllScopeTestsPreserved e κ ∧ FiberConstant e j := by
  rw [descends_iff_fiberConstant, paired_fiberConstant_iff,
    all_scope_tests_iff_key_fiberConstant]

/-- An actually recovered key reflects and preserves binary equality tests. -/
theorem descended_guard_exact
    {X : Type u} {Y : Type v} {Key : Type w}
    (e : X → Y) (κ : X → Key) (g : Image e → Key)
    (hg : ∀ x, g (toImage e x) = κ x) (x y : X) :
    (g (toImage e x) = g (toImage e y)) ↔ κ x = κ y := by
  rw [hg x, hg y]

/-- Injectivity is required only in the special case where the entire input
is the key. It is too strong for snapshots with irrelevant annotations. -/
theorem identity_key_descent_iff_injective {Key : Type u} {Y : Type v}
    (e : Key → Y) :
    DescendsToImage e (fun x => x) ↔ Function.Injective e := by
  rw [descends_iff_fiberConstant]
  rfl

theorem no_descent_of_fiber_counterexample
    {X : Type u} {Y : Type v} {R : Type w}
    (e : X → Y) (j : X → R) (x y : X)
    (sameView : e x = e y) (differentResult : j x ≠ j y) :
    ¬ DescendsToImage e j := by
  intro h
  exact differentResult ((descends_iff_fiberConstant e j).mp h x y sameView)

/-! ## A typed omission window counterexample

Actions below have a deliberately small dependent signature: repayment takes
two person references and one obligation reference. Affects carry a quality
and a typed object. These branches are syntax; no ruling is assigned to them.
The history is a stipulated complete toy history, not an observed event log.
-/

inductive RefSort where
  | person | obligation | object
  deriving DecidableEq, Repr

structure Ref (sort : RefSort) where
  name : String
  deriving DecidableEq, Repr

inductive Action where
  | repay (performer recipient : Ref .person) (obligation : Ref .obligation)
  deriving DecidableEq, Repr

structure TypedObject where
  sort : RefSort
  referent : Ref sort
  deriving DecidableEq, Repr

structure Affect where
  quality : String
  object : TypedObject
  deriving DecidableEq, Repr

structure Opportunity where
  occurrence : String
  clock : String
  opensAt : Nat
  closesAt : Nat
  deriving DecidableEq, Repr

def Opportunity.WellFormed (o : Opportunity) : Prop := o.opensAt < o.closesAt

inductive Target where
  | perform (action : Action)
  | omit (action : Action) (opportunity : Opportunity)
  | affect (state : Affect)
  deriving DecidableEq, Repr

structure TimeView where
  clock : String
  cutoff : Nat
  perspective : String
  deriving DecidableEq, Repr

/-- All seven guarded coordinates. String-valued names here are opaque
identities, not a claim that each coordinate already has rich semantics. -/
structure Scope where
  question : String
  subject : Ref .person
  target : Target
  context : String
  time : TimeView
  profile : String
  profileVersion : String
  deriving DecidableEq, Repr

def ExactGuard (x y : Scope) : Prop := x = y

theorem exact_guard_iff_seven_coordinates (x y : Scope) :
    ExactGuard x y ↔
      x.question = y.question ∧ x.subject = y.subject ∧
      x.target = y.target ∧ x.context = y.context ∧ x.time = y.time ∧
      x.profile = y.profile ∧ x.profileVersion = y.profileVersion := by
  constructor
  · intro h
    cases h
    exact ⟨rfl, rfl, rfl, rfl, rfl, rfl, rfl⟩
  · rintro ⟨hq, hs, ht, hc, htime, hp, hv⟩
    cases x
    cases y
    simp_all [ExactGuard]

theorem perform_ne_omit (a b : Action) (o : Opportunity) :
    Target.perform a ≠ Target.omit b o := by
  intro h
  cases h

theorem perform_ne_affect (a : Action) (f : Affect) :
    Target.perform a ≠ Target.affect f := by
  intro h
  cases h

theorem omit_ne_affect (a : Action) (o : Opportunity) (f : Affect) :
    Target.omit a o ≠ Target.affect f := by
  intro h
  cases h

/-- The erased view deliberately retains occurrence and clock but forgets the
opening and closing times. All other scope coordinates are retained. -/
inductive WindowErasedTarget where
  | perform (action : Action)
  | omit (action : Action) (occurrence clock : String)
  | affect (state : Affect)
  deriving DecidableEq, Repr

def eraseWindow : Target → WindowErasedTarget
  | .perform a => .perform a
  | .omit a o => .omit a o.occurrence o.clock
  | .affect f => .affect f

structure WindowErasedScope where
  question : String
  subject : Ref .person
  target : WindowErasedTarget
  context : String
  time : TimeView
  profile : String
  profileVersion : String
  deriving DecidableEq, Repr

def eraseScopeWindow (s : Scope) : WindowErasedScope :=
  ⟨s.question, s.subject, eraseWindow s.target, s.context, s.time,
    s.profile, s.profileVersion⟩

def debtor : Ref .person := ⟨"debtor"⟩
def creditor : Ref .person := ⟨"creditor"⟩
def debt : Ref .obligation := ⟨"identified-obligation"⟩
def repayment : Action := .repay debtor creditor debt

def shortOpportunity : Opportunity :=
  ⟨"repayment-occurrence", "case-clock", 0, 5⟩

def longOpportunity : Opportunity :=
  ⟨"repayment-occurrence", "case-clock", 0, 10⟩

def scopeFor (o : Opportunity) : Scope :=
  ⟨"whether-repayment-occurred-in-window", debtor, .omit repayment o,
    "stipulated-case", ⟨"case-clock", 10, "retrospective"⟩,
    "stipulated-profile", "version-one"⟩

def shortScope : Scope := scopeFor shortOpportunity
def longScope : Scope := scopeFor longOpportunity

structure Event where
  action : Action
  occurrence : String
  clock : String
  tick : Nat
  deriving DecidableEq, Repr

def completeToyHistory : List Event :=
  [⟨repayment, "repayment-occurrence", "case-clock", 7⟩]

def Event.inOpportunity (e : Event) (a : Action) (o : Opportunity) : Bool :=
  e.action == a && e.occurrence == o.occurrence && e.clock == o.clock &&
    decide (o.opensAt ≤ e.tick) && decide (e.tick < o.closesAt)

/-- Conditional closed-history nonperformance. No epistemic claim follows
from a real log being empty. No deontic ruling is computed here. -/
def omitted (history : List Event) (a : Action) (o : Opportunity) : Bool :=
  !(history.any fun e => e.inOpportunity a o)

def omissionValue (s : Scope) : Option Bool :=
  match s.target with
  | .omit a o => some (omitted completeToyHistory a o)
  | _ => none

theorem short_window_wellFormed : shortOpportunity.WellFormed := by
  unfold Opportunity.WellFormed shortOpportunity
  decide

theorem long_window_wellFormed : longOpportunity.WellFormed := by
  unfold Opportunity.WellFormed longOpportunity
  decide

theorem windows_closed_at_observation :
    shortOpportunity.closesAt ≤ shortScope.time.cutoff ∧
    longOpportunity.closesAt ≤ longScope.time.cutoff := by decide

theorem erased_scope_collision :
    eraseScopeWindow shortScope = eraseScopeWindow longScope := rfl

theorem complete_scopes_differ : shortScope ≠ longScope := by decide

theorem short_window_omission : omissionValue shortScope = some true := by decide
theorem long_window_non_omission : omissionValue longScope = some false := by decide

theorem omission_value_differs : omissionValue shortScope ≠ omissionValue longScope := by decide

/-- An erasure cannot recover every exact-key comparison for this model. -/
theorem omission_erasure_breaks_exact_guard :
    ¬ AllScopeTestsPreserved eraseScopeWindow (fun s => s) := by
  intro h
  exact complete_scopes_differ
    ((all_scope_tests_iff_key_fiberConstant _ _).mp h _ _ erased_scope_collision)

theorem omission_key_does_not_descend :
    ¬ DescendsToImage eraseScopeWindow (fun s => s) :=
  no_descent_of_fiber_counterexample _ _ _ _ erased_scope_collision complete_scopes_differ

/-- This is a semantic witness as well as a syntactic collision. It remains
conditional on the stipulated complete toy history. -/
theorem omission_truth_does_not_descend :
    ¬ DescendsToImage eraseScopeWindow omissionValue :=
  no_descent_of_fiber_counterexample _ _ _ _ erased_scope_collision omission_value_differs

/-! ## Harmless noninjective erasure
An annotation unrelated to the guarded scope can be dropped safely. This is
why the theorem factors the scope key rather than demanding injectivity on
every snapshot field.
-/

abbrev AnnotatedScope := Scope × Bool

def annotationErasure : AnnotatedScope → Scope := Prod.fst

theorem annotation_erasure_preserves_scope_tests :
    AllScopeTestsPreserved annotationErasure Prod.fst := by
  intro q x y h
  change x.1 = y.1 at h
  rw [h]

theorem annotation_erasure_not_injective : ¬ Function.Injective annotationErasure := by
  intro h
  have eq : (shortScope, false) = (shortScope, true) := h rfl
  have bad : false = true := congrArg Prod.snd eq
  cases bad

#print axioms descends_iff_fiberConstant
#print axioms descended_map_unique
#print axioms all_scope_tests_iff_key_fiberConstant
#print axioms scope_guard_descent_criterion
#print axioms paired_fiberConstant_iff
#print axioms guarded_output_descent_criterion
#print axioms descended_guard_exact
#print axioms identity_key_descent_iff_injective
#print axioms no_descent_of_fiber_counterexample
#print axioms exact_guard_iff_seven_coordinates
#print axioms perform_ne_omit
#print axioms perform_ne_affect
#print axioms omit_ne_affect
#print axioms short_window_wellFormed
#print axioms long_window_wellFormed
#print axioms windows_closed_at_observation
#print axioms erased_scope_collision
#print axioms complete_scopes_differ
#print axioms short_window_omission
#print axioms long_window_non_omission
#print axioms omission_value_differs
#print axioms omission_erasure_breaks_exact_guard
#print axioms omission_key_does_not_descend
#print axioms omission_truth_does_not_descend
#print axioms annotation_erasure_preserves_scope_tests
#print axioms annotation_erasure_not_injective

end IDAContextDescent
