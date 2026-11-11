import Usul.Typing.IDAOmission

/-! Bind one typed observation batch to the exact omission scope of the
current snapshot. The caller is responsible for authenticating the batch. -/

namespace Usul.IDA.Omission.Wire

open ActRegistry

structure ScopeWire where
  action : ActionWire
  opportunity : Opportunity
  accountable : RefWire
  performer : OperandWire
  definition : KindKey
  definitionDigest : List Nat
  clockVersion : Nat
  deriving DecidableEq, Repr

def encodeScope (s : Scope) : ScopeWire :=
  ⟨encodeAction s.action, s.opportunity, encodeRef s.accountable, encodeOperand s.performer,
    s.definition, s.definitionDigest, s.clockVersion⟩

def decodeScope (w : ScopeWire) : Option Scope := do
  pure ⟨← decodeAction w.action, w.opportunity, ← decodeRef w.accountable,
    ← decodeOperand w.performer, w.definition, w.definitionDigest, w.clockVersion⟩

theorem scope_roundtrip (s : Scope) : decodeScope (encodeScope s) = some s := by
  cases s
  simp [decodeScope, encodeScope, action_roundtrip, ref_roundtrip, operand_roundtrip]

theorem scope_injective {s t : Scope} (h : encodeScope s = encodeScope t) : s = t := by
  have hd := congrArg decodeScope h
  simpa only [scope_roundtrip, Option.some.injEq] using hd

structure ReportWire where
  mode : String
  occurredAt : Nat
  recordedAt : Nat
  deriving Repr

structure CoverageWire where
  modes : List String
  recordedAt : Nat
  deriving Repr

structure View where
  schema : String
  scope : ScopeWire
  reports : List ReportWire
  coverage : Option CoverageWire
  deriving Repr

def schema : String := "usul.ida.omission-observations.v1"

inductive Failure where
  | context (cause : Context.Failure)
  | noOpportunity | wrongSchema | wrongScope | unknownMode
  deriving DecidableEq, Repr

def decodeMode (mode : String) : Except Failure Mode :=
  match mode with
  | "direct" => .ok .direct
  | "alternate" => .ok .alternate
  | _ => .error .unknownMode

structure BoundView where
  reports : List Completion
  coverage : Option Coverage

def decodeView (s : Scope) (w : View) : Except Failure BoundView :=
  if w.schema ≠ schema then .error .wrongSchema
  else if w.scope ≠ encodeScope s then .error .wrongScope
  else do
    let reports ← w.reports.mapM fun r => do
      pure (⟨s, ← decodeMode r.mode, r.occurredAt, r.recordedAt⟩ : Completion)
    let coverage ← w.coverage.mapM fun c => do
      pure (⟨s, ← c.modes.mapM decodeMode, c.recordedAt⟩ : Coverage)
    pure ⟨reports, coverage⟩

theorem decodeView_exact {s : Scope} {w : View} {v : BoundView}
    (h : decodeView s w = .ok v) : w.schema = schema ∧ w.scope = encodeScope s := by
  by_cases hv : w.schema = schema
  · by_cases hs : w.scope = encodeScope s
    · exact ⟨hv, hs⟩
    · simp [decodeView, hv, hs] at h
  · simp [decodeView, hv] at h

def review (r : Registry) (catalog : Context.Catalog) (expected : Context.Snapshot)
    (w : View) : Except Failure Outcome :=
  match Context.resolve r catalog expected with
  | .error why => .error (.context why)
  | .ok actual =>
    match Scope.fromSnapshot actual with
    | none => .error .noOpportunity
    | some s =>
      match decodeView s w with
      | .error why => .error why
      | .ok v =>
        .ok (evaluate s actual.envelope.context.effectiveAt actual.time.cutoff v.reports v.coverage)

theorem review_exact {r : Registry} {catalog : Context.Catalog} {expected : Context.Snapshot}
    {w : View} {result : Outcome} (h : review r catalog expected w = .ok result) :
    Context.resolve r catalog expected = .ok expected ∧
      ∃ s v, Scope.fromSnapshot expected = some s ∧ w.schema = schema ∧
        w.scope = encodeScope s ∧ decodeView s w = .ok v ∧
        evaluate s expected.envelope.context.effectiveAt expected.time.cutoff
          v.reports v.coverage = result := by
  cases hr : Context.resolve r catalog expected with
  | error why => simp [review, hr] at h
  | ok actual =>
    have he := ((Context.resolve_iff r catalog expected actual).mp hr).2.2.2
    subst actual
    cases hs : Scope.fromSnapshot expected with
    | none => simp [review, hr, hs] at h
    | some s =>
      cases hv : decodeView s w with
      | error why => simp [review, hr, hs, hv] at h
      | ok v =>
        have ⟨hver, hscope⟩ := decodeView_exact hv
        exact ⟨rfl, s, v, rfl, hver, hscope, hv, by simpa [review, hr, hs, hv] using h⟩

end Usul.IDA.Omission.Wire
