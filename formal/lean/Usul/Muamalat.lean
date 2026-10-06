import Usul.Sadi

/-!
# al-Saʿdī's transaction rules (muʿāmalāt) — formal readings (roadmap M3)

A small model of possession, liability and contract. Most of these rules are case
distinctions (taqsīm / farq); their readings are total functions over the cases, with
theorems stating each branch. Where rules interact, a consistency theorem shows the
readings agree (Q13 with Q36, Q26 with Q43). Rule numbers as in
`corpus/proposals/sadi_qawaid.json`; every reading is a candidate until reviewed.
-/

namespace Usul.Muamalat

open Usul

/-! ## Q10 — proof on the claimant, oath on the one who denies -/

inductive Party where
  | claimant | denier
  deriving DecidableEq, Repr

inductive Proof where
  | bayyina | yamin
  deriving DecidableEq, Repr

def burden : Party → Proof
  | .claimant => .bayyina
  | .denier => .yamin

theorem q10_burden_injective (a b : Party) (h : burden a = burden b) : a = b := by
  cases a <;> cases b <;> simp_all [burden]

/-! ## Q12 — exchange contracts require the consent of both parties -/

structure Exchange where
  consentA : Bool
  consentB : Bool

def Exchange.gate : Sadi.Gate Exchange :=
  ⟨[fun e => e.consentA = true, fun e => e.consentB = true], []⟩

theorem q12_no_contract_without_consent (e : Exchange) (h : e.consentA = false ∨ e.consentB = false) :
    ¬ Exchange.gate.Holds e := by
  rcases h with h | h
  · exact Sadi.q08_missing_condition (c := fun e => e.consentA = true) (by simp [Exchange.gate]) (by simp [h])
  · exact Sadi.q08_missing_condition (c := fun e => e.consentB = true) (by simp [Exchange.gate]) (by simp [h])

theorem q12_mutual_consent_suffices (e : Exchange) (ha : e.consentA = true) (hb : e.consentB = true) :
    Exchange.gate.Holds e := by
  refine ⟨?_, by simp [Exchange.gate]⟩
  intro c hc
  simp [Exchange.gate] at hc
  rcases hc with rfl | rfl <;> assumption

/-! ## Q13 / Q36 — destruction: liability does not depend on intent (Q13); destroying to
benefit makes one liable, destroying to repel the thing's harm does not (Q36) -/

inductive MentalState where
  | deliberate | ignorant | forgetful
  deriving DecidableEq, Repr

inductive Purpose where
  | benefit | repelHarm
  deriving DecidableEq, Repr

/-- Q13: destruction without right is compensable, whatever the mental state. -/
def itlafLiable (withRight : Bool) (_ : MentalState) : Bool := !withRight

/-- Q36: repelling the thing's own harm is destruction with right. -/
def withRight : Purpose → Bool
  | .benefit => false
  | .repelHarm => true

theorem q13_intent_irrelevant (r : Bool) (m m' : MentalState) : itlafLiable r m = itlafLiable r m' := rfl

theorem q36_benefit_liable (m : MentalState) : itlafLiable (withRight .benefit) m = true := rfl
theorem q36_repel_not_liable (m : MentalState) : itlafLiable (withRight .repelHarm) m = false := rfl

/-- Q13 and Q36 agree: Q13's strict liability covers only destruction without right. -/
theorem q13_q36_consistent (p : Purpose) (m : MentalState) :
    itlafLiable (withRight p) m = true ↔ p = .benefit := by
  cases p <;> simp [itlafLiable, withRight]

/-! ## Q14 — loss in a trustee's hand is not compensable without transgression or
negligence; in a wrongdoer's hand it is compensable absolutely -/

inductive Hand where
  | trustee | wrongdoer
  deriving DecidableEq, Repr

def lossLiable (h : Hand) (transgressed negligent : Bool) : Bool :=
  match h with
  | .trustee => transgressed || negligent
  | .wrongdoer => true

theorem q14_trustee_without_fault (t n : Bool) (ht : t = false) (hn : n = false) :
    lossLiable .trustee t n = false := by simp [lossLiable, ht, hn]

theorem q14_wrongdoer_always (t n : Bool) : lossLiable .wrongdoer t n = true := rfl

theorem q14_fault_makes_trustee_liable (t n : Bool) (h : t = true ∨ n = true) :
    lossLiable .trustee t n = true := by
  rcases h with h | h <;> simp [lossLiable, h]

/-! ## Q18 / Q19 — fungibles are compensated in kind, others by value; an unattainable
stipulated price reverts to value -/

inductive Good where
  | fungible | valued
  deriving DecidableEq, Repr

inductive Compensation where
  | inKind | byValue
  deriving DecidableEq, Repr

def compensation : Good → Compensation
  | .fungible => .inKind
  | .valued => .byValue

theorem q18_partition (g : Good) : compensation g = .inKind ↔ g = .fungible := by
  cases g <;> simp [compensation]

def priceDue (stipulated : Option Nat) (value : Nat) : Nat := stipulated.getD value

theorem q19_unattainable_reverts_to_value (v : Nat) : priceDue none v = v := rfl
theorem q19_stipulated_binds (p v : Nat) : priceDue (some p) v = p := rfl

/-! ## Q20 — an unidentifiable right-holder is treated as non-existent -/

inductive Recipient where
  | owner | publicInterest
  deriving DecidableEq, Repr

def recipient (ownerIdentifiable : Bool) : Recipient :=
  if ownerIdentifiable then .owner else .publicInterest

theorem q20_unknown_owner (b : Bool) : recipient b = .publicInterest ↔ b = false := by
  cases b <;> simp [recipient]

/-! ## Q21 — uncertainty and gambling are forbidden in exchanges and contests -/

inductive ContractKind where
  | exchange | contest | gift
  deriving DecidableEq, Repr

def ghararForbidden (k : ContractKind) (gharar : Bool) : Bool := gharar && k != .gift

theorem q21_forbidden_iff (k : ContractKind) (g : Bool) :
    ghararForbidden k g = true ↔ g = true ∧ k ≠ .gift := by
  cases k <;> cases g <;> simp [ghararForbidden]

/-! ## Q24 — whoever reaches an unowned permissible thing first has the better right -/

/-- The claimant with the earliest time (Q33's `best` on the negated time). -/
def firstClaimant {P : Type} (claims : List (P × Nat)) : Option (P × Nat) :=
  Sadi.best (fun c => -(c.2 : Int)) claims

theorem q24_first_has_priority {P : Type} {claims : List (P × Nat)} {w : P × Nat}
    (h : firstClaimant claims = some w) : ∀ c ∈ claims, w.2 ≤ c.2 :=
  Sadi.q33_lighter_harm (fun c : P × Nat => c.2) h

/-! ## Q25 — lots are prescribed when the entitled is unknown and division impossible -/

def lotPrescribed (entitledKnown divisible : Bool) : Bool := !entitledKnown && !divisible

theorem q25_lot_iff (k d : Bool) : lotPrescribed k d = true ↔ k = false ∧ d = false := by
  cases k <;> cases d <;> simp [lotPrescribed]

/-! ## Q26 / Q43 — a trustee's word is accepted, unless sense or custom belie it (Q26); about
returning the thing, only if he held it for the owner's benefit (Q43) -/

inductive HeldFor where
  | owner | self
  deriving DecidableEq, Repr

def wordAccepted (contradictsSenseOrCustom : Bool) : Bool := !contradictsSenseOrCustom

def returnClaimAccepted (heldFor : HeldFor) (contradicts : Bool) : Bool :=
  heldFor == .owner && wordAccepted contradicts

theorem q43_self_interest_not_believed (c : Bool) : returnClaimAccepted .self c = false := rfl

/-- Q43 refines Q26: an accepted return claim is always an accepted word. -/
theorem q26_q43_consistent (h : HeldFor) (c : Bool) :
    returnClaimAccepted h c = true → wordAccepted c = true := by
  cases h <;> simp [returnClaimAccepted]

/-! ## Q35 — whoever escapes punishment for a reason owes doubled compensation -/

def compensationOwed (value : Nat) (punishmentLapsed : Bool) : Nat :=
  if punishmentLapsed then 2 * value else value

theorem q35_doubled (v : Nat) : compensationOwed v true = 2 * v := rfl
theorem q35_never_less (v : Nat) (b : Bool) : v ≤ compensationOwed v b := by
  cases b <;> simp [compensationOwed]; omega

/-! ## Q37 — when contracting parties disagree, the stronger evidence prevails -/

def prevailing {P : Type} (claims : List (P × Nat)) : Option (P × Nat) :=
  Sadi.best (fun c => (c.2 : Int)) claims

theorem q37_strongest_prevails {P : Type} {claims : List (P × Nat)} {w : P × Nat}
    (h : prevailing claims = some w) : ∀ c ∈ claims, c.2 ≤ w.2 :=
  Sadi.q33_higher_benefit (fun c : P × Nat => c.2) h

/-! ## Q44 — whoever performs what is due earns what was set for him -/

def earned (performed : Bool) (wage : Nat) : Nat := if performed then wage else 0

theorem q44_performance_earns (w : Nat) : earned true w = w := rfl

/-! ## Q46 — a creditor whose cause is evident may take his due from a refusing debtor's
property, up to its amount; with a hidden cause he may not -/

def mayTake (causeEvident refuses : Bool) (claim amount : Nat) : Bool :=
  causeEvident && refuses && decide (amount ≤ claim)

theorem q46_hidden_cause_forbids (r : Bool) (c a : Nat) : mayTake false r c a = false := rfl

theorem q46_never_more_than_due (e r : Bool) (c a : Nat) (h : mayTake e r c a = true) : a ≤ c := by
  cases e <;> cases r <;> simp [mayTake] at h <;> omega

/-! ## Q47 — what a vow makes obligatory is assimilated to what the law makes obligatory -/

inductive ObligationSource where
  | sharia | vow
  deriving DecidableEq, Repr

def obligationStatus (_ : ObligationSource) : Hukm := .wajib

theorem q47_vow_as_law : obligationStatus .vow = obligationStatus .sharia := rfl

/-! ## Q49 — basic needs are not surplus wealth -/

def surplus (assets basicNeeds : Nat) : Nat := assets - basicNeeds

theorem q49_needs_excluded (a n : Nat) : surplus a n + min a n = a := by
  unfold surplus; omega

/-! ## Q53 — a contract that proves void voids what was built on it; a voluntary rescission
leaves earlier dependent contracts standing -/

inductive Ending where
  | provedVoid | rescinded
  deriving DecidableEq, Repr

def dependentsSurvive : Ending → Bool
  | .provedVoid => false
  | .rescinded => true

theorem q53_distinction : dependentsSurvive .provedVoid ≠ dependentsSurvive .rescinded := by
  simp [dependentsSurvive]

/-! ## Q54 — in transactions the actual state of affairs counts, not belief -/

def dispositionValid (actuallyEntitled _believedEntitled : Bool) : Bool := actuallyEntitled

theorem q54_belief_irrelevant (a b b' : Bool) : dispositionValid a b = dispositionValid a b' := rfl

/-! ## Q55 — no excuse for one who confessed, even if he claims error -/

def confessionBinds (_claimsError : Bool) : Bool := true

theorem q55_error_claim_irrelevant (e : Bool) : confessionBinds e = true := rfl

/-! ## Q56 — the heir stands in the deceased's place for the estate, except the listed rights -/

inductive EstateRight where
  | ownership | debtClaim | khiyarShart | shufaUnclaimed
  deriving DecidableEq, Repr

def inherits : EstateRight → Bool
  | .khiyarShart | .shufaUnclaimed => false
  | _ => true

theorem q56_exceptions_only (r : EstateRight) :
    inherits r = false ↔ r = .khiyarShart ∨ r = .shufaUnclaimed := by
  cases r <;> simp [inherits]

end Usul.Muamalat
