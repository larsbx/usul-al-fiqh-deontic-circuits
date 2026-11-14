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
    ∀ s : RelabelSituation, s.enabled = true → s.feature ≠ .mubah →
      relabeledEncoder.judge s ≠ relabelEncoder.judge s :=
  relabel_changes_applicable_answer

theorem require_relabel_fixed_answer_iff :
    ∀ s : RelabelSituation, s.enabled = true →
      (relabeledEncoder.judge s = relabelEncoder.judge s ↔ s.feature = .mubah) :=
  relabel_fixed_answer_iff

theorem require_relabel_factorization :
    Schema.Factors relabelEncoder.judge relabelEncoder.proj ∧
      Schema.Factors relabeledEncoder.judge relabelEncoder.proj := relabel_factorization

theorem require_relabel_matrix : ∀ (enabled : Bool) (feature : Hukm) (noise : Bool),
    relabelCells enabled feature noise =
      [if enabled then encodeHukm feature + 1 else 0,
       if enabled then encodeHukm feature + 1 else 0,
       enabled.toNat, enabled.toNat,
       if enabled then encodeHukm feature + 1 else 0,
       if enabled then (4 - encodeHukm feature) + 1 else 0,
       1, (decide (enabled = false ∨ feature = .mubah)).toNat] := relabel_matrix

theorem require_unattested_known_nonempty_consistent :
    unattestedKnown ≠ [] ∧ Cat.factorsOnB unattestedFeature unattestedKnown = true ∧
      Cat.FactorsOn unattestedFeature unattestedKnown := unattested_known_nonempty_consistent

theorem require_unattested_candidate_factorization : ∀ knownValue unseenValue : Hukm,
    Schema.Factors (unattestedExtension knownValue unseenValue) unattestedFeature :=
  unattested_candidate_factorization

theorem require_unattested_candidate_agreement : ∀ knownValue unseenValue : Hukm,
    Qiyas.Agrees (unattestedExtension knownValue unseenValue) unattestedKnown ↔ knownValue = .wajib :=
  unattested_candidate_agreement

theorem require_unattested_feature_absent : ∀ noise : Bool,
    ∀ p ∈ unattestedKnown, unattestedFeature p.1 ≠ unattestedFeature (true, noise) :=
  unattested_feature_absent

theorem require_unattested_two_extensions : ∀ noise : Bool,
    Schema.Factors (unattestedExtension .wajib .mubah) unattestedFeature ∧
    Qiyas.Agrees (unattestedExtension .wajib .mubah) unattestedKnown ∧
    Schema.Factors (unattestedExtension .wajib .mandub) unattestedFeature ∧
    Qiyas.Agrees (unattestedExtension .wajib .mandub) unattestedKnown ∧
    unattestedExtension .wajib .mubah (true, noise) ≠
      unattestedExtension .wajib .mandub (true, noise) :=
  unattested_two_extensions

theorem require_unattested_free_answer : ∀ (noise : Bool) (answer : Hukm),
    ∃ H : UnattestedSituation → Hukm,
      Schema.Factors H unattestedFeature ∧ Qiyas.Agrees H unattestedKnown ∧ H (true, noise) = answer :=
  unattested_free_answer

theorem require_unattested_matrix : ∀ (knownValue unseenValue : Hukm) (feature noise : Bool),
    unattestedCells knownValue unseenValue feature noise =
      [encodeHukm (if feature then unseenValue else knownValue),
       1, (decide (knownValue = .wajib)).toNat, 1, (!feature).toNat,
       if feature then 2 else 4, if feature then 3 else 4, (!feature).toNat] :=
  unattested_matrix

theorem require_fivefold_sigma_not_boolean_complement :
    sigma .mubah = .mubah ∧ meet .mubah (sigma .mubah) ≠ .haram ∧
      join .mubah (sigma .mubah) ≠ .wajib := fivefold_sigma_not_boolean_complement

theorem require_fivefold_boolean_complements_iff : ∀ h : Hukm,
    (∃ k : Hukm, meet h k = .haram ∧ join h k = .wajib) ↔ h = .haram ∨ h = .wajib :=
  fivefold_boolean_complements_iff

theorem require_fivefold_binding_not_injective :
    Hukm.mandub ≠ .mubah ∧ Hukm.binding .mandub = Hukm.binding .mubah :=
  fivefold_binding_not_injective

theorem require_fivefold_matrix : ∀ h k : Hukm,
    fivefoldCells h k =
      [encodeHukm h, encodeHukm k, min (encodeHukm h) (encodeHukm k),
       max (encodeHukm h) (encodeHukm k), 4 - encodeHukm h, 4 - encodeHukm k,
       (decide (encodeHukm h = 2)).toNat,
       (decide ((encodeHukm h = 0 ∧ encodeHukm k = 4) ∨
         (encodeHukm h = 4 ∧ encodeHukm k = 0))).toNat] := fivefold_matrix

theorem require_relabeling_boundary :
    Cat.Typing.Reads relabelEncoder relabeledEncoder ∧
    Cat.Typing.Reads relabeledEncoder relabelEncoder ∧
    relabeledEncoder.proj = relabelEncoder.proj ∧
    (∀ s : RelabelSituation, relabeledEncoder.applies s = relabelEncoder.applies s) ∧
    relabeledEncoder.judge ⟨true, .mandub, false⟩ ≠ relabelEncoder.judge ⟨true, .mandub, false⟩ ∧
    (∀ s : RelabelSituation, s.enabled = true →
      (relabeledEncoder.judge s = relabelEncoder.judge s ↔ s.feature = .mubah)) ∧
    Schema.Factors relabelEncoder.judge relabelEncoder.proj ∧
    Schema.Factors relabeledEncoder.judge relabelEncoder.proj := relabeling_boundary

theorem require_unattested_boundary :
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
  unattested_boundary

theorem require_fivefold_boundary :
    sigma .mubah = .mubah ∧ meet .mubah (sigma .mubah) ≠ .haram ∧
    join .mubah (sigma .mubah) ≠ .wajib ∧
    (∀ h : Hukm, (∃ k : Hukm, meet h k = .haram ∧ join h k = .wajib) ↔
      h = .haram ∨ h = .wajib) ∧
    Hukm.mandub ≠ .mubah ∧ Hukm.binding .mandub = Hukm.binding .mubah := fivefold_boundary

end UsulTest.IDAProjectionContracts
