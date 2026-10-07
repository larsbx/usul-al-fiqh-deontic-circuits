/-!
# Taʿāruḍ resolution (roadmap §2.4, M5 seed)

Ibn ʿUthaymīn, *al-Uṣūl*: when two adilla conflict, reconcile (*jamʿ*) if possible,
else abrogate (*naskh*) if the chronology is known, else prefer (*tarjīḥ*), else
suspend judgement (*tawaqquf*). The procedure is a total function by construction;
the lemmas pin down its order.
-/

namespace Usul

/-- What each stage of resolution can offer for a given conflict. -/
structure Conflict (P : Type) where
  jam    : Option P
  naskh  : Option P
  tarjih : Option P

inductive Resolution (P : Type) where
  | jam (p : P) | naskh (p : P) | tarjih (p : P) | tawaqquf
  deriving DecidableEq, Repr

def resolve {P : Type} (c : Conflict P) : Resolution P :=
  match c.jam, c.naskh, c.tarjih with
  | some p, _, _ => .jam p
  | none, some p, _ => .naskh p
  | none, none, some p => .tarjih p
  | none, none, none => .tawaqquf

variable {P : Type} {c : Conflict P} {p : P}

theorem resolve_jam_first (h : c.jam = some p) : resolve c = .jam p := by
  simp [resolve, h]

theorem resolve_naskh_before_tarjih (hj : c.jam = none) (hn : c.naskh = some p) :
    resolve c = .naskh p := by
  simp [resolve, hj, hn]

/-- Tawaqquf is reached exactly when every earlier stage fails. -/
theorem resolve_tawaqquf_iff :
    resolve c = .tawaqquf ↔ c.jam = none ∧ c.naskh = none ∧ c.tarjih = none := by
  rcases c with ⟨j, n, t⟩
  cases j <;> cases n <;> cases t <;> simp [resolve]

end Usul
