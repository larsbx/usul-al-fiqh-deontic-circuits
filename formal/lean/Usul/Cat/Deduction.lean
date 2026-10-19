import Usul.Readings.RajabA26

/-!
# Deduction to the qāʿida: attainable verdicts as a presheaf on partial situations

Routing a farʿ to its qāʿida by its words fails when the words are the farʿ's bāb's and not its
qāʿida's (PR-48). This module reads the question the other way, as takhrīj al-uṣūl ʿalā al-furūʿ:
from an **established conclusion** (the ruling an authoritative position states) and the facts
the text settles, which accepted readings can derive it?

* **The space.** Partial situations, ordered by refinement: `s ≤ t` when `t` settles every fact
  `s` does, the same way, and perhaps more. Settling a fact is an established state transition, an
  arrow `s ⟶ t`.
* **The presheaf.** For a reading, `view s` is the set of its local signatures that complete `s`,
  and `Reach s` the verdicts those completions give. A refinement shrinks both (`reach_antitone`),
  so `Reach` is a presheaf of sets of verdicts on the poset of partial situations. It is the
  situation-indexed counterpart of `Usul.Cat.Interval`'s spans.
* **Deduction.** A reading is admissible for an established conclusion `a` at `s` when
  `Reach s a`. Otherwise `s` carries an obstruction to deriving `a` by that reading.
* **Soundness** (`sound`): if a refinement of `s` derives `a`, then `Reach s a`. Deduction never
  excludes the reading a case truly falls under, provided the typed facts are a true restriction
  of the case's facts.
* **Finality** (`excluded_forever`): an excluded verdict stays excluded under every refinement.
  No further fact brings the reading back.
* **Compatibility** (`reach_common_refinement`): a common refinement of two partial situations
  reaches only what both reach.

`pair` instantiates the theory for a reading of two facts. `idhn` is Ibn Rajab 23's reading
(`Usul.Readings.RajabA26.idhnLapses`): once the text says the refusal was not forbidden, «يسقط
إذنه» is out of reach (`idhn_permitted_refusal_excludes_lapse`). Settling only that the refusal
was forbidden leaves both verdicts in reach (`idhn_forbidden_refusal_reaches_both`).
`pipeline/usul_corpus/deduction.py` computes the same presheaf exhaustively for every encoder.
-/

namespace Usul.Cat.Deduction

/-- Partial situations `P` under refinement `le`, read by one reading with local signatures `L`
and verdicts `O`. `view s l`: the signature `l` completes `s`. -/
structure Reading (P L O : Type) where
  le : P → P → Prop
  le_refl : ∀ s, le s s
  le_trans : ∀ {a b c}, le a b → le b c → le a c
  view : P → L → Prop
  view_antitone : ∀ {s t}, le s t → ∀ l, view t l → view s l
  run : L → O

namespace Reading

variable {P L O : Type} (R : Reading P L O)

/-- The verdicts attainable from `s` by some completion. -/
def Reach (s : P) (a : O) : Prop := ∃ l, R.view s l ∧ R.run l = a

/-- Restriction: a refinement reaches no more than what it refines. -/
theorem reach_antitone {s t : P} (h : R.le s t) {a : O} : R.Reach t a → R.Reach s a :=
  fun ⟨l, hv, hr⟩ => ⟨l, R.view_antitone h l hv, hr⟩

/-- Soundness: a derivation at any refinement of `s` keeps the reading admissible at `s`. -/
theorem sound {s t : P} {l : L} (h : R.le s t) (hv : R.view t l) : R.Reach s (R.run l) :=
  ⟨l, R.view_antitone h l hv, rfl⟩

/-- Finality: an obstruction at `s` persists under every refinement. -/
theorem excluded_forever {s t : P} (h : R.le s t) {a : O} (hn : ¬ R.Reach s a) : ¬ R.Reach t a :=
  fun ht => hn (R.reach_antitone h ht)

/-- Compatibility: a common refinement reaches only what both partial situations reach. -/
theorem reach_common_refinement {s s' t : P} (h : R.le s t) (h' : R.le s' t) {a : O}
    (ht : R.Reach t a) : R.Reach s a ∧ R.Reach s' a :=
  ⟨R.reach_antitone h ht, R.reach_antitone h' ht⟩

end Reading

/-! ## Two facts -/

variable {O α β : Type}

/-- Partial situations of a reading of two facts: each `none` until the text settles it. A
signature completes `s` when it agrees with every fact `s` settles. -/
def pair (run : α × β → O) : Reading (Option α × Option β) (α × β) O where
  le s t := (∀ x, s.1 = some x → t.1 = some x) ∧ (∀ y, s.2 = some y → t.2 = some y)
  le_refl _ := ⟨fun _ h => h, fun _ h => h⟩
  le_trans h h' := ⟨fun x hx => h'.1 x (h.1 x hx), fun y hy => h'.2 y (h.2 y hy)⟩
  view s l := (∀ x, s.1 = some x → l.1 = x) ∧ (∀ y, s.2 = some y → l.2 = y)
  view_antitone h _ hv := ⟨fun x hx => hv.1 x (h.1 x hx), fun y hy => hv.2 y (h.2 y hy)⟩
  run := run

/-- A fully settled pair reaches exactly its own verdict. -/
theorem pair_total (run : α × β → O) (x : α) (y : β) (a : O) :
    (pair run).Reach (some x, some y) a ↔ run (x, y) = a := by
  constructor
  · rintro ⟨⟨x', y'⟩, ⟨hx, hy⟩, rfl⟩
    cases hx x rfl; cases hy y rfl; rfl
  · intro h
    exact ⟨(x, y), ⟨fun _ hx => Option.some.inj hx, fun _ hy => Option.some.inj hy⟩, h⟩

/-- Ibn Rajab 23's reading as a reading of two facts: refusal forbidden, mere permission. -/
def idhn : Reading (Option Bool × Option Bool) (Bool × Bool) Bool :=
  pair fun l => Usul.Readings.RajabA26.idhnLapses l.1 l.2

/-- The text says the refusal was his to make: «يسقط إذنه» is out of reach, whatever is later
settled of what was asked. -/
theorem idhn_permitted_refusal_excludes_lapse : ¬ idhn.Reach (some false, none) true := by
  rintro ⟨⟨r, m⟩, ⟨hr, _⟩, h⟩
  cases hr false rfl
  simp [idhn, pair, Usul.Readings.RajabA26.idhnLapses] at h

/-- Settling only that the refusal was forbidden leaves both verdicts in reach: the nawʿ decides. -/
theorem idhn_forbidden_refusal_reaches_both (a : Bool) : idhn.Reach (some true, none) a :=
  ⟨(true, a), ⟨fun _ h => (Option.some.inj h).symm ▸ rfl, fun _ h => nomatch h⟩,
   by cases a <;> rfl⟩

/-- Finality, instantiated: no refinement of «the refusal was permitted» derives the lapse. -/
theorem idhn_lapse_excluded_under_refinement (t : Option Bool × Option Bool)
    (h : idhn.le (some false, none) t) : ¬ idhn.Reach t true :=
  idhn.excluded_forever h idhn_permitted_refusal_excludes_lapse

end Usul.Cat.Deduction
