/-!
# Shard rajab-a10: readings of Ibn Rajab's qawāʿid 109 and 111

Each reading is formalised from the qāʿida's own statement (status `candidate`). Where the
statement leaves a question to khilāf, the reading returns the side the statement does not
establish, and the other side is held as a position on the farʿ, not as the reading.
-/

namespace Usul.Readings.RajabA10

/-- Qāʿida 109, its first kind: «المنع من واحد مبهم من أعيان أو معين مشتبهة بأعيان يؤثر الاشتباه
فيها المنع بمنع التصرف في تلك الأعيان قبل تمييزه». `confusionEffective`: what is barred is one
unspecified among the items, or a specific one confused with them, and the confusion has effect
(the items are limited in number); `distinguished`: it has been singled out. The output is whether
dealing with each of the items is barred. -/
def vagueOneBarsAll (confusionEffective distinguished : Bool) : Bool :=
  confusionEffective && !distinguished

/-- Qāʿida 109, its second kind: «والمنع من الجمع يمنع من التصرف في القدر الذي يحصل به الجمع
خاصة». `combiningAmount`: the items the question is about are the amount by which the
combination comes about. The output is whether they are barred. -/
def combinationBarsItsAmount (combiningAmount : Bool) : Bool := combiningAmount

/-- Qāʿida 109, the second kind when the combination comes about at once: «فإن حصل الجمع دفعة
واحدة منع من الجميع مع التساوي، فإن كان لواحد منهما مزية على غيره بأن يصح وروده على غيره ولا
عكس اختص الفساد به على الصحيح». The corruption falls on the one the other has precedence over
(f019: «لأن الحرة تمتاز عليهما بصفة ورود نكاحها عليها … ولا عكس»). `hasPrecedence`: the item in
question has that precedence over the other; with equality no item has it. The output is whether
the item's contract is void. -/
def simultaneousCombinationVoids (hasPrecedence : Bool) : Bool := !hasPrecedence

/-- With equality every item is void (fāsid, the qāʿida's «الفساد»): «منع من الجميع مع التساوي». -/
theorem simultaneous_equal_voids_all : simultaneousCombinationVoids false = true := rfl

/-- Qāʿida 109, its third kind: «والمنع من القدر المشترك كالمنع من الجميع يقتضي العموم».
`barsCommonAmount`: what is barred is the amount common to all (an indefinite under negation or a
condition). The output is whether the bar is general over every instance. -/
def commonAmountGeneral (barsCommonAmount : Bool) : Bool := barsCommonAmount

/-- Qāʿida 111: «إذا كان الواجب بسبب واحد أحد شيئين فقامت حجة بها أحدهما دون الآخر فهل يثبت أم
لا؟ على روايتين». The statement does not establish the one alternative by a proof that does not
establish the cause; it is established when the proof establishes the cause itself.
`proofEstablishesCause`: the proof is one by which the cause (and so either alternative) is
established. The output is whether the alternative the proof points to is owed. -/
def alternativeProvenAlone (proofEstablishesCause : Bool) : Bool := proofEstablishesCause

end Usul.Readings.RajabA10
