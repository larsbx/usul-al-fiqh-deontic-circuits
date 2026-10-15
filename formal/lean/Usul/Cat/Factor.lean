import Usul.Cat.Basic
import Usul.Qiyas

/-!
# L-QIY-1: qiyās as factorization (roadmap §2.5, M9)

The roadmap's reading:

```text
ʿilla e is valid  ⇔  H factors through π_e   (H ≅ Ĥ ∘ π_e on the known cases)
qiyās(aṣl, farʿ)  :≡  π_e(aṣl) = π_e(farʿ)  ⇒  H(farʿ) := Ĥ(π_e(farʿ))
naqḍ              :≡  a witness against factorization
```

`Schema.Factors H e` (S1) states invariance: cases `e` cannot tell apart share the ruling. This
module proves it is the factorization the roadmap names, in three forms:

* **functorial** (`factors_iff_functor`): `H` is a functor from the *kernel* of `e` (the thin
  groupoid in which `x ⟶ y` iff `e x = e y`) to the discrete category of rulings;
* **global** (`factors_iff_exists`): `H = Ĥ ∘ e` for some `Ĥ`;
* **on the given cases** (`factorsOn_iff_exists`, L-QIY-1 proper): over the finite list of cases
  ruled by naṣṣ or ijmāʿ, `e` is consistent iff some `Ĥ` reproduces every given ruling, iff some
  ruling extending the given cases factors through `e` (`factorsOn_iff_extension`). Its failure
  is exactly a naqḍ witness (`not_factorsOn_iff_naqd`), and it is decided by `factorsOnB`.

Qiyās is then the value of `Ĥ` at the farʿ: determined whenever the farʿ's `e` is attested
among the given cases (`qiyas_determined`), and underdetermined otherwise (`unattested_free`).
The second half is the formal content of farq: without an aṣl sharing the ʿilla, the given
cases fix nothing.
-/

namespace Usul.Cat

open Usul.Schema Usul.Qiyas

variable {α F β : Type}

/-- The kernel of `e`: the cases `e` cannot tell apart, as a thin groupoid. -/
def ker (e : α → F) : Cat := Cat.thin (fun x y => e x = e y) (fun _ => rfl) Eq.trans

/-! ## Global factorization -/

/-- Functorial form: `H` factors through `e` iff it is a functor `ker e ⥤ disc β`. -/
theorem factors_iff_functor {H : α → β} {e : α → F} :
    Factors H e ↔ ∃ Φ : Functor (ker e) (Cat.disc β), Φ.obj = H := by
  constructor
  · intro hf
    exact ⟨Functor.intoThin (Cat.disc_thin β) H fun g => ⟨hf _ _ g.down⟩, rfl⟩
  · rintro ⟨Φ, rfl⟩ x y h
    exact (Φ.map (C := ker e) ⟨h⟩).down

/-- Set form: `H` factors through `e` iff `H = Ĥ ∘ e`. Off the image of `e`, `Ĥ` is arbitrary. -/
theorem factors_iff_exists [Inhabited β] {H : α → β} {e : α → F} :
    Factors H e ↔ ∃ Ĥ : F → β, ∀ x, H x = Ĥ (e x) := by
  classical
  refine ⟨fun hf => ?_, fun ⟨Ĥ, h⟩ => Factors.of_eq Ĥ h⟩
  refine ⟨fun f => if h : ∃ x, e x = f then H h.choose else default, fun x => ?_⟩
  dsimp only
  split
  · next h => exact hf _ _ h.choose_spec.symm
  · next h => exact absurd ⟨x, rfl⟩ h

/-- `Ĥ` is unique on the image of `e`. -/
theorem hat_unique {H : α → β} {e : α → F} {Ĥ₁ Ĥ₂ : F → β}
    (h₁ : ∀ x, H x = Ĥ₁ (e x)) (h₂ : ∀ x, H x = Ĥ₂ (e x)) (x : α) : Ĥ₁ (e x) = Ĥ₂ (e x) := by
  rw [← h₁, ← h₂]

/-! ## Factorization on the given cases (L-QIY-1) -/

/-- On the given cases, no two cases with the same `e` differ in ruling. -/
def FactorsOn (e : α → F) (known : Known α β) : Prop :=
  ∀ p ∈ known, ∀ q ∈ known, e p.1 = e q.1 → p.2 = q.2

/-- A naqḍ witness: two given cases share `e` and differ in ruling. -/
def Naqd (e : α → F) (known : Known α β) : Prop :=
  ∃ p ∈ known, ∃ q ∈ known, e p.1 = e q.1 ∧ p.2 ≠ q.2

/-- The check, decidable. -/
def factorsOnB [DecidableEq F] [DecidableEq β] (e : α → F) (known : Known α β) : Bool :=
  known.all fun p => known.all fun q => !(e p.1 == e q.1) || p.2 == q.2

theorem factorsOnB_iff [DecidableEq F] [DecidableEq β] {e : α → F} {known : Known α β} :
    factorsOnB e known = true ↔ FactorsOn e known := by
  simp only [factorsOnB, FactorsOn, List.all_eq_true, Bool.or_eq_true, Bool.not_eq_true',
    beq_eq_false_iff_ne, beq_iff_eq]
  exact forall₂_congr fun p _ => forall₂_congr fun q _ => by
    by_cases h : e p.1 = e q.1 <;> simp [h]

/-- Failure to factor is exactly a naqḍ. -/
theorem not_factorsOn_iff_naqd {e : α → F} {known : Known α β} :
    ¬ FactorsOn e known ↔ Naqd e known := by
  classical
  simp only [FactorsOn, Naqd, Classical.not_forall, exists_prop]

/-- L-QIY-1: `e` is consistent with the given cases iff some `Ĥ` on features reproduces them. -/
theorem factorsOn_iff_exists [Inhabited β] {e : α → F} {known : Known α β} :
    FactorsOn e known ↔ ∃ Ĥ : F → β, ∀ p ∈ known, Ĥ (e p.1) = p.2 := by
  classical
  constructor
  · intro hf
    refine ⟨fun f => if h : ∃ q ∈ known, e q.1 = f then h.choose.2 else default, fun p hp => ?_⟩
    dsimp only
    split
    · next h => exact hf _ h.choose_spec.1 _ hp h.choose_spec.2
    · next h => exact absurd ⟨p, hp, rfl⟩ h
  · rintro ⟨Ĥ, h⟩ p hp q hq he
    rw [← h p hp, ← h q hq, he]

/-- L-QIY-1, extension form: `e` is consistent with the given cases iff some total ruling that
agrees with them factors through `e`. -/
theorem factorsOn_iff_extension [Inhabited β] {e : α → F} {known : Known α β} :
    FactorsOn e known ↔ ∃ H : α → β, Factors H e ∧ Agrees H known := by
  rw [factorsOn_iff_exists]
  constructor
  · rintro ⟨Ĥ, h⟩
    exact ⟨Ĥ ∘ e, Factors.of_eq Ĥ fun _ => rfl, fun p hp => h p hp⟩
  · rintro ⟨H, hf, ha⟩
    obtain ⟨Ĥ, hĤ⟩ := factors_iff_exists.1 hf
    exact ⟨Ĥ, fun p hp => (hĤ p.1).symm.trans (ha p hp)⟩

/-- A finer feature stays consistent (cf. `Factors.refine`). -/
theorem FactorsOn.refine {F' : Type} {e : α → F} {e' : α → F'} {known : Known α β} (k : F' → F)
    (he : ∀ x, e x = k (e' x)) (h : FactorsOn e known) : FactorsOn e' known :=
  fun p hp q hq h' => h p hp q hq (by rw [he, he, h'])

/-! ## Qiyās as evaluation of `Ĥ` -/

/-- Qiyās is determined: if the farʿ shares `e` with a given aṣl, every ruling that agrees with
the given cases and factors through `e` assigns the farʿ the aṣl's ruling. -/
theorem qiyas_determined {e : α → F} {known : Known α β} {H : α → β}
    (hf : Factors H e) (ha : Agrees H known) {asl : α × β} (hasl : asl ∈ known) {far : α}
    (h : e far = e asl.1) : H far = asl.2 :=
  (hf far asl.1 h).trans (ha asl hasl)

/-- Without an attested aṣl, the given cases fix nothing at the farʿ: any value is the value of
some consistent extension. -/
theorem unattested_free [Inhabited β] {e : α → F} {known : Known α β} (hf : FactorsOn e known)
    {far : α} (hfar : ∀ p ∈ known, e p.1 ≠ e far) (b : β) :
    ∃ H : α → β, Factors H e ∧ Agrees H known ∧ H far = b := by
  classical
  obtain ⟨Ĥ, h⟩ := factorsOn_iff_exists.1 hf
  refine ⟨fun x => if e x = e far then b else Ĥ (e x), ?_, fun p hp => ?_, by simp⟩
  · exact Factors.of_eq (fun f => if f = e far then b else Ĥ f) fun _ => rfl
  · simp [hfar p hp, h p hp]

end Usul.Cat
