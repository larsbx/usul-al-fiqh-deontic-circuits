/-!
# Shard rajab-a23: readings of Ibn Rajab's qawāʿid 153 and 157

Each reading is formalised from the qāʿida's own statement in the pinned witness
(`openiti-rajab-shamela21730`), status `candidate`. Where a record reports a split, the other
sides stay recorded positions in the takhrīj suite `corpus/takhrij/rajab_m8_rajab_a23_furu.json`.
-/

namespace Usul.Readings.RajabA23

/-- Qāʿida 153: «ولد الولد هل يدخل في مسمى الولد عند الإطلاق، هذا ثلاثة أنواع: أحدها: أنه يدخل
في مسماه مطلقا مع وجود الولد وعدمه»; the second, «ما يدخل فيه عند عدم الولد لا مع وجوده»; the
third, «ما لا يدخل فيه في مسمى الولد بحال». `firstKind`: the ruling is of the first kind (the
grandchild is included with or without the child); `secondKind`: it is of the second kind
(included only when the child is absent); `childPresent`: the intermediate child (the
grandchild's parent) is present. The output is that the grandchild takes the child's ruling
(equivalently, the grandfather the father's) on that point. A ruling of neither kind is of the
third, where he never does. -/
def grandchildCountsAsChild (firstKind secondKind childPresent : Bool) : Bool :=
  firstKind || (secondKind && !childPresent)

/-- The first kind: included whether or not the child is present. -/
theorem first_kind_always (s c : Bool) : grandchildCountsAsChild true s c = true := by
  cases s <;> cases c <;> rfl

/-- The second kind bars the grandchild while the child is present. -/
theorem second_kind_barred_by_child : grandchildCountsAsChild false true true = false := rfl

/-- The second kind admits the grandchild when the child is absent. -/
theorem second_kind_absent_child : grandchildCountsAsChild false true false = true := rfl

/-- The third kind (neither of the first two): never included, «بحال». -/
theorem third_kind_never (c : Bool) : grandchildCountsAsChild false false c = false := by
  cases c <;> rfl

/-- Qāʿida 157: «إذا تغير حال المرأة التي في العدة بانتقالها من رق إلى حرية أو طرأ عليها سبب موجب
لعدة أخرى من الزوج كوفاته فهل يلزمها الانتقال إلى عدة الوفاة أو إلى عدة حرة؟ إن كان زوجها متمكنا
من تلافي نكاحها في العدة لزمها الانتقال وإلا فلا، إلا ما يستثنى من ذلك من الإبانة في المريض».
`statusChanges`: her state changes in the ʿidda (she is freed) or a cause of another ʿidda from
the husband supervenes (his death); `canRemedy`: the husband could remedy the marriage within
the ʿidda; `sickIbana`: the case is the excepted one, her separation by a husband in his final
illness. The output is that she moves to the new ʿidda (of a free woman, or of death). -/
def transfersToNewIdda (statusChanges canRemedy sickIbana : Bool) : Bool :=
  statusChanges && (canRemedy || sickIbana)

/-- Without a change in her state or a new cause, there is nothing to move to, whatever else
holds. -/
theorem no_change_no_transfer (r s : Bool) : transfersToNewIdda false r s = false := by
  cases r <;> cases s <;> rfl

/-- «وإلا فلا»: a husband who cannot remedy the marriage, outside the exception, does not move
her. -/
theorem no_remedy_no_transfer : transfersToNewIdda true false false = false := rfl

/-- «لزمها الانتقال»: a change while the husband can remedy the marriage moves her. -/
theorem remedy_transfers (s : Bool) : transfersToNewIdda true true s = true := by
  cases s <;> rfl

end Usul.Readings.RajabA23
