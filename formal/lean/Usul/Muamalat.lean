import Usul.Schema

/-!
# al-Saʿdī's transaction rules (muʿāmalāt) — formal readings (roadmap M3)

A small model of possession, liability and contract. Most of these rules are case
distinctions (taqsīm / farq); their readings are total functions over the cases, with
theorems stating each branch. Where rules interact, a consistency theorem shows the
readings agree (Q13 with Q36, Q26 with Q43). Each thin reading is also proved to be an
instance of a schema in `Usul.Schema` (`*_is_*`, `*_from_*`), so its structure transports to
any other bāb. Rule numbers as in
`corpus/proposals/sadi_qawaid.json`; every reading is a candidate until reviewed.
-/

namespace Usul.Muamalat

open Usul Usul.Schema

/-! ## Q10 — proof on the claimant, oath on the one who denies -/

inductive Party where
  | claimant | denier
  deriving DecidableEq, Repr

def burden : Party → Proof
  | .claimant => .bayyina
  | .denier => .yamin

theorem q10_burden_injective (a b : Party) (h : burden a = burden b) : a = b := by
  cases a <;> cases b <;> simp_all [burden]

/-- What each party asserts about the defendant's dhimma: occupied (claimant) or free (denier). -/
def Party.claim : Party → Bool
  | .claimant => true
  | .denier => false

/-- Q10 is S6 under the presumption of barāʾat al-dhimma: the roles are derived from whether
a claim departs from the presumption. -/
theorem q10_from_presumption (p : Party) : burden p = burdenOf false p.claim := by
  cases p <;> rfl

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

/-- Q13 is S1: liability ignores the mental state. -/
theorem q13_ignores_intent : Ignores itlafLiable := fun _ _ _ => rfl

/-- Qiyās over liability: destructions with the same right-status share liability. -/
theorem q13_q36_factor_through_right :
    Factors (fun pm : Purpose × MentalState => itlafLiable (withRight pm.1) pm.2) (withRight ·.1) :=
  Factors.of_eq (fun r => !r) fun _ => rfl

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

/-- Authorised holding: a trustee without transgression or negligence; never a wrongdoer. -/
def authorizedHold : Hand → Bool → Bool → Bool
  | .trustee, t, n => !(t || n)
  | .wrongdoer, _, _ => false

/-- Q13 and Q14 share one shape: liability is the absence of authorisation (for Q13 the
authorisation is the right of Q36). -/
theorem q14_liable_iff_unauthorized (h : Hand) (t n : Bool) : lossLiable h t n = !authorizedHold h t n := by
  cases h <;> simp [lossLiable, authorizedHold]

theorem q13_liable_iff_unauthorized (r : Bool) (m : MentalState) : itlafLiable r m = !r := rfl

/-- Q14 is S1: liability for loss factors through authorisation. -/
theorem q14_factors_through_authorization :
    Factors (fun x : Hand × Bool × Bool => lossLiable x.1 x.2.1 x.2.2)
      (fun x => authorizedHold x.1 x.2.1 x.2.2) :=
  Factors.of_eq (fun a => !a) fun ⟨h, t, n⟩ => q14_liable_iff_unauthorized h t n

theorem q14_fault_makes_trustee_liable (t n : Bool) (h : t = true ∨ n = true) :
    lossLiable .trustee t n = true := by
  rcases h with h | h <;> simp [lossLiable, h]

/-! ## Q18 / Q19 — ḍamān: fungibles by their like, others by value; an unattainable
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

/-- Q19 is S2: the stipulated price, falling back to value. -/
theorem q19_is_priority (s : Option Nat) (v : Nat) : priceDue s v = resolveD [s] v := by
  cases s <;> rfl

/-! ## Q20 — an unidentifiable right-holder is treated as non-existent -/

inductive Recipient where
  | owner | publicInterest
  deriving DecidableEq, Repr

def recipient (ownerIdentifiable : Bool) : Recipient :=
  if ownerIdentifiable then .owner else .publicInterest

theorem q20_unknown_owner (b : Bool) : recipient b = .publicInterest ↔ b = false := by
  cases b <;> simp [recipient]

/-- Q20 is S2: the owner when identifiable, falling back to the public interest. -/
theorem q20_is_priority (b : Bool) :
    recipient b = resolveD [if b then some .owner else none] .publicInterest := by
  cases b <;> rfl

/-! ## Q21 — uncertainty and gambling are forbidden in exchanges and contests -/

inductive ContractKind where
  | exchange | contest | gift
  deriving DecidableEq, Repr

def ghararForbidden (k : ContractKind) (gharar : Bool) : Bool := gharar && k != .gift

theorem q21_forbidden_iff (k : ContractKind) (g : Bool) :
    ghararForbidden k g = true ↔ g = true ∧ k ≠ .gift := by
  cases k <;> cases g <;> simp [ghararForbidden]

/-- Q21 is S3: gharar is an impediment, outside gifts. -/
theorem q21_is_gate (k : ContractKind) (g : Bool) :
    ghararForbidden k g = false ↔
      (Sadi.Gate.ofBools [] [fun x : ContractKind × Bool => x.2 && x.1 != .gift]).Holds (k, g) := by
  rw [Sadi.Gate.holds_ofBools]; cases k <;> cases g <;> simp [ghararForbidden]

/-! ## Q24 — whoever reaches an unowned permissible thing first has the better right -/

/-- The claimant with the earliest time (Q33's `best` on the negated time). -/
def firstClaimant {P : Type} (claims : List (P × Nat)) : Option (P × Nat) :=
  Sadi.best (fun c => -(c.2 : Int)) claims

theorem q24_first_has_priority {P : Type} {claims : List (P × Nat)} {w : P × Nat}
    (h : firstClaimant claims = some w) : ∀ c ∈ claims, w.2 ≤ c.2 :=
  Sadi.q33_lighter_harm (fun c : P × Nat => c.2) h

/-- Q24 is S8 on the negated time. -/
theorem q24_is_optimal {P : Type} {claims : List (P × Nat)} {w : P × Nat}
    (h : firstClaimant claims = some w) : Optimal (fun c => -(c.2 : Int)) claims w :=
  best_optimal h

/-! ## Q25 — lots are prescribed when the entitled is unknown and division impossible -/

def lotPrescribed (entitledKnown divisible : Bool) : Bool := !entitledKnown && !divisible

theorem q25_lot_iff (k d : Bool) : lotPrescribed k d = true ↔ k = false ∧ d = false := by
  cases k <;> cases d <;> simp [lotPrescribed]

inductive Allocation where
  | toEntitled | divide | lot
  deriving DecidableEq, Repr

/-- Q25 is S2: give to the known entitled, else divide, else cast lots. -/
def allocation (entitledKnown divisible : Bool) : Allocation :=
  resolveD [if entitledKnown then some .toEntitled else none, if divisible then some .divide else none] .lot

theorem q25_lot_is_last_resort (k d : Bool) : allocation k d = .lot ↔ lotPrescribed k d = true := by
  cases k <;> cases d <;> simp [allocation, lotPrescribed, resolveD, first]

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

/-- The presumption about a return: made, when the thing was held for the owner (amāna) and
nothing in sense or custom belies it; otherwise not made (the presumption of ʿadam). -/
def returnPresumption (h : HeldFor) (contradicts : Bool) : Bool := h == .owner && !contradicts

/-- Q26 and Q43 are S6: the trustee's claim is taken on oath exactly when it agrees with the
presumption; contradiction by sense or custom (a Q52 qarīna) displaces it. -/
theorem q26_q43_from_presumption (h : HeldFor) (c : Bool) :
    returnClaimAccepted h c = (burdenOf (returnPresumption h c) true == .yamin) := by
  cases h <;> cases c <;> rfl

/-! ## Q35 — whoever escapes punishment for a reason owes doubled ḍamān («ضوعف عليه الضمان») -/

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

/-- Q37 is S8 on the strength of evidence. -/
theorem q37_is_optimal {P : Type} {claims : List (P × Nat)} {w : P × Nat}
    (h : prevailing claims = some w) : Optimal (fun c => (c.2 : Int)) claims w :=
  best_optimal h

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

/-- Q47 is S1: the status ignores its source … -/
theorem q47_ignores_source : Factors obligationStatus (fun _ => ()) :=
  Factors.of_eq (fun _ => .wajib) fun _ => rfl

/-- … so every ruling computed from the status (making up, kaffāra, sin of omission, …)
is the same for a vow as for the law. -/
theorem q47_consequences {β : Type} (g : Hukm → β) :
    g (obligationStatus .vow) = g (obligationStatus .sharia) :=
  (q47_ignores_source.post g).qiyas rfl

/-! ## Q49 — basic needs are not surplus wealth -/

def surplus (assets basicNeeds : Nat) : Nat := assets - basicNeeds

theorem q49_needs_excluded (a n : Nat) : surplus a n + min a n = a := by
  unfold surplus; omega

/-! ## Q53 — when a contract proves fāsid, what was built on it is bāṭil («إذا تبين فساد العقد، بطل ما بني عليه»); a voluntary rescission
leaves earlier dependent contracts standing -/

inductive Ending where
  | provedVoid | rescinded
  deriving DecidableEq, Repr

def dependentsSurvive : Ending → Bool
  | .provedVoid => false
  | .rescinded => true

theorem q53_distinction : dependentsSurvive .provedVoid ≠ dependentsSurvive .rescinded := by
  simp [dependentsSurvive]

section Voiding

variable {C : Type}

/-- Q53 is S4: the bāṭil contracts are the closure of those proved fāsid under "built on". -/
def Voided (builtOn : C → C → Prop) (ending : C → Option Ending) : C → Prop :=
  Closure builtOn (fun c => ending c = some .provedVoid)

theorem q53_void_propagates {builtOn : C → C → Prop} {ending : C → Option Ending} {a b : C}
    (ha : Voided builtOn ending a) (h : builtOn a b) : Voided builtOn ending b :=
  .step ha h

/-- Rescinding a contract (not proved fāsid) makes nothing bāṭil: the closure is unchanged. -/
theorem q53_rescission_inert [DecidableEq C] (builtOn : C → C → Prop) (ending : C → Option Ending)
    (c₀ : C) (h₀ : ending c₀ ≠ some .provedVoid) (c : C) :
    Voided builtOn (fun c => if c = c₀ then some .rescinded else ending c) c ↔ Voided builtOn ending c := by
  have hseed : ∀ c, (if c = c₀ then some Ending.rescinded else ending c) = some .provedVoid ↔
      ending c = some .provedVoid := by
    intro c
    by_cases hc : c = c₀
    · subst hc; simp [h₀]
    · simp [hc]
  exact ⟨Closure.mono (fun c h => (hseed c).1 h) (fun _ _ h => h) c,
    Closure.mono (fun c h => (hseed c).2 h) (fun _ _ h => h) c⟩

end Voiding

/-! ## Q54 — in transactions the actual state of affairs counts, not belief -/

def dispositionValid (actuallyEntitled _believedEntitled : Bool) : Bool := actuallyEntitled

theorem q54_belief_irrelevant (a b b' : Bool) : dispositionValid a b = dispositionValid a b' := rfl

/-- Q54 is S1: validity ignores belief. -/
theorem q54_ignores_belief : Ignores dispositionValid := fun _ _ _ => rfl

/-! ## Q55 — no excuse for one who confessed, even if he claims error -/

def confessionBinds (_claimsError : Bool) : Bool := true

theorem q55_error_claim_irrelevant (e : Bool) : confessionBinds e = true := rfl

inductive Plea where
  | confess | claimError | retract
  deriving DecidableEq, Repr

/-- Whether the confessor is bound after a plea (in the rights of persons). -/
def plead (bound : Bool) : Plea → Bool
  | .confess => true
  | _ => bound

/-- Q55 is S5: after a confession every later plea is inert, whatever came before. -/
theorem q55_confession_absorbs (pre post : List Plea) :
    (pre ++ Plea.confess :: post).foldl plead false = true := by
  rw [List.foldl_append, List.foldl_cons]
  exact inert_fold plead (· = true) true rfl post fun e _ s hs => by subst hs; cases e <;> rfl

/-! ## Q56 — the heir stands in the deceased's place in everything of the estate

The statement goes on «إلا ما استثني من خيار الشرط والشفعة إذا لم يطالب المورث في قول ضعيف».
The mashhūr from Aḥmad excepts the two; al-Saʿdī: «والصحيح: أنها مثل غيرها؛ لأن المقصود واحد …
وما قيل فيها من التعليل موجود في غيرها», and again in the furūq (F37): «من الفروق الضعيفة جداً».
Where the madhhab is divided the position is a parameter; `sahih` is al-Saʿdī's, and the rule as
he states it. -/

inductive EstateRight where
  | ownership | debtClaim | khiyarShart | shufaUnclaimed
  deriving DecidableEq, Repr

inductive Q56Reading where
  | sahih | mashhur
  deriving DecidableEq, Repr

def inherits : Q56Reading → EstateRight → Bool
  | .mashhur, .khiyarShart | .mashhur, .shufaUnclaimed => false
  | _, _ => true

/-- al-Saʿdī: the heir inherits every right of the estate. -/
theorem q56_heir_in_everything (r : EstateRight) : inherits .sahih r = true := by
  cases r <;> rfl

/-- The mashhūr, which he calls weak: everything but khiyār al-sharṭ and an unclaimed shufʿa. -/
theorem q56_mashhur_exceptions (r : EstateRight) :
    inherits .mashhur r = false ↔ r = .khiyarShart ∨ r = .shufaUnclaimed := by
  cases r <;> simp [inherits]

/-- The two readings part exactly on the two rights the mashhūr excepts. -/
theorem q56_readings_differ_iff (r : EstateRight) :
    inherits .sahih r ≠ inherits .mashhur r ↔ r = .khiyarShart ∨ r = .shufaUnclaimed := by
  cases r <;> simp [inherits]

/-! ## Q30 — a refusing co-owner is compelled to what the common holding necessarily requires -/

def partnerMustJoin (necessary consents : Bool) : Bool := necessary || consents

theorem q30_necessity_compels (c : Bool) : partnerMustJoin true c = true := by
  cases c <;> rfl

theorem q30_otherwise_by_consent (c : Bool) : partnerMustJoin false c = c := by
  cases c <;> rfl

/-! ## Q32 — whoever pays another's obligation has recourse against him, unless he gave it -/

def recourse (intendedGift : Bool) (paid : Nat) : Nat := if intendedGift then 0 else paid

theorem q32_recourse_for_paid (p : Nat) : recourse false p = p := rfl
theorem q32_gift_no_recourse (p : Nat) : recourse true p = 0 := rfl
theorem q32_never_more_than_paid (g : Bool) (p : Nat) : recourse g p ≤ p := by
  cases g <;> simp [recourse]

/-- Q32 is S3: having paid as a gift is the impediment to recourse. -/
theorem q32_is_gate (g : Bool) {p : Nat} (hp : 0 < p) :
    0 < recourse g p ↔ (Sadi.Gate.ofBools [] [fun x : Bool => x]).Holds g := by
  rw [Sadi.Gate.holds_ofBools]; cases g <;> simp [recourse, hp]

/-! ## Q42 — reserving a usufruct: a known one in exchanges, known or unknown in gifts -/

def reservationValid (k : ContractKind) (known : Bool) : Bool := known || k == .gift

/-- Q42 is Q21 applied to the reserved usufruct: the reservation is valid exactly when
its uncertainty is not forbidden gharar. -/
theorem q42_instance_of_q21 (k : ContractKind) (known : Bool) :
    reservationValid k known = !ghararForbidden k !known := by
  cases k <;> cases known <;> rfl

/-! ## Q45 — whose consent a contract or rescission does not require, his knowledge it
does not require either -/

structure Requirement where
  consent : Bool
  knowledge : Bool
  deriving DecidableEq, Repr

/-- Q45 as a coherence condition: knowledge is required only where consent is. -/
def Requirement.Coherent (r : Requirement) : Prop := r.knowledge = true → r.consent = true

/-- Bring a requirement in line with Q45 by dropping an unsupported knowledge requirement. -/
def Requirement.normalize (r : Requirement) : Requirement :=
  { r with knowledge := r.knowledge && r.consent }

theorem q45_normalize_coherent (r : Requirement) : r.normalize.Coherent := by
  cases r with | mk c k => cases c <;> cases k <;> simp [Requirement.normalize, Requirement.Coherent]

theorem q45_normalize_fixes_coherent (r : Requirement) (h : r.Coherent) : r.normalize = r := by
  cases r with | mk c k => cases c <;> cases k <;> simp_all [Requirement.normalize, Requirement.Coherent]

/-- `normalize` is an interior operator onto the coherent requirements. -/
theorem q45_normalize_idem (r : Requirement) : r.normalize.normalize = r.normalize :=
  q45_normalize_fixes_coherent r.normalize (q45_normalize_coherent r)

/-! ## Q51 — the causes and motives of contracts and gifts are taken into account -/

inductive Motive where
  | lawful | unlawful
  deriving DecidableEq, Repr

def contractValid (formValid : Bool) (m : Motive) : Bool := formValid && m == .lawful

theorem q51_form_insufficient : contractValid true .unlawful = false := rfl

theorem q51_valid_iff (f : Bool) (m : Motive) :
    contractValid f m = true ↔ f = true ∧ m = .lawful := by
  cases f <;> cases m <;> simp [contractValid]

/-- Q51 and Q54 agree: motive counts (Q51), belief about entitlement does not (Q54);
a disposition needs actual entitlement and a lawful motive. -/
theorem q51_q54_consistent (a b b' : Bool) (m : Motive) :
    contractValid (dispositionValid a b) m = contractValid (dispositionValid a b') m := rfl

/-- Q12 ⊓ Q51 (S3): a deal is the exchange gate read on deals, met with the motive gate. -/
structure Deal where
  exchange : Exchange
  motive : Motive

def Deal.gate : Sadi.Gate Deal :=
  (Exchange.gate.comap Deal.exchange).meet (Sadi.Gate.ofBools [fun d => d.motive == .lawful] [])

theorem deal_holds_iff (d : Deal) :
    Deal.gate.Holds d ↔ Exchange.gate.Holds d.exchange ∧ d.motive = .lawful := by
  rw [Deal.gate, Sadi.Gate.holds_meet, Sadi.Gate.holds_comap, Sadi.Gate.holds_ofBools]
  rcases d with ⟨e, m⟩
  cases m <;> simp

end Usul.Muamalat
