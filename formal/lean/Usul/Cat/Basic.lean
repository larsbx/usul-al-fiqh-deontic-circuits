/-!
# Categories and functors (roadmap §0 carrier «category theory», Phase IV)

The roadmap gives category theory one job: compositional *specification*, checked through Lean
statements. This module is the minimal core that job needs, kept free of Mathlib like the rest of
the kernel: small categories, the opposite, thin categories of preorders, functors, and
up-sets (the object part of a cosieve).

Every scale in the kernel (ḥukm valence, epistemic grade, al-Albānī's verdicts) is a preorder,
so its category is thin: at most one arrow between two objects. In a thin category the functor
laws hold automatically (`Functor.intoThin`), so a *monotone map is a functor*, and the seams
between the sciences become functors.
-/

namespace Usul.Cat

/-- A small category. -/
structure Cat where
  Obj : Type
  Hom : Obj → Obj → Type
  id : ∀ a, Hom a a
  comp : ∀ {a b c}, Hom a b → Hom b c → Hom a c
  id_comp : ∀ {a b} (f : Hom a b), comp (id a) f = f
  comp_id : ∀ {a b} (f : Hom a b), comp f (id b) = f
  assoc : ∀ {a b c d} (f : Hom a b) (g : Hom b c) (h : Hom c d),
    comp (comp f g) h = comp f (comp g h)

namespace Cat

/-- Arrows reversed. -/
def op (C : Cat) : Cat where
  Obj := C.Obj
  Hom a b := C.Hom b a
  id := C.id
  comp f g := C.comp g f
  id_comp := C.comp_id
  comp_id := C.id_comp
  assoc f g h := (C.assoc h g f).symm

@[simp] theorem op_op (C : Cat) : C.op.op = C := rfl

/-- The thin category of a preorder: an arrow `a ⟶ b` is a proof of `r a b`. -/
def thin {α : Type} (r : α → α → Prop) (refl : ∀ a, r a a)
    (trans : ∀ {a b c}, r a b → r b c → r a c) : Cat where
  Obj := α
  Hom a b := PLift (r a b)
  id a := ⟨refl a⟩
  comp f g := ⟨trans f.down g.down⟩
  id_comp _ := rfl
  comp_id _ := rfl
  assoc _ _ _ := rfl

/-- A scale: the thin category of a rank into `Nat` (`a ⟶ b` iff `rank a ≤ rank b`). -/
def scale {α : Type} (rank : α → Nat) : Cat :=
  thin (fun a b => rank a ≤ rank b) (fun _ => Nat.le_refl _) Nat.le_trans

/-- Only identities: arrows are equalities. -/
def disc (β : Type) : Cat := thin (@Eq β) (fun _ => rfl) Eq.trans

/-- Parallel arrows are equal. -/
def Thin (C : Cat) : Prop := ∀ {a b} (f g : C.Hom a b), f = g

theorem thin_thin {α : Type} {r : α → α → Prop} {refl trans} : Thin (thin r refl trans) :=
  fun f g => by cases f; cases g; rfl

theorem Thin.op {C : Cat} (h : Thin C) : Thin C.op := h

theorem scale_thin {α : Type} (rank : α → Nat) : Thin (scale rank) := thin_thin

theorem disc_thin (β : Type) : Thin (disc β) := thin_thin

end Cat

open Cat

/-- A functor. -/
structure Functor (C D : Cat) where
  obj : C.Obj → D.Obj
  map : ∀ {a b}, C.Hom a b → D.Hom (obj a) (obj b)
  map_id : ∀ a, map (C.id a) = D.id (obj a)
  map_comp : ∀ {a b c} (f : C.Hom a b) (g : C.Hom b c), map (C.comp f g) = D.comp (map f) (map g)

namespace Functor

variable {C D E : Cat}

protected def id (C : Cat) : Functor C C := ⟨fun a => a, fun f => f, fun _ => rfl, fun _ _ => rfl⟩

/-- Composition, diagrammatic order: first `F`, then `G`. -/
def comp (F : Functor C D) (G : Functor D E) : Functor C E where
  obj a := G.obj (F.obj a)
  map f := G.map (F.map f)
  map_id a := by rw [F.map_id, G.map_id]
  map_comp f g := by rw [F.map_comp, G.map_comp]

/-- Into a thin category the functor laws are free: an object map with arrows is a functor. -/
def intoThin (hD : Thin D) (obj : C.Obj → D.Obj) (map : ∀ {a b}, C.Hom a b → D.Hom (obj a) (obj b)) :
    Functor C D :=
  ⟨obj, map, fun _ => hD _ _, fun _ _ => hD _ _⟩

/-- A monotone map between scales is a functor. -/
def ofMono {α β : Type} {r : α → Nat} {s : β → Nat} (f : α → β)
    (h : ∀ {a b}, r a ≤ r b → s (f a) ≤ s (f b)) : Functor (scale r) (scale s) :=
  intoThin (scale_thin s) f fun g => ⟨h g.down⟩

/-- An antitone map between scales is a functor into the opposite. -/
def ofAnti {α β : Type} {r : α → Nat} {s : β → Nat} (f : α → β)
    (h : ∀ {a b}, r a ≤ r b → s (f b) ≤ s (f a)) : Functor (scale r) (scale s).op :=
  intoThin (Thin.op (scale_thin s)) f fun g => ⟨h g.down⟩

/-- Functors preserve arrows: in a scale, monotonicity is read back from the functor. -/
theorem mono {α β : Type} {r : α → Nat} {s : β → Nat} (F : Functor (scale r) (scale s))
    {a b : α} (h : r a ≤ r b) : s (F.obj a) ≤ s (F.obj b) :=
  (F.map ⟨h⟩).down

end Functor

/-- Two functors inverse on objects. Between thin categories this is an isomorphism, since the
arrows are then determined. -/
structure ObjIso (C D : Cat) where
  hom : Functor C D
  inv : Functor D C
  inv_hom : ∀ a, inv.obj (hom.obj a) = a
  hom_inv : ∀ b, hom.obj (inv.obj b) = b

/-- An up-set: closed along arrows (the object part of a cosieve). In a scale: a threshold. -/
def UpSet (C : Cat) (S : C.Obj → Prop) : Prop := ∀ {a b}, C.Hom a b → S a → S b

/-- Up-sets pull back along functors. -/
theorem UpSet.comap {C D : Cat} {S : D.Obj → Prop} (F : Functor C D) (h : UpSet D S) :
    UpSet C (fun a => S (F.obj a)) :=
  fun f => h (F.map f)

/-- In a scale, every threshold `{a | t ≤ rank a}` is an up-set. -/
theorem UpSet.threshold {α : Type} (rank : α → Nat) (t : Nat) :
    UpSet (scale rank) (fun a => t ≤ rank a) :=
  fun f h => Nat.le_trans h f.down

end Usul.Cat
