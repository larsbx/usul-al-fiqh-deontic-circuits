/-!
# Shard rajab-a25: the reading of Ibn Rajab's qāʿida 158

Formalised from the qāʿida's own statement in the pinned witness (`openiti-rajab-shamela21730`),
status `candidate`. The qāʿida settles a conflict of two uṣūl by the one that is reinforced; where
they are equal it reports two wujūh, and those stay recorded positions in the takhrīj suite
`corpus/takhrij/rajab_m8_rajab_a25_furu.json`.
-/

namespace Usul.Readings.RajabA25

/-- Qāʿida 158: «إذا تعارض معنا أصلان عمل بالأرجح منهما لاعتضاده بما يرجحه، فإن تساويا خرج في
المسألة وجها غالبا». Each record names two uṣūl, one for each position; the *first* aṣl is the one
behind the position the record states first. `firstReinforced`: the record says the first aṣl is
reinforced («معتضد», «عضده الظاهر»); `secondReinforced`: the same of the second. The output is
that the ruling follows the first aṣl.

The reinforced aṣl governs. Where neither is reinforced, or both are, the two are equal and the
qāʿida gives only «خرج في المسألة وجها»: two wujūh. The reading then returns the record's
first-stated wajh, and the other wajh stays a recorded position, so every such farʿ is a
genuine ikhtilāf whose madhhab side is checked against the later works. -/
def firstAslGoverns (firstReinforced secondReinforced : Bool) : Bool :=
  firstReinforced || !secondReinforced

/-- The reinforced first aṣl governs whatever is said of the second. -/
theorem reinforced_first_governs (s : Bool) : firstAslGoverns true s = true := by
  cases s <;> rfl

/-- A second aṣl reinforced alone bars the first: «عمل بالأرجح منهما». -/
theorem reinforced_second_alone_governs : firstAslGoverns false true = false := rfl

/-- Neither reinforced, the two are equal: the reading takes the first-stated wajh. -/
theorem equal_usul_take_first_stated : firstAslGoverns false false = true := rfl

/-- Both reinforced is again equality, and again the first-stated wajh. -/
theorem both_reinforced_equal : firstAslGoverns true true = firstAslGoverns false false := rfl

end Usul.Readings.RajabA25
