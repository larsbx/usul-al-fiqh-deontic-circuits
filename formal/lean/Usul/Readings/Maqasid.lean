import Usul.Qiyas

/-!
# The maqāṣid al-sharīʿa: ranks, the five kulliyyāt, istiṣlāḥ and their order in tarjīḥ

Four pinned witnesses state the doctrine; each part below is read from its own words.

* **al-Shāṭibī, *al-Muwāfaqāt*** (Kitāb al-Maqāṣid, v02 p017–031): «تكاليف الشريعة ترجع إلى حفظ مقاصدها
  في الخلق، وهذه المقاصد لا تعدو ثلاثة أقسام … ضرورية … حاجية … تحسينية» (p017). The ḍarūriyyāt are kept
  from two sides, «من جانب الوجود» and «من جانب العدم» (p018), and «مجموع الضروريات خمسة، وهي: حفظ الدين،
  والنفس، والنسل، والمال، والعقل» (p020). Every rank has its complements (p024), and «كل تكملة فلها … شرط،
  وهو: أن لا يعود اعتبارها على الأصل بالإبطال» (p026). «المقاصد الضرورية في الشريعة أصل للحاجية
  والتحسينية» (p031).
* **al-Ghazālī, *al-Mustaṣfā*** (v01 p173–177): «ومقصود الشرع من الخلق خمسة: وهو أن يحفظ عليهم دينهم
  ونفسهم وعقلهم ونسلهم ومالهم» (p174); a maṣlaḥa no specific aṣl attests is admitted only as «ضرورة قطعية
  كلية» (p176), with the shield (tatarrus), the fortress, the ship and the famine as its furūʿ.
* **Ibn Qudāma, *Rawḍat al-Nāẓir*** (v01 p478–483), the kernel's own uṣūl: maṣlaḥa attested, cancelled
  or neither; the unattested in three ranks; the five, each with the law's deterrent; and the
  dispute: «فذهب مالك، وبعض الشافعية إلى أن هذه المصلحة حجة … والصحيح: أن ذلك ليس بحجة» (p482).
* **Ibn al-Najjār, *Sharḥ al-Kawkab al-Munīr*** (v04 p158–169, p726–728), the Ḥanbalī order: the
  kulliyyāt joined by «ف» with al-ʿirḍ at the rank of wealth, «فيكون من أدنى الكليات» (p163), and in
  tarjīḥ: «تقدم المقاصد الضرورية … على غيرها … ومكملها … على الحاجية … وتقدم المصلحة الحاجية على
  التحسينية … ويقدم حفظ الدين على باقي الضرورية» (p727), with a dissent «وقيل: تقدم الأربع الأخر على
  الدينية» (p728).

Two policy points are pinned, not chosen (method §4, invariant 8): whether the unattested ḍarūrī
maṣlaḥa is a proof (`Stance`: the Rawḍa, al-Ghazālī, Mālik as the Rawḍa reports him), and whether
dīn precedes the other four (`DinReading`). Status: candidate reading.
-/

namespace Usul.Readings.Maqasid

/-! ## The three ranks (al-Muwāfaqāt v02 p017; al-Mustaṣfā v01 p173) -/

/-- «ضرورية … حاجية … تحسينية». -/
inductive Rutba where
  | daruri | haji | tahsini
  deriving DecidableEq, Repr

/-- «فهي أقوى المراتب في المصالح» (al-Mustaṣfā p174): the ḍarūrī highest, the taḥsīnī lowest. -/
def Rutba.rank : Rutba → Nat
  | .daruri => 2 | .haji => 1 | .tahsini => 0

theorem Rutba.rank_injective (a b : Rutba) (h : a.rank = b.rank) : a = b := by
  cases a <;> cases b <;> simp_all [Rutba.rank]

/-! ## The kulliyyāt -/

/-- The universals the law preserves. al-ʿIrḍ is al-Kawkab's sixth (v04 p161). -/
inductive Kulli where
  | din | nafs | aql | nasl | mal | ird
  deriving DecidableEq, Repr

/-- al-Mustaṣfā p174: «دينهم ونفسهم وعقلهم ونسلهم ومالهم». -/
def fiveMustasfa : List Kulli := [.din, .nafs, .aql, .nasl, .mal]
/-- The Rawḍa p481: «دينهم، وأنفسهم، وعقلهم، ونسبهم، ومالهم» (nasab read as nasl, as its own
example «حفظا للنسل والأنساب» does). -/
def fiveRawda : List Kulli := [.din, .nafs, .aql, .nasl, .mal]
/-- al-Muwāfaqāt p020: «حفظ الدين، والنفس، والنسل، والمال، والعقل». -/
def fiveMuwafaqat : List Kulli := [.din, .nafs, .nasl, .mal, .aql]
/-- al-Kawkab p160: «حفظ الدين، ف … النفس، ف … العقل، ف … النسل، ف … المال، و … العرض». -/
def sixKawkab : List Kulli := [.din, .nafs, .aql, .nasl, .mal, .ird]

/-- The Rawḍa abridges al-Mustaṣfā: the same five in the same order. -/
theorem rawda_is_mustasfa : fiveRawda = fiveMustasfa := rfl

/-- al-Shāṭibī's five are al-Ghazālī's, in another order. -/
theorem muwafaqat_same_five (k : Kulli) : k ∈ fiveMuwafaqat ↔ k ∈ fiveMustasfa := by
  cases k <;> decide

theorem five_nodup : fiveMustasfa.Nodup ∧ fiveMuwafaqat.Nodup := by decide

/-- al-Kawkab's six are the five and al-ʿirḍ, appended last. -/
theorem kawkab_adds_ird : sixKawkab = fiveMustasfa ++ [.ird] := rfl

theorem ird_outside_the_five : Kulli.ird ∉ fiveMustasfa ∧ Kulli.ird ∉ fiveMuwafaqat := by decide

/-- al-Kawkab's order, read from its «ف» (each after the one before it), with al-ʿirḍ «في رتبة المال
… فيكون من أدنى الكليات» (p163). -/
def Kulli.rank : Kulli → Nat
  | .din => 4 | .nafs => 3 | .aql => 2 | .nasl => 1 | .mal => 0 | .ird => 0

/-- al-Kawkab lists its kulliyyāt in descending rank. -/
theorem kawkab_descending : sixKawkab.Pairwise (fun a b => b.rank ≤ a.rank) := by decide

/-- al-ʿIrḍ is the lowest of the kulliyyāt, level with wealth. -/
theorem ird_lowest (k : Kulli) : Kulli.ird.rank ≤ k.rank ∧ Kulli.ird.rank = Kulli.mal.rank := by
  cases k <;> decide

/-! ## Preservation from two sides (al-Muwāfaqāt v02 p018–020) -/

/-- «ما يقيم أركانها ويثبت قواعدها … من جانب الوجود»; «ما يدرأ عنها الاختلال الواقع أو المتوقع فيها
… من جانب العدم». -/
inductive Janib where
  | wujud | adam
  deriving DecidableEq, Repr

/-- The four divisions of the law al-Shāṭibī assigns to the five. -/
inductive Bab where
  | ibadat | adat | muamalat | jinayat
  deriving DecidableEq, Repr

/-- What each division preserves directly: «فأصول العبادات راجعة إلى حفظ الدين من جانب الوجود …
والعادات راجعة إلى حفظ النفس والعقل من جانب الوجود … والمعاملات راجعة إلى حفظ النسل والمال من جانب
الوجود … والجنايات … ترجع إلى حفظ الجميع من جانب العدم». -/
def preserves : Bab → Janib → Kulli → Bool
  | .ibadat, .wujud, k => k == .din
  | .adat, .wujud, k => k == .nafs || k == .aql
  | .muamalat, .wujud, k => k == .nasl || k == .mal
  | .jinayat, .adam, k => k ∈ fiveMuwafaqat
  | _, _, _ => false

/-- «وإلى حفظ النفس والعقل أيضا، لكن بواسطة العادات»: muʿāmalāt keep life and mind through the
ʿādāt, not directly. -/
def mediated : Bab → Janib → Kulli → Bool
  | .muamalat, .wujud, k => preserves .adat .wujud k
  | _, _, _ => false

/-- Every one of the five is kept from both sides, and the jināyāt keep all five from non-existence. -/
theorem both_sides (k : Kulli) (hk : k ∈ fiveMuwafaqat) :
    (∃ b, preserves b .wujud k = true) ∧ preserves .jinayat .adam k = true := by
  cases k <;> simp_all [fiveMuwafaqat, preserves] <;> first
    | exact ⟨.ibadat, rfl⟩ | exact ⟨.adat, rfl⟩ | exact ⟨.muamalat, rfl⟩

/-- From the side of existence each of the five has exactly one direct division. -/
theorem wujud_partition (k : Kulli) (hk : k ∈ fiveMuwafaqat) :
    ([Bab.ibadat, .adat, .muamalat, .jinayat].filter (preserves · .wujud k)).length = 1 := by
  cases k <;> simp_all [fiveMuwafaqat] <;> decide

/-- Only the jināyāt preserve from the side of non-existence. -/
theorem adam_only_jinayat (b : Bab) (k : Kulli) (h : preserves b .adam k = true) : b = .jinayat := by
  cases b <;> simp_all [preserves]

/-! ## The deterrents of the five (the Rawḍa v01 p481; al-Mustaṣfā v01 p174) -/

/-- «قضاء الشرع بقتل الكافر المضل، وعقوبة المبتدع الداعي … وقضاؤه بالقصاص … وإيجابه حد الشرب …
وإيجابه حد الزنا … وإيجابه زجر السارق». -/
inductive Zajr where
  | qatlMudill | qisas | haddShurb | haddZina | zajrSariq
  deriving DecidableEq, Repr

/-- «صيانة لدينهم … إذ به حفظ النفوس … إذ به حفظ العقول … حفظا للنسل والأنساب … حفظا للأموال». -/
def Zajr.hifz : Zajr → Kulli
  | .qatlMudill => .din | .qisas => .nafs | .haddShurb => .aql | .haddZina => .nasl | .zajrSariq => .mal

def Zajr.all : List Zajr := [.qatlMudill, .qisas, .haddShurb, .haddZina, .zajrSariq]

/-- The Rawḍa's deterrents run through its five in its own order, one deterrent to each. -/
theorem deterrents_cover_the_five : Zajr.all.map Zajr.hifz = fiveRawda := rfl

theorem deterrent_unique (z z' : Zajr) (h : z.hifz = z'.hifz) : z = z' := by
  cases z <;> cases z' <;> simp_all [Zajr.hifz]

/-- The deterrents keep the five from non-existence: each is a jināya-side preservation. -/
theorem deterrents_are_jinayat (z : Zajr) : preserves .jinayat .adam z.hifz = true := by
  cases z <;> decide

/-! ## Istiṣlāḥ: when a maṣlaḥa is a proof (the Rawḍa v01 p478–483; al-Mustaṣfā v01 p173–177) -/

/-- The law's witness to a maṣlaḥa: «قسم شهد الشرع باعتبارها … ما شهد ببطلانه … ما لم يشهد له بإبطال،
ولا اعتبار معين». -/
inductive Shahada where
  | itibar | ilgha | irsal
  deriving DecidableEq, Repr

/-- The positions on the unattested ḍarūrī maṣlaḥa, pinned as the sources state them. `rawda`:
«والصحيح: أن ذلك ليس بحجة»; `mustasfa`: admitted only as «ضرورة قطعية كلية», the qaṭʿ including
«ظن قريب من القطع» (p177); `malik`: «فذهب مالك، وبعض الشافعية إلى أن هذه المصلحة حجة». -/
inductive Stance where
  | rawda | mustasfa | malik
  deriving DecidableEq, Repr

/-- A maṣlaḥa as istiṣlāḥ reads it: its witness, its rank, and al-Ghazālī's two further
properties, certainty (qaṭʿiyya) and universality (kulliyya). -/
structure Maslaha where
  shahada : Shahada
  rutba : Rutba
  qatiyya : Bool
  kulliyya : Bool
  deriving DecidableEq, Repr

/-- Whether the stance accepts an unattested ḍarūrī maṣlaḥa of the given certainty and universality. -/
def Stance.acceptsMursal : Stance → Bool → Bool → Bool
  | .rawda, _, _ => false
  | .mustasfa, q, k => q && k
  | .malik, _, _ => true

/-- Whether a maṣlaḥa is a proof (ḥujja).
* attested: «فهذا هو القياس» (Rawḍa p478), a proof on every stance;
* cancelled: «فهذا لا خلاف في بطلانه؛ لمخالفته النص» (p479);
* unattested ḥājī or taḥsīnī: «لا نعلم خلافا في أنه لا يجوز التمسك بهما من غير أصل» (p480);
* unattested ḍarūrī: the stance decides. -/
def hujja (s : Stance) (m : Maslaha) : Bool :=
  match m.shahada, m.rutba with
  | .itibar, _ => true
  | .ilgha, _ => false
  | .irsal, .daruri => s.acceptsMursal m.qatiyya m.kulliyya
  | .irsal, _ => false

/-- The dispute is confined to the unattested ḍarūrī: elsewhere every stance agrees. -/
theorem dispute_locus (s s' : Stance) (m : Maslaha) (h : hujja s m ≠ hujja s' m) :
    m.shahada = .irsal ∧ m.rutba = .daruri := by
  rcases m with ⟨sh, r, q, k⟩
  cases sh <;> cases r <;> simp_all [hujja]

/-- The stances are nested: whatever the Rawḍa admits al-Ghazālī admits, and whatever he admits,
Mālik (as the Rawḍa reports him) admits. -/
theorem stances_nested (m : Maslaha) :
    (hujja .rawda m = true → hujja .mustasfa m = true) ∧
      (hujja .mustasfa m = true → hujja .malik m = true) := by
  rcases m with ⟨sh, r, q, k⟩
  cases sh <;> cases r <;> simp [hujja, Stance.acceptsMursal]

/-- Istiṣlāḥ refines the munāsib's recognition (`Usul.Qiyas.Recognition`): the cancelled maṣlaḥa is
the never-accepted `mulgha`, and the unattested ḍarūrī is `mursal`, whose disputed acceptance
parameter each stance fixes. -/
theorem refines_recognition (s : Stance) (r : Rutba) (q k : Bool) (b : Bool) :
    hujja s ⟨.ilgha, r, q, k⟩ = Qiyas.Recognition.mulgha.accepted b ∧
      hujja s ⟨.irsal, .daruri, q, k⟩ = Qiyas.Recognition.mursal.accepted (s.acceptsMursal q k) := by
  cases r <;> exact ⟨rfl, rfl⟩

/-! ### al-Ghazālī's furūʿ (al-Mustaṣfā v01 p175–177) -/

/-- The shield: «فهذا مقطوع به من مقصود الشرع والمقطوع به لا يحتاج شهادة أصل». -/
theorem tatarrus : hujja .mustasfa ⟨.irsal, .daruri, true, true⟩ = true := rfl

/-- The fortress: «لأنها ليست قطعية بل ظنية»; it fails on certainty alone, whatever its rank. -/
theorem qala (r : Rutba) : hujja .mustasfa ⟨.irsal, r, false, true⟩ = false := by cases r <;> rfl

/-- The ship and the famine: «لأنها ليست كلية»; each fails on universality alone. -/
theorem safina (r : Rutba) (q : Bool) : hujja .mustasfa ⟨.irsal, r, q, false⟩ = false := by
  cases r <;> cases q <;> rfl

/-- The king's fast: «فهذا لا خلاف في بطلانه» (Rawḍa p479), cancelled on every stance. -/
theorem kaffarat_al_malik (s : Stance) (r : Rutba) (q k : Bool) : hujja s ⟨.ilgha, r, q, k⟩ = false := rfl

/-- On the Rawḍa's own stance the shield is not admitted by istiṣlāḥ: the policy point is open. -/
theorem tatarrus_disputed : hujja .rawda ⟨.irsal, .daruri, true, true⟩ ≠ hujja .mustasfa ⟨.irsal, .daruri, true, true⟩ := by
  decide

/-! ## Complements (al-Muwāfaqāt v02 p024–030) -/

/-- A complement of an original (asl) over situations `S`, both as requirements. Considering the
complement requires both; it «يفضي اعتبارها إلى رفض أصلها» when no feasible situation meets both
although one meets the original. -/
def Nullifies {S : Type} (feasible : List S) (asl takmila : S → Bool) : Prop :=
  feasible.any asl = true ∧ feasible.any (fun s => asl s && takmila s) = false

/-- The requirement in force: the original with its complement, unless the complement nullifies it;
then «لم تعتبر التكملة، واعتبر الأصل من غير مزيد» (p026). -/
def required {S : Type} (feasible : List S) (asl takmila : S → Bool) (s : S) : Bool :=
  if feasible.any (fun s => asl s && takmila s) then asl s && takmila s else asl s

/-- A complement never takes away its original: if the original can be met, the requirement can. -/
theorem takmila_never_cancels_asl {S : Type} (feasible : List S) (asl takmila : S → Bool)
    (h : feasible.any asl = true) : feasible.any (required feasible asl takmila) = true := by
  unfold required
  split <;> simp_all

/-- The requirement always includes the original: the complement is «كالصفة مع الموصوف». -/
theorem required_implies_asl {S : Type} (feasible : List S) (asl takmila : S → Bool) (s : S)
    (h : required feasible asl takmila s = true) : asl s = true := by
  unfold required at h
  split at h <;> simp_all

/-- Where the complement does not nullify, it is considered in full. -/
theorem takmila_considered {S : Type} (feasible : List S) (asl takmila : S → Bool)
    (h : feasible.any (fun s => asl s && takmila s) = true) (s : S) :
    required feasible asl takmila s = (asl s && takmila s) := by
  simp [required, h]

/-- Where it nullifies, the original stands alone. -/
theorem takmila_dropped {S : Type} (feasible : List S) (asl takmila : S → Bool)
    (h : Nullifies feasible asl takmila) (s : S) : required feasible asl takmila s = asl s := by
  simp [required, h.2]

/-- «فإن دعت الضرورة إلى إحياء المهجة بتناول النجس، كان تناوله أولى» (p026): where only the impure is
at hand, keeping life (the original) requires eating, and avoiding impurity (a complement for
manliness) falls. Situations: (eats, what is eaten is impure). -/
theorem najis_for_the_mahja :
    required [(false, true), (true, true)] (fun s => s.1) (fun s => !s.2) (true, true) = true := rfl

/-! ## The ḍarūrī as the original of the others (al-Muwāfaqāt v02 p031–033) -/

/-- Which ranks stand intact. Their dependence: «فلو فرض اختلال الضروري بإطلاق، لاختلا باختلاله
بإطلاق»; the taḥsīnī serves the ḥājī and the ḥājī the ḍarūrī. -/
structure Intact where
  daruri : Bool
  haji : Bool
  tahsini : Bool
  deriving DecidableEq, Repr

/-- A state respects the dependence when a complement stands only on what it completes. -/
def Intact.Coherent (i : Intact) : Prop :=
  (i.haji = true → i.daruri = true) ∧ (i.tahsini = true → i.haji = true)

/-- The second maṭlab: the ḍarūrī absolutely disrupted, the other two are too. -/
theorem daruri_disrupts_all (i : Intact) (hc : i.Coherent) (h : i.daruri = false) :
    i.haji = false ∧ i.tahsini = false := by
  rcases i with ⟨d, hj, t⟩
  cases d <;> cases hj <;> cases t <;> simp_all [Intact.Coherent]

/-- The third maṭlab: the converse fails, «ولا يلزم من اختلالهما … اختلال الضروري بإطلاق». -/
theorem others_need_not_disrupt_daruri :
    ∃ i : Intact, i.Coherent ∧ i.haji = false ∧ i.tahsini = false ∧ i.daruri = true :=
  ⟨⟨true, false, false⟩, by simp [Intact.Coherent]⟩

/-! ## The order of the maqāṣid in tarjīḥ (al-Kawkab v04 p726–728) -/

/-- What a maṣlaḥa preserves, as al-Kawkab ranks it for tarjīḥ: one of the ḍarūriyyāt, a complement
of a ḍarūrī («ومكملها»), a ḥājī or a taḥsīnī. -/
inductive Maqsad where
  | daruri (k : Kulli) | mukammil | haji | tahsini
  deriving DecidableEq, Repr

/-- «تقدم المقاصد الضرورية … على غيرها … ومكملها … على الحاجية … وتقدم المصلحة الحاجية على التحسينية». -/
def Maqsad.tier : Maqsad → Nat
  | .daruri _ => 3 | .mukammil => 2 | .haji => 1 | .tahsini => 0

/-- The tiers refine al-Shāṭibī's three ranks: a complement of the ḍarūrī sits between it and the ḥājī. -/
def Maqsad.rutba : Maqsad → Rutba
  | .daruri _ | .mukammil => .daruri | .haji => .haji | .tahsini => .tahsini

theorem tier_refines_rank (a b : Maqsad) (h : a.rutba.rank < b.rutba.rank) : a.tier < b.tier := by
  cases a <;> cases b <;> simp_all [Maqsad.rutba, Maqsad.tier, Rutba.rank]

/-- The two positions on dīn against the other ḍarūriyyāt: `kawkab`, «ويقدم حفظ الدين على باقي
الضرورية … لأنها المقصود الأعظم»; `qila`, «وقيل: تقدم الأربع الأخر على الدينية؛ لأنها حق آدمي». -/
inductive DinReading where
  | kawkab | qila
  deriving DecidableEq, Repr

/-- Which of two conflicting maṣāliḥ is put first. -/
inductive Taqdim where
  | first | second | tawaqquf
  deriving DecidableEq, Repr

/-- Rank of a ḍarūrī within the tier, on each reading: dīn highest (`kawkab`) or lowest (`qila`);
the others by al-Kawkab's «ف». -/
def Kulli.tarjihRank : DinReading → Kulli → Nat
  | .kawkab, k => k.rank
  | .qila, .din => 0
  | .qila, k => k.rank + 1

/-- The order of two maṣāliḥ: the higher tier first; within the ḍarūriyyāt, by rank on the reading;
the rest suspended (tawaqquf), as al-Kawkab states no further order. -/
def taqdim (r : DinReading) (a b : Maqsad) : Taqdim :=
  let key : Maqsad → Nat × Nat := fun
    | .daruri k => (3, k.tarjihRank r)
    | m => (m.tier, 0)
  let (ta, ra) := key a
  let (tb, rb) := key b
  if ta > tb then .first else if ta < tb then .second
  else if ra > rb then .first else if ra < rb then .second else .tawaqquf

/-- The higher tier always comes first, whatever the reading. -/
theorem tier_decides (r : DinReading) (a b : Maqsad) (h : b.tier < a.tier) : taqdim r a b = .first := by
  cases a <;> cases b <;> simp_all [taqdim, Maqsad.tier] <;> omega

/-- Every maqṣad, for the exhaustive checks below. -/
def Maqsad.all : List Maqsad :=
  [.daruri .din, .daruri .nafs, .daruri .aql, .daruri .nasl, .daruri .mal, .daruri .ird,
    .mukammil, .haji, .tahsini]

theorem Maqsad.mem_all (m : Maqsad) : m ∈ Maqsad.all := by
  cases m with
  | daruri k => cases k <;> decide
  | _ => decide

/-- The order is antisymmetric: swapping the two swaps the verdict. -/
theorem taqdim_swap (r : DinReading) (a b : Maqsad) :
    taqdim r a b = .first ↔ taqdim r b a = .second := by
  have h : ∀ r ∈ [DinReading.kawkab, .qila], ∀ a ∈ Maqsad.all, ∀ b ∈ Maqsad.all,
      (taqdim r a b = .first ↔ taqdim r b a = .second) := by decide
  exact h r (by cases r <;> decide) a (Maqsad.mem_all a) b (Maqsad.mem_all b)

/-- Strict precedence is transitive on each reading. -/
theorem taqdim_trans (r : DinReading) (a b c : Maqsad) (hab : taqdim r a b = .first)
    (hbc : taqdim r b c = .first) : taqdim r a c = .first := by
  have h : ∀ r ∈ [DinReading.kawkab, .qila], ∀ a ∈ Maqsad.all, ∀ b ∈ Maqsad.all, ∀ c ∈ Maqsad.all,
      taqdim r a b = .first → taqdim r b c = .first → taqdim r a c = .first := by decide
  exact h r (by cases r <;> decide) a (Maqsad.mem_all a) b (Maqsad.mem_all b) c (Maqsad.mem_all c) hab hbc

/-- On al-Kawkab's reading dīn precedes every other ḍarūrī. -/
theorem din_first (k : Kulli) (h : k ≠ .din) : taqdim .kawkab (.daruri .din) (.daruri k) = .first := by
  cases k <;> simp_all [taqdim, Kulli.tarjihRank, Kulli.rank]

/-- The two readings differ only where dīn meets another ḍarūrī. -/
theorem din_reading_locus (a b : Maqsad) (h : taqdim .kawkab a b ≠ taqdim .qila a b) :
    a = .daruri .din ∨ b = .daruri .din := by
  have hall : ∀ a ∈ Maqsad.all, ∀ b ∈ Maqsad.all,
      taqdim .kawkab a b ≠ taqdim .qila a b → a = .daruri .din ∨ b = .daruri .din := by decide
  exact hall a (Maqsad.mem_all a) b (Maqsad.mem_all b) h

/-- Wealth and honour stand level: al-Kawkab states no order between them. -/
theorem mal_ird_suspended (r : DinReading) : taqdim r (.daruri .mal) (.daruri .ird) = .tawaqquf := by
  cases r <;> rfl

/-- The order agrees with al-Shāṭibī's dependence: the original ḍarūrī precedes its complement, and
the complement of the ḍarūrī precedes the ḥājī. -/
theorem asl_before_takmila (r : DinReading) (k : Kulli) :
    taqdim r (.daruri k) .mukammil = .first ∧ taqdim r .mukammil .haji = .first ∧
      taqdim r .haji .tahsini = .first := by
  cases r <;> cases k <;> exact ⟨rfl, rfl, rfl⟩

end Usul.Readings.Maqasid
