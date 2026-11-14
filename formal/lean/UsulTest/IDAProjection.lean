import Usul.Cat.IDAProjection
import Usul.Cat.Typing
import UsulTest.IDASubstitution

/-! Synthetic guard observations over the ACT-02 grounded repayment. The report
and scope rows satisfy ACT-01 snapshot shape. Separate five-valued `Hukm` fixtures
isolate answer relabeling and underdetermination on unseen feature classes,
and distinguish omission duality from Boolean complementation. -/

namespace UsulTest.IDAProjection

open Usul Usul.IDA Usul.IDA.Projection
open IDAActRegistry (payer recipient)
open IDASubstitution (groundedSnapshot repayment)

def nextDefinition : ActRegistry.Definition :=
  { repayment with key := { repayment.key with version := 2 } }

def registry : ActRegistry.Registry := ⟨1, [repayment, nextDefinition]⟩

def supportDef : Context.PredicateDefinition := IDAContext.predicate

def exceptionDef : Context.PredicateDefinition :=
  ⟨⟨⟨"synthetic.predicate", "guard"⟩, 1⟩, [.person]⟩

def otherVersion : Context.PredicateDefinition :=
  { exceptionDef with key := { exceptionDef.key with version := 2 } }

def unrelatedDef : Context.PredicateDefinition :=
  ⟨⟨⟨"synthetic.predicate", "unrelated"⟩, 1⟩, [.person]⟩

def vocabulary : Context.Vocabulary :=
  { IDASubstitution.vocabulary with definitions := [supportDef, exceptionDef, otherVersion, unrelatedDef] }

def base : Context.Snapshot := { groundedSnapshot with vocabulary := vocabulary }

def rule (enabled : Bool) : Rule :=
  ⟨scope base, ⟨⟨supportDef, by decide⟩, rfl⟩, ⟨⟨exceptionDef, by decide⟩, rfl⟩, by decide, enabled⟩

def report (d : Context.PredicateDefinition) (person : EntityRef) (positive : Bool)
    (mention : String := "m1") : ActRegistry.Qualification :=
  ⟨d.key.symbol, d.key.version, [person], positive, ⟨"synthetic.mention", mention⟩⟩

def rowMask (mask : Nat) : List ActRegistry.Qualification :=
  ([report supportDef recipient true, report supportDef recipient false,
    report exceptionDef payer true, report exceptionDef payer false].zipIdx).filterMap
      fun (q, i) => if mask.testBit i then some q else none

def rows (mask noise : Nat) : List ActRegistry.Qualification :=
  let qs := rowMask mask
  match noise with
  | 1 => qs ++ [report unrelatedDef recipient true]
  | 2 => qs ++ [report otherVersion payer true]
  | 3 => qs ++ [report exceptionDef recipient true]
  | 4 => qs ++ qs.map (fun q => { q with mention := ⟨"synthetic.mention", "m2"⟩ })
  | 5 => qs.reverse
  | _ => qs

def scopeVariant (shape : Fin 15) : Context.Snapshot := match shape.val with
  | 1 =>
    let other := base.opportunity.map fun o => { o with occurrence := ⟨"synthetic.event", "two"⟩ }
    IDAContext.synchronize { base with opportunity := other }
  | 2 => { base with inquiry := { base.inquiry with questionId := 2 } }
  | 3 => IDAContext.setMetadata base fun m => { m with profileVersion := 2 }
  | 4 => { base with admissionPolicy := { base.admissionPolicy with version := 2 } }
  | 5 => { base with time := { base.time with cutoff := 21 } }
  | 6 => { base with inquiry := { base.inquiry with accountable := payer } }
  | 7 => { base with inquiry := { base.inquiry with performer := ⟨"creditor", recipient⟩ } }
  | 8 => IDAContext.setMetadata base fun m => { m with interpretationVersion := 2 }
  | 9 => { base with envelope := { base.envelope with key := nextDefinition.key } }
  | 10 => IDAContext.setMetadata base fun m => { m with contextId := 2 }
  | 11 => { base with time := { base.time with clockVersion := 2 } }
  | 12 => { base with vocabulary := { vocabulary with pin := { vocabulary.pin with version := 2 } } }
  | 13 =>
    let action := { base.envelope.action with
      operands := [⟨"debtor", recipient⟩, ⟨"creditor", payer⟩, ⟨"debt", IDASubstitution.debt⟩] }
    IDAContext.synchronize { base with
      envelope := { base.envelope with action := action }
      inquiry := { base.inquiry with performer := ⟨"debtor", recipient⟩ } }
  | 14 => IDAContext.setMetadata base fun m => { m with effectiveAt := 11 }
  | _ => base

def snapshot (shape : Fin 15) (mask noise : Nat) : Context.Snapshot :=
  let s := scopeVariant shape
  let updated := if noise = 0 then s else
    { s with
      key := { s.key with version := s.key.version + 1 }
      envelope := { s.envelope with context := { s.envelope.context with evidenceRevision := 2 } } }
  { updated with envelope := { updated.envelope with qualifications := rows mask noise } }

/-- The exporter reports malformed input shapes explicitly. Named controls and the
independent table require the specified finite domain to be well formed. -/
def input (shape : Fin 15) (mask noise : Nat) : Option (Input registry) :=
  let s := snapshot shape mask noise
  if h : s.WellFormed registry then some ⟨s, h⟩ else none

def baseline (mask : Nat) : Option (Input registry) := input 0 mask 0

def code : Outcome → Nat
  | .outsideScope => 0 | .unresolved => 1 | .fallback => 2 | .negativeSupport => 3
  | .positiveSupport => 4 | .contestedSupport => 5 | .exception => 6 | .contestedException => 7

def caseCells (enabled : Bool) (shape : Fin 15) (mask noise : Nat) : List Nat :=
  match input shape mask noise, baseline mask with
  | some x, some y =>
    let r := rule enabled
    let p := project r x
    [1, code (evaluate r x), code (evaluateProjected r p),
     p.support.positive.toNat, p.support.negative.toNat,
     p.exception.positive.toNat, p.exception.negative.toNat,
     (decide (Equivalent r x y)).toNat, (decide (core x = core y)).toNat,
     (decide (kind x = kind y)).toNat]
  | _, _ => List.replicate 10 0

def pairCells (enabled : Bool) (left right : Nat) : List Nat :=
  match baseline left, input 0 right 1 with
  | some a, some b =>
    let r := rule enabled
    [(decide (Equivalent r a b)).toNat, (decide (evaluate r a = evaluate r b)).toNat,
     (decide (core a = core b)).toNat, (decide (kind a = kind b)).toNat]
  | _, _ => List.replicate 4 0

def supportOnly : Input registry := ⟨snapshot 0 1 0, by decide⟩
def supportPlusException : Input registry := ⟨snapshot 0 5 0, by decide⟩
def irrelevantAddition : Input registry := ⟨snapshot 0 1 1, by decide⟩
def distinctOccurrence : Input registry := ⟨snapshot 1 1 0, by decide⟩
def sameAnswerExtraRead : Input registry := ⟨snapshot 0 7 0, by decide⟩

theorem hidden_exception :
    supportPlusException.val.envelope.qualifications =
      supportOnly.val.envelope.qualifications ++ [report exceptionDef payer true] ∧
    (project (rule true) supportOnly).support = (project (rule true) supportPlusException).support ∧
    evaluate (rule true) supportOnly = .positiveSupport ∧
    evaluate (rule true) supportPlusException = .exception := by decide

theorem core_loses_relevant_reports :
    ¬ Schema.Factors (evaluate (r := registry) (rule true)) core := by
  intro h
  have he := h supportOnly supportPlusException (by decide)
  rw [hidden_exception.2.2.1, hidden_exception.2.2.2] at he
  contradiction

theorem kind_loses_occurrence :
    kind supportOnly = kind distinctOccurrence ∧
    core supportOnly ≠ core distinctOccurrence ∧
    evaluate (rule true) distinctOccurrence = .outsideScope := by decide

theorem kind_does_not_factor :
    ¬ Schema.Factors (evaluate (r := registry) (rule true)) kind := by
  intro h
  have he := h supportOnly distinctOccurrence kind_loses_occurrence.1
  rw [hidden_exception.2.2.1, kind_loses_occurrence.2.2] at he
  contradiction

theorem equivalent_receipt_can_be_stale :
    Equivalent (rule true) supportOnly irrelevantAddition ∧
    Context.resolve registry [irrelevantAddition.val] supportOnly.val = .error .stale := by decide

theorem equal_answers_do_not_imply_equivalence :
    evaluate (rule true) supportPlusException = evaluate (rule true) sameAnswerExtraRead ∧
    ¬ Equivalent (rule true) supportPlusException sameAnswerExtraRead := by decide

theorem explicit_negative_only :
    caseCells true 0 0 0 = [1,1,1,0,0,0,0,1,1,1] ∧
    caseCells true 0 8 0 = [1,2,2,0,0,0,1,1,1,1] ∧
    caseCells false 0 8 0 = [1,1,1,0,0,0,1,1,1,1] := by decide

/-! ## Relabeling preserves reads, not the selected answer

These synthetic cases use the actual five-valued ruling carrier. No case supplies
a new source-backed ruling. The encoder reads applicability and a ruling-valued
feature, ignoring noise; relabeling uses the existing omission duality. -/

structure RelabelSituation where
  enabled : Bool
  feature : Hukm
  noise : Bool
  deriving DecidableEq, Repr

def relabelEncoder : Usul.Typing.Typed RelabelSituation Hukm where
  Local := Hukm
  proj := fun s => if s.enabled then some s.feature else none
  embed := fun feature => ⟨true, feature, false⟩
  run := id
  proj_embed := fun _ => rfl

def relabeledEncoder : Usul.Typing.Typed RelabelSituation Hukm :=
  relabelEncoder.mapRun sigma

def optionHukmCode : Option Hukm → Nat
  | none => 0
  | some h => encodeHukm h + 1

def relabelCells (enabled : Bool) (feature : Hukm) (noise : Bool) : List Nat :=
  let s : RelabelSituation := ⟨enabled, feature, noise⟩
  let originalProjection : Option Hukm := relabelEncoder.proj s
  let relabeledProjection : Option Hukm := relabeledEncoder.proj s
  [optionHukmCode originalProjection, optionHukmCode relabeledProjection,
   (relabelEncoder.applies s).toNat, (relabeledEncoder.applies s).toNat,
   optionHukmCode (relabelEncoder.judge s), optionHukmCode (relabeledEncoder.judge s),
   (decide (originalProjection = relabeledProjection)).toNat,
   (decide (relabelEncoder.judge s = relabeledEncoder.judge s)).toNat]

theorem relabel_same_reads :
    Cat.Typing.Reads relabelEncoder relabeledEncoder ∧
      Cat.Typing.Reads relabeledEncoder relabelEncoder :=
  Cat.Typing.Reads.mapRun sigma relabelEncoder

theorem relabel_same_projection : relabeledEncoder.proj = relabelEncoder.proj := rfl

theorem relabel_same_applicability (s : RelabelSituation) :
    relabeledEncoder.applies s = relabelEncoder.applies s := rfl

theorem relabel_changes_applicable_answer (s : RelabelSituation) (h : s.enabled = true)
    (hm : s.feature ≠ .mubah) :
    relabeledEncoder.judge s ≠ relabelEncoder.judge s := by
  rcases s with ⟨enabled, feature, noise⟩
  cases enabled <;> cases feature <;>
    simp_all [relabelEncoder, relabeledEncoder, Usul.Typing.Typed.judge,
      Usul.Typing.Typed.mapRun, sigma, Hukm.σ]

theorem relabel_fixed_answer_iff (s : RelabelSituation) (h : s.enabled = true) :
    relabeledEncoder.judge s = relabelEncoder.judge s ↔ s.feature = .mubah := by
  simpa [relabeledEncoder, relabelEncoder, Usul.Typing.Typed.judge,
    Usul.Typing.Typed.mapRun, h] using sigma_fixed_iff s.feature

theorem relabel_factorization :
    Schema.Factors relabelEncoder.judge relabelEncoder.proj ∧
      Schema.Factors relabeledEncoder.judge relabelEncoder.proj :=
  ⟨Cat.Typing.judge_factors relabelEncoder,
    Cat.Typing.judge_mapRun_factors sigma relabelEncoder⟩

theorem relabel_matrix : ∀ (enabled : Bool) (feature : Hukm) (noise : Bool),
    relabelCells enabled feature noise =
      [if enabled then encodeHukm feature + 1 else 0,
       if enabled then encodeHukm feature + 1 else 0,
       enabled.toNat, enabled.toNat,
       if enabled then encodeHukm feature + 1 else 0,
       if enabled then (4 - encodeHukm feature) + 1 else 0,
       1, (decide (enabled = false ∨ feature = .mubah)).toNat] := by
  intro enabled feature noise
  cases enabled <;> cases feature <;> cases noise <;> decide

/-! ## Consistency on known cases leaves an unseen feature open

The known data contain both noisy versions of feature `false`, labeled `wajib`.
Every candidate below factors globally through the feature. Only candidates that
also agree with these nonempty data are admissible extensions of this fixture. -/

abbrev UnattestedSituation := Bool × Bool

def unattestedFeature (s : UnattestedSituation) : Bool := s.1

def unattestedKnown : Qiyas.Known UnattestedSituation Hukm :=
  [((false, false), .wajib), ((false, true), .wajib)]

def unattestedCases : List UnattestedSituation :=
  [(false, false), (false, true), (true, false), (true, true)]

def unattestedExtension (knownValue unseenValue : Hukm) (s : UnattestedSituation) : Hukm :=
  if unattestedFeature s then unseenValue else knownValue

def unattestedAgreementB (knownValue unseenValue : Hukm) : Bool :=
  unattestedKnown.all fun p => unattestedExtension knownValue unseenValue p.1 == p.2

def unattestedFactorizationB (knownValue unseenValue : Hukm) : Bool :=
  unattestedCases.all fun left => unattestedCases.all fun right =>
    !(unattestedFeature left == unattestedFeature right) ||
      unattestedExtension knownValue unseenValue left == unattestedExtension knownValue unseenValue right

def unattestedCells (knownValue unseenValue : Hukm) (feature noise : Bool) : List Nat :=
  let s : UnattestedSituation := (feature, noise)
  let first := unattestedExtension .wajib .mubah s
  let second := unattestedExtension .wajib .mandub s
  [encodeHukm (unattestedExtension knownValue unseenValue s),
   (Cat.factorsOnB unattestedFeature unattestedKnown).toNat,
   (unattestedAgreementB knownValue unseenValue).toNat,
   (unattestedFactorizationB knownValue unseenValue).toNat,
   (unattestedKnown.any fun p => unattestedFeature p.1 == unattestedFeature s).toNat,
   encodeHukm first, encodeHukm second, (decide (first = second)).toNat]

theorem unattested_known_nonempty_consistent :
    unattestedKnown ≠ [] ∧ Cat.factorsOnB unattestedFeature unattestedKnown = true ∧
      Cat.FactorsOn unattestedFeature unattestedKnown :=
  ⟨by decide, by decide, Cat.factorsOnB_iff.1 (by decide)⟩

theorem unattested_candidate_factorization (knownValue unseenValue : Hukm) :
    Schema.Factors (unattestedExtension knownValue unseenValue) unattestedFeature :=
  Schema.Factors.of_eq (fun f => if f then unseenValue else knownValue) (fun _ => rfl)

theorem unattested_candidate_agreement (knownValue unseenValue : Hukm) :
    Qiyas.Agrees (unattestedExtension knownValue unseenValue) unattestedKnown ↔ knownValue = .wajib := by
  constructor
  · intro h
    exact h ((false, false), .wajib) (by decide)
  · intro h p hp
    rcases List.mem_cons.mp hp with hp | hp
    · subst p
      exact h
    · have he : p = ((false, true), .wajib) := List.eq_of_mem_singleton hp
      subst p
      exact h

theorem unattested_feature_absent (noise : Bool) :
    ∀ p ∈ unattestedKnown, unattestedFeature p.1 ≠ unattestedFeature (true, noise) := by
  intro p hp
  rcases List.mem_cons.mp hp with hp | hp
  · subst p
    exact Bool.false_ne_true
  · have he : p = ((false, true), .wajib) := List.eq_of_mem_singleton hp
    subst p
    exact Bool.false_ne_true

theorem unattested_two_extensions (noise : Bool) :
    Schema.Factors (unattestedExtension .wajib .mubah) unattestedFeature ∧
    Qiyas.Agrees (unattestedExtension .wajib .mubah) unattestedKnown ∧
    Schema.Factors (unattestedExtension .wajib .mandub) unattestedFeature ∧
    Qiyas.Agrees (unattestedExtension .wajib .mandub) unattestedKnown ∧
    unattestedExtension .wajib .mubah (true, noise) ≠
      unattestedExtension .wajib .mandub (true, noise) :=
  ⟨unattested_candidate_factorization .wajib .mubah,
    (unattested_candidate_agreement .wajib .mubah).2 rfl,
    unattested_candidate_factorization .wajib .mandub,
    (unattested_candidate_agreement .wajib .mandub).2 rfl,
    by change Hukm.mubah ≠ Hukm.mandub; decide⟩

theorem unattested_free_answer (noise : Bool) (answer : Hukm) :
    ∃ H : UnattestedSituation → Hukm,
      Schema.Factors H unattestedFeature ∧ Qiyas.Agrees H unattestedKnown ∧ H (true, noise) = answer :=
  Cat.unattested_free unattested_known_nonempty_consistent.2.2 (unattested_feature_absent noise) answer

theorem unattested_matrix : ∀ (knownValue unseenValue : Hukm) (feature noise : Bool),
    unattestedCells knownValue unseenValue feature noise =
      [encodeHukm (if feature then unseenValue else knownValue),
       1, (decide (knownValue = .wajib)).toNat, 1, (!feature).toNat,
       if feature then 2 else 4, if feature then 3 else 4, (!feature).toNat] := by
  intro knownValue unseenValue feature noise
  cases knownValue <;> cases unseenValue <;> cases feature <;> cases noise <;> decide

/-! ## The actual fivefold lattice is not Boolean

The existing wire order enumerates the carrier; it is not a numerical score.
`sigma` is the omission duality. Only the endpoints have Boolean complements. -/

def fivefoldValues : List Hukm := [.haram, .makruh, .mubah, .mandub, .wajib]

def fivefoldCells (h k : Hukm) : List Nat :=
  [encodeHukm h, encodeHukm k, encodeHukm (meet h k), encodeHukm (join h k),
   encodeHukm (sigma h), encodeHukm (sigma k), (decide (sigma h = h)).toNat,
   (decide (meet h k = .haram ∧ join h k = .wajib)).toNat]

theorem fivefold_sigma_not_boolean_complement :
    sigma .mubah = .mubah ∧ meet .mubah (sigma .mubah) ≠ .haram ∧
      join .mubah (sigma .mubah) ≠ .wajib := by decide

theorem fivefold_boolean_complements_iff (h : Hukm) :
    (∃ k : Hukm, meet h k = .haram ∧ join h k = .wajib) ↔ h = .haram ∨ h = .wajib := by
  constructor
  · rintro ⟨k, hk⟩
    cases h <;> cases k <;> revert hk <;> decide
  · rintro (rfl | rfl)
    · exact ⟨.wajib, by decide⟩
    · exact ⟨.haram, by decide⟩

theorem fivefold_binding_not_injective :
    Hukm.mandub ≠ .mubah ∧ Hukm.binding .mandub = Hukm.binding .mubah := by decide

theorem fivefold_matrix (h k : Hukm) :
    fivefoldCells h k =
      [encodeHukm h, encodeHukm k, min (encodeHukm h) (encodeHukm k),
       max (encodeHukm h) (encodeHukm k), 4 - encodeHukm h, 4 - encodeHukm k,
       (decide (encodeHukm h = 2)).toNat,
       (decide ((encodeHukm h = 0 ∧ encodeHukm k = 4) ∨
         (encodeHukm h = 4 ∧ encodeHukm k = 0))).toNat] := by
  cases h <;> cases k <;> decide

/-- Terminal contract bundle: mutual reads does not identify the output function. -/
theorem relabeling_boundary :
    Cat.Typing.Reads relabelEncoder relabeledEncoder ∧
    Cat.Typing.Reads relabeledEncoder relabelEncoder ∧
    relabeledEncoder.proj = relabelEncoder.proj ∧
    (∀ s : RelabelSituation, relabeledEncoder.applies s = relabelEncoder.applies s) ∧
    relabeledEncoder.judge ⟨true, .mandub, false⟩ ≠ relabelEncoder.judge ⟨true, .mandub, false⟩ ∧
    (∀ s : RelabelSituation, s.enabled = true →
      (relabeledEncoder.judge s = relabelEncoder.judge s ↔ s.feature = .mubah)) ∧
    Schema.Factors relabelEncoder.judge relabelEncoder.proj ∧
    Schema.Factors relabeledEncoder.judge relabelEncoder.proj :=
  ⟨relabel_same_reads.1, relabel_same_reads.2, relabel_same_projection,
    relabel_same_applicability, relabel_changes_applicable_answer _ rfl (by decide),
    relabel_fixed_answer_iff,
    relabel_factorization.1, relabel_factorization.2⟩

/-- Terminal contract bundle: consistency on populated data does not select an unseen answer. -/
theorem unattested_boundary :
    unattestedKnown ≠ [] ∧ Cat.FactorsOn unattestedFeature unattestedKnown ∧
    Schema.Factors (unattestedExtension .wajib .mubah) unattestedFeature ∧
    Qiyas.Agrees (unattestedExtension .wajib .mubah) unattestedKnown ∧
    Schema.Factors (unattestedExtension .wajib .mandub) unattestedFeature ∧
    Qiyas.Agrees (unattestedExtension .wajib .mandub) unattestedKnown ∧
    (∀ noise : Bool,
      unattestedExtension .wajib .mubah (true, noise) ≠
        unattestedExtension .wajib .mandub (true, noise)) ∧
    (∀ (noise : Bool) (answer : Hukm), ∃ H : UnattestedSituation → Hukm,
      Schema.Factors H unattestedFeature ∧ Qiyas.Agrees H unattestedKnown ∧ H (true, noise) = answer) :=
  ⟨unattested_known_nonempty_consistent.1, unattested_known_nonempty_consistent.2.2,
    unattested_candidate_factorization .wajib .mubah,
    (unattested_candidate_agreement .wajib .mubah).2 rfl,
    unattested_candidate_factorization .wajib .mandub,
    (unattested_candidate_agreement .wajib .mandub).2 rfl,
    fun noise => (unattested_two_extensions noise).2.2.2.2, unattested_free_answer⟩

/-- Terminal contract bundle separating the fivefold carrier from Boolean collapse. -/
theorem fivefold_boundary :
    sigma .mubah = .mubah ∧ meet .mubah (sigma .mubah) ≠ .haram ∧
    join .mubah (sigma .mubah) ≠ .wajib ∧
    (∀ h : Hukm, (∃ k : Hukm, meet h k = .haram ∧ join h k = .wajib) ↔
      h = .haram ∨ h = .wajib) ∧
    Hukm.mandub ≠ .mubah ∧ Hukm.binding .mandub = Hukm.binding .mubah :=
  ⟨fivefold_sigma_not_boolean_complement.1,
    fivefold_sigma_not_boolean_complement.2.1,
    fivefold_sigma_not_boolean_complement.2.2,
    fivefold_boolean_complements_iff,
    fivefold_binding_not_injective.1, fivefold_binding_not_injective.2⟩

end UsulTest.IDAProjection
