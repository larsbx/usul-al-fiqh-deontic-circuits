import Usul.Cat.Factor
import Usul.Typing.Answers

/-!
# Categories downstream of the types: typed encoders

The stack is qawāʿid → types → categories. The qawāʿid define the types (`Usul.Typing.Qaida`): one
structure per qāʿida with exactly the facts it states, `Situation` their join. Encoders are typed
over them (`Typed S O`: `proj` reads the local signature off a situation, `embed` writes one back,
`proj_embed`). This module builds the categorical layer on those types.

* **Retract** (`retract`): a typed encoder's local signature is a retract of the situation type.
  Reading back an embedded record loses nothing.
* **L-QIY-1 over the types** (`judge_factors`): an encoder's ruling factors through its qāʿida
  type's projection. It is S1 `Factors`, so `Usul.Cat.Factor` applies: the ruling is a functor
  from the kernel of the projection to the rulings (`judge_functor`). Qiyās between situations
  (`qiyas`) is licensed by the type: two situations with the same local signature receive the
  same ruling, whatever other qawāʿid's facts they carry.
* **The category of typed encoders** (`readsCat S`): objects are encoders typed over `S`, with an
  arrow `E ⟶ F` when `E` reads at least as much as `F` (`Reads`: wherever `E` applies, `F` does,
  and `F`'s signature is a function of `E`'s). Applying is an up-set along arrows
  (`applies_upSet`). Where the finer encoder applies, the coarser one's ruling factors through the
  finer signature (`Reads.factors`), so the finer type licenses the coarser encoder's qiyās.
  A qāʿida type that `extends` another gives an arrow: Ibn Rajab 16's type extends Q28's, and
  `substituteAtObligation ⟶ substitute` (`rajab16_reads_q28`).
* **Answers** (`Reads.mapRun`, `judge_mapRun_factors`): relabelling an encoder's answer
  (`Typed.mapRun`, as `Usul.Typing.Answers` does for validity and negated encoders) is an
  isomorphism in `readsCat` and keeps the factorization.
-/

namespace Usul.Cat.Typing

open Usul Usul.Schema Usul.Typing

variable {S O O' O'' : Type}

/-- The local signature is a retract of the situation type. -/
theorem retract (E : Typed S O) : (fun l => E.proj (E.embed l)) = some := funext E.proj_embed

/-- L-QIY-1 over the types: the ruling factors through the qāʿida type's projection. -/
theorem judge_factors (E : Typed S O) : Factors E.judge E.proj :=
  Factors.of_eq (Option.map E.run) fun _ => rfl

/-- Qiyās between situations, licensed by the type. -/
theorem qiyas (E : Typed S O) {asl far : S} (h : E.proj far = E.proj asl) : E.judge far = E.judge asl :=
  (judge_factors E).qiyas h

/-- The ruling as a functor from the kernel of the projection (`Usul.Cat.Factor`). -/
theorem judge_functor (E : Typed S O) :
    ∃ Φ : Functor (ker E.proj) (Cat.disc (Option O)), Φ.obj = E.judge :=
  factors_iff_functor.1 (judge_factors E)

/-! ## The category of typed encoders -/

/-- `E` reads at least as much as `F`: wherever `E` applies, `F` applies, and `F`'s local
signature is a function of `E`'s. -/
def Reads (E : Typed S O) (F : Typed S O') : Prop :=
  ∃ k : E.Local → F.Local, ∀ s l, E.proj s = some l → F.proj s = some (k l)

theorem Reads.refl (E : Typed S O) : Reads E E := ⟨id, fun _ _ h => h⟩

theorem Reads.trans {E : Typed S O} {F : Typed S O'} {G : Typed S O''}
    (h : Reads E F) (h' : Reads F G) : Reads E G := by
  obtain ⟨k, hk⟩ := h
  obtain ⟨k', hk'⟩ := h'
  exact ⟨k' ∘ k, fun s l he => hk' s (k l) (hk s l he)⟩

/-- Where the finer encoder applies, the coarser one's ruling factors through its signature. -/
theorem Reads.factors {E : Typed S O} {F : Typed S O'} (h : Reads E F) {x y : S} {l : E.Local}
    (hx : E.proj x = some l) (hy : E.proj y = some l) : F.judge x = F.judge y := by
  obtain ⟨k, hk⟩ := h
  simp only [Typed.judge, hk x l hx, hk y l hy]

theorem Reads.applies {E : Typed S O} {F : Typed S O'} (h : Reads E F) {s : S}
    (he : E.applies s = true) : F.applies s = true := by
  obtain ⟨k, hk⟩ := h
  obtain ⟨l, hl⟩ := Option.isSome_iff_exists.1 he
  simp [Typed.applies, hk s l hl]

/-- Encoders typed over `S`, of any answer type. -/
abbrev TypedOver (S : Type) := (O : Type) × Typed S O

/-- The category of typed encoders over `S`, thin, ordered by `Reads`. -/
def readsCat (S : Type) : Cat :=
  Cat.thin (fun E F : TypedOver S => Reads E.2 F.2) (fun E => Reads.refl E.2) Reads.trans

theorem readsCat_thin (S : Type) : Cat.Thin (readsCat S) := Cat.thin_thin

/-- Applying to a situation is an up-set along arrows: what a finer type covers, a coarser one does. -/
theorem applies_upSet (s : S) : UpSet (readsCat S) fun E => E.2.applies s = true :=
  fun f h => f.down.applies h

/-- The qāʿida types' `extends` as an arrow: Ibn Rajab 16's type extends Q28's. -/
theorem rajab16_reads_q28 : Reads substituteAtObligation substitute :=
  ⟨Prod.fst, fun s l h => by
    obtain ⟨p, t⟩ := l
    cases hp : s.originalPossible <;> cases ht : s.settledAtObligation <;>
      simp_all [substituteAtObligation, substitute]⟩

/-! ## Answers -/

/-- Relabelling the answer reads the same signature, both ways: an isomorphism in `readsCat`. -/
theorem Reads.mapRun (f : O → O') (E : Typed S O) : Reads E (E.mapRun f) ∧ Reads (E.mapRun f) E :=
  ⟨Reads.refl E, Reads.refl E⟩

/-- A relabelled encoder still factors through its type. -/
theorem judge_mapRun_factors (f : O → O') (E : Typed S O) : Factors (E.mapRun f).judge E.proj :=
  judge_factors (E.mapRun f)

end Usul.Cat.Typing
