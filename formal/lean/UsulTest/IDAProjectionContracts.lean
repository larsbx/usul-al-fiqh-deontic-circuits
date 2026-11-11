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

end UsulTest.IDAProjectionContracts
