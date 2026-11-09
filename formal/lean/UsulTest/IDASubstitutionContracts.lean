import UsulTest.IDASubstitution

/-! Fixed statements for the ACT-02 verification gate. -/

namespace UsulTest.IDASubstitutionContracts

open Usul.IDA Usul.IDA.Substitution

example (σ : Sub Γ Δ) (τ : Sub Δ Θ) (υ : Sub Θ Ξ) :
    (σ.then τ).then υ = σ.then (τ.then υ) := Sub.assoc σ τ υ

example (args : Args Γ ks) (slot : Var ks k) (σ : Sub Γ Δ) :
    (args.subst σ).get slot = (args.get slot).subst σ := Args.get_subst args slot σ

example (r : Rigid k) (σ : Sub Γ Δ) : (Term.rigid r).subst σ = .rigid r :=
  Term.rigid_preserved r σ

example (d : Description r Γ) : d.subst Sub.id = d := Description.subst_id d

example (d : Description r Γ) (σ : Sub Γ Δ) (τ : Sub Δ Θ) :
    (d.subst σ).subst τ = d.subst (σ.then τ) := Description.subst_comp d σ τ

example (d : Description r Γ) (σ : Sub Γ Δ) :
    (d.subst σ).schema = d.schema := Description.schema_preserved d σ

example (d : Description r Γ) (σ : Sub Γ Δ) (ρ : Grounding Δ) :
    ((d.subst σ).ground ρ).WellFormed := Description.subst_wellFormed d σ ρ

example (i : Inquiry r Γ) (σ : Sub Γ Δ) (ρ : Grounding Δ) :
    (i.subst σ).ground ρ = i.ground (σ.then ρ) := Inquiry.ground_comp i σ ρ

example (f : Formula v Γ) : f.subst Sub.id = f := Formula.subst_id f

example (f : Formula v Γ) (σ : Sub Γ Δ) (τ : Sub Δ Θ) :
    (f.subst σ).subst τ = f.subst (σ.then τ) := Formula.subst_comp f σ τ

example {P : List (Formula v Γ)} {f : Formula v Γ}
    (h : Derives P f) (σ : Sub Γ Δ) :
    Derives (P.map (·.subst σ)) (f.subst σ) := Derives.subst h σ

example {P Q : List (Formula v Γ)} {f : Formula v Γ}
    (h : Derives P f) (lift : ∀ p ∈ P, Derives Q p) :
    Derives Q f := Derives.cut h lift

example {P : List (Formula v Γ)} {f : Formula v Γ} :
    Derives P f ↔ ∀ a ∈ f.atoms, a ∈ P.flatMap Formula.atoms := Derives.iff_atoms

example (x y : PremiseContext v) (σ : Sub y.variables x.variables) :
    (PremiseArrow.check x y σ).isSome ↔
      ∀ f ∈ y.premises, Derives x.premises (f.subst σ) := PremiseArrow.check_iff x y σ

example {v} {x y z w : PremiseContext v} (f : PremiseArrow x y) (g : PremiseArrow y z)
    (h : PremiseArrow z w) : (f.comp g).comp h = f.comp (g.comp h) :=
  PremiseArrow.assoc f g h

end UsulTest.IDASubstitutionContracts
