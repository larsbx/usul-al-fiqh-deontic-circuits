import Usul.Cat.IDASubstitution
import Usul.Typing.IDASemantics

/-! ACT-04 categorical adapters for the type-layer interpretation. The
valuation functor and meaning presheaves package the independently proved
substitution laws; naturality preserves their exact interpreter domains. -/

namespace Usul.Cat.IDASemantics

open Usul.IDA Usul.IDA.Substitution Usul.IDA.Semantics
open IDASubstitution (contexts smallTypes descriptions formulas)

def valuations : Functor contexts smallTypes where
  obj := Valuation
  map := Valuation.pull
  map_id _ := funext pull_id
  map_comp σ τ := funext (pull_comp τ σ)

def meanings (B : Type) : Functor contexts.op smallTypes where
  obj Γ := Valuation Γ → B
  map σ f := f ∘ Valuation.pull σ
  map_id _ := by
    funext f ρ
    exact congrArg f (pull_id ρ)
  map_comp σ τ := by
    funext f ρ
    exact congrArg f (pull_comp σ τ ρ)

theorem description_naturality (i : Interpreter r B) (d : Description r Γ) (σ : Sub Γ Δ) :
    i.interpret ((descriptions r).map σ d) =
      (meanings (Option B)).map σ (i.interpret d) :=
  funext (interpret_subst i d σ)

theorem formula_naturality (h : History v) (f : Formula v Γ) (σ : Sub Γ Δ) :
    (fun ρ : Valuation Δ => evaluate h ρ ((formulas v).map σ f)) =
      (meanings Bool).map σ (fun ρ => evaluate h ρ f) :=
  funext (evaluate_subst h f σ)

end Usul.Cat.IDASemantics
