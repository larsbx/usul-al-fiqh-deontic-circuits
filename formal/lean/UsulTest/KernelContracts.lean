import Usul

/-! Tests of semantic and admission boundaries. No corpus interpretation is adopted. -/

namespace UsulTest.KernelContracts

open Usul Usul.Grounded Usul.CommandSchemata

-- Empty frameworks, cycles, duplicates and a multi-step defense chain.
#guard checkedGrounded 0 [] == some []
#guard checkedGrounded 1 [] == some [0]
#guard checkedGrounded 1 [(0, 0)] == some []
#guard checkedGrounded 2 [(0, 1), (1, 0)] == some []
#guard checkedGrounded 3 [(0, 1), (1, 2), (2, 0)] == some []
#guard checkedGrounded 3 [(0, 1), (0, 1), (1, 2)] == some [0, 2]
#guard checkedGrounded 6 [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)] == some [0, 2, 4]
-- Every endpoint is checked. An empty vertex set cannot carry an edge.
#guard checkedGrounded 0 [(0, 0)] == none
#guard checkedGrounded 1 [(2, 0)] == none
#guard checkedGrounded 1 [(0, 2)] == none

-- These statements apply to all well-formed frameworks, not a sampled bound.
example {n : Nat} {edges : List (Nat × Nat)} (wf : WellFormed n edges) :
    Dung.Complete (attack (n := n) edges) (extension (grounded n edges)) :=
  grounded_complete wf

example {n : Nat} {edges : List (Nat × Nat)} {S : List Nat}
    (ok : checkedGrounded n edges = some S) {E : Dung.ASet (Fin n)}
    (complete : Dung.Complete (attack edges) E) : Dung.Subset (extension S) E :=
  checkedGrounded_least ok complete

-- Evaluation alone supplies neither the command context nor admissibility.
def rejectAll : CommandPremises := ⟨fun _ => False, False, False⟩
def rejectQarina : CommandPremises := ⟨fun _ => False, True, False⟩

-- Even a true input flag cannot manufacture the author's factual premise.
example : CommandDerivation (.propheticAct .authorConditional true) .literal :=
  .propheticAct (.authorInference rfl)

example : ¬ Nonempty (AdmittedCommand rejectAll
    (.propheticAct .authorConditional true) .literal) :=
  no_author_admission_without_imitation (fun h => h)

-- A caller with actual external evidence can admit the conditional trace.
example (p : CommandPremises) (imitation : p.imitationEstablished) :
    AdmittedCommand p (.propheticAct .authorConditional true) .literal :=
  ⟨fun _ => imitation, .propheticAct (.authorInference rfl)⟩

-- The unanswered branch requires no positive imitation claim.
example : AdmittedCommand rejectAll (.propheticAct .authorConditional false) .unsettled :=
  ⟨fun impossible => Bool.noConfusion impossible, .propheticAct (.authorUnanswered rfl)⟩

example : CommandDerivation (.obligation .qadi .wujubLabel (some .mandub)) .mandub :=
  .obligation (.indication rfl)

example : ¬ Nonempty (AdmittedCommand rejectQarina
    (.obligation .qadi .wujubLabel (some .mandub)) .mandub) := by
  apply no_admission_without_premises
  rintro ⟨_, ha⟩
  exact ha .mandub rfl

example : ¬ Nonempty (AdmittedCommand rejectAll
    (.obligation .abuBarakat .fardLabel none) .wajib) := by
  apply no_admission_without_premises
  exact fun hp => hp.1

example : ¬ Nonempty (AdmittedCommand rejectAll
    (.intended .qadiReport .permission) ⟨.literal, .mubah⟩) := by
  apply no_admission_without_premises
  exact fun h => h

example : ¬ Nonempty (NonverbalDerivation .jamiWriting .gesture .literal) :=
  no_positive_gesture_derivation

example : ¬ Nonempty (PropheticActDerivation .authorConditional false .literal) := by
  rintro ⟨d⟩
  have h := author_literal_requires_imitation d
  cases h

-- Conflicting usage reports retain different derivations but the same given ruling.
def permissionReport : IntendedDerivation .qadiReport .permission ⟨.literal, .mubah⟩ :=
  .qadiReport .permission
def permissionArgument : IntendedDerivation .qadiArgument .permission ⟨.figurative, .mubah⟩ :=
  .qadiPermissionArgument

example : (IntendedCommand.mk .literal .mubah).ruling =
    (IntendedCommand.mk .figurative .mubah).ruling :=
  (derivation_preserves_intended_ruling permissionReport).trans
    (derivation_preserves_intended_ruling permissionArgument).symm

-- A result is unique only after fixing its reading and all inputs.
example {q : CommandRequest} {a b : q.Result}
    (da : CommandDerivation q a) (db : CommandDerivation q b) : a = b :=
  CommandDerivation.deterministic da db

end UsulTest.KernelContracts
