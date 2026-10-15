/-!
# Shard rajab-a11: readings of Ibn Rajab's qawāʿid 112, 113, 114 and 115

Each reading is formalised from the qāʿida's own statement (status `candidate`). Where the
statement leaves a question to khilāf, the reading returns the side the statement itself marks
(«الأشهر», or the split the statement draws between contexts), and the other side is held as a
position on the farʿ, not as the reading.
-/

namespace Usul.Readings.RajabA11

/-- Qāʿida 112: «إذا اجتمع للمضطر محرمان كل منهما لا يباح بدون الضرورة وجب تقديم أخفهما مفسدة
وأقلهما ضررا ; لأن الزيادة لا ضرورة إليها فلا يباح». `heavier`: this option is the greater in
harm of the two forbidden things before the one in necessity. The output is whether the option
is permitted to him: the excess has no necessity and is not permitted; where the two are equal
neither is an excess. -/
def necessityPermits (heavier : Bool) : Bool := !heavier

/-- Qāʿida 113: a set of numbered things distributed over another set. With a qarīna «فلا خلاف
في ذلك»: one-to-one «إما لجريان العرف أو دلالة الشرع على ذلك، وإما لاستحالة ما سواه», or each
over the whole; without one «والأشهر أنه يوزع كل من أفراد الجملة على جميع أفراد الجملة الأخرى
إذا أمكن». `qarinaOneToOne`: custom, the sharʿ or the impossibility of anything else points to
pairing each individual with one individual. The output is whether each individual is
distributed over the whole of the other set. -/
def eachOverWhole (qarinaOneToOne : Bool) : Bool := !qarinaOneToOne

/-- Qāʿida 113 without a qarīna: the qāʿida's «الأشهر», each over the whole. -/
theorem eachOverWhole_unmarked : eachOverWhole false = true := rfl

/-- Qāʿida 114: «إطلاق الشركة هل يتنزل على المناصفة أو هو مبهم يفتقر إلى تفسير؟», the qāʿida
splitting by context: in the inshāʾ of a sale «وقال القاضي … في البيع … ينزل على المناصفة»,
while «والذي ذكره الأصحاب في الإقرار أنه مبهم». `isIqrar`: the unqualified partnership is stated
in an admission. The output is whether it is taken as half and half. -/
def sharikaHalves (isIqrar : Bool) : Bool := !isIqrar

/-- Qāʿida 115: «الحقوق المشتركة بين اثنين فصاعدا نوعان: أحدهما: ما يقع استحقاق كل واحد بانفراده
لجميع الحق ويتزاحمون فيه عند الاجتماع. والثاني: ما يستحق كل واحد من الحق بحصته بخاصة».
`eachEntitledWhole`: the right is of the first kind. The output is whether each holder's right
reaches the whole, so that what one drops, or what a crowding gives up, accrues to the rest
(«فإذا عفى أحدهم عن حقه توفر على الباقين»). -/
def accruesToRest (eachEntitledWhole : Bool) : Bool := eachEntitledWhole

end Usul.Readings.RajabA11
