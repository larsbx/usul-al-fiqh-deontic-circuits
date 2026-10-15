-- Candidate semantic controls. These are encoder component checks, not legal verdicts.
import Usul.Readings.RajabA10
import Usul.Readings.RajabA2
import Usul.Refinements

-- Harb chronology supplies neither value of this structurally defined priority input.
-- Both evaluations are retained to show why extracting the Boolean value is load-bearing.
#guard Usul.Readings.RajabA10.simultaneousCombinationVoids true == false
#guard Usul.Readings.RajabA10.simultaneousCombinationVoids false == true

-- The fuller/tailor component is independent of the unstated public/rescue dimension.
example (publicOrRescue : Bool) :
    Usul.Readings.RajabA2.wageWithoutStipulation true publicOrRescue = true := by
  cases publicOrRescue <;> rfl

-- The judicial lot component does not require guessing whether the property is divisible.
example (divisible : Bool) :
    Usul.Refinements.allocationFull false divisible true = .lot := by
  cases divisible <;> rfl
