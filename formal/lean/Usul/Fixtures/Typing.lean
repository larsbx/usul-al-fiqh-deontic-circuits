import Usul.Fixtures.TypingData

/-!
# Finite typed routing

The generated declarations contain every exported type, field, encoder read,
and implication. Values remain atoms: knowing a field is distinct from knowing
that its Boolean value is true. This evaluator computes the least finite closure
of the directed implications, with original facts taking priority by field.

Derived facts are a relation, not a single-value record. Two applicable rules
may derive different values of an initially absent field, and both values remain
available to later rules. Only an explicitly stated value prevents derivation.
The closure bound is the number of possible consequent occurrences plus one;
each productive round adds a previously absent consequent fact.
-/
namespace Usul.Fixtures.Typing

abbrev Fact := String × String
abbrev Facts := List Fact

structure Rule where
  name : String
  premises : Facts
  consequences : Facts
  deriving Repr, DecidableEq, BEq

def rules : List Rule :=
  Data.implications.map fun (name, premises, consequences) => ⟨name, premises, consequences⟩

def stated (situation : String) : Facts :=
  Data.situations.filterMap fun (s, field, value) =>
    if s == situation then some (field, value) else none

def hasField (facts : Facts) (field : String) : Bool :=
  facts.any fun fact => fact.1 == field

def ruleEnabled (rule : Rule) (facts : Facts) : Bool :=
  rule.premises.all facts.contains

/-- Test the original facts, never the growing derived relation. -/
def addConsequence (original current : Facts) (fact : Fact) : Facts :=
  if !hasField original fact.1 && !current.contains fact then fact :: current
  else current

def applyRule (original current : Facts) (rule : Rule) : Facts :=
  if ruleEnabled rule current then
    rule.consequences.foldl (addConsequence original) current
  else current

def closeRound (relations : List Rule) (original current : Facts) : Facts :=
  relations.foldl (applyRule original) current

def closeFuel (relations : List Rule) (original : Facts) : Nat → Facts → Facts
  | 0, current => current
  | fuel + 1, current =>
      let next := closeRound relations original current
      if next == current then current else closeFuel relations original fuel next

def close (relations : List Rule) (original : Facts) : Facts :=
  if original.isEmpty then []
  else closeFuel relations original
    ((relations.map (fun rule => rule.consequences.length)).sum + 1) original

def closure (situation : String) : Facts := close rules (stated situation)

def holds (situation field value : String) : Bool :=
  (closure situation).contains (field, value)

def known (situation field : String) : Bool := hasField (closure situation) field

def situationExists (situation : String) : Bool := !(stated situation).isEmpty

def encoderDeclared (encoder : String) : Bool :=
  Data.encoderTypes.any fun entry => entry.1 == encoder

def qaidaDeclared (qaida : String) : Bool :=
  Data.qaidaTypes.any fun entry => entry.1 == qaida

def allReads : List (String × Nat × String) := Data.encoderReads ++ Data.syntheticReads

def readFields (encoder : String) : List String :=
  allReads.filterMap fun (e, _, field) => if e == encoder then some field else none

def reads (encoder field : String) : Bool := (readFields encoder).contains field

def allFields : List (String × String × String) := Data.typeFields ++ Data.syntheticFields

def typedField (field : String) : Bool :=
  allFields.any fun (_, candidate, _) => candidate == field

def directFieldOf (qaida field : String) : Bool :=
  allFields.any fun (owner, candidate, _) => owner == qaida && candidate == field

def fieldOfFuel : Nat → String → String → Bool
  | 0, qaida, field => directFieldOf qaida field
  | fuel + 1, qaida, field =>
      directFieldOf qaida field ||
        Data.typeExtends.any (fun (child, parent) =>
          child == qaida && fieldOfFuel fuel parent field)

def fieldOf (qaida field : String) : Bool :=
  fieldOfFuel (Data.qaidaTypes.length + 1) qaida field

def typeBelowFuel : Nat → String → String → Bool
  | 0, child, ancestor => child == ancestor
  | fuel + 1, child, ancestor =>
      child == ancestor || Data.typeExtends.any (fun (t, parent) =>
        t == child && typeBelowFuel fuel parent ancestor)

def typeBelow (child ancestor : String) : Bool :=
  typeBelowFuel (Data.qaidaTypes.length + 1) child ancestor

def related (left right : String) : Bool := typeBelow left right || typeBelow right left

def applies (encoder situation : String) : Bool :=
  encoderDeclared encoder && situationExists situation &&
    (readFields encoder).all (known situation)

def route (situation encoder : String) : Bool := applies encoder situation

def missingFact (encoder situation field : String) : Bool :=
  situationExists situation && reads encoder field && !known situation field

def shares (field first second : String) : Bool :=
  decide (first < second) && reads first field && reads second field

def illTyped (encoder field : String) : Bool :=
  reads encoder field && !typedField field

def unrelatedSharedField (field first second : String) : Bool :=
  decide (first < second) && directFieldOf first field && directFieldOf second field &&
    !related first second

/-- Quantify over every exported encoder, including those without named cases. -/
def allExportedWellTyped : Bool :=
  Data.encoderTypes.all fun (encoder, _) =>
    (readFields encoder).all fun field => !illTyped encoder field

/-- Synthetic collision witnesses are excluded exactly as in the original query. -/
def noSilentIdentification : Bool :=
  allFields.all fun (first, field, _) =>
    allFields.all fun (second, otherField, _) =>
      field != otherField || first.startsWith "fx_" || second.startsWith "fx_" ||
        !unrelatedSharedField field first second

def coverage (encoder situation : String) : Option (Nat × Nat) :=
  if encoderDeclared encoder && situationExists situation then
    let fields := readFields encoder
    some ((fields.filter (known situation)).length, fields.length)
  else none

/-- An absent situation cannot seed even a rule with no premises. -/
theorem close_empty (relations : List Rule) : close relations [] = [] := rfl

/-- Appending a consequence never erases facts already in the relation. -/
theorem addConsequence_preserves (original current : Facts) (fact old : Fact)
    (present : old ∈ current) : old ∈ addConsequence original current fact := by
  unfold addConsequence
  split
  · exact List.mem_cons_of_mem _ present
  · exact present

private theorem foldl_preserves_mem {α : Type} (step : Facts → α → Facts)
    (safe : ∀ current item old, old ∈ current → old ∈ step current item)
    (items : List α) (current : Facts) (old : Fact) (present : old ∈ current) :
    old ∈ items.foldl step current := by
  induction items generalizing current with
  | nil => exact present
  | cons item rest ih =>
      exact ih (step current item) (safe current item old present)

theorem applyRule_preserves (original current : Facts) (rule : Rule) (old : Fact)
    (present : old ∈ current) : old ∈ applyRule original current rule := by
  unfold applyRule
  split
  · exact foldl_preserves_mem (addConsequence original)
      (fun current item old h => addConsequence_preserves original current item old h)
      rule.consequences current old present
  · exact present

theorem closeRound_preserves (relations : List Rule) (original current : Facts)
    (old : Fact) (present : old ∈ current) :
    old ∈ closeRound relations original current :=
  foldl_preserves_mem (applyRule original)
    (fun current rule old h => applyRule_preserves original current rule old h)
    relations current old present

theorem closeFuel_preserves (relations : List Rule) (original : Facts) (fuel : Nat)
    (current : Facts) (old : Fact) (present : old ∈ current) :
    old ∈ closeFuel relations original fuel current := by
  induction fuel generalizing current with
  | zero => exact present
  | succ fuel ih =>
      simp only [closeFuel]
      split
      · exact present
      · exact ih _ (closeRound_preserves relations original current old present)

/-- Every explicitly stated fact survives all rounds, for arbitrary finite rules. -/
theorem close_preserves (relations : List Rule) (original : Facts) (old : Fact)
    (present : old ∈ original) : old ∈ close relations original := by
  cases original with
  | nil => cases present
  | cons first rest =>
      exact closeFuel_preserves relations (first :: rest) _ (first :: rest) old present

end Usul.Fixtures.Typing
