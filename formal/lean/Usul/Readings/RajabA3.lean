/-!
# Shard rajab-a3: readings of Ibn Rajab's qawāʿid 53 and 78

Each reading is formalised from the qāʿida's own statement (status: candidate).
-/

namespace Usul.Readings.RajabA3

/-- Qāʿida 53: disposal of a thing to which a right of God or of a specific person attaches.
If the right has settled in the thing by its holder's demand or taking («إن كان الحق مستقرا فيها
بمطالبة من له الحق بحقه أو يأخذه بحقه لم ينفذ التصرف»), the disposal does not take effect; if
there is nothing but the right's attachment for satisfaction from it («ولم يوجد سوى تعلق الحق
لاستيفائه منها صح التصرف على ظاهر المذهب»), it is valid. A demand settles the right only where
the thing itself is due to him and cannot be turned aside («بحقه الذي لا يمكن دفعه عنه»):
`demanded` is the holder's demand or taking, `fixedInAyn` that the thing itself is what he is
owed. The output is whether the owner's act stands. -/
def disposalStands (demanded fixedInAyn : Bool) : Bool := !(demanded && fixedInAyn)

/-- The qāʿida's second clause: a bare attachment never blocks the disposal. -/
theorem bare_attachment_stands (fixedInAyn : Bool) : disposalStands false fixedInAyn = true := by
  cases fixedInAyn <;> rfl

/-- A demand for a right not fixed in the thing (the jānī's arsh, the zakat) blocks nothing. -/
theorem unfixed_demand_stands (demanded : Bool) : disposalStands demanded false = true := by
  cases demanded <;> rfl

/-- Qāʿida 78: one who brings a loss on another's property to free his own («من أدخل النقص على
ملك غيره لاستصلاح تملكه وتخلصه من ملك غيره») is liable if the sufferer was not negligent («فإن
لم يكن ممن دخل النقص عليه بتفريط ... فالضمان على من أدخل النقص»), not liable if he was
(«وإن كان منه تفريط فلا ضمان»), nor if the sufferer permitted the freeing where the other could
not be compelled to it («وكذا إن وجد ممن دخل النقص عليه إذن في تفريغ ملكه»). `causesLoss` is
that the freeing brings a loss at all. The qāʿida's «فوجهان» for a bare permission to occupy is
left open: that permission is not an input. -/
def lossLiable (causesLoss sufferedNegligent emptyingPermitted : Bool) : Bool :=
  causesLoss && !sufferedNegligent && !emptyingPermitted

/-- The sufferer's negligence removes liability («فلا ضمان على من أدخل النقص»). -/
theorem negligent_sufferer_not_liable (l p : Bool) : lossLiable l true p = false := by
  cases l <;> rfl

end Usul.Readings.RajabA3
