import Usul.Taarud
import Usul.Sadi
import Usul.Muamalat
import Usul.Kulliyyat
import Usul.Refinements

/-!
# The bank applied to its own contradictions (al-Saʿdī, *al-Qawāʿid wa'l-Uṣūl al-Jāmiʿa*)

Two qawāʿid of the bank, each read without its qayd, can rule opposite ways on the same case.
That is an apparent taʿāruḍ inside the bank. It is resolved by the bank's own order
(`Usul.resolve`: jamʿ, then naskh, then tarjīḥ, then tawaqquf) and by its own rules of reading:
Q29 «يجب تقييد اللفظ بملحقاته» (a rule is read with its attached condition) and Q57 «مهما أمكن»
(both statements are given effect wherever possible).

In every pair below the qayd is the author's own sentence, quoted and located in
`corpus/review/sadi_tanaqud.json`. It splits the shared cases: on one side the first rule governs,
on the other the second. So each pair reaches jamʿ, the first stage, and none reaches tawaqquf.
For each pair, three things are proved:

* `clash`: the clash is real; on some case the two readings without their qayd disagree;
* `jam`: the qayd gives one ruling, and resolution takes it (`resolve_takes_jam`);
* a link lemma: the ruling agrees with the rule's existing encoding, so the jamʿ is the
  formalisation that was already there, now shown to be consistent.

Earlier pairs proved in place: Q13/Q36 (`Muamalat.q13_q36_consistent`), Q26/Q43
(`Muamalat.q26_q43_consistent`), Q51/Q54 (`Muamalat.q51_q54_consistent`).

T11–T15 carry the pass to Ibn Rajab's *Taqrīr al-Qawāʿid* (`corpus/tanaqud/rajab.json`): three pairs
inside his book, two across the bank against al-Saʿdī. The qayd is again his own sentence.
-/

namespace Usul.Tanaqud

open Usul.Muamalat Usul.Kulliyyat

/-- Two qawāʿid, each read without its qayd, and the qayd that splits the shared cases
(`true`: the case is the first rule's). -/
structure Pair (C R : Type) where
  first  : C → R
  second : C → R
  qayd   : C → Bool

variable {C R : Type}

/-- The jamʿ: each rule on its own side of the qayd. -/
def Pair.jam (p : Pair C R) (c : C) : R := if p.qayd c then p.first c else p.second c

/-- The readings without their qayd disagree on some case. -/
def Pair.Clash (p : Pair C R) : Prop := ∃ c, p.first c ≠ p.second c

theorem Pair.jam_first (p : Pair C R) {c : C} (h : p.qayd c = true) : p.jam c = p.first c := by
  simp [Pair.jam, h]

theorem Pair.jam_second (p : Pair C R) {c : C} (h : p.qayd c = false) : p.jam c = p.second c := by
  simp [Pair.jam, h]

/-- A jamʿ exists, so the bank's resolution order takes it before naskh, tarjīḥ or tawaqquf. -/
theorem resolve_takes_jam (p : Pair C R) (n t : Option (C → R)) :
    resolve ⟨some p.jam, n, t⟩ = .jam p.jam := rfl

/-! ## T1 · Q13 ⟂ Q27: destruction by the forgetful

Q13: destruction is compensated whatever the mental state. Q27: whoever commits a prohibited
act out of ignorance or forgetfulness is discharged. On a muḥrim who forgetfully kills game the
two disagree. al-Saʿdī (in Q13): «الحق في قتل الصيد للمحرم لله، والإثم مترتب على القصد،
فكذلك الجزاء». A human's right follows Q13; God's right follows Q27. -/

inductive Right where
  | adami | allah
  deriving DecidableEq, Repr

def t1 : Pair (Right × MentalState) Bool where
  first  := fun c => itlafLiable false c.2
  second := fun c => !(c.2 != .deliberate && Sadi.dischargedByExcuse .commitProhibited)
  qayd   := fun c => c.1 == .adami

theorem t1_clash : t1.Clash := ⟨(.allah, .forgetful), by decide⟩

theorem t1_jam (r : Right) (m : MentalState) :
    t1.jam (r, m) = true ↔ r = .adami ∨ m = .deliberate := by
  cases r <;> cases m <;> decide

/-! ## T2 · Q20 ⟂ Q25: the entitled is unknown

Q20: an owner who cannot be known is treated as absent (the property goes to the public
interest). Q25: when the entitled is unknown and the thing cannot be divided, lots are cast. On
an unknown entitled and an indivisible thing the two disagree. al-Saʿdī: Q20 is the owner
«تعذر علينا معرفته … أيس من معرفته»; Q25 is «فمتى تشاح اثنان فأكثر». Known competing
claimants follow Q25; no one who can be identified follows Q20. -/

inductive Disposal where
  | lot | publicInterest
  deriving DecidableEq, Repr

/-- The case: whether the candidates are known claimants. -/
def t2 : Pair Bool Disposal where
  first  := fun _ => if lotPrescribed false false then .lot else .publicInterest
  second := fun _ => if recipient false = .publicInterest then .publicInterest else .lot
  qayd   := id

theorem t2_clash : t2.Clash := ⟨true, by decide⟩

theorem t2_jam (claimants : Bool) :
    t2.jam claimants = if claimants then .lot else .publicInterest := by
  cases claimants <;> rfl

/-! ## T3 · Q31 ⟂ Q41: two acts of worship of one kind

Q31: each cause works its own effect. Q41: two acts of worship of one kind merge into one. On
two kaffārāt owed they disagree. al-Saʿdī (Q41) restricts the merger to «إذا كان مقصودهما
واحدا» and adds «وأما إذا كانت الكفارات متباينة مقاصدها»: then each is owed. -/

/-- The case: whether the two owed acts share their purpose. The result is how many
performances are owed. -/
def t3 : Pair Bool Nat where
  first  := fun _ => 1
  second := fun _ => 2
  qayd   := id

theorem t3_clash : t3.Clash := ⟨true, by decide⟩

/-- The jamʿ is Q41's own `discharges`: one performance exactly when it discharges the other. -/
theorem t3_jam (same : Bool) :
    t3.jam same = if discharges (⟨(), true, ()⟩ : Act Unit Bool Unit) ⟨(), same, ()⟩ then 1 else 2 := by
  cases same <;> rfl

/-! ## T4 · Q55 ⟂ Q57: the confessor who says he meant otherwise

Q57: speech is carried on what the speaker meant. Q55: a confessor is bound even if he claims
error. They disagree on a confessor who claims his intent differed from his words. al-Saʿdī
(Q57): «وأما إذا تعلق بكلامه حق للغير … إذا طالبه بمقتضى لفظه لم يكن لنا أن نحكم إلا بالظاهر».
Both rules cite «إنما أقضي بنحو ما أسمع». When another person's right is attached and he demands
it, the outward follows (Q55); otherwise the intent follows (Q57). -/

/-- The case: whether another's right is attached and he demands the wording. The result is
whether the speaker is bound by his literal words. -/
def t4 : Pair Bool Bool where
  first  := fun _ => confessionBinds true
  second := fun _ => reading true (some false) (fun _ => true)
  qayd   := id

theorem t4_clash : t4.Clash := ⟨true, by decide⟩

theorem t4_jam (demanded : Bool) : t4.jam demanded = demanded := by cases demanded <;> rfl

/-! ## T5 · Q17 ⟂ Q39: acting early

Q17: whoever hastens a thing before its time is deprived of it. Q39: acts of worship may be
advanced after their cause and before their condition. On an early act they disagree. al-Saʿdī
(Q17): what is penalised is acting «قبل وجود أسبابها الصحيحة»; (Q39): «ويجوز تقديمها بعد
وجود السبب، وقبل شرط الوجوب». After the cause, Q39 governs; before it, Q17. -/

/-- The case: whether the cause has occurred. The result is whether the early act stands. -/
def t5 : Pair Bool Bool where
  first  := fun _ => timelyPerformance 1 1 2
  second := fun _ => obtains true true
  qayd   := id

theorem t5_clash : t5.Clash := ⟨true, by decide⟩

/-- The jamʿ is Q39's own `timelyPerformance`, with the cause at time 1 and the condition at 2. -/
theorem t5_jam (afterCause : Bool) :
    t5.jam afterCause = timelyPerformance (if afterCause then 1 else 0) 1 2 := by
  cases afterCause <;> rfl

/-! ## T6 · Q4 ⟂ Q40: able to do part

Q4: nothing is obligatory with inability. Q40: what one can do of the command is obligatory. On
someone unable to do the whole they disagree. al-Saʿdī (Q40): «فإن قدر على بعضه وعجز عن باقيه
وجب عليه فعل ما قدر عليه، إلا أن يكون المقدور عليه وسيلة محضة». Inability lifts what it
reaches, part by part. -/

/-- The case: whether the part can be done, and whether it is a pure means (wasīla maḥḍa). The result is
whether the part is obligatory. -/
def t6 : Pair (Bool × Bool) Bool where
  first  := fun c => !c.2
  second := fun _ => Sadi.operative false false .wajib == .wajib
  qayd   := Prod.fst

theorem t6_clash : t6.Clash := ⟨(true, false), by decide⟩

/-- The jamʿ is Q4 applied to each part, which is Q40's `obligedParts`. -/
theorem t6_jam (can pure : Bool) :
    t6.jam (can, pure) = (Sadi.operative can false .wajib == .wajib && !pure) := by
  cases can <;> cases pure <;> rfl

theorem t6_obligedParts {P : Type} (parts : List P) (can pure : P → Bool) (x : P) :
    x ∈ Sadi.obligedParts parts can pure ↔ x ∈ parts ∧ t6.jam (can x, pure x) = true := by
  simp only [Sadi.obligedParts, List.mem_filter, t6_jam]
  cases can x <;> cases pure x <;> simp [Sadi.operative]

/-! ## T7 · Q21 ⟂ Q50: gharar in what follows

Q21: gharar is forbidden in exchanges. Q50: what follows may be established where it could not
stand alone. On the unseen foundations of a sold house they disagree. al-Saʿdī (Q50): «لا يجوز
بيع المجهول الذي لم ير ولم يوصف، لكن إذا بيعت الدار ونحوها دخلت فيها الأساسات». -/

/-- The case: whether the uncertain item follows a known whole. The result is whether the
sale is forbidden. -/
def t7 : Pair Bool Bool where
  first  := fun _ => !established false true
  second := fun _ => ghararForbidden .exchange true
  qayd   := id

theorem t7_clash : t7.Clash := ⟨true, by decide⟩

theorem t7_jam (follows : Bool) :
    t7.jam follows = (ghararForbidden .exchange true && !established false follows) := by
  cases follows <;> rfl

/-! ## T8 · Q11 ⟂ Q52: the presumption against an indicator

Q11: certainty is not removed by doubt, and what was remains. Q52: strong indicators are
preferred over the presumption. al-Saʿdī (Q52): «لأننا إنما قدمنا الأصل حيث لا مرجح سواه،
فإذا وجد ما هو أقوى منه وجب تقديم الأرجح». The presumption holds against doubt and yields to
what is stronger than doubt. This is the bank's displacement rule (`Refinements.zahirPrevails`). -/

/-- The case: the grade of the contrary indicator. The result is whether the presumption stands. -/
def t8 : Pair Grade Bool where
  first  := fun _ => false
  second := fun _ => true
  qayd   := fun g => decide (Grade.shakk < g)

theorem t8_clash : t8.Clash := ⟨.zann, by decide⟩

theorem t8_jam (g : Grade) : t8.jam g = !Refinements.zahirPrevails .shakk g false := by
  cases g <;> rfl

/-! ## T9 · Q12 ⟂ Q45: whose consent is needed

Q12: exchange contracts need mutual consent. Q45: whoever's consent is not required need not
know either (cancellation under an option, divorce, manumission, pre-emption). On the other
party's consent they disagree. al-Saʿdī (Q45): «فله الفسخ سواء رضي الآخر، أو لم يرض، وسواء علم
أو لم يعلم». The concluding of an exchange follows Q12; a unilateral right follows Q45. -/

/-- The case: whether the act concludes an exchange. The result is whether the other party's
consent is required. -/
def t9 : Pair Bool Bool where
  first  := fun _ => true
  second := fun _ => false
  qayd   := id

theorem t9_clash : t9.Clash := ⟨true, by decide⟩

/-- On the exchange side the requirement is Q12's gate: without the other's consent it fails. -/
theorem t9_exchange_side : t9.jam true = true ∧ ¬ Exchange.gate.Holds ⟨true, false⟩ :=
  ⟨rfl, q12_no_contract_without_consent _ (.inr rfl)⟩

/-! ## T10 · Q10 ⟂ Q26: the trustee who claims loss

Q10: proof is on the claimant. Q26: the trustee's word is accepted. A trustee who claims the
thing perished is a claimant who is believed. al-Saʿdī (Q26): «لأن صاحبه ائتمنه ونزله منزلة
نفسه». The owner's trust makes the trustee's claim the presumption, so he is the denier of
liability. -/

/-- The case: whether the thing was held in trust (for the owner). The result is what the
holder must bring. -/
def t10 : Pair Bool Schema.Proof where
  first  := fun _ => .yamin
  second := fun _ => burden .claimant
  qayd   := id

theorem t10_clash : t10.Clash := ⟨true, by decide⟩

/-- The jamʿ is Q10 read by presumption, as Q26/Q43 already encode it. -/
theorem t10_jam (trust : Bool) :
    t10.jam trust = Schema.burdenOf (returnPresumption (if trust then .owner else .self) false) true := by
  cases trust <;> rfl

/-! ## T11 · Ibn Rajab 66 ⟂ Ibn Rajab 6: an act on a mistaken belief

Q66 (reading `Refinements.validWithBasis`): a disposition stands when a valid basis exists in
fact. Q6 (`Refinements.errorExcused`): an act done on a belief later shown wrong stands, unless
another's right attaches or he was negligent. Read without their qayd, with no valid basis in
fact Q66 holds not ṣaḥīḥ what Q6 lets stand, and with another's right attached Q6 undoes what Q66 upholds.
Ibn Rajab (Q66): «ثم تبين خطؤه فيه وأن السبب المعتمد غيره وهو موجود». Q66 governs only where
the true basis exists; elsewhere Q6. -/

/-- The case: a valid basis exists in fact, another's right is attached, he was negligent. The
act was done on a belief later shown wrong. -/
def t11 : Pair (Bool × Bool × Bool) Bool where
  first  := fun c => Refinements.validWithBasis true c.1
  second := fun c => Refinements.errorExcused c.2.1 c.2.2
  qayd   := fun c => c.1

theorem t11_clash : t11.Clash := ⟨(false, false, false), by decide⟩

/-- The jamʿ: the act stands if a valid basis exists in fact, or else if Q6 excuses it. -/
theorem t11_jam (basis others negligent : Bool) :
    t11.jam (basis, others, negligent) =
      (Refinements.validWithBasis true basis || Refinements.errorExcused others negligent) := by
  cases basis <;> cases others <;> cases negligent <;> rfl

/-! ## T12 · al-Saʿdī Q28 ⟂ Ibn Rajab 7: the original found during the substitute

al-Saʿdī Q28 (`Sadi.useSubstitute`): the substitute only when the original is impossible, so
once it is found he switches. Ibn Rajab 7: whoever began a general concession «لا يجب عليه
الانتقال منه بوجود الأصل». Ibn Rajab's qayd (Q7): «الضرب الثاني: أن يكون المتلبس به إنما شرع
ضرورة للعجز عن الأصل وتعذره». Q28 governs the necessity substitute, the concession stands. -/

/-- The case: the substitute begun was a necessity (not a general concession). The result:
whether he must switch to the original now found. -/
def t12 : Pair Bool Bool where
  first  := fun _ => !Sadi.useSubstitute true
  second := fun _ => false
  qayd   := id

theorem t12_clash : t12.Clash := ⟨true, by decide⟩

/-- The jamʿ is Ibn Rajab 7's reading, `Refinements.mustSwitch`. -/
theorem t12_jam (necessity : Bool) : t12.jam necessity = Refinements.mustSwitch necessity := by
  cases necessity <;> rfl

/-! ## T13 · Ibn Rajab 32 ⟂ Ibn Rajab 33: an excepted benefit of uncertain extent

Q32 (`Refinements.benefitExceptionValid`): excepting the benefit of what one transfers is valid for
a known period, and in waqf and manumission for his life too. Q33 (as read,
`Refinements.uncertainExceptionValid`): an exception of uncertain extent is valid when the law
makes it, not when it is stated. A waqf excepting its benefit for the founder's life is a stated
exception of uncertain extent: Q32 upholds it, Q33 holds it not ṣaḥīḥ. Ibn Rajab (Q32): «لأن جهالة المدة
هنا لا تؤثر فإنها لا تزيد على جهالة مدة كل بطن بالنسبة إلى من بعده». Where the transfer already
bears that uncertainty Q32 governs; elsewhere Q33. -/

/-- The case, the period being unknown: the exception arises by law, the transfer tolerates
an uncertain period. The result: whether the exception is valid. -/
def t13 : Pair (Bool × Bool) Bool where
  first  := fun c => Refinements.benefitExceptionValid false c.2
  second := fun c => Refinements.uncertainExceptionValid c.1
  qayd   := fun c => c.2

theorem t13_clash : t13.Clash := ⟨(false, true), by decide⟩

/-- The jamʿ: valid where the transfer tolerates the uncertainty, or the law makes the exception. -/
theorem t13_jam (implicit tolerates : Bool) :
    t13.jam (implicit, tolerates) =
      (Refinements.benefitExceptionValid false tolerates || Refinements.uncertainExceptionValid implicit) := by
  cases implicit <;> cases tolerates <;> rfl

/-! ## T14 · Ibn Rajab 1 ⟂ al-Saʿdī Q9: an oath about running water

Ibn Rajab 1 (as read, `Refinements.runningBody`): running water is judged jirya by jirya.
al-Saʿdī Q9 (`Kulliyyat.measure`): what the law leaves undefined is measured by custom, and
custom counts the running river as one body. One who swore not to stand in this water while
it runs: by Q1 he cannot stand in what keeps changing, by Q9 he has stood in it. Ibn Rajab
(1.f003): «والأيمان مرجعها إلى العرف». Oaths follow Q9; ṭahāra follows Q1. -/

/-- The case: the question is an oath. The result: how the running water is reckoned. -/
def t14 : Pair Bool Refinements.Body where
  first  := fun _ => Refinements.runningBody true
  second := fun _ => Refinements.oathBody true
  qayd   := not

theorem t14_clash : t14.Clash := ⟨true, by decide⟩

/-- The jamʿ: in an oath custom's one body (`Refinements.oath_follows_custom`), elsewhere the jirya. -/
theorem t14_jam (oath : Bool) :
    t14.jam oath = if oath then Refinements.oathBody true else Refinements.runningBody true := by
  cases oath <;> rfl

/-! ## T15 · Ibn Rajab 14 ⟂ Ibn Rajab 15: a breach certain in one of two

Q14 (its second riwāya): when the cause is certainly in one of two, «الأصل زال يقينا في أحدهما
فتعذر البقاء عليه», so the ruling attaches. Q15: a presumption is kept, and its consequence for
another presumption «لم يلتفت إلى ذلك اللازم». Two who find al-manī (المني) in a shared garment: by Q14 the
breach attaches, by Q15 each keeps his certain ṭahāra. Ibn Rajab (14.f002): «فينظر إليهما مجتمعين
في حكم يتعلق باجتماعهما». Taken together (one leading the other, both slave-women in one
ownership) Q14 governs; each alone keeps his aṣl (Q15). -/

/-- The case: the two are taken together in one ruling. The result: whether the certain
breach attaches. -/
def t15 : Pair Bool Bool where
  first  := fun _ => true
  second := fun _ => Refinements.consequenceCarries true
  qayd   := id

theorem t15_clash : t15.Clash := ⟨true, by decide⟩

/-- The jamʿ is Q14's reading, `Refinements.oneOfTwoAttaches`. -/
theorem t15_jam (together : Bool) : t15.jam together = Refinements.oneOfTwoAttaches together := by
  cases together <;> rfl

/-! ## Ibn Rajab 93 with Ibn Rajab 75: no clash

Q93: whoever took from a usurper unaware has recourse against him «ما لم يدخل على ضمانه». Q75
(`Refinements.recourseFull`): recourse for paying what another owed. What he entered on
liability for was his own due, not the usurper's, so Q75 gives no recourse there either. -/

theorem rajab_q93_q75_consistent (entered : Bool) :
    Refinements.takerRecourse entered = Refinements.recourseFull false (!entered) false := by
  cases entered <;> rfl

end Usul.Tanaqud
