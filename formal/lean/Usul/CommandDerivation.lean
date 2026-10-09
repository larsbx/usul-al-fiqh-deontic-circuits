import Usul.CommandSchemata

/-!
# Proof-relevant candidate command derivations

The constructors record which reported reading licenses an evaluation. They are in
`Type`, so a derivation retains its rule and premises. Soundness and completeness
connect this independently stated rule system to the M5 executable functions.

These are derivations *under a supplied candidate reading*, not accepted fatwās.
Admissibility of a qarīna and the first-command-position context are external
premises at the admission boundary; the evaluator cannot establish either.
-/

namespace Usul.CommandSchemata

inductive NonverbalDerivation : NonverbalReading → NonverbalForm → CommandUsage → Type where
  | qadiDenial (f : NonverbalForm) : NonverbalDerivation .qadiReported f .notLiteral
  | writingArgument : NonverbalDerivation .jamiWriting .writing .literal
  | gestureUnanswered : NonverbalDerivation .jamiWriting .gesture .unsettled

theorem NonverbalDerivation.sound {r f u} (d : NonverbalDerivation r f u) :
    nonverbalUsage r f = u := by cases d <;> rfl

def NonverbalDerivation.complete (r : NonverbalReading) (f : NonverbalForm) :
    NonverbalDerivation r f (nonverbalUsage r f) := by
  cases r with
  | qadiReported => exact .qadiDenial f
  | jamiWriting => cases f with
    | writing => exact .writingArgument
    | gesture => exact .gestureUnanswered

inductive PropheticActDerivation : PropheticActReading → Bool → CommandUsage → Type where
  | figurativeReport (i : Bool) : PropheticActDerivation .abuBarakat i .figurative
  | literalReport (i : Bool) : PropheticActDerivation .literalReport i .literal
  | authorInference {i : Bool} (imitation : i = true) :
      PropheticActDerivation .authorConditional i .literal
  | authorUnanswered {i : Bool} (missing : i = false) :
      PropheticActDerivation .authorConditional i .unsettled

theorem PropheticActDerivation.sound {r i u} (d : PropheticActDerivation r i u) :
    propheticActUsage r i = u := by
  cases d <;> simp_all [propheticActUsage]

def PropheticActDerivation.complete (r : PropheticActReading) (i : Bool) :
    PropheticActDerivation r i (propheticActUsage r i) := by
  cases r with
  | abuBarakat => exact .figurativeReport i
  | literalReport => exact .literalReport i
  | authorConditional => cases i with
    | false => exact .authorUnanswered rfl
    | true => exact .authorInference rfl

inductive ObligationDerivation : ObligationReading → ObligationExpression → Option Hukm →
    Hukm → Type where
  | nass {r e q} (explicit : obligationIsNass r e = true) :
      ObligationDerivation r e q .wajib
  | default {r e} (defeasible : obligationIsNass r e = false) :
      ObligationDerivation r e none .wajib
  | indication {r e h} (defeasible : obligationIsNass r e = false) :
      ObligationDerivation r e (some h) h

theorem ObligationDerivation.sound {r e q h} (d : ObligationDerivation r e q h) :
    obligationStatus r e q = h := by
  cases d <;> simp_all [obligationStatus, Dalala.amrStatus, Schema.resolveD, Schema.first]

def ObligationDerivation.complete (r : ObligationReading) (e : ObligationExpression)
    (q : Option Hukm) : ObligationDerivation r e q (obligationStatus r e q) := by
  cases hn : obligationIsNass r e with
  | true => simpa [obligationStatus, hn] using
      (ObligationDerivation.nass (q := q) hn)
  | false => cases q with
    | none => simpa [obligationStatus, hn, Dalala.amrStatus, Schema.resolveD, Schema.first]
        using (ObligationDerivation.default hn)
    | some h => simpa [obligationStatus, hn, Dalala.amrStatus, Schema.resolveD, Schema.first]
        using (ObligationDerivation.indication (h := h) hn)

inductive IntendedDerivation : IntendedUseReading → IntendedRuling → IntendedCommand → Type where
  | qadiReport (i : IntendedRuling) : IntendedDerivation .qadiReport i ⟨.literal, i.hukm⟩
  | karkhiRecommendation : IntendedDerivation .karkhiRazi .recommendation ⟨.figurative, .mandub⟩
  | karkhiPermissionUnanswered : IntendedDerivation .karkhiRazi .permission ⟨.unsettled, .mubah⟩
  | abuPermission : IntendedDerivation .abuBarakat .permission ⟨.figurative, .mubah⟩
  | abuRecommendationUnanswered :
      IntendedDerivation .abuBarakat .recommendation ⟨.unsettled, .mandub⟩
  | qadiRecommendationArgument :
      IntendedDerivation .qadiArgument .recommendation ⟨.literal, .mandub⟩
  | qadiPermissionArgument : IntendedDerivation .qadiArgument .permission ⟨.figurative, .mubah⟩

theorem IntendedDerivation.sound {r i c} (d : IntendedDerivation r i c) :
    intendedCommand r i = c := by cases d <;> rfl

def IntendedDerivation.complete (r : IntendedUseReading) (i : IntendedRuling) :
    IntendedDerivation r i (intendedCommand r i) := by
  cases r with
  | qadiReport => exact .qadiReport i
  | karkhiRazi => cases i with
    | recommendation => exact .karkhiRecommendation
    | permission => exact .karkhiPermissionUnanswered
  | abuBarakat => cases i with
    | recommendation => exact .abuRecommendationUnanswered
    | permission => exact .abuPermission
  | qadiArgument => cases i with
    | recommendation => exact .qadiRecommendationArgument
    | permission => exact .qadiPermissionArgument

/-! ## Typed requests and the admission boundary -/

inductive CommandRequest where
  | nonverbal (reading : NonverbalReading) (form : NonverbalForm)
  | propheticAct (reading : PropheticActReading) (imitation : Bool)
  | obligation (reading : ObligationReading) (expression : ObligationExpression)
      (qarina : Option Hukm)
  | intended (reading : IntendedUseReading) (ruling : IntendedRuling)

def CommandRequest.Result : CommandRequest → Type
  | .nonverbal .. | .propheticAct .. => CommandUsage
  | .obligation .. => Hukm
  | .intended .. => IntendedCommand

def CommandRequest.evaluate (q : CommandRequest) : q.Result :=
  match q with
  | .nonverbal r f => nonverbalUsage r f
  | .propheticAct r i => propheticActUsage r i
  | .obligation r e c => obligationStatus r e c
  | .intended r i => intendedCommand r i

/-- The caller must justify every supplied indication and the source's first-position
context. This policy is not computed from an encoder output. -/
structure CommandPremises where
  admissibleQarina : Hukm → Prop
  firstCommandPosition : Prop

def CommandPremises.Holds (p : CommandPremises) : CommandRequest → Prop
  | .obligation _ _ q => p.firstCommandPosition ∧ ∀ h, q = some h → p.admissibleQarina h
  | .intended .. => p.firstCommandPosition
  | _ => True

inductive CommandDerivation : (q : CommandRequest) → q.Result → Type where
  | nonverbal {r f u} (d : NonverbalDerivation r f u) :
      CommandDerivation (.nonverbal r f) u
  | propheticAct {r i u} (d : PropheticActDerivation r i u) :
      CommandDerivation (.propheticAct r i) u
  | obligation {r e c h} (d : ObligationDerivation r e c h) :
      CommandDerivation (.obligation r e c) h
  | intended {r i c} (d : IntendedDerivation r i c) :
      CommandDerivation (.intended r i) c

theorem CommandDerivation.sound {q v} (d : CommandDerivation q v) : q.evaluate = v := by
  cases d with
  | nonverbal d => exact d.sound
  | propheticAct d => exact d.sound
  | obligation d => exact d.sound
  | intended d => exact d.sound

def CommandDerivation.complete (q : CommandRequest) : CommandDerivation q q.evaluate :=
  match q with
  | .nonverbal r f => .nonverbal (NonverbalDerivation.complete r f)
  | .propheticAct r i => .propheticAct (PropheticActDerivation.complete r i)
  | .obligation r e c => .obligation (ObligationDerivation.complete r e c)
  | .intended r i => .intended (IntendedDerivation.complete r i)

theorem CommandDerivation.iff_evaluation {q : CommandRequest} {v : q.Result} :
    Nonempty (CommandDerivation q v) ↔ q.evaluate = v :=
  ⟨fun ⟨d⟩ => d.sound, fun h => h ▸ ⟨complete q⟩⟩

theorem CommandDerivation.deterministic {q : CommandRequest} {a b : q.Result}
    (da : CommandDerivation q a) (db : CommandDerivation q b) : a = b :=
  da.sound.symm.trans db.sound

/-- A rule trace plus independently supplied premises, still only a candidate. -/
structure AdmittedCommand (p : CommandPremises) (q : CommandRequest) (v : q.Result) where
  premises : p.Holds q
  derivation : CommandDerivation q v

theorem admitted_iff {p : CommandPremises} {q : CommandRequest} {v : q.Result} :
    Nonempty (AdmittedCommand p q v) ↔ p.Holds q ∧ q.evaluate = v := by
  constructor
  · rintro ⟨d⟩; exact ⟨d.premises, d.derivation.sound⟩
  · rintro ⟨hp, hv⟩
    exact ⟨⟨hp, hv ▸ CommandDerivation.complete q⟩⟩

theorem no_admission_without_premises {p : CommandPremises} {q : CommandRequest}
    (missing : ¬ p.Holds q) (v : q.Result) : ¬ Nonempty (AdmittedCommand p q v) :=
  fun ⟨d⟩ => missing d.premises

theorem author_literal_requires_imitation {i : Bool}
    (d : PropheticActDerivation .authorConditional i .literal) : i = true := by
  have h := d.sound
  cases i <;> simp_all [propheticActUsage]

theorem no_positive_gesture_derivation :
    ¬ Nonempty (NonverbalDerivation .jamiWriting .gesture .literal) := by
  rintro ⟨d⟩
  have h := d.sound
  cases h

theorem no_karkhi_permission_classification {u : CommandUsage}
    (d : IntendedDerivation .karkhiRazi .permission ⟨u, .mubah⟩) : u = .unsettled := by
  have h := congrArg IntendedCommand.usage d.sound
  exact h.symm

theorem derivation_preserves_intended_ruling {r i c} (d : IntendedDerivation r i c) :
    c.ruling = i.hukm := by rw [← d.sound]; rfl

end Usul.CommandSchemata
