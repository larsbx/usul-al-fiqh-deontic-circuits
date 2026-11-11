import Usul.Cat.Basic
import Usul.Typing.IDASubstitution

/-! The verified substitution and premise arrow operations, packaged in the
existing category interface. Reindexing is contravariant in the context. -/

namespace Usul.Cat.IDASubstitution

open Usul.IDA.Substitution

def contexts : Cat where
  Obj := Variables
  Hom Δ Γ := Sub Γ Δ
  id _ := Sub.id
  comp f g := g.then f
  id_comp f := f.then_id
  comp_id f := Sub.id_then f
  assoc f g h := (Sub.assoc h g f).symm

def premiseContexts (v : Usul.IDA.Context.Vocabulary) : Cat where
  Obj := PremiseContext v
  Hom := PremiseArrow
  id := PremiseArrow.id
  comp := PremiseArrow.comp
  id_comp := PremiseArrow.id_comp
  comp_id := PremiseArrow.comp_id
  assoc := PremiseArrow.assoc

def forgetPremises (v : Usul.IDA.Context.Vocabulary) : Functor (premiseContexts v) contexts where
  obj := PremiseContext.variables
  map := PremiseArrow.substitution
  map_id _ := rfl
  map_comp _ _ := rfl

/-- Only the small types used by this syntax, with ordinary functions. -/
def smallTypes : Cat where
  Obj := Type
  Hom A B := A → B
  id _ := id
  comp f g := g ∘ f
  id_comp _ := rfl
  comp_id _ := rfl
  assoc _ _ _ := rfl

def descriptions (r : Usul.IDA.ActRegistry.Registry) : Functor contexts.op smallTypes where
  obj := Description r
  map σ d := d.subst σ
  map_id _ := funext Description.subst_id
  map_comp σ τ := funext (fun d => (d.subst_comp σ τ).symm)

def formulas (v : Usul.IDA.Context.Vocabulary) : Functor contexts.op smallTypes where
  obj := Formula v
  map σ f := f.subst σ
  map_id _ := funext Formula.subst_id
  map_comp σ τ := funext (fun f => (f.subst_comp σ τ).symm)

end Usul.Cat.IDASubstitution
