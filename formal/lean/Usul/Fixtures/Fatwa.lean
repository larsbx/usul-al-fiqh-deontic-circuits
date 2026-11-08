import Usul.Refinements

/-!
# Native ordered fatwa oracle

The input is a finite database of ground atoms. Absent facts remain absent: in
particular, failure to find `fault = true` differs from finding `fault = false`.
The encoder bank delegates to the existing Lean kernels. The extended oracle
tries the source rules in their declared order and retains the first decision.
Generated fixtures contain only input facts and declared expectations.
-/

namespace Usul.Fixtures.Fatwa

abbrev Facts := List (String × String)

structure Case where
  id : String
  encoder : String
  encoderFacts : Facts := []
  facts : Facts := []
  textRuling : Option String := none
  positions : List String := []
  deriving Repr, DecidableEq

def lookup (facts : Facts) (key : String) : Option String :=
  (facts.find? fun p => p.1 == key).map Prod.snd

def has (facts : Facts) (key value : String) : Bool :=
  lookup facts key == some value

def boolAtom (b : Bool) : String := if b then "true" else "false"

def grade : String → Option Usul.Grade
  | "wahm" => some .wahm
  | "shakk" => some .shakk
  | "zann" => some .zann
  | "qat" => some .qat
  | _ => none

def purpose : String → Option Usul.Muamalat.Purpose
  | "benefit" => some .benefit
  | "repelHarm" => some .repelHarm
  | _ => none

def itlaf (p : String) : Option String := do
  let p ← purpose p
  pure (boolAtom (Usul.Muamalat.itlafLiable (Usul.Muamalat.withRight p) .deliberate))

def luqataAtom : Usul.Refinements.LuqataOutcome → String
  | .hold => "hold"
  | .finderOwns => "finderOwns"
  | .charity => "charity"

def recipientAtom : Usul.Muamalat.Recipient → String
  | .owner => "owner"
  | .publicInterest => "publicInterest"

/-- The bank preserves the source's sparse-input behavior. A true trust-loss
flag suffices without a hand, but a false answer requires a hand fact. -/
def bank (c : Case) : Option String := do
  let f := c.encoderFacts
  match c.encoder with
  | "trust_loss" =>
    if has f "hand" "wrongdoer" || has f "transgressed" "true" || has f "negligent" "true" then
      pure (boolAtom (Usul.Muamalat.lossLiable
        (if has f "hand" "wrongdoer" then .wrongdoer else .trustee)
        (has f "transgressed" "true") (has f "negligent" "true")))
    else
      let _ ← lookup f "hand"
      pure (boolAtom (Usul.Muamalat.lossLiable .trustee false false))
  | "itlaf" => (lookup f "purpose").bind itlaf
  | "asl_zahir" =>
    let a ← (lookup f "asl_grade").bind grade
    let z ← (lookup f "zahir_grade").bind grade
    let amara ← lookup f "amara"
    pure (boolAtom (Usul.Refinements.zahirPrevails a z (amara == "true")))
  | "luqata" =>
    let y ← lookup f "year_passed"
    let o ← lookup f "ownable"
    pure (luqataAtom (Usul.Refinements.luqata (y != "false") (o == "true")))
  | "unknown_owner" =>
    let i ← lookup f "owner_identifiable"
    pure (recipientAtom (Usul.Muamalat.recipient (i == "true")))
  | _ => none

structure Decision where
  ruling : String
  rule : String
  deriving Repr, DecidableEq, BEq

/-- `enabled` supports exact, compiling semantic mutation controls. -/
def applyRule (name : String) (enabled : Bool) (result : Option String) : Option Decision :=
  if enabled then result.map (fun ruling => ⟨ruling, name⟩) else none

def whenFact (condition : Bool) (result : String) : Option String :=
  if condition then some result else none

def liabilityRules (c : Case) : List (Option Decision) :=
  let f := c.facts
  [applyRule "no_legal_value" true (whenFact (has f "has_legal_value" "false") "false"),
   applyRule "lawful_authority" true (whenFact (has f "lawful_authority_act" "true") "false"),
   applyRule "sirayat_al_jinaya" true (lookup f "death_from_injury"),
   applyRule "unattributed_death" true (whenFact
     (has f "later_death" "true" && (lookup f "death_from_injury").isNone) "false"),
   applyRule "itlaf_bi_haqq" true ((lookup f "purpose").bind itlaf),
   applyRule "physician" true (if has f "physician" "true" && has f "permitted" "true"
     then lookup f "fault" else none),
   applyRule "guarantee_by_contract" true (whenFact (has f "hand" "guarantor_by_contract") "true"),
   applyRule "hand_of_trust" true (do
     let h ← lookup f "hand"
     if h == "guarantor_by_contract" then none else do
       let t ← lookup f "transgressed"
       let n ← lookup f "negligent"
       pure (boolAtom (Usul.Muamalat.lossLiable
         (if h == "wrongdoer" then .wrongdoer else .trustee) (t == "true") (n == "true")))),
   applyRule "quwwa_qahira" true (whenFact
     (has f "unavoidable" "true" && !(has f "fault" "true")) "false"),
   applyRule "victim_fault" true (whenFact
     (has f "victim_fault" "true" && has f "fault" "false") "false"),
   applyRule "mubashir_liable" true (whenFact (has f "causation" "direct") "true"),
   applyRule "mubashir_first" true (whenFact
     (has f "causation" "indirect" && has f "other_direct_actor" "true") "false"),
   applyRule "mutasabbib_by_fault" true (if has f "causation" "indirect" then lookup f "fault" else none),
   applyRule "no_causation" true (whenFact (has f "causation" "none") "false"),
   applyRule "bank" true (bank c)]

def doubtRules (c : Case) : List (Option Decision) :=
  let f := c.facts
  [applyRule "sufra_kudra_after_tuhr" true (whenFact (has f "discharge_after_purity" "true") "false"),
   applyRule "bayyina_in_qada" true (whenFact (has f "forum" "qada" && !(has f "bayyina" "true")) "false"),
   applyRule "bank" true (bank c)]

def foundPropertyRules (c : Case) : List (Option Decision) :=
  let f := c.facts
  [applyRule "rikaz" true (whenFact (has f "buried_treasure" "true" && !(has f "muslim_buried" "true")) "rikazFifth"),
   applyRule "trivial_find" true (whenFact (has f "trivial" "true") "keepNow"),
   applyRule "haram_makka" true (whenFact (has f "location" "makka_haram") "hold"),
   applyRule "dallat_al_ibil" true (whenFact (has f "animal" "self_preserving" || has f "self_keeping" "true") "leave"),
   applyRule "perishable_find" true (whenFact (has f "perishable" "true") "hold"),
   applyRule "dallat_al_ghanam" true (whenFact (has f "animal" "vulnerable")
     (if has f "year_passed" "true" then "finderOwns" else "hold")),
   applyRule "announced_year" true ((lookup f "year_passed").map fun y => if y == "true" then "finderOwns" else "hold"),
   applyRule "bank" true (bank c)]

def unknownOwnerRules (c : Case) : List (Option Decision) :=
  let f := c.facts
  [applyRule "illicit_exchange" true (whenFact (has f "illicit_exchange" "true") "publicInterest"),
   applyRule "owner_appears_after_charity" true (whenFact (has f "owner_later_appears" "true") "ownerChooses"),
   applyRule "family_recipient" true (whenFact
     (has f "owner_identifiable" "false" && has f "recipient_is_own_family" "true") "familyAllowed"),
   applyRule "recipient" true ((lookup f "owner_identifiable").map fun i =>
     recipientAtom (Usul.Muamalat.recipient (i == "true"))),
   applyRule "bank" true (bank c)]

def firstDecision : List (Option Decision) → Option Decision
  | [] => none
  | none :: rest => firstDecision rest
  | some d :: _ => some d

def oracle (c : Case) : Option Decision :=
  firstDecision (match c.encoder with
    | "trust_loss" | "itlaf" => liabilityRules c
    | "asl_zahir" => doubtRules c
    | "luqata" => foundPropertyRules c
    | "unknown_owner" => unknownOwnerRules c
    | _ => [])

def sameRuling (a b : String) : Bool :=
  a == b || (a == "hold" && b == "handToAuthority") ||
    (a == "handToAuthority" && b == "hold")

def agrees (c : Case) : Bool :=
  match oracle c, c.textRuling with
  | some d, some t => sameRuling d.ruling t
  | _, _ => false

def withinPositions (c : Case) : Bool :=
  match oracle c with
  | some d => c.positions.any (sameRuling d.ruling)
  | none => false

inductive Query where
  | bank (id ruling : String)
  | oracle (id : String) (ruling rule : Option String)
  | agrees (id : String)
  | withinPositions (id : String)
  | textRuling (id : String) (ruling : Option String)
  | undefined (predicate : String)
  deriving Repr, DecidableEq

def Query.caseId : Query → Option String
  | .bank id _ | .oracle id _ _ | .agrees id | .withinPositions id | .textRuling id _ => some id
  | .undefined _ => none

def matchesAtom (requested : Option String) (actual : String) : Bool :=
  requested.all (· == actual)

/-- Missing ground cases/facts fail normally; an undefined predicate is an
evaluation error, so a negative expectation cannot conceal it. -/
def evaluate (cases : List Case) (q : Query) : Except String Bool := do
  match q with
  | .undefined predicate => throw s!"undefined fatwa predicate: {predicate}"
  | _ =>
    let some c := cases.find? (fun c => q.caseId == some c.id) | pure false
    pure (match q with
      | .bank _ expected => bank c == some expected
      | .oracle _ ruling rule =>
        match oracle c with
        | some d => matchesAtom ruling d.ruling && matchesAtom rule d.rule
        | none => false
      | .agrees _ => agrees c
      | .withinPositions _ => withinPositions c
      | .textRuling _ ruling => c.textRuling.any (matchesAtom ruling)
      | .undefined _ => false)

/-- An applicable first rule is never replaced by a later rule. -/
theorem firstDecision_head (d : Decision) (rest : List (Option Decision)) :
    firstDecision (some d :: rest) = some d := rfl

/-- Adding an inapplicable rule preserves the selected decision. -/
theorem firstDecision_skip (rest : List (Option Decision)) :
    firstDecision (none :: rest) = firstDecision rest := rfl

/-- Every selected result is an actual candidate; no default ruling is invented. -/
theorem firstDecision_member (xs : List (Option Decision)) (d : Decision)
    (h : firstDecision xs = some d) : some d ∈ xs := by
  induction xs with
  | nil => simp [firstDecision] at h
  | cons x xs ih =>
    cases x with
    | none => exact List.mem_cons_of_mem _ (ih h)
    | some a =>
      simp only [firstDecision, Option.some.injEq] at h
      subst a
      exact List.mem_cons_self

/-- No text ruling means no agreement, even if an oracle rule applies. -/
theorem agrees_requires_text (c : Case) (h : c.textRuling = none) : agrees c = false := by
  simp [agrees, h]

/-- A disputed case with no reported positions cannot pass vacuously. -/
theorem positions_nonvacuous (c : Case) (h : c.positions = []) : withinPositions c = false := by
  simp [withinPositions, h]
  cases oracle c <;> rfl

end Usul.Fixtures.Fatwa
