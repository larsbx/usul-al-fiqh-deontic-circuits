import Usul.Schema
import Usul.Typing.IDASubstitution

/-! A scoped, synthetic observation evaluator for ACT-03. Its outcomes are
observation statuses. The input witness checks snapshot shape, not admission
or authentication of its reported qualifications. -/

namespace Usul.IDA.Projection

abbrev Input (r : ActRegistry.Registry) := {s : Context.Snapshot // s.WellFormed r}

def core (x : Input r) : TargetExpr := x.val.target

def kind (x : Input r) : ActRegistry.KindKey := x.val.envelope.key

structure Scope where
  inquiry : Context.Inquiry
  kind : ActRegistry.KindKey
  definitionDigest : List Nat
  registrySnapshot : Nat
  vocabulary : Context.Vocabulary
  policy : ActRegistry.KindKey
  context : ActRegistry.Snapshot
  time : Context.TimeView
  deriving DecidableEq, Repr

/-- Keep the full inquiry, definition and time coordinates. Evidence revision
and snapshot identity are outside this evaluator's observation scope. -/
def scope (s : Context.Snapshot) : Scope :=
  ⟨s.inquiry, s.envelope.key, s.envelope.definitionDigest, s.envelope.registrySnapshot,
   s.vocabulary, s.admissionPolicy, { s.envelope.context with evidenceRevision := 0 }, s.time⟩

structure PersonPredicate (v : Context.Vocabulary) where
  predicate : Substitution.Predicate v
  unary : predicate.val.arguments = [.person]

def PersonPredicate.key (p : PersonPredicate v) : ActRegistry.KindKey := p.predicate.val.key

structure Rule where
  scope : Scope
  support : PersonPredicate scope.vocabulary
  exception : PersonPredicate scope.vocabulary
  distinct : support.key ≠ exception.key
  defaultEnabled : Bool

/-- A report query includes the exact predicate version and rigid person. -/
def matchesQuery (key : ActRegistry.KindKey) (person : EntityRef)
    (q : ActRegistry.Qualification) : Bool :=
  q.predicate == key.symbol && q.version == key.version && q.arguments == [person]

def hasReport (qs : List ActRegistry.Qualification) (key : ActRegistry.KindKey)
    (person : EntityRef) (positive : Bool) : Bool :=
  qs.any fun q => matchesQuery key person q && (q.polarity == positive)

inductive Outcome where
  | outsideScope | unresolved | fallback | negativeSupport | positiveSupport
  | contestedSupport | exception | contestedException
  deriving DecidableEq, Repr

/-- Exceptions take priority. The fallback requires a matching negative
exception report as well as the fixed default flag. -/
def classify (defaultEnabled supportPos supportNeg exceptionPos exceptionNeg : Bool) : Outcome :=
  if exceptionPos then
    if exceptionNeg then .contestedException else .exception
  else if supportPos then
    if supportNeg then .contestedSupport else .positiveSupport
  else if supportNeg then .negativeSupport
  else if defaultEnabled && exceptionNeg then .fallback
  else .unresolved

/-- Direct evaluation on the full list. Support concerns the accountable person.
The exception concerns the declared performer. -/
def evaluate (rule : Rule) (x : Input r) : Outcome :=
  let s := x.val
  if scope s ≠ rule.scope then .outsideScope
  else
    let qs := s.envelope.qualifications
    classify rule.defaultEnabled
      (hasReport qs rule.support.key s.inquiry.accountable true)
      (hasReport qs rule.support.key s.inquiry.accountable false)
      (hasReport qs rule.exception.key s.inquiry.performer.referent true)
      (hasReport qs rule.exception.key s.inquiry.performer.referent false)

structure Signs where
  positive : Bool
  negative : Bool
  deriving DecidableEq, Repr

/-- Compute both existence observations from the complete matching row set. -/
def signs (qs : List ActRegistry.Qualification) (key : ActRegistry.KindKey)
    (person : EntityRef) : Signs :=
  let matching := qs.filter (matchesQuery key person)
  ⟨matching.any (·.polarity), matching.any (! ·.polarity)⟩

theorem signs_positive (qs : List ActRegistry.Qualification) (k : ActRegistry.KindKey)
    (p : EntityRef) : (signs qs k p).positive = hasReport qs k p true := by
  simp [signs, hasReport]

theorem signs_negative (qs : List ActRegistry.Qualification) (k : ActRegistry.KindKey)
    (p : EntityRef) : (signs qs k p).negative = hasReport qs k p false := by
  simp [signs, hasReport]

theorem signs_append_irrelevant (qs extra : List ActRegistry.Qualification)
    (k : ActRegistry.KindKey) (p : EntityRef)
    (h : extra.filter (matchesQuery k p) = []) :
    signs (qs ++ extra) k p = signs qs k p := by
  simp [signs, List.filter_append, h]

structure Dependencies where
  scope : Scope
  support : Signs
  exception : Signs
  deriving DecidableEq, Repr

def project (rule : Rule) (x : Input r) : Dependencies :=
  let s := x.val
  ⟨scope s, signs s.envelope.qualifications rule.support.key s.inquiry.accountable,
    signs s.envelope.qualifications rule.exception.key s.inquiry.performer.referent⟩

def evaluateProjected (rule : Rule) (d : Dependencies) : Outcome :=
  if d.scope ≠ rule.scope then .outsideScope
  else classify rule.defaultEnabled d.support.positive d.support.negative
    d.exception.positive d.exception.negative

theorem projection_exact (rule : Rule) (x : Input r) :
    evaluate rule x = evaluateProjected rule (project rule x) := by
  simp [evaluate, evaluateProjected, project, signs_positive, signs_negative]

def Equivalent (rule : Rule) (a b : Input r) : Prop := project rule a = project rule b

instance (rule : Rule) (a b : Input r) : Decidable (Equivalent rule a b) :=
  inferInstanceAs (Decidable (project rule a = project rule b))

theorem equivalence (rule : Rule) : Equivalence (Equivalent (r := r) rule) :=
  ⟨fun _ => rfl, Eq.symm, Eq.trans⟩

theorem frame (rule : Rule) {a b : Input r} (h : Equivalent rule a b) :
    evaluate rule a = evaluate rule b := by
  rw [projection_exact, projection_exact rule b, h]

theorem irrelevant_append (rule : Rule) {a b : Input r}
    (extra : List ActRegistry.Qualification)
    (hs : scope a.val = scope b.val)
    (hq : b.val.envelope.qualifications = a.val.envelope.qualifications ++ extra)
    (hp : extra.filter (matchesQuery rule.support.key a.val.inquiry.accountable) = [])
    (he : extra.filter (matchesQuery rule.exception.key a.val.inquiry.performer.referent) = []) :
    Equivalent rule a b := by
  have hInquiry := congrArg Scope.inquiry hs
  change a.val.inquiry = b.val.inquiry at hInquiry
  simp [Equivalent, project, hq, ← hs, ← hInquiry, signs_append_irrelevant _ _ _ _ hp,
    signs_append_irrelevant _ _ _ _ he]

theorem factors (rule : Rule) :
    Usul.Schema.Factors (evaluate (r := r) rule) (project rule) :=
  Usul.Schema.Factors.of_eq (evaluateProjected rule) (projection_exact rule)

theorem same_scope (rule : Rule) {a b : Input r} (h : Equivalent rule a b) :
    scope a.val = scope b.val := congrArg Dependencies.scope h

theorem classify_fallback_iff (enabled sp sn ep en : Bool) :
    classify enabled sp sn ep en = .fallback ↔
      enabled = true ∧ sp = false ∧ sn = false ∧ ep = false ∧ en = true := by
  cases enabled <;> cases sp <;> cases sn <;> cases ep <;> cases en <;> decide

theorem fallback_requires_negative (rule : Rule) (x : Input r)
    (h : evaluate rule x = .fallback) :
    hasReport x.val.envelope.qualifications rule.exception.key
      x.val.inquiry.performer.referent false = true := by
  by_cases hs : scope x.val = rule.scope
  · simp [evaluate, hs, classify_fallback_iff] at h
    exact h.2.2.2.2
  · simp [evaluate, hs] at h

theorem projection_preserves_target (x : Input r) :
    (scope x.val).inquiry.scope.target = .structured (core x) :=
  x.property.2.2.2.2.2.1.1

end Usul.IDA.Projection
