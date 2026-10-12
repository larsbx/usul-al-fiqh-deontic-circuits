import Usul.Typing
import Usul.Readings.Mubashara

/-!
# The remaining encoders, typed

Each encoder of `takhrij.ENCODERS` typed over `Situation` by the facts of its qāʿida's type
(`Usul.Typing.Qaida`). `run` is the encoder's existing kernel term, so typing changes no ruling.
-/

namespace Usul.Typing

open Usul Usul.Muamalat

/-- `amr` reads `Qaida.Lahham43`. -/
def amr : Typed Situation (Usul.Hukm) where
  Local := (Option Usul.Hukm)
  proj s := s.qarina
  embed x1 := { qarina := some x1 }
  run x1 := Usul.Dalala.amrStatus x1
  proj_embed := fun _ => rfl

/-- `amr_mixed` reads `Qaida.Lahham43`. -/
def amrMixed : Typed Situation (Usul.Hukm) where
  Local := (Usul.Hukm)
  proj s := s.perItemStatus
  embed x1 := { perItemStatus := some x1 }
  run x1 := Usul.Refinements.amrPerItem (fun _ : Unit => x1) ()
  proj_embed := fun _ => rfl

/-- `command_intended_usage` reads `Qaida.Lahham43`. -/
def commandIntendedUsage : Typed Situation (Usul.CommandSchemata.CommandUsage) where
  Local := (Usul.CommandSchemata.IntendedUseReading) × (Usul.CommandSchemata.IntendedRuling)
  proj s := do pure (← s.intendedReading, ← s.intended)
  embed | (x1, x2) => { intendedReading := some x1, intended := some x2 }
  run | (x1, x2) => Usul.CommandSchemata.intendedUsage x1 x2
  proj_embed := fun _ => rfl

/-- `command_nonverbal_usage` reads `Qaida.Lahham43`. -/
def commandNonverbalUsage : Typed Situation (Usul.CommandSchemata.CommandUsage) where
  Local := (Usul.CommandSchemata.NonverbalReading) × (Usul.CommandSchemata.NonverbalForm)
  proj s := do pure (← s.nonverbalReading, ← s.commandForm)
  embed | (x1, x2) => { nonverbalReading := some x1, commandForm := some x2 }
  run | (x1, x2) => Usul.CommandSchemata.nonverbalUsage x1 x2
  proj_embed := fun _ => rfl

/-- `command_obligation_status` reads `Qaida.Lahham43`. -/
def commandObligationStatus : Typed Situation (Usul.Hukm) where
  Local := (Usul.CommandSchemata.ObligationReading) × (Usul.CommandSchemata.ObligationExpression) × (Option Usul.Hukm)
  proj s := do pure (← s.obligationReading, ← s.expression, ← s.qarina)
  embed | (x1, x2, x3) => { obligationReading := some x1, expression := some x2, qarina := some x3 }
  run | (x1, x2, x3) => Usul.CommandSchemata.obligationStatus x1 x2 x3
  proj_embed := fun _ => rfl

/-- `command_prophetic_act_usage` reads `Qaida.Lahham43`. -/
def commandPropheticActUsage : Typed Situation (Usul.CommandSchemata.CommandUsage) where
  Local := (Usul.CommandSchemata.PropheticActReading) × (Bool)
  proj s := do pure (← s.propheticActReading, ← s.imitationEstablished)
  embed | (x1, x2) => { propheticActReading := some x1, imitationEstablished := some x2 }
  run | (x1, x2) => Usul.CommandSchemata.propheticActUsage x1 x2
  proj_embed := fun _ => rfl

/-- `haml_ala_adna` reads `Qaida.Lahham52`. -/
def hamlAlaAdna : Typed Situation (Bool) where
  Local := (Bool) × (Bool)
  proj s := do pure (← s.unspecified, ← s.ranked)
  embed | (x1, x2) => { unspecified := some x1, ranked := some x2 }
  run | (x1, x2) => Usul.Refinements.hamlAlaAdna x1 x2
  proj_embed := fun _ => rfl

/-- `umum_lafz` reads `Qaida.Lahham61`. -/
def umumLafz : Typed Situation (Bool) where
  Local := (Bool) × (Bool)
  proj s := do pure (← s.inOccasion, ← s.generalWording)
  embed | (x1, x2) => { inOccasion := some x1, generalWording := some x2 }
  run | (x1, x2) => Usul.Dalala.coversBeyondSabab true x1 x2
  proj_embed := fun _ => rfl

/-- `running_water` reads `Qaida.Rajab1`. -/
def runningWater : Typed Situation (Usul.Refinements.Body) where
  Local := (Bool)
  proj s := s.running
  embed x1 := { running := some x1 }
  run x1 := Usul.Refinements.runningBody x1
  proj_embed := fun _ => rfl

/-- `hair_detached` reads `Qaida.Rajab2`. -/
def hairDetached : Typed Situation (Usul.Refinements.Attachment) where
  Local := (Bool)
  proj s := s.hairOrNail
  embed x1 := { hairOrNail := some x1 }
  run x1 := Usul.Refinements.hairStatus x1
  proj_embed := fun _ => rfl

/-- `excess_in_following` reads `Qaida.Rajab3`. -/
def excessInFollowing : Typed Situation (Bool) where
  Local := (Bool) × (Bool) × (Bool)
  proj s := do pure (← s.separable, ← s.lightened, ← s.following)
  embed | (x1, x2, x3) => { separable := some x1, lightened := some x2, following := some x3 }
  run | (x1, x2, x3) => Usul.Refinements.excessObligatoryIn x1 x2 x3
  proj_embed := fun _ => rfl

/-- `excess_over_sufficient` reads `Qaida.Rajab3`. -/
def excessOverSufficient : Typed Situation (Bool) where
  Local := (Bool) × (Bool)
  proj s := do pure (← s.separable, ← s.lightened)
  embed | (x1, x2) => { separable := some x1, lightened := some x2 }
  run | (x1, x2) => Usul.Refinements.excessObligatory x1 x2
  proj_embed := fun _ => rfl

/-- `advance_after_cause` reads `Qaida.Rajab4`. -/
def advanceAfterCause : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.causePresent
  embed x1 := { causePresent := some x1 }
  run x1 := Usul.Refinements.advanceAllowed x1
  proj_embed := fun _ => rfl

/-- `advanced_kaffara_at_obligation` reads `Qaida.Rajab5`. -/
def advancedKaffaraAtObligation : Typed Situation (Bool) where
  Local := (Bool) × (Bool)
  proj s := do pure (← s.dueAtPerformance, ← s.kaffaraChanged)
  embed | (x1, x2) => { dueAtPerformance := some x1, kaffaraChanged := some x2 }
  run | (x1, x2) => Usul.Refinements.advancedSufficesIn x1 x2
  proj_embed := fun _ => rfl

/-- `advanced_worship` reads `Qaida.Rajab5`. -/
def advancedWorship : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.dueAtPerformance
  embed x1 := { dueAtPerformance := some x1 }
  run x1 := Usul.Refinements.advancedSuffices x1
  proj_embed := fun _ => rfl

/-- `prohibited_worship` reads `Qaida.Rajab9`. -/
def prohibitedWorship : Typed Situation (Bool) where
  Local := (Usul.Refinements.Prohibited)
  proj s := s.target
  embed x1 := { target := some x1 }
  run x1 := Usul.Refinements.validDespite x1
  proj_embed := fun _ => rfl

/-- `wording_in_other_tongue` reads `Qaida.Rajab10`. -/
def wordingInOtherTongue : Typed Situation (Bool) where
  Local := (Bool) × (Bool)
  proj s := do pure (← s.meaningOnly, ← s.able)
  embed | (x1, x2) => { meaningOnly := some x1, able := some x2 }
  run | (x1, x2) => Usul.Refinements.otherTongueValid x1 x2
  proj_embed := fun _ => rfl

/-- `wording_need_not_learn` reads `Qaida.Rajab10`. -/
def wordingNeedNotLearn : Typed Situation (Bool) where
  Local := (Bool) × (Bool) × (Bool)
  proj s := do pure (← s.meaningOnly, ← s.able, ← s.needNotLearn)
  embed | (x1, x2, x3) => { meaningOnly := some x1, able := some x2, needNotLearn := some x3 }
  run | (x1, x2, x3) => Usul.Refinements.otherTongueValidIn x1 x2 x3
  proj_embed := fun _ => rfl

/-- `nafl_before_fard` reads `Qaida.Rajab11`. -/
def naflBeforeFard : Typed Situation (Bool) where
  Local := (Bool) × (Bool)
  proj s := do pure (← s.narrow, ← s.financial)
  embed | (x1, x2) => { narrow := some x1, financial := some x2 }
  run | (x1, x2) => Usul.Refinements.naflValid x1 x2
  proj_embed := fun _ => rfl

/-- `combining_forms` reads `Qaida.Rajab12`. -/
def combiningForms : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.substitutes
  embed x1 := { substitutes := some x1 }
  run x1 := Usul.Refinements.combineForms x1
  proj_embed := fun _ => rfl

/-- `cause_from_one_of_two` reads `Qaida.Rajab14`. -/
def causeFromOneOfTwo : Typed Situation (Usul.Refinements.Attach) where
  Local := (Bool)
  proj s := s.harmless
  embed x1 := { harmless := some x1 }
  run x1 := Usul.Refinements.attachTo x1
  proj_embed := fun _ => rfl

/-- `each_on_its_asl` reads `Qaida.Rajab15`. -/
def eachOnItsAsl : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.separateMatters
  embed x1 := { separateMatters := some x1 }
  run x1 := Usul.Refinements.eachOnItsAsl x1
  proj_embed := fun _ => rfl

/-- `many_over_noble` reads `Qaida.Rajab17`. -/
def manyOverNoble : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.sameCost
  embed x1 := { sameCost := some x1 }
  run x1 := Usul.Refinements.preferMany x1
  proj_embed := fun _ => rfl

/-- `settles_without_ability` reads `Qaida.Rajab19`. -/
def settlesWithoutAbility : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.makingUp
  embed x1 := { makingUp := some x1 }
  run x1 := Usul.Refinements.settlesInDhimma x1
  proj_embed := fun _ => rfl

/-- `growth_from_substance` reads `Qaida.Rajab20`. -/
def growthFromSubstance : Typed Situation (Usul.Refinements.Growth) where
  Local := (Bool)
  proj s := s.fromSubstance
  embed x1 := { fromSubstance := some x1 }
  run x1 := Usul.Refinements.growthKind x1
  proj_embed := fun _ => rfl

/-- `khalt_as_shirka` reads `Qaida.Khalt`. -/
def khaltAsShirka : Typed Situation (Usul.Refinements.Mixed) where
  Local := (Bool) × (Bool)
  proj s := do pure (← s.mixedSameKind, ← s.indistinct)
  embed | (x1, x2) => { mixedSameKind := some x1, indistinct := some x2 }
  run | (x1, x2) => Usul.Refinements.mixedOutcome x1 x2
  proj_embed := fun _ => rfl

/-- `mixed_haram_by_proportion` reads `Qaida.Khalt`. -/
def mixedHaramByProportion : Typed Situation (Usul.Refinements.MixedHaram) where
  Local := (Bool)
  proj s := s.lawfulMany
  embed x1 := { lawfulMany := some x1 }
  run x1 := Usul.Refinements.mixedHaram x1
  proj_embed := fun _ => rfl

/-- `right_after_transfer` reads `Qaida.Rajab24`. -/
def rightAfterTransfer : Typed Situation (Bool) where
  Local := (Bool) × (Bool)
  proj s := do pure (← s.onProperty, ← s.reasonCeases)
  embed | (x1, x2) => { onProperty := some x1, reasonCeases := some x2 }
  run | (x1, x2) => Usul.Refinements.rightSurvivesTransfer x1 x2
  proj_embed := fun _ => rfl

/-- `follows_proven_ownership` reads `Qaida.Rajab25`. -/
def followsProvenOwnership : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.followsInSale
  embed x1 := { followsInSale := some x1 }
  run x1 := Usul.Refinements.followsProven x1
  proj_embed := fun _ => rfl

/-- `benefit_to_other` reads `Qaida.Rajab27`. -/
def benefitToOther : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.benefitsOther
  embed x1 := { benefitsOther := some x1 }
  run x1 := Usul.Refinements.liableForOthersBenefit x1
  proj_embed := fun _ => rfl

/-- `concurrent_causes` reads `Qaida.Rajab28`. -/
def concurrentCauses : Typed Situation (Usul.Refinements.Share) where
  Local := (Bool)
  proj s := s.otherActPermitted
  embed x1 := { otherActPermitted := some x1 }
  run x1 := Usul.Refinements.concurrentShare x1
  proj_embed := fun _ => rfl

/-- `tolerance_exceeded` reads `Qaida.Rajab29`. -/
def toleranceExceeded : Typed Situation (Usul.Refinements.Lapse) where
  Local := (Bool)
  proj s := s.atFault
  embed x1 := { atFault := some x1 }
  run x1 := Usul.Refinements.toleranceLapse x1
  proj_embed := fun _ => rfl

/-- `failed_obligation_returns` reads `Qaida.Rajab30`. -/
def failedObligationReturns : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.failedToCount
  embed x1 := { failedToCount := some x1 }
  run x1 := Usul.Refinements.returnsToOwner x1
  proj_embed := fun _ => rfl

/-- `makeup_after_failure` reads `Qaida.Rajab31`. -/
def makeupAfterFailure : Typed Situation (Usul.Refinements.MakeupExtent) where
  Local := (Usul.Refinements.MakeupFailure)
  proj s := s.failure
  embed x1 := { failure := some x1 }
  run x1 := Usul.Refinements.makeupAfterFailure x1
  proj_embed := fun _ => rfl

/-- `benefit_exception` reads `Qaida.Rajab32`. -/
def benefitException : Typed Situation (Bool) where
  Local := (Bool) × (Bool)
  proj s := do pure (← s.knownPeriod, ← s.toleratesUncertainty)
  embed | (x1, x2) => { knownPeriod := some x1, toleratesUncertainty := some x2 }
  run | (x1, x2) => Usul.Refinements.benefitExceptionValid x1 x2
  proj_embed := fun _ => rfl

/-- `implicit_exception` reads `Qaida.Rajab33`. -/
def implicitException : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.implicit
  embed x1 := { implicit := some x1 }
  run x1 := Usul.Refinements.uncertainExceptionValid x1
  proj_embed := fun _ => rfl

/-- `manumission_spread` reads `Qaida.Rajab34`. -/
def manumissionSpread : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.bindingContract
  embed x1 := { bindingContract := some x1 }
  run x1 := Usul.Refinements.manumissionReachesBenefits x1
  proj_embed := fun _ => rfl

/-- `benefit_then_thing` reads `Qaida.Rajab35`. -/
def benefitThenThing : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.perpetualCommutative
  embed x1 := { perpetualCommutative := some x1 }
  run x1 := Usul.Refinements.priorContractDissolves x1
  proj_embed := fun _ => rfl

/-- `lease_after_authority` reads `Qaida.Rajab36`. -/
def leaseAfterAuthority : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.succeedsLessor
  embed x1 := { succeedsLessor := some x1 }
  run x1 := Usul.Refinements.leaseDissolves x1
  proj_embed := fun _ => rfl

/-- `successive_by_binding` reads `Qaida.Rajab37`. -/
def successiveByBinding : Typed Situation (Bool) where
  Local := (Bool) × (Bool) × (Bool)
  proj s := do pure (← s.successive, ← s.earlierBinding, ← s.laterBinding)
  embed | (x1, x2, x3) => { successive := some x1, earlierBinding := some x2, laterBinding := some x3 }
  run | (x1, x2, x3) => Usul.Refinements.laterBindingGoverns x1 x2 x3
  proj_embed := fun _ => rfl

/-- `successive_contracts` reads `Qaida.Rajab37`. -/
def successiveContracts : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.successive
  embed x1 := { successive := some x1 }
  run x1 := Usul.Refinements.laterContractGoverns x1
  proj_embed := fun _ => rfl

/-- `words_out_of_nature` reads `Qaida.Rajab38`. -/
def wordsOutOfNature : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.otherContractPossible
  embed x1 := { otherContractPossible := some x1 }
  run x1 := Usul.Refinements.asKinayaValid x1
  proj_embed := fun _ => rfl

/-- `contract_by_kinaya` reads `Qaida.Rajab39`. -/
def contractByKinaya : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.needsWitnessing
  embed x1 := { needsWitnessing := some x1 }
  run x1 := Usul.Refinements.kinayaConcludes x1
  proj_embed := fun _ => rfl

/-- `right_to_substitute` reads `Qaida.Rajab41`. -/
def rightToSubstitute : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.boundToThing
  embed x1 := { boundToThing := some x1 }
  run x1 := Usul.Refinements.rightPassesToSubstitute x1
  proj_embed := fun _ => rfl

/-- `return_of_held_property` reads `Qaida.Rajab42`. -/
def returnOfHeldProperty : Typed Situation (Bool) where
  Local := (Bool) × (Bool)
  proj s := do pure (← s.heldByConsent, ← s.guaranteed)
  embed | (x1, x2) => { heldByConsent := some x1, guaranteed := some x2 }
  run | (x1, x2) => Usul.Refinements.returnAtOnce x1 x2
  proj_embed := fun _ => rfl

/-- `continued_holding` reads `Qaida.Rajab43`. -/
def continuedHolding : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.withholds
  embed x1 := { withholds := some x1 }
  run x1 := Usul.Refinements.holderLiable x1
  proj_embed := fun _ => rfl

/-- `holding_after_contract_end` reads `Qaida.Rajab43`. -/
def holdingAfterContractEnd : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.endedByHolder
  embed x1 := { endedByHolder := some x1 }
  run x1 := Usul.Refinements.liableAfterEnding x1
  proj_embed := fun _ => rfl

/-- `void_contract_concluded` reads `Qaida.Rajab46`. -/
def voidContractConcluded : Typed Situation (Bool) where
  Local := (Bool) × (Bool)
  proj s := do pure (← s.binding, ← s.pervasive)
  embed | (x1, x2) => { binding := some x1, pervasive := some x2 }
  run | (x1, x2) => Usul.Refinements.voidConcluded x1 x2
  proj_embed := fun _ => rfl

/-- `defective_compensation` reads `Qaida.Rajab47`. -/
def defectiveCompensation : Typed Situation (Usul.Refinements.CompensationBasis) where
  Local := (Bool)
  proj s := s.contractLiability
  embed x1 := { contractLiability := some x1 }
  run x1 := Usul.Refinements.defectiveCompensationBasis x1
  proj_embed := fun _ => rfl

/-- `qabd_in_contracts` reads `Qaida.Rajab49`. -/
def qabdInContracts : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.qabdCompletes
  embed x1 := { qabdCompletes := some x1 }
  run x1 := Usul.Refinements.bindsWithoutQabd x1
  proj_embed := fun _ => rfl

/-- `forced_acquisition` reads `Qaida.Rajab50`. -/
def forcedAcquisition : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.acquisitionNecessity
  embed x1 := { acquisitionNecessity := some x1 }
  run x1 := Usul.Refinements.ownedBeforePayment x1
  proj_embed := fun _ => rfl

/-- `forced_acquisition_solvent` reads `Qaida.Rajab50`. -/
def forcedAcquisitionSolvent : Typed Situation (Bool) where
  Local := (Bool) × (Bool) × (Bool)
  proj s := do pure (← s.acquisitionNecessity, ← s.shufa, ← s.solvent)
  embed | (x1, x2, x3) => { acquisitionNecessity := some x1, shufa := some x2, solvent := some x3 }
  run | (x1, x2, x3) => Usul.Refinements.ownedBeforePaymentIn x1 x2 x3
  proj_embed := fun _ => rfl

/-- `daman_without_qabd` reads `Qaida.Rajab51`. -/
def damanWithoutQabd : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.determined
  embed x1 := { determined := some x1 }
  run x1 := Usul.Refinements.inNewOwnersDaman x1
  proj_embed := fun _ => rfl

/-- `disposal_before_qabd` reads `Qaida.Rajab52`. -/
def disposalBeforeQabd : Typed Situation (Bool) where
  Local := (Bool) × (Bool)
  proj s := do pure (← s.mubham, ← s.settled)
  embed | (x1, x2) => { mubham := some x1, settled := some x2 }
  run | (x1, x2) => Usul.Refinements.disposeBeforeQabd x1 x2
  proj_embed := fun _ => rfl

/-- `disposal_before_qabd_debt` reads `Qaida.Rajab52`. -/
def disposalBeforeQabdDebt : Typed Situation (Bool) where
  Local := (Bool) × (Bool) × (Bool)
  proj s := do pure (← s.mubham, ← s.settled, ← s.debtToThird)
  embed | (x1, x2, x3) => { mubham := some x1, settled := some x2, debtToThird := some x3 }
  run | (x1, x2, x3) => Usul.Refinements.disposeBeforeQabdIn x1 x2 x3
  proj_embed := fun _ => rfl

/-- `disposal_over_anothers_right` reads `Qaida.Rajab54`. -/
def disposalOverAnothersRight : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.extinguishes
  embed x1 := { extinguishes := some x1 }
  run x1 := Usul.Refinements.mayDisposeOver x1
  proj_embed := fun _ => rfl

/-- `right_to_own_disposal` reads `Qaida.Rajab55`. -/
def rightToOwnDisposal : Typed Situation (Bool) where
  Local := (Bool) × (Bool)
  proj s := do pure (← s.causeComplete, ← s.tieRemains)
  embed | (x1, x2) => { causeComplete := some x1, tieRemains := some x2 }
  run | (x1, x2) => Usul.Refinements.disposalTakes x1 x2
  proj_embed := fun _ => rfl

/-- `concurrent_condition` reads `Qaida.Rajab56`. -/
def concurrentCondition : Typed Situation (Bool) where
  Local := (Bool) × (Bool)
  proj s := do pure (← s.prior, ← s.concurrent)
  embed | (x1, x2) => { prior := some x1, concurrent := some x2 }
  run | (x1, x2) => Usul.Refinements.conditionMet x1 x2
  proj_embed := fun _ => rfl

/-- `ruling_with_bar` reads `Qaida.Rajab57`. -/
def rulingWithBar : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.withBar
  embed x1 := { withBar := some x1 }
  run x1 := Usul.Refinements.holdsAgainstBar x1
  proj_embed := fun _ => rfl

/-- `desisting_at_once` reads `Qaida.Rajab58`. -/
def desistingAtOnce : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.foresaw
  embed x1 := { foresaw := some x1 }
  run x1 := Usul.Refinements.desistIsAct x1
  proj_embed := fun _ => rfl

/-- `annulment_on_nonexistent` reads `Qaida.Rajab59`. -/
def annulmentOnNonexistent : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.annulment
  embed x1 := { annulment := some x1 }
  run x1 := Usul.Refinements.annulsNonexistent x1
  proj_embed := fun _ => rfl

/-- `annulment_without_return` reads `Qaida.Rajab59`. -/
def annulmentWithoutReturn : Typed Situation (Bool) where
  Local := (Bool) × (Bool)
  proj s := do pure (← s.annulment, ← s.defectReturn)
  embed | (x1, x2) => { annulment := some x1, defectReturn := some x2 }
  run | (x1, x2) => Usul.Refinements.annulsNonexistentIn x1 x2
  proj_embed := fun _ => rfl

/-- `deputy_of_principal` reads `Qaida.Rajab61`. -/
def deputyOfPrincipal : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.general
  embed x1 := { general := some x1 }
  run x1 := Usul.Refinements.removedWithPrincipal x1
  proj_embed := fun _ => rfl

/-- `deputy_of_qadi` reads `Qaida.Rajab61`. -/
def deputyOfQadi : Typed Situation (Bool) where
  Local := (Bool) × (Bool)
  proj s := do pure (← s.general, ← s.ofQadi)
  embed | (x1, x2) => { general := some x1, ofQadi := some x2 }
  run | (x1, x2) => Usul.Refinements.removedWithPrincipalIn x1 x2
  proj_embed := fun _ => rfl

/-- `removal_before_knowledge` reads `Qaida.Rajab62`. -/
def removalBeforeKnowledge : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.publicOffice
  embed x1 := { publicOffice := some x1 }
  run x1 := Usul.Refinements.removedBeforeKnowledge x1
  proj_embed := fun _ => rfl

/-- `unknown_condition` reads `Qaida.Rajab64`. -/
def unknownCondition : Typed Situation (Bool) where
  Local := (Bool) × (Bool)
  proj s := do pure (← s.knew, ← s.liabilityOnly)
  embed | (x1, x2) => { knew := some x1, liabilityOnly := some x2 }
  run | (x1, x2) => Usul.Refinements.countsAsMet x1 x2
  proj_embed := fun _ => rfl

/-- `unknown_condition_in_fact` reads `Qaida.Rajab64`. -/
def unknownConditionInFact : Typed Situation (Bool) where
  Local := (Bool) × (Bool) × (Bool)
  proj s := do pure (← s.knew, ← s.liabilityOnly, ← s.transactionAuthority)
  embed | (x1, x2, x3) => { knew := some x1, liabilityOnly := some x2, transactionAuthority := some x3 }
  run | (x1, x2, x3) => Usul.Refinements.countsAsMetIn x1 x2 x3
  proj_embed := fun _ => rfl

/-- `qisas_belongs_to_whom` reads `Qaida.Rajab65`. -/
def qisasBelongsToWhom : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.rightIsVictims
  embed x1 := { rightIsVictims := some x1 }
  run x1 := Usul.Refinements.pardonOfSpreadValid x1
  proj_embed := fun _ => rfl

/-- `mistaken_basis` reads `Qaida.Rajab66`. -/
def mistakenBasis : Typed Situation (Bool) where
  Local := (Bool) × (Bool)
  proj s := do pure (← s.believedBasis, ← s.actualBasis)
  embed | (x1, x2) => { believedBasis := some x1, actualBasis := some x2 }
  run | (x1, x2) => Usul.Refinements.validWithBasis x1 x2
  proj_embed := fun _ => rfl

/-- `hukm_against_own_ijtihad` reads `Qaida.ShakkShartFuru`. -/
def hukmAgainstOwnIjtihad : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.contradictsNass
  embed x1 := { contradictsNass := some x1 }
  run x1 := Usul.Refinements.rulingUndone x1
  proj_embed := fun _ => rfl

/-- `taliq_al_bay` reads `Qaida.ShakkShartFuru`. -/
def taliqAlBay : Typed Situation (Bool) where
  Local := (Bool) × (Bool)
  proj s := do pure (← s.conditional, ← s.knownToHold)
  embed | (x1, x2) => { conditional := some x1, knownToHold := some x2 }
  run | (x1, x2) => Usul.Refinements.conditionedSaleValid x1 x2
  proj_embed := fun _ => rfl

/-- `hand_liability` reads `Qaida.Rajab91`. -/
def handLiability : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.propertyLike
  embed x1 := { propertyLike := some x1 }
  run x1 := Usul.Refinements.handLiable x1
  proj_embed := fun _ => rfl

/-- `taker_from_usurper` reads `Qaida.Rajab93`. -/
def takerFromUsurper : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.enteredOnLiability
  embed x1 := { enteredOnLiability := some x1 }
  run x1 := Usul.Refinements.takerRecourse x1
  proj_embed := fun _ => rfl

/-- `ayman_by_urf` reads `Qaida.Sadi9`. -/
def aymanByUrf : Typed Situation (Usul.Refinements.Body) where
  Local := (Bool)
  proj s := s.customOneBody
  embed x1 := { customOneBody := some x1 }
  run x1 := Usul.Refinements.oathBody x1
  proj_embed := fun _ => rfl

/-- `fay_tie_break` reads `Qaida.Sadi25`. -/
def fayTieBreak : Typed Situation (Usul.Refinements.TieBreak) where
  Local := (Bool)
  proj s := s.tieBreakCriteria
  embed x1 := { tieBreakCriteria := some x1 }
  run x1 := Usul.Refinements.fayTieBreak [x1]
  proj_embed := fun _ => rfl

/-- `lots` reads `Qaida.Sadi25`. -/
def lots : Typed Situation (Usul.Muamalat.Allocation) where
  Local := (Bool) × (Bool) × (Bool)
  proj s := do pure (← s.entitledKnown, ← s.divisible, ← s.confusionCategory)
  embed | (x1, x2, x3) => { entitledKnown := some x1, divisible := some x2, confusionCategory := some x3 }
  run | (x1, x2, x3) => Usul.Refinements.allocationFull x1 x2 x3
  proj_embed := fun _ => rfl

/-- `partners` reads `Qaida.Sadi30`. -/
def partners : Typed Situation (Bool) where
  Local := (Bool) × (Bool)
  proj s := do pure (← s.necessary, ← s.consents)
  embed | (x1, x2) => { necessary := some x1, consents := some x2 }
  run | (x1, x2) => Usul.Muamalat.partnerMustJoin x1 x2
  proj_embed := fun _ => rfl

/-- `recourse` reads `Qaida.Sadi32`. -/
def recourse : Typed Situation (Bool) where
  Local := (Bool) × (Bool) × (Bool) × (Bool)
  proj s := do pure (← s.gift, ← s.owedByOther, ← s.permission, ← s.permissionUnobtainable)
  embed | (x1, x2, x3, x4) => { gift := some x1, owedByOther := some x2, permission := some x3, permissionUnobtainable := some x4 }
  run | (x1, x2, x3, x4) => Usul.Refinements.recourseNec x1 x2 x3 x4
  proj_embed := fun _ => rfl

/-- `doubled` reads `Qaida.Sadi35`. -/
def doubled : Typed Situation (Nat) where
  Local := (Bool)
  proj s := s.lapsed
  embed x1 := { lapsed := some x1 }
  run x1 := Usul.Muamalat.compensationOwed 1 x1
  proj_embed := fun _ => rfl

/-- `ghulul_forfeiture` reads `Qaida.Sadi35`. -/
def ghululForfeiture : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.asGhulul
  embed x1 := { asGhulul := some x1 }
  run x1 := Usul.Refinements.ghululForfeits x1
  proj_embed := fun _ => rfl

/-- `partial_capability` reads `Qaida.Sadi40`. -/
def partialCapability : Typed Situation (Bool) where
  Local := (Bool) × (Bool)
  proj s := do pure (← s.capableOfPart, ← s.pureMeans)
  embed | (x1, x2) => { capableOfPart := some x1, pureMeans := some x2 }
  run | (x1, x2) => decide (0 ∈ Usul.Sadi.obligedParts [0] (fun _ => x1) (fun _ => x2))
  proj_embed := fun _ => rfl

/-- `tadakhul` reads `Qaida.Sadi41`. -/
def tadakhul : Typed Situation (Bool) where
  Local := (Bool) × (Bool)
  proj s := do pure (← s.actsSameKind, ← s.samePurpose)
  embed | (x1, x2) => { actsSameKind := some x1, samePurpose := some x2 }
  run | (x1, x2) => Usul.Kulliyyat.discharges (⟨0, 0, 0⟩ : Usul.Kulliyyat.Act Nat Nat Nat) ⟨if x1 then 0 else 1, if x2 then 0 else 1, 1⟩
  proj_embed := fun _ => rfl

/-- `knowledge` reads `Qaida.Sadi45`. -/
def knowledge : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.consentRequired
  embed x1 := { consentRequired := some x1 }
  run x1 := (Usul.Muamalat.Requirement.normalize ⟨x1, true⟩).knowledge
  proj_embed := fun _ => rfl

/-- `continuity` reads `Qaida.Sadi48`. -/
def continuity : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.customaryContinuity
  embed x1 := { customaryContinuity := some x1 }
  run x1 := Usul.Kulliyyat.continuous 1 [0, if x1 then 1 else 5]
  proj_embed := fun _ => rfl

/-- `residual_jawaz_after_sarf` reads `Qaida.Sadi50`. -/
def residualJawazAfterSarf : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.sarf
  embed x1 := { sarf := some x1 }
  run x1 := Usul.Refinements.jawazAfterSarf x1
  proj_embed := fun _ => rfl

/-- `tabaa` reads `Qaida.Sadi50`. -/
def tabaa : Typed Situation (Bool) where
  Local := (Bool) × (Bool)
  proj s := do pure (← s.independentProof, ← s.followsEstablished)
  embed | (x1, x2) => { independentProof := some x1, followsEstablished := some x2 }
  run | (x1, x2) => Usul.Kulliyyat.established x1 x2
  proj_embed := fun _ => rfl

/-- `right_for_or_against_self` reads `Qaida.Sadi55`. -/
def rightForOrAgainstSelf : Typed Situation (Bool) where
  Local := (Bool)
  proj s := s.forHimself
  embed x1 := { forHimself := some x1 }
  run x1 := Usul.Refinements.heardAfterDenial x1
  proj_embed := fun _ => rfl

/-- `generality` reads `Qaida.Sadi59`. -/
def generality : Typed Situation (Bool) where
  Local := (Usul.Sadi.NounForm) × (Usul.Sadi.Context) × (Bool)
  proj s := do pure (← s.nounForm, ← s.context, ← s.ahd)
  embed | (x1, x2, x3) => { nounForm := some x1, context := some x2, ahd := some x3 }
  run | (x1, x2, x3) => Usul.Dalala.IsGeneralIn x1 x2 x3
  proj_embed := fun _ => rfl

/-- `mubashara_tasabbub` reads Ibn Rajab 127's type, which extends itlāf's. -/
def mubasharaTasabbub : Typed Situation Usul.Readings.Mubashara.Daman where
  Local := Bool × Bool
  proj s := do pure (← s.arisingFromSabab, ← s.udwanInMubashara)
  embed | (a, u) => { arisingFromSabab := some a, udwanInMubashara := some u }
  run | (a, u) => Usul.Readings.Mubashara.damanOn a u
  proj_embed := fun _ => rfl

end Usul.Typing
