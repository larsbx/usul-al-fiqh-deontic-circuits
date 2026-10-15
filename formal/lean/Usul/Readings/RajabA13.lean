/-!
# Shard rajab-a13: readings of Ibn Rajab's qawāʿid 119, 120, 122 and 124

Each reading is formalised from the qāʿida's own statement in the pinned witness
(`openiti-rajab-shamela21730`), status `candidate`. Qāʿida 119 carries two attached qawāʿid
(«ويتصل بهذه القاعدة قاعدتان»); each gets its own reading. Where the statement poses a question
(«فيه وجهان»), the reading takes one side and names its ground; the other side stays a recorded
position in the takhrīj suite `corpus/takhrij/rajab_m8_rajab_a13_furu.json`.
-/

namespace Usul.Readings.RajabA13

/-- Qāʿida 119: «إذا وجدنا لفظا عاما قد خص بعض أفراده بحكم موافق للأول أو مخالف له فهل يقضي
بخروج الخاص من العام وانفراده بحكمه المختص به أو يقضي بدخوله فيه». Its first division:
«أن يكون الخاص والعام في كلام واحد متصل فالمذهب أنه يفرد الخاص بحكمه ولا يقضي بدخوله في
العام». Its second division, two separate utterances: where retraction is possible
(«كالوصية»), «أشهرهن تقديم الخاص مطلقا»; where it is not («كالأقارير والشهادات والعقود»),
«فيقع التعارض في الشهادات ولا يكون الإقرار الثاني ولا العقد الثاني رجوعا عن الأول».
`connected`: the general and the specific are in one connected utterance; `revocable`: the
speaker may retract what he said (a bequest, a governor's appointment). The output is that the
specific is singled out with its own ruling and not counted within the general. -/
def specificSingledOut (connected revocable : Bool) : Bool := connected || revocable

/-- The first division: in one connected utterance the specific is singled out, whether or not
the act can be retracted («وسواء إن كان ذلك الحكم مما يمكن الرجوع عنه كالوصايا أو لا يمكن
كالإقرار»). -/
theorem connected_singles_out (r : Bool) : specificSingledOut true r = true := by
  cases r <;> rfl

/-- The second division, revocable acts: the specific is preferred absolutely («تقديم الخاص
مطلقا»), connected or not. -/
theorem revocable_singles_out (c : Bool) : specificSingledOut c true = true := by
  cases c <;> rfl

/-- Two separate irrevocable utterances (two iqrārs, two contracts): neither is a retraction of
the other, so the specific is not singled out and the two stand together. -/
theorem separate_irrevocable_stand : specificSingledOut false false = false := rfl

/-- Qāʿida 119, first attached qāʿida: «إذا اجتمع في شخص استحقاق بجهة خاصة كوصية معينة وميراث
واستحقاق بجهة عامة كالفقر والمسكنة فإنه لا يأخذ إلا بالجهة الخاصة نص عليه أحمد».
`specialTitle`: the claimant holds an entitlement by a special title (a named bequest, an
inheritance) beside his membership of a general class named in the same disposition. The output
is that he takes by the special title alone and nothing from the general class's share. -/
def takesOnlyBySpecial (specialTitle : Bool) : Bool := specialTitle

/-- The text joins the attached qāʿida to qāʿida 119 («ويتصل بهذه القاعدة»): a person named by a
special title in a bequest, which is revocable, is the specific singled out of the general. -/
theorem special_title_is_q119_instance (s c : Bool) :
    takesOnlyBySpecial s = (s && specificSingledOut c true) := by
  cases s <;> cases c <;> rfl

/-- Qāʿida 119, second attached qāʿida: «إذا اجتمعت صفات في عين فهل يتعدد الاستحقاق بها كالأعيان
المتعددة المشهور في المذهب أنها كالأعيان في تعدد الاستحقاق», with its own caveat: «إذا كانت الجهة
واحدة لم يتعدد الاستحقاق بتعدد الأوصاف المدلية إليها». `combinedAttributes`: several attributes,
each a ground of entitlement, meet in one person or thing; `singleJiha`: they all lead to one and
the same head of entitlement. The output is that the entitlement is multiplied by the
attributes, as if they were several persons. -/
def entitlementMultiplies (combinedAttributes singleJiha : Bool) : Bool :=
  combinedAttributes && !singleJiha

/-- The caveat is a bar: attributes leading to one head never multiply the entitlement,
whatever else holds. -/
theorem single_jiha_never_multiplies (a : Bool) : entitlementMultiplies a true = false := by
  cases a <;> rfl

/-- Without combined attributes there is nothing to multiply. -/
theorem no_combination_no_multiplying (j : Bool) : entitlementMultiplies false j = false := rfl

/-- Qāʿida 120: «يرجح ذو القرابتين على ذي القرابة الواحدة، وإن لم تكن إحداهما لها مدخل في
الاستحقاق». `doubleKinship`: the claimant is related by two kinships (the full brother) against a
rival related by one of them (the paternal brother), even where the second kinship gives no
entitlement of its own. The output is that the one with two kinships is preferred. -/
def doubleKinshipPreferred (doubleKinship : Bool) : Bool := doubleKinship

/-- Qāʿida 122: «يخص العموم بالعادة على المنصوص». `customaryUsage`: an established custom or
practice bears on the general term, the testator's habit of giving to some of a class, the
customary hours of work, what is customarily eaten of a thing. The output is that the general
term is restricted to what the custom covers. -/
def customRestricts (customaryUsage : Bool) : Bool := customaryUsage

/-- Qāʿida 124: «هل نخص اللفظ العام بسببه الخاص إذا كان السبب هو المقتضي له؟ فيه وجهان». The
reading takes the second wajh, «وهو الصحيح عند صاحبي المغني والمحرر», which Ibn ʿAqīl calls
«قياس المذهب» and Ibn Rajab's own conclusion follows («فإن كان ثم سبب يقتضي اختصاص اليمين بحال
بقاء الصفة لم يحنث بالكلام بعد زوالها ... فهي كمسألتنا»). `promptingCause`: the general word
was uttered on a particular cause that prompted it. The output is that the general word is
restricted to its cause. -/
def causeRestricts (promptingCause : Bool) : Bool := promptingCause

/-- Without a prompting cause the general word keeps its generality. -/
theorem no_cause_general : causeRestricts false = false := rfl

end Usul.Readings.RajabA13
