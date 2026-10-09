import Usul

/-! Source contrasts within existing farʿ records, in addition to the generated main guards.
All amounts here are synthetic witnesses that distinguish named price from equivalent value.
No guard adopts a scholarly position or supplies a missing source fact. -/

open Usul.Refinements

-- q31.f002: corruption requires the earlier place of iḥrām; prevention does not.
#guard makeupAfterFailure .corruption == .asBegun
#guard makeupAfterFailure .prevention == .baseline

-- q31.f003: the fault branch and the selected al-Mughnī no-fault branch differ.
#guard makeupAfterFailure .lossWithFault == .asBegun
#guard makeupAfterFailure .lossWithoutFault == .baseline

-- q47.f000–1: a named price cannot replace equivalent compensation in the loss reading.
#guard defectiveCompensation false 7 11 == 11
#guard defectiveCompensation false 13 11 == 11
-- q47.f002–3: the selected contract reading preserves the named consideration.
#guard defectiveCompensation true 7 11 == 7
#guard defectiveCompensation true 7 13 == 7

-- PR #32: the generic readings retain their explicit input boundaries.
#guard runningBody false == .whole
#guard runningBody true == .perJirya
#guard preferMany false == false
#guard preferMany true == true
#guard validWithBasis true false == false
#guard validWithBasis false true == false
#guard validWithBasis true true == true
#guard handLiable false == false
#guard handLiable true == true
-- The input refers to the liability object being checked, not every object in the record.
#guard takerRecourse true == false
#guard takerRecourse false == true
