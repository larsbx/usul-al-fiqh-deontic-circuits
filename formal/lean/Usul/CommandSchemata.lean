import Usul.Dalala

/-!
# Candidate command schemata (M5, Ibn al-Laḥḥām 43)

These functions make the named readings expressible. A reading is an explicit input,
not an adopted position. Naming an expression as a literal or figurative command is
distinct from assigning an act's five-fold ruling. `unsettled` preserves a question
that the cited position does not answer; `notLiteral` does not invent figurative use.
The source receipts and open review questions are in `lahham_m5_commands_plan.json`.
-/

namespace Usul.CommandSchemata

open Usul

inductive CommandUsage where
  | literal | figurative | notLiteral | unsettled
  deriving DecidableEq, Repr

/-! ## Writing and gesture (43.f001)

Abū al-Barakāt reports al-Qāḍī denying literal naming for both. Ibn al-Laḥḥām infers
literal naming from the Jāmiʿ's argument about writing; that argument supplies no
positive conclusion about gesture. -/

inductive NonverbalForm where
  | writing | gesture
  deriving DecidableEq, Repr

inductive NonverbalReading where
  | qadiReported | jamiWriting
  deriving DecidableEq, Repr

def nonverbalUsage : NonverbalReading → NonverbalForm → CommandUsage
  | .qadiReported, _ => .notLiteral
  | .jamiWriting, .writing => .literal
  | .jamiWriting, .gesture => .unsettled

theorem writing_does_not_settle_gesture :
    nonverbalUsage .jamiWriting .gesture = .unsettled := rfl

theorem writing_readings_differ :
    nonverbalUsage .qadiReported .writing ≠ nonverbalUsage .jamiWriting .writing := by decide

/-! ## Naming the Prophet's act (43.f003)

The Abū al-Barakāt report says figurative; the named Mālikī/Shāfiʿī report says literal.
The author's own inference is explicitly conditional on established imitation:
«وهذا ينبغى إذا ثبت التأسى بفعله». Failure to supply that premise leaves it unsettled.
-/

inductive PropheticActReading where
  | abuBarakat | literalReport | authorConditional
  deriving DecidableEq, Repr

def propheticActUsage (reading : PropheticActReading) (imitationEstablished : Bool) : CommandUsage :=
  match reading with
  | .abuBarakat => .figurative
  | .literalReport => .literal
  | .authorConditional => if imitationEstablished then .literal else .unsettled

theorem author_inference_needs_imitation :
    propheticActUsage .authorConditional false = .unsettled := rfl

theorem author_inference_with_imitation :
    propheticActUsage .authorConditional true = .literal := rfl

/-! ## An explicit obligation expression and reinterpretation (43.f004)

Scoped to the three expressions in this question: the unqualified threat, wujūb and
farḍ. Abū al-Barakāt's reported reading treats them as naṣṣ; al-Qāḍī's reading permits
reinterpretation. An admissible qarīna is supplied, not inferred. Bare commands keep
the existing Dalala default under either reading. -/

inductive ObligationExpression where
  | bareCommand | unqualifiedThreat | wujubLabel | fardLabel
  deriving DecidableEq, Repr

inductive ObligationReading where
  | qadi | abuBarakat
  deriving DecidableEq, Repr

def obligationIsNass : ObligationReading → ObligationExpression → Bool
  | .qadi, _ => false
  | .abuBarakat, .bareCommand => false
  | .abuBarakat, _ => true

def obligationStatus (reading : ObligationReading) (expression : ObligationExpression)
    (qarina : Option Hukm) : Hukm :=
  if obligationIsNass reading expression then .wajib else Dalala.amrStatus qarina

theorem bare_command_conservative (r : ObligationReading) (q : Option Hukm) :
    obligationStatus r .bareCommand q = Dalala.amrStatus q := by cases r <;> rfl

theorem qadi_retains_defeasibility (e : ObligationExpression) (q : Option Hukm) :
    obligationStatus .qadi e q = Dalala.amrStatus q := rfl

theorem nass_blocks_reinterpretation (r : ObligationReading) (e : ObligationExpression)
    (q : Option Hukm) (h : obligationIsNass r e = true) :
    obligationStatus r e q = .wajib := by simp [obligationStatus, h]

theorem explicit_readings_differ :
    obligationStatus .qadi .wujubLabel (some .mandub) ≠
      obligationStatus .abuBarakat .wujubLabel (some .mandub) := by decide

/-! ## An intended recommendation or permission (43.f007)

Within the question's stated first position (a bare command obligates), the case
presupposes the intended ruling and disputes its literal/figurative naming.
The Karkhī/Rāzī report here concerns recommendation, and Abū al-Barakāt's report
permission; neither is extended to the other intended ruling. The text explicitly
notes tension between al-Qāḍī's report and his subsequent argument about permission.
-/

inductive IntendedRuling where
  | recommendation | permission
  deriving DecidableEq, Repr

def IntendedRuling.hukm : IntendedRuling → Hukm
  | .recommendation => .mandub
  | .permission => .mubah

inductive IntendedUseReading where
  | qadiReport | karkhiRazi | abuBarakat | qadiArgument
  deriving DecidableEq, Repr

def intendedUsage : IntendedUseReading → IntendedRuling → CommandUsage
  | .qadiReport, _ => .literal
  | .karkhiRazi, .recommendation => .figurative
  | .karkhiRazi, .permission => .unsettled
  | .abuBarakat, .permission => .figurative
  | .abuBarakat, .recommendation => .unsettled
  | .qadiArgument, .recommendation => .literal
  | .qadiArgument, .permission => .figurative

structure IntendedCommand where
  usage : CommandUsage
  ruling : Hukm
  deriving DecidableEq, Repr

def intendedCommand (reading : IntendedUseReading) (intended : IntendedRuling) : IntendedCommand :=
  ⟨intendedUsage reading intended, intended.hukm⟩

theorem naming_preserves_intended_ruling (a b : IntendedUseReading) (i : IntendedRuling) :
    (intendedCommand a i).ruling = (intendedCommand b i).ruling := rfl

theorem permission_reports_stay_distinct :
    intendedUsage .qadiReport .permission ≠ intendedUsage .qadiArgument .permission := by decide

theorem recommendation_report_does_not_settle_permission :
    intendedUsage .karkhiRazi .permission = .unsettled := rfl

end Usul.CommandSchemata
