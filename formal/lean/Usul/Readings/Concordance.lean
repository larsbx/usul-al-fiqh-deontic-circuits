import Usul.Refinements

/-!
# Two readings of one qāʿida: Ibn Rajab 3, 9, 14, 15

Two contributions formalised the same four qawāʿid: the textual-foundation work (`wholeObligatory`,
`worshipValidDespite`, `oneOfTwoAttaches`, `consequenceCarries`, cited by the tanāquḍ pair T-15) and
the M8 tranches 7–8 (`excessObligatory`, `validDespite`, `attachTo`, `eachOnItsAsl`, which carry the
annotated furūʿ). The integration rule for a duplicate principle is to keep both and prove them
equivalent, or retire one (derivation-method §5.3).

* Qāʿidas 3, 9 and 15: the readings are equivalent, proved below.
* Qāʿida 14: they read two different moves of the text, and they are joined, not equated.
  - Each man taken alone: «فهل يلحق الحكم بكل منهما». Ibn Rajab's farq, «بخلاف إيجاب الطهارة عليهما
    فإنه لا ضرر فيه», is `attachTo`.
  - The two taken together: «فينظر إليهما مجتمعين في حكم يتعلق باجتماعهما». This is `oneOfTwoAttaches`.
  - On the first riwāya's own ground, «كل واحد منهما متيقن للطهارة شاك في الحدث» (Q15: each on his
    aṣl), the harmless case binds neither. This is the madhhab: al-Inṣāf «على الصحيح من المذهب»,
    al-Furūʿ «عن الأصح», and Sharḥ al-Muntahā «فلا غسل على واحد», adding that neither follows the
    other in prayer (the joint ruling). `attachOnCertainty` is that jamʿ, conservative over `attachTo`.
-/

namespace Usul.Readings.Concordance

open Usul.Refinements

/-! ## Qāʿida 3 -/

/-- The excess is obligatory only where it cannot be told apart and the whole was the original
duty, lightened: the same function under both names. -/
theorem q3_readings_agree : wholeObligatory = excessObligatory := rfl

/-! ## Qāʿida 9 -/

/-- The four sites of a prohibition, one-to-one: «ذات العبادة», «شرطها» specific to it or not, and
what is no condition of it. -/
def siteOf : ProhibitionSite → Prohibited
  | .essence => .essence
  | .specificCondition => .specificCondition
  | .generalCondition => .generalCondition
  | .external => .outside

def siteOf_inv : Prohibited → ProhibitionSite
  | .essence => .essence
  | .specificCondition => .specificCondition
  | .generalCondition => .generalCondition
  | .outside => .external

theorem siteOf_inv_siteOf (s : ProhibitionSite) : siteOf_inv (siteOf s) = s := by cases s <;> rfl
theorem siteOf_siteOf_inv (p : Prohibited) : siteOf (siteOf_inv p) = p := by cases p <;> rfl

theorem q9_readings_agree (s : ProhibitionSite) : worshipValidDespite s = validDespite (siteOf s) := by
  cases s <;> rfl

/-- The M8 reading inherits the link to al-Saʿdī Q38: Ibn Rajab 9 refines it and agrees on every site. -/
theorem validDespite_refines_q38 (p : Prohibited) :
    validDespite p = Sadi.validDespiteProhibition (siteOf_inv p).toSadi := by
  cases p <;> rfl

/-! ## Qāʿida 15 -/

/-- «لم يلتفت إلى ذلك اللازم»: the corollary carries exactly when the matters are not each on
its own aṣl. One reading asks whether the corollary carries, the other whether each stays on its
aṣl. -/
theorem q15_readings_agree (x : Bool) : consequenceCarries x = !eachOnItsAsl x := rfl

/-! ## Qāʿida 14: the jamʿ -/

/-- Each man alone, when each is certain of his own state and doubts only the breach («متيقن
للطهارة شاك في الحدث»): a harmless ruling binds neither. Otherwise Ibn Rajab's farq stands: binding
each is harmless in ṭahāra, and where it would cut a right each abstains. -/
def attachOnCertainty (harmless eachCertain : Bool) : Attach :=
  if harmless && eachCertain then .neither else attachTo harmless

theorem attachOnCertainty_conservative (h : Bool) : attachOnCertainty h false = attachTo h := by
  cases h <;> rfl

/-- The jamʿ departs from `attachTo` only on the harmless case, and only to `neither`. -/
theorem attachOnCertainty_departs (h c : Bool) (hne : attachOnCertainty h c ≠ attachTo h) :
    h = true ∧ c = true ∧ attachOnCertainty h c = .neither := by
  cases h <;> cases c <;> simp_all [attachOnCertainty, attachTo]

/-- Where a right would be cut, certainty does not change the reading: each abstains. -/
theorem attachOnCertainty_abstains (c : Bool) : attachOnCertainty false c = .abstain := by
  cases c <;> rfl

/-- The alone case is Q15: each stays on his aṣl, and its corollary for the other does not carry. -/
theorem q14_alone_is_q15 :
    attachOnCertainty true true = .neither ∧ eachOnItsAsl true = true ∧ consequenceCarries true = false :=
  ⟨rfl, rfl, rfl⟩

/-- The two readings of Q14 answer different facts: taken together (one leading the other in
prayer, both slave-women in one ownership) the certain cause attaches; taken alone it does not. -/
theorem q14_together_attaches_alone_not : oneOfTwoAttaches true = true ∧ oneOfTwoAttaches false = false :=
  ⟨rfl, rfl⟩

end Usul.Readings.Concordance
