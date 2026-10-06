import Usul.Schema

/-!
# The review process, read with its own principles (dogfooding)

The interpretive-question register (`corpus/review/sadi_interpretive_questions.json`) is run
by the same uṣūl the project formalises, applied only where doing so cannot deadlock:

* **Status by priority (S2, taʿāruḍ order; Aḥmad's resort, `DalilKind.qiyas_after_athar`).**
  A question is `referenced` when an established answer is cited, `analogized` when only
  analogies are offered, otherwise `open` (tawaqquf). Analogy never outranks a cited text.
* **Persistence (Q11, istiṣḥāb).** Status is computed from the evidence on file; nothing
  moves it but new evidence.
* **Analogy is qiyās (Q58, S1).** An analogy between two rules is licensed by a shared schema
  (the ʿilla); naqḍ — a cited ʿilla missing from either side — rejects it.
* **Adoption is a gate (Q8, S3).** No status here means "adopted": adoption needs the
  `SHARIAH-AUTHORITY` gate, which this repository does not hold.

**Bootstrap deadlock.** A principle cannot be used to *run* the review while its own reading
is *under* review: the review would wait on the question, the question on the review.
`no_deadlock_of_stratified` proves that if the rules the process uses are disjoint from the
rules under open questions, the waits-for relation is empty; `no_cycle_of_rank` is the general
form (a rank that every wait strictly decreases rules out a cycle). The register declares the
rules it uses and those it must avoid (Q33, because IQ-10 asks about its tie-breaking), and
`test_process_is_stratified` checks the hypothesis on the data.
-/

namespace Usul.Process

open Usul Usul.Schema

/-! ## Status by priority -/

inductive Status where
  | referenced | analogized | open
  deriving DecidableEq, Repr

/-- The status the evidence on file supports: a cited answer, else an analogy, else open. -/
def status (cited analogies : Bool) : Status :=
  resolveD [if cited then some .referenced else none, if analogies then some .analogized else none] .open

theorem status_cited (a : Bool) : status true a = .referenced := rfl

/-- Analogy never outranks a cited text (qiyās after athar). -/
theorem analogy_never_outranks_text (a : Bool) : status true a ≠ .analogized := by
  simp [status_cited]

/-- Tawaqquf exactly when nothing is on file. -/
theorem open_iff (c a : Bool) : status c a = .open ↔ c = false ∧ a = false := by
  cases c <;> cases a <;> simp [status, resolveD, first]

/-- The order mirrors Aḥmad's order of resort: every transmitted source precedes qiyās. A
cited position is a transmission (naql), an analogy is qiyās, and `open` is tawaqquf. -/
theorem order_is_resort (k : DalilKind) (h : k ≠ .qiyas ∧ k ≠ .istishab) :
    k.resort < DalilKind.qiyas.resort :=
  DalilKind.qiyas_after_athar k h

/-- No status is "adopted": the process can reference and analogise, never adopt. -/
theorem never_adopts (c a : Bool) : status c a ∈ [Status.referenced, .analogized, .open] := by
  cases c <;> cases a <;> simp [status, resolveD, first]

/-! ## Analogy as qiyās -/

/-- An analogy from rule `asl` to rule `far` through schema `s`, given each rule's tags. -/
def Licensed {R S : Type} (tags : R → S → Prop) (asl far : R) (s : S) : Prop :=
  tags asl s ∧ tags far s

/-- What the schema guarantees of the aṣl transfers to the farʿ (Q58 read through S1):
any property computed from the schema tag alone agrees on both sides. -/
theorem licensed_transfers {R S β : Type} (tags : R → S → Prop) [∀ r s, Decidable (tags r s)]
    {asl far : R} {s : S} (h : Licensed tags asl far s) (P : Bool → β) :
    P (decide (tags far s)) = P (decide (tags asl s)) := by
  simp [h.1, h.2]

/-- Naqḍ: a missing tag on either side defeats the analogy. -/
theorem naqd {R S : Type} {tags : R → S → Prop} {asl far : R} {s : S}
    (h : ¬ tags far s ∨ ¬ tags asl s) : ¬ Licensed tags asl far s :=
  fun ⟨ha, hf⟩ => h.elim (· hf) (· ha)

/-! ## Deadlock freedom -/

section Deadlock

variable {Q R : Type}

/-- `q` waits on `q'` when the process step for `q` uses a rule that `q'` has under review. -/
def WaitsOn (uses : R → Prop) (about : Q → R → Prop) (isOpen : Q → Prop) (_q q' : Q) : Prop :=
  ∃ r, uses r ∧ isOpen q' ∧ about q' r

/-- Stratification: the rules the process uses are not under any open question. -/
def Stratified (uses : R → Prop) (about : Q → R → Prop) (isOpen : Q → Prop) : Prop :=
  ∀ r, uses r → ∀ q, isOpen q → ¬ about q r

theorem no_deadlock_of_stratified {uses : R → Prop} {about : Q → R → Prop} {isOpen : Q → Prop}
    (h : Stratified uses about isOpen) (q q' : Q) : ¬ WaitsOn uses about isOpen q q' :=
  fun ⟨r, hu, ho, ha⟩ => h r hu q' ho ha

/-- General form: if every wait strictly lowers a rank, no question waits on itself through
any chain (the chain is S4's closure of the wait relation). -/
theorem no_cycle_of_rank {W : Q → Q → Prop} (rank : Q → Nat) (hr : ∀ a b, W a b → rank b < rank a)
    (q : Q) : ¬ Closure W (W q) q := by
  have key : ∀ b, Closure W (W q) b → rank b < rank q :=
    Closure.least _ (fun b h => hr q b h) (fun a b ha hab => Nat.lt_trans (hr a b hab) ha)
  exact fun h => Nat.lt_irrefl _ (key q h)

end Deadlock

end Usul.Process
