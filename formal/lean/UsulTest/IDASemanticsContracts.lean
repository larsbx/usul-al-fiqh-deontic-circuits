import UsulTest.IDASemantics

/-! Fixed propositions for semantic substitution, scope, and nonvacuity. -/

namespace UsulTest.IDASemanticsContracts

open Usul.IDA Usul.IDA.Substitution Usul.IDA.Semantics

example (σ : Sub Γ Δ) (τ : Sub Δ Θ) (ρ : Valuation Θ) :
    Valuation.pull (σ.then τ) ρ = Valuation.pull σ (Valuation.pull τ ρ) :=
  pull_comp σ τ ρ

example (h : History v) (f : Formula v Γ) (σ : Sub Γ Δ) (ρ : Valuation Δ) :
    Satisfies h ρ (f.subst σ) ↔ Satisfies h (Valuation.pull σ ρ) f :=
  satisfaction_subst h f σ ρ

example (h : History v) (premises : List (Formula v Γ)) (σ : Sub Γ Δ) (ρ : Valuation Δ) :
    ModelsPremises h ρ (premises.map (·.subst σ)) ↔
      ModelsPremises h (Valuation.pull σ ρ) premises :=
  premises_subst h premises σ ρ

example {premises : List (Formula v Γ)} {f : Formula v Γ}
    (d : Derives premises f) (h : History v) (ρ : Valuation Γ)
    (hp : ModelsPremises h ρ premises) : Satisfies h ρ f := sound d h ρ hp

example {x y : PremiseContext v} {f : Formula v y.variables}
    (a : PremiseArrow x y) (d : Derives y.premises f) (h : History v)
    (ρ : Valuation x.variables) (hp : ModelsPremises h ρ x.premises) :
    Satisfies h ρ (f.subst a.substitution) := sound_along a d h ρ hp

example (i : Interpreter r B) (d : Description r Γ) (σ : Sub Γ Δ) :
    i.supported (d.subst σ) ↔ i.supported d := supported_subst i d σ

example (i : Interpreter r B) (d : Description r Γ) (ρ : Valuation Γ) :
    (i.interpret d ρ).isSome ↔ i.supported d := interpretation_supported i d ρ

example (i : Interpreter r B) (d : Description r Γ) (σ : Sub Γ Δ) (ρ : Valuation Δ) :
    i.interpret (d.subst σ) ρ = i.interpret d (Valuation.pull σ ρ) :=
  interpret_subst i d σ ρ

example (i : Inquiry r Γ) (σ : Sub Γ Δ) (ρ : Valuation Δ) :
    (i.subst σ).ground ρ.grounding = i.ground (Valuation.pull σ ρ).grounding :=
  groundInquiry_subst i σ ρ

example (h : History v) (ρ : Valuation Γ) (p : Predicate v) (args : Args Γ p.val.arguments) :
    ¬ ModelsPremises h ρ [.atom p args true, .atom p args false] :=
  opposing_premises_incompatible h ρ p args

example (cases : List (Point v Γ)) (premises : List (Formula v Γ)) (f : Formula v Γ) :
    assess cases premises f = .robust ↔ compatible cases premises ≠ [] ∧
      ∀ p ∈ compatible cases premises, Satisfies p.history p.valuation f :=
  robust_iff cases premises f

end UsulTest.IDASemanticsContracts
