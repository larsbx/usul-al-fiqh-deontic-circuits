import UsulTest.IDAProjection

/-! Fixed propositions for the scoped projection and its loss witnesses. -/

namespace UsulTest.IDAProjectionContracts

open Usul Usul.IDA Usul.IDA.Projection
open UsulTest.IDAProjection

example (p : Rule) (x : Input r) :
    evaluate p x = evaluateProjected p (project p x) := projection_exact p x

example (p : Rule) : Schema.Factors (evaluate (r := r) p) (project p) := factors p

example (p : Rule) :
    ∃ Φ : Cat.Functor (Cat.ker (project (r := r) p)) (Cat.Cat.disc Outcome),
      Φ.obj = evaluate p :=
  Cat.IDAProjection.evaluation_functor p

example (p : Rule) {x y : Input r} (h : Equivalent p x y) :
    evaluate p x = evaluate p y := frame p h

example (p : Rule) : Equivalence (Equivalent (r := r) p) := equivalence p

example (p : Rule) {x y : Input r} (h : Equivalent p x y) :
    scope x.val = scope y.val := same_scope p h

example (x : Input r) :
    (scope x.val).inquiry.scope.target = .structured (core x) := projection_preserves_target x

example (p : Rule) {a b : Input r} (extra : List ActRegistry.Qualification)
    (hs : scope a.val = scope b.val)
    (hq : b.val.envelope.qualifications = a.val.envelope.qualifications ++ extra)
    (hp : extra.filter (matchesQuery p.support.key a.val.inquiry.accountable) = [])
    (he : extra.filter (matchesQuery p.exception.key a.val.inquiry.performer.referent) = []) :
    Equivalent p a b := irrelevant_append p extra hs hq hp he

example (p : Rule) (x : Input r) (h : evaluate p x = .fallback) :
    hasReport x.val.envelope.qualifications p.exception.key
      x.val.inquiry.performer.referent false = true := fallback_requires_negative p x h

example : ¬ Schema.Factors (evaluate (r := registry) (rule true)) core :=
  core_loses_relevant_reports

example : ¬ Schema.Factors (evaluate (r := registry) (rule true)) kind :=
  kind_does_not_factor

example :
    Equivalent (rule true) supportOnly irrelevantAddition ∧
      Context.resolve registry [irrelevantAddition.val] supportOnly.val = .error .stale :=
  equivalent_receipt_can_be_stale

example :
    evaluate (rule true) supportPlusException = evaluate (rule true) sameAnswerExtraRead ∧
      ¬ Equivalent (rule true) supportPlusException sameAnswerExtraRead :=
  equal_answers_do_not_imply_equivalence

theorem require_relabel_same_reads :
    Cat.Typing.Reads relabelEncoder relabeledEncoder ∧
      Cat.Typing.Reads relabeledEncoder relabelEncoder := relabel_same_reads

theorem require_relabel_same_projection :
    relabeledEncoder.proj = relabelEncoder.proj := relabel_same_projection

theorem require_relabel_same_applicability :
    ∀ s : RelabelSituation, relabeledEncoder.applies s = relabelEncoder.applies s :=
  relabel_same_applicability

theorem require_relabel_changes_applicable_answer :
    ∀ s : RelabelSituation, s.enabled = true → relabeledEncoder.judge s ≠ relabelEncoder.judge s :=
  relabel_changes_applicable_answer

theorem require_relabel_factorization :
    Schema.Factors relabelEncoder.judge relabelEncoder.proj ∧
      Schema.Factors relabeledEncoder.judge relabelEncoder.proj := relabel_factorization

theorem require_relabel_matrix : ∀ enabled feature noise : Bool,
    relabelCells enabled feature noise =
      [if enabled then feature.toNat + 1 else 0,
       if enabled then feature.toNat + 1 else 0,
       enabled.toNat, enabled.toNat,
       if enabled then feature.toNat + 1 else 0,
       if enabled then (!feature).toNat + 1 else 0,
       1, (!enabled).toNat] := relabel_matrix

theorem require_unattested_known_nonempty_consistent :
    unattestedKnown ≠ [] ∧ Cat.factorsOnB unattestedFeature unattestedKnown = true ∧
      Cat.FactorsOn unattestedFeature unattestedKnown := unattested_known_nonempty_consistent

theorem require_unattested_candidate_factorization : ∀ knownValue unseenValue : Bool,
    Schema.Factors (unattestedExtension knownValue unseenValue) unattestedFeature :=
  unattested_candidate_factorization

theorem require_unattested_candidate_agreement : ∀ knownValue unseenValue : Bool,
    Qiyas.Agrees (unattestedExtension knownValue unseenValue) unattestedKnown ↔ knownValue = true :=
  unattested_candidate_agreement

theorem require_unattested_feature_absent : ∀ noise : Bool,
    ∀ p ∈ unattestedKnown, unattestedFeature p.1 ≠ unattestedFeature (true, noise) :=
  unattested_feature_absent

theorem require_unattested_two_extensions : ∀ noise : Bool,
    Schema.Factors (unattestedExtension true false) unattestedFeature ∧
    Qiyas.Agrees (unattestedExtension true false) unattestedKnown ∧
    Schema.Factors (unattestedExtension true true) unattestedFeature ∧
    Qiyas.Agrees (unattestedExtension true true) unattestedKnown ∧
    unattestedExtension true false (true, noise) ≠ unattestedExtension true true (true, noise) :=
  unattested_two_extensions

theorem require_unattested_free_answer : ∀ noise answer : Bool,
    ∃ H : UnattestedSituation → Bool,
      Schema.Factors H unattestedFeature ∧ Qiyas.Agrees H unattestedKnown ∧ H (true, noise) = answer :=
  unattested_free_answer

theorem require_unattested_matrix : ∀ knownValue unseenValue feature noise : Bool,
    unattestedCells knownValue unseenValue feature noise =
      [(if feature then unseenValue else knownValue).toNat,
       1, knownValue.toNat, 1, (!feature).toNat, (!feature).toNat, 1, (!feature).toNat] :=
  unattested_matrix

theorem require_relabeling_boundary :
    Cat.Typing.Reads relabelEncoder relabeledEncoder ∧
    Cat.Typing.Reads relabeledEncoder relabelEncoder ∧
    relabeledEncoder.proj = relabelEncoder.proj ∧
    (∀ s : RelabelSituation, relabeledEncoder.applies s = relabelEncoder.applies s) ∧
    relabeledEncoder.judge ⟨true, false, false⟩ ≠ relabelEncoder.judge ⟨true, false, false⟩ ∧
    Schema.Factors relabelEncoder.judge relabelEncoder.proj ∧
    Schema.Factors relabeledEncoder.judge relabelEncoder.proj := relabeling_boundary

theorem require_unattested_boundary :
    unattestedKnown ≠ [] ∧ Cat.FactorsOn unattestedFeature unattestedKnown ∧
    Schema.Factors (unattestedExtension true false) unattestedFeature ∧
    Qiyas.Agrees (unattestedExtension true false) unattestedKnown ∧
    Schema.Factors (unattestedExtension true true) unattestedFeature ∧
    Qiyas.Agrees (unattestedExtension true true) unattestedKnown ∧
    (∀ noise : Bool,
      unattestedExtension true false (true, noise) ≠ unattestedExtension true true (true, noise)) :=
  unattested_boundary

end UsulTest.IDAProjectionContracts
