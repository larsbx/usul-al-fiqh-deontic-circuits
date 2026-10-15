import Usul

/-!
M11 fixtures: the shared fragment of `formal/tla/Taklif.tla`, read in the three institutions of
`Usul.Cat.Carriers`. The satisfaction conditions are theorems. These guards check them on
fixtures, as the exit criterion asks, and pin the TLA+ invariants on behaviours built from the
spec's own actions.

Variables (`Taklif.tla`): 0 baligh, 1 aqil, 2 travelling, 3 rukhsa, 4 bound ≠ {}.
-/

namespace UsulTest.Institutions

open Usul Usul.Cat Usul.Cat.Carriers Form

abbrev N := 5

def baligh : Form N := var 0
def aqil : Form N := var 1
def travelling : Form N := var 2
def rukhsa : Form N := var 3
def bound : Form N := var 4

def mukallaf : Form N := .and baligh aqil

/-- `Init`. -/
def init : Form N := .and (.not baligh) (.and aqil (.and (.not travelling) (.and (.not rukhsa) (.not bound))))
/-- `OnlyMukallafBound`. -/
def onlyMukallafBound : Form N := .imp bound mukallaf
/-- `RukhsaNeedsSabab`. -/
def rukhsaNeedsSabab : Form N := .imp rukhsa travelling
/-- `BulughIrreversible`: `[][baligh => baligh']_vars`. -/
def bulughIrreversible : Form (N + N) := .imp (var (Fin.castAdd N 0)) (var (Fin.natAdd N 0))

def spec : List (TSen N) := [.now init, .always onlyMukallafBound, .always rukhsaNeedsSabab, .step bulughIrreversible]

/-- A state from its five flags. -/
def st (b a t r d : Bool) : Fin N → Bool := fun i => match i.val with
  | 0 => b | 1 => a | 2 => t | 3 => r | _ => d

/-- Init → Bulugh → Depart → TakeRukhsa → Arrive → LoseAql. -/
def behaviour : Trace N :=
  ⟨st false true false false false,
   [st true true false false true, st true true true false true, st true true true true true,
    st true true false false true, st true false false false false]⟩

/-- A rukhsa taken at home: violates `RukhsaNeedsSabab`. -/
def rukhsaAtHome : Trace N := ⟨st false true false false false, [st true true false true true]⟩

/-- Bulūgh undone: violates `BulughIrreversible`. -/
def bulughUndone : Trace N := ⟨st false true false false false, [st true true false false true, st false true false false false]⟩

#guard spec.all (·.holds behaviour)
#guard !(TSen.always rukhsaNeedsSabab).holds rukhsaAtHome
#guard !(TSen.step bulughIrreversible).holds bulughUndone
#guard (spec.filter (!·.holds rukhsaAtHome)).length == 1
#guard (spec.filter (!·.holds bulughUndone)).length == 1

/-! ## Satisfaction conditions on fixtures -/

/-- The subject signature (`Usul.Signature.Subject`: bulūgh, ʿaql) embedded in Taklif's. -/
def ι : finSet.Hom 2 N := Fin.castLE (by decide)

def mukallaf₂ : Form 2 := .and (var 0) (var 1)

def traces : List (Trace N) := [behaviour, rukhsaAtHome, bulughUndone]

def sentences₂ : List (TSen 2) :=
  [.now mukallaf₂, .always mukallaf₂, .always (.imp (var 0) (var 1)),
   .step (.imp (var (Fin.castAdd 2 0)) (var (Fin.natAdd 2 0)))]

-- traceI along `ι`: `t ⊨ ι(φ) ↔ t|ι ⊨ φ` on every fixture.
#guard traces.all fun t => sentences₂.all fun φ => (φ.rename ι).holds t == φ.holds (t.map ι)

-- propI along `ι`, on all 32 valuations.
#guard (allVals N).all fun v => (mukallaf₂.rename ι).eval v == mukallaf₂.eval (v ∘ ι)

-- `compile` and `initial`: the translated sentence holds iff the source holds of the reduct.
#guard (allVals N).all fun v => [init, onlyMukallafBound, rukhsaNeedsSabab].all fun φ =>
  compile.α N φ v == φ.eval (compile.β N v)
#guard traces.all fun t => [init, onlyMukallafBound, rukhsaNeedsSabab].all fun φ =>
  (initial.α N φ).holds t == φ.eval (initial.β N t)

/-! ## The bridge to the Lean signature, and borrowing -/

/-- `mukallaf₂` is `Subject.IsMukallaf`, read on a valuation. -/
example (v : Fin 2 → Bool) : propI.Sat 2 v mukallaf₂ ↔ (⟨v 0, v 1⟩ : Subject).IsMukallaf := by
  simp [mukallaf₂, Subject.IsMukallaf, Form.eval]

/-- Decided by truth tables in Lean: a duty that binds proves the bearer is a mukallaf … -/
example : propI.Entails N [onlyMukallafBound, bound] mukallaf := entailsB_iff.1 rfl

/-- … and the same entailment holds of every behaviour's initial state, since `initial` is onto. -/
example : traceI.Entails N ([onlyMukallafBound, bound].map (initial.α N)) (initial.α N mukallaf) :=
  initial.entails_map (entailsB_iff.1 rfl)

/-- Losing ʿaql does not by itself discharge travel: no entailment. -/
example : ¬ propI.Entails N [.not aqil] (.not travelling) := fun h => absurd (entailsB_iff.2 h) (by decide)

end UsulTest.Institutions
