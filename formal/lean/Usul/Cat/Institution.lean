import Usul.Cat.Basic

/-!
# M11: institutions and comorphisms

The roadmap treats Lean, TLA+ and Haskell as *institutions* (Goguen–Burstall): each has
signatures, sentences and models over a signature, and a satisfaction relation that is invariant
under change of notation. A **comorphism** `I ⥤ J` translates signatures and sentences forward
and models backward, preserving satisfaction. It is the formal content of «checking an
`I`-claim with `J`'s tool».

* `Institution`, with the **satisfaction condition** `M' ⊨ σ(φ) ↔ M'|σ ⊨ φ` as a field.
* `Comorphism`, with its own satisfaction condition and the naturality of both translations;
  comorphisms compose (`Comorphism.comp`).
* **Borrowing** (`Comorphism.entails_iff`): semantic consequence is preserved by every comorphism
  (`entails_map`), and it is reflected when every source model is the reduct of some target model
  (`entails_of_map`). This is exactly when a check run in `J` (TLC on traces, QuickCheck
  on executables) proves the `I`-statement. Without that surjectivity, a pass in `J` only
  approximates the `I`-statement.

Concrete carriers are in `Usul.Cat.Carriers`.
-/

namespace Usul.Cat

/-- An institution over a small signature category. -/
structure Institution where
  Sig : Cat
  Sen : Sig.Obj → Type
  sen : ∀ {S T}, Sig.Hom S T → Sen S → Sen T
  Mod : Sig.Obj → Type
  /-- The reduct: a model of the larger signature read in the smaller. -/
  red : ∀ {S T}, Sig.Hom S T → Mod T → Mod S
  Sat : ∀ S, Mod S → Sen S → Prop
  sen_id : ∀ {S} (φ : Sen S), sen (Sig.id S) φ = φ
  sen_comp : ∀ {S T U} (f : Sig.Hom S T) (g : Sig.Hom T U) (φ : Sen S),
    sen (Sig.comp f g) φ = sen g (sen f φ)
  red_id : ∀ {S} (M : Mod S), red (Sig.id S) M = M
  red_comp : ∀ {S T U} (f : Sig.Hom S T) (g : Sig.Hom T U) (M : Mod U),
    red (Sig.comp f g) M = red f (red g M)
  /-- Truth is invariant under change of notation. -/
  satisfaction : ∀ {S T} (σ : Sig.Hom S T) (M : Mod T) (φ : Sen S),
    Sat T M (sen σ φ) ↔ Sat S (red σ M) φ

namespace Institution

variable (I : Institution)

/-- Semantic consequence over `S`. -/
def Entails (S : I.Sig.Obj) (Γ : List (I.Sen S)) (φ : I.Sen S) : Prop :=
  ∀ M, (∀ ψ ∈ Γ, I.Sat S M ψ) → I.Sat S M φ

/-- Consequence is preserved along signature morphisms. -/
theorem entails_sen {S T : I.Sig.Obj} (σ : I.Sig.Hom S T) {Γ : List (I.Sen S)} {φ : I.Sen S}
    (h : I.Entails S Γ φ) : I.Entails T (Γ.map (I.sen σ)) (I.sen σ φ) := by
  intro M hM
  rw [I.satisfaction]
  exact h _ fun ψ hψ => (I.satisfaction σ M ψ).1 (hM _ (List.mem_map_of_mem hψ))

end Institution

/-- A comorphism: signatures and sentences forward, models backward, satisfaction preserved. -/
structure Comorphism (I J : Institution) where
  sig : Functor I.Sig J.Sig
  α : ∀ S, I.Sen S → J.Sen (sig.obj S)
  β : ∀ S, J.Mod (sig.obj S) → I.Mod S
  α_natural : ∀ {S T} (σ : I.Sig.Hom S T) (φ : I.Sen S), J.sen (sig.map σ) (α S φ) = α T (I.sen σ φ)
  β_natural : ∀ {S T} (σ : I.Sig.Hom S T) (M : J.Mod (sig.obj T)),
    β S (J.red (sig.map σ) M) = I.red σ (β T M)
  satisfaction : ∀ S (M : J.Mod (sig.obj S)) (φ : I.Sen S), J.Sat _ M (α S φ) ↔ I.Sat S (β S M) φ

namespace Comorphism

variable {I J K : Institution}

/-- Comorphisms compose. -/
def comp (F : Comorphism I J) (G : Comorphism J K) : Comorphism I K where
  sig := F.sig.comp G.sig
  α S φ := G.α _ (F.α S φ)
  β S M := F.β S (G.β _ M)
  α_natural σ φ := (G.α_natural (F.sig.map σ) _).trans (congrArg (G.α _) (F.α_natural σ φ))
  β_natural σ M := (congrArg (F.β _) (G.β_natural (F.sig.map σ) M)).trans (F.β_natural σ _)
  satisfaction S M φ := (G.satisfaction _ M _).trans (F.satisfaction S _ φ)

variable (F : Comorphism I J)

/-- Borrowing, forward: every comorphism preserves consequence. -/
theorem entails_map {S : I.Sig.Obj} {Γ : List (I.Sen S)} {φ : I.Sen S} (h : I.Entails S Γ φ) :
    J.Entails (F.sig.obj S) (Γ.map (F.α S)) (F.α S φ) := by
  intro M hM
  rw [F.satisfaction]
  exact h _ fun ψ hψ => (F.satisfaction S M ψ).1 (hM _ (List.mem_map_of_mem hψ))

/-- Borrowing, backward: when every model is a reduct, a check in `J` proves the `I`-statement. -/
theorem entails_of_map {S : I.Sig.Obj} (hβ : ∀ M : I.Mod S, ∃ M', F.β S M' = M)
    {Γ : List (I.Sen S)} {φ : I.Sen S} (h : J.Entails (F.sig.obj S) (Γ.map (F.α S)) (F.α S φ)) :
    I.Entails S Γ φ := by
  intro M hM
  obtain ⟨M', rfl⟩ := hβ M
  rw [← F.satisfaction]
  refine h M' fun ψ' hψ' => ?_
  obtain ⟨ψ, hψ, rfl⟩ := List.mem_map.1 hψ'
  exact (F.satisfaction S M' ψ).2 (hM ψ hψ)

theorem entails_iff {S : I.Sig.Obj} (hβ : ∀ M : I.Mod S, ∃ M', F.β S M' = M)
    {Γ : List (I.Sen S)} {φ : I.Sen S} :
    J.Entails (F.sig.obj S) (Γ.map (F.α S)) (F.α S φ) ↔ I.Entails S Γ φ :=
  ⟨F.entails_of_map hβ, F.entails_map⟩

end Comorphism

end Usul.Cat
