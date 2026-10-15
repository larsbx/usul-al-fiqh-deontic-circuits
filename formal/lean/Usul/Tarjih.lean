import Usul.Signature
import Usul.Taarud
import Usul.Jadal

/-!
# Tarjīḥ by proof

A ruling stands by its proof, not by who holds it. Between reported positions, tarjīḥ weighs the
proofs each one cites (Ibn Qudāma, *Rawḍat al-Nāẓir*, «باب: في ترتيب الأدلة ومعرفة الترجيح»,
v02 p389–401). Who holds a position, the madhhab's label included, is kept as a record
(`Usul.Reconcile`) and never enters the weighing.

* **Tiers** (p389–390). The mujtahid looks first to ijmāʿ, «لكون الإجماع دليلا قاطعا»; then
  to the Book and the mutawātir Sunna, «وهما على رتبة واحدة»; then to the āḥād reports; then to
  qiyās. A text is certain only if both its transmission and its indication are (`Tier.kind`). «ولا يتصور أن يتعارض علم وظن»: a proof of a higher tier is not weighed against a lower
  one. Below the āḥād the tiers follow Aḥmad's order of resort (`DalilKind.resort`): the fatwā
  of a ṣaḥābī, the ṣaḥābī view nearest the text, the mursal and the weak report, qiyās, and
  istiṣḥāb last. `Tier.refines_resort` checks that the tiers never invert that order.
* **Murajjiḥāt** (p391–401). Two proofs of one tier are weighed by the advantages the source
  states: in the chain (more narrators, the narrator's precision, his piety, the one the event
  concerns, the one who took part in it), in the text (corroboration by the Book, the Sunna,
  ijmāʿ, a qiyās, the caliphs or a ṣaḥābī; agreed raising; a narrator not contradicting
  himself; a connected chain), from outside (what moves from the original state; the
  affirming report), and between ʿilal (p397–401). Ibn al-Najjār's *Sharḥ al-Kawkab al-Munīr*
  (v04 p650–703) adds the strength of the indication, which the Rawḍa leaves out: the Prophet's
  saying over his deed and his deed over his tacit approval, what was heard from him over his
  silence, prohibition over command and command over permission, the specific over the general
  and the unspecialised general over the specialised, iqtiḍāʾ over īmāʾ and mafhūm, īmāʾ over
  mafhūm, the mafhūm of agreement over that of contrast, a ruling whose ʿilla the Lawgiver
  states, and what the two Ṣaḥīḥs agree on. Al-Ṭūfī's *Sharḥ Mukhtaṣar al-Rawḍa* (v03 p729–746)
  adds the spoken over the implied («ودلالة المنطوق على المفهوم», p730), the naṣṣ over the ẓāhir
  (p738), the clear over the ambiguous and the literal over the figurative (p729–730), the
  better-known sense (p730, p746), a text stated to give the ruling over one read from context
  (p730), and the view of the more learned of two ṣaḥāba (p743). Each advantage carries its standing in the sources
  (asserted, disputed, weak, rejected; `Murajjih.standing`), and which standings decide is a
  `Policy`: by default what a cited source asserts as its own, with the strict and the inclusive
  policies run beside it. Each advantage also carries its `Basis`: stated by a source comparing the
  two proofs, or applied by the bank to properties the proofs show; by default only the stated
  decide.
* **Rebuttal.** A source may cite a proof only to answer it: «وخرجه بعض أصحابنا على وجهين … ولا
  يصح» (al-Mughnī v07:p258), «وقد أشار القاضي إلى الفرق … وهذا ممنوع» (Ibn Rajab, v01:p222). The
  proof is kept with the objection that answers it (`Proof.rebuttal`, a `Jadal.Qadih`, so it reduces
  to manʿ or muʿāraḍa), and the policy decides whether it still counts: by default what its own
  source rebuts does not, under `all` it does. A rebuttal is the citing source's own answer, never
  the bank's.
* **Tawaqquf.** «فإن لم يمكن الجمع، ولا معرفة النسخ: رجحنا، فأخذنا الأقوى في أنفسنا» (p391):
  where the stated advantages do not settle it, the weighing is the mujtahid's own, and the
  bank suspends.
-/

namespace Usul.Tarjih

/-- The tiers of proof, weakest first. -/
inductive Tier where
  | istishab | qiyas | mursalDaif | aqrabSahabi | fatwaSahabi | zanni | qati | ijma
  deriving DecidableEq, Repr

def Tier.rank : Tier → Nat
  | .istishab => 0 | .qiyas => 1 | .mursalDaif => 2 | .aqrabSahabi => 3
  | .fatwaSahabi => 4 | .zanni => 5 | .qati => 6 | .ijma => 7

/-- The kind of dalīl a tier is. The Rawḍa splits naṣṣ by certainty: `qati` is a text certain in
transmission *and* indication (the Book or the mutawātir Sunna, explicit on the point); `zanni` is
a text whose proof is a ẓann, an āḥād report or the Book by its generality, apparent sense,
implied sense or an interpretation. «لا يتصور أن يتعارض علم وظن» holds of what is ʿilm on the
point, which a certain text with a probable indication is not. -/
def Tier.kind : Tier → DalilKind
  | .istishab => .istishab | .qiyas => .qiyas | .mursalDaif => .mursalDaif
  | .aqrabSahabi => .aqrabSahabi | .fatwaSahabi => .fatwaSahabi
  | .zanni => .nass | .qati => .nass | .ijma => .ijma

theorem Tier.rank_injective : ∀ a b : Tier, a.rank = b.rank → a = b := by
  intro a b; cases a <;> cases b <;> decide

/-- The tiers refine Aḥmad's order of resort: a stronger tier is never resorted to later. -/
theorem Tier.refines_resort : ∀ t u : Tier, t.rank < u.rank → u.kind.resort ≤ t.kind.resort := by
  intro t u; cases t <;> cases u <;> decide

/-- The advantages the Rawḍa states between two proofs of one tier. -/
inductive Murajjih where
  -- the chain (p391–394)
  | kathratRuwat | tayaqquz | wara | sahibWaqia | mubashir
  -- the text (p394–395)
  | corroborated | marfu | consistentNarrator | muttasil
  -- from outside (p396)
  | naqil | muthbit
  -- between ʿilal (p397–401)
  | usulMany | tardAks | mutaaddiya | wasf | ithbat | aslShari | aslAgreed | aslStronger
  | muaththira | mulaima | munasaba
  -- the indication and the report (al-Kawkab v04 p650–703)
  | sahihayn | masmu | qawl | fil | nahy | amr | khass | ammMahfuz | iqtida | ima | muwafaqa | muallal
  | hazir
  -- the indication (al-Ṭūfī, Sharḥ Mukhtaṣar al-Rawḍa v03 p729–746)
  | mantuq | nass | mubayyan | haqiqa | ashhar | siyaq | afqah
  -- called weak or rejected by a cited source: recorded, not counted
  | khiffa | hissiyya | fewerAwsaf | dariHadd
  deriving DecidableEq, Repr

/-- How the cited sources hold an advantage. Every murajjiḥ is formalised with its standing; which
standings decide is a policy (`Policy`), itself part of the formalisation, so the weak and the
rejected are kept and can be run, not dropped. -/
inductive Standing where
  /-- a cited source asserts it and reports no dissent -/
  | asserted
  /-- a cited source asserts it and reports a dissent -/
  | disputed
  /-- a cited source calls it weak -/
  | weak
  /-- a cited source rejects it -/
  | rejected
  deriving DecidableEq, Repr

/-- The standing of each advantage in the cited sources.
* Disputed: more narrators («وقال بعض الحنفية: لا يرجح به», Rawḍa v02 p391), the transitive ʿilla
  («ومنع ذلك قوم», p399, Ibn Qudāma siding «والأول أولى»), prohibition over permission (al-Qāḍī's,
  «وقيل: لا يرجح بذلك», p396; asserted in al-Kawkab v04 p679), the saying over the deed («وقيل:
  هما سواء، وقيل: الفعل أولى», al-Kawkab v04 p656), command over permission (al-Āmidī and others
  the other way, v04 p659), what moves from the original state (al-Rāzī and al-Ṭūfī the other way,
  v04 p687).
* Weak: lightness of the ruling, «وهي ترجيحات ضعيفة» (Rawḍa p398; al-Kawkab asserts it, v04
  p692); the sensible ʿilla and the fewer properties, «ترجيح ضعيف», Abū al-Khaṭṭāb choosing
  «التسوية» (p398–399).
* Rejected: what wards off the ḥadd, «ولا يرجح المسقط للحد» (Rawḍa p396; al-Kawkab gives it «عند
  الأكثر», v04 p689). -/
def Murajjih.standing : Murajjih → Standing
  | .kathratRuwat | .mutaaddiya | .hazir | .qawl | .amr | .naqil => .disputed
  | .khiffa | .hissiyya | .fewerAwsaf => .weak
  | .dariHadd => .rejected
  | _ => .asserted

/-- Where an advantage comes from. `stated`: a cited source compares the two proofs itself («وهذا
أخص من حديث أبي سعيد، فيقدم عليه»). `applied`: the bank applies a murajjiḥ of the uṣūl works to
properties each proof shows in its source, which no source compares. Both are kept; the policy
decides whether the applied count. -/
inductive Basis where
  | stated | applied
  deriving DecidableEq, Repr

/-- Which advantages decide: by their standing in the uṣūl works, and whether an applied one counts;
and which proofs: whether one its own source rebuts still counts. -/
structure Policy where
  standing : Standing → Bool
  applied : Bool
  rebutted : Bool

namespace Policy
/-- Only stated advantages that no cited source disputes, and only unrebutted proofs. -/
def strict : Policy := ⟨fun | .asserted => true | _ => false, false, false⟩
/-- Stated advantages a cited source asserts as its own, disputed or not, and the proofs no citing
source rebuts: the bank's default. -/
def sources : Policy := ⟨fun | .asserted | .disputed => true | _ => false, false, false⟩
/-- As `sources`, and the bank's own applications of the murajjiḥāt too. -/
def applying : Policy := ⟨sources.standing, true, false⟩
/-- Every recorded advantage and every cited proof: the weak, the rejected, the applied and the
rebutted included. -/
def all : Policy := ⟨fun _ => true, true, true⟩

/-- The policies are nested: strict ⊆ sources ⊆ applying ⊆ all. -/
theorem strict_le_sources (s : Standing) (h : strict.standing s = true) : sources.standing s = true := by
  cases s <;> simp_all [strict, sources]

theorem sources_le_applied (s : Standing) : sources.standing s = applying.standing s := rfl

theorem le_all (s : Standing) : all.standing s = true ∧ all.applied = true ∧ all.rebutted = true :=
  ⟨rfl, rfl, rfl⟩

/-- The default leaves out exactly what a cited source calls weak or rejects. -/
theorem sources_false_iff (s : Standing) : sources.standing s = false ↔ s = .weak ∨ s = .rejected := by
  cases s <;> simp [sources]

/-- The default counts only what a source states. -/
theorem sources_stated_only : sources.applied = false := rfl

/-- The default leaves out a proof its own source rebuts; only `all` counts it. -/
theorem sources_unrebutted : sources.rebutted = false := rfl
end Policy

/-- A proof cited for position `pos`, of tier `tier`, with the objection by which the source citing
it answers it, if it does (`Jadal.Qadih`: «ولا يصح», «وهذا ممنوع», a farq, a naqḍ). -/
structure Proof (P : Type) where
  pos : P
  tier : Tier
  rebuttal : Option Jadal.Qadih
  deriving DecidableEq, Repr

/-- The policy counts the proof: unrebutted, or the policy keeps rebutted proofs. -/
def Proof.counts {P : Type} (π : Policy) (x : Proof P) : Bool :=
  x.rebuttal.isNone || π.rebutted

/-- The proofs the policy weighs, each as (position, tier). -/
def cited {P : Type} (π : Policy) (ps : List (Proof P)) : List (P × Tier) :=
  (ps.filter (·.counts π)).map fun x => (x.pos, x.tier)

/-- `all` weighs every cited proof. -/
theorem cited_all {P : Type} (ps : List (Proof P)) :
    cited Policy.all ps = ps.map fun x => (x.pos, x.tier) := by
  simp only [cited, Proof.counts, Policy.all, Bool.or_true]
  congr 1; exact List.filter_eq_self.2 fun _ _ => rfl

/-- Where no proof is rebutted, which policy is run makes no difference to what is weighed. -/
theorem cited_unrebutted {P : Type} {π π' : Policy} {ps : List (Proof P)}
    (h : ∀ x ∈ ps, x.rebuttal = none) : cited π ps = cited π' ps := by
  have : ∀ ρ : Policy, ps.filter (·.counts ρ) = ps := fun ρ =>
    List.filter_eq_self.2 fun x hx => by simp [Proof.counts, h x hx]
  simp [cited, this]

/-- A rebutted proof is not weighed under a policy that leaves rebutted proofs out. -/
theorem rebutted_not_cited {P : Type} {π : Policy} {ps : List (Proof P)} {x : Proof P}
    (hπ : π.rebutted = false) (hx : x.rebuttal.isSome) : x ∉ ps.filter (·.counts π) := by
  simp_all [Proof.counts, Option.isSome_iff_ne_none]

/-- One advantage: the proof for `winner` is preferred to the proof for `loser`. -/
structure Advantage (P : Type) where
  winner : P
  loser : P
  by_ : Murajjih
  basis : Basis
  deriving DecidableEq, Repr

/-- The policy counts the advantage. -/
def Advantage.counts {P : Type} (π : Policy) (a : Advantage P) : Bool :=
  π.standing a.by_.standing && (a.basis == .stated || π.applied)

variable {P : Type} [DecidableEq P]

/-- The strongest tier any proof cited for `p` reaches; `none` if it cites none. -/
def top (ps : List (P × Tier)) (p : P) : Option Nat :=
  ((ps.filter (·.1 = p)).map (·.2.rank)).max?

/-- Some advantage the policy counts prefers `p` to `q`. -/
def favours (π : Policy) (as : List (Advantage P)) (p q : P) : Bool :=
  as.any fun a => a.winner = p && a.loser = q && a.counts π

/-- `p` outweighs `q`: a proof of a higher tier, or of the same tier with a counted advantage over
`q` and none from `q` back. A position citing no proof outweighs nothing. -/
def beats (π : Policy) (ps : List (P × Tier)) (as : List (Advantage P)) (p q : P) : Bool :=
  match top ps p, top ps q with
  | some _, none => true
  | some a, some b => a > b || (a == b && favours π as p q && !favours π as q p)
  | none, _ => false

/-- Tarjīḥ: the reported ruling that outweighs every other, if any. -/
def prevail (π : Policy) (rs : List P) (ps : List (P × Tier)) (as : List (Advantage P)) : Option P :=
  rs.find? fun p => rs.all fun q => q = p || beats π ps as p q

/-- The whole procedure: the kernel's `resolve`, its tarjīḥ by the proofs the policy weighs. -/
def reconcile (π : Policy) (jam naskh : Option P) (rs : List P) (ps : List (Proof P))
    (as : List (Advantage P)) : Resolution P :=
  resolve ⟨jam, naskh, prevail π rs (cited π ps) as⟩

variable {π : Policy} {rs : List P} {ps : List (P × Tier)} {as : List (Advantage P)} {p q : P}

/-- Tarjīḥ never invents a ruling. -/
theorem prevail_mem (h : prevail π rs ps as = some p) : p ∈ rs :=
  List.mem_of_find?_eq_some h

/-- A position that cites no proof outweighs nothing, whoever holds it. -/
theorem beats_unproven (h : top ps p = none) : beats π ps as p q = false := by
  simp [beats, h]

/-- A higher tier decides, whatever advantages the lower one has (p390). -/
theorem beats_of_tier {a b : Nat} (hp : top ps p = some a) (hq : top ps q = some b) (h : b < a) :
    beats π ps as p q = true := by
  simp [beats, hp, hq, h]

/-- No advantage lifts a lower tier. -/
theorem not_beats_of_tier {a b : Nat} (hp : top ps p = some a) (hq : top ps q = some b) (h : a < b) :
    beats π ps as p q = false := by
  have : ¬ b < a := Nat.lt_asymm h
  have : a ≠ b := Nat.ne_of_lt h
  simp_all [beats]

/-- Across tiers the policy is idle: only proofs of one tier are weighed by advantages. -/
theorem beats_policy_irrelevant {π' : Policy} {a b : Nat} (hp : top ps p = some a)
    (hq : top ps q = some b) (h : a ≠ b) : beats π ps as p q = beats π' ps as p q := by
  have : (a == b) = false := by simpa using h
  simp [beats, hp, hq, this]

/-- Outweighing is asymmetric, so at most one reported ruling prevails. -/
theorem beats_asymm (h : beats π ps as p q = true) : beats π ps as q p = false := by
  unfold beats at *
  cases hp : top ps p <;> cases hq : top ps q <;> simp_all
  rename_i a b
  rcases h with h | ⟨⟨rfl, h₁⟩, h₂⟩
  · exact ⟨Nat.le_of_lt h, fun e => absurd h (e ▸ Nat.lt_irrefl _)⟩
  · simp_all

/-- Advantages the policy does not count never decide. -/
theorem favours_uncounted (h : ∀ a ∈ as, a.counts π = false) : favours π as p q = false := by
  simp only [favours, List.any_eq_false]
  intro a ha; simp [h a ha]

/-- Under the default, what a cited source calls weak or rejects never decides. -/
theorem favours_sources_weak (h : ∀ a ∈ as, a.by_.standing = .weak ∨ a.by_.standing = .rejected) :
    favours Policy.sources as p q = false :=
  favours_uncounted fun a ha => by
    simp [Advantage.counts, (Policy.sources_false_iff _).2 (h a ha)]

/-- A policy that does not count applied advantages is decided only by what the sources state. -/
theorem favours_applied_ignored (hπ : π.applied = false) (h : ∀ a ∈ as, a.basis = .applied) :
    favours π as p q = false :=
  favours_uncounted fun a ha => by simp [Advantage.counts, hπ, h a ha]

theorem reconcile_jam_first {jam : P} {naskh : Option P} {xs : List (Proof P)} :
    reconcile π (some jam) naskh rs xs as = .jam jam :=
  rfl

theorem reconcile_tawaqquf_iff {jam naskh : Option P} {xs : List (Proof P)} :
    reconcile π jam naskh rs xs as = .tawaqquf ↔ jam = none ∧ naskh = none ∧ prevail π rs (cited π xs) as = none :=
  resolve_tawaqquf_iff

/-- A position whose every proof its source rebuts outweighs nothing under a policy that leaves the
rebutted out: it stands as one that cites no proof. -/
theorem beats_rebutted {xs : List (Proof P)} (hπ : π.rebutted = false)
    (h : ∀ x ∈ xs, x.pos = p → x.rebuttal.isSome) : beats π (cited π xs) as p q = false :=
  beats_unproven <| by
    simp only [top, cited, List.filter_map, List.map_map, List.max?_eq_none_iff, List.map_eq_nil_iff,
      List.filter_eq_nil_iff, List.mem_filter]
    intro x ⟨hx, hc⟩ hp
    simp_all [Proof.counts, Option.isSome_iff_ne_none]

open Policy in
section
-- A report outweighs a qiyās, whatever the qiyās's advantages.
#guard prevail sources ["a", "b"] [("a", Tier.zanni), ("b", .qiyas)] [⟨"b", "a", .muaththira, .stated⟩] == some "a"
-- Two reports: the connected one over the mursal.
#guard prevail sources ["a", "b"] [("a", Tier.zanni), ("b", .zanni)] [⟨"a", "b", .muttasil, .stated⟩] == some "a"
-- Advantages on both sides: the weighing is the mujtahid's own, so tawaqquf.
#guard prevail sources ["a", "b"] [("a", Tier.zanni), ("b", .zanni)] [⟨"a", "b", .muttasil, .stated⟩, ⟨"b", "a", .muthbit, .stated⟩] == none
-- A weak advantage decides only under the policy that counts everything.
#guard prevail sources ["a", "b"] [("a", Tier.zanni), ("b", .zanni)] [⟨"a", "b", .khiffa, .stated⟩] == none
#guard prevail all ["a", "b"] [("a", Tier.zanni), ("b", .zanni)] [⟨"a", "b", .khiffa, .stated⟩] == some "a"
-- A disputed advantage decides by default, not under the strict policy.
#guard prevail sources ["a", "b"] [("a", Tier.zanni), ("b", .zanni)] [⟨"a", "b", .qawl, .stated⟩] == some "a"
#guard prevail strict ["a", "b"] [("a", Tier.zanni), ("b", .zanni)] [⟨"a", "b", .qawl, .stated⟩] == none
-- An applied advantage decides only under the policies that count the bank's applications.
#guard prevail sources ["a", "b"] [("a", Tier.zanni), ("b", .zanni)] [⟨"a", "b", .khass, .applied⟩] == none
#guard prevail applying ["a", "b"] [("a", Tier.zanni), ("b", .zanni)] [⟨"a", "b", .khass, .applied⟩] == some "a"
-- A position citing no proof loses to one that cites any.
#guard prevail sources ["a", "b"] [("b", Tier.istishab)] [] == some "b"
-- Nothing cited on either side: tawaqquf.
#guard prevail sources ["a", "b"] ([] : List (String × Tier)) [] == none
#guard reconcile sources none none ["a", "b"] [⟨"a", Tier.qati, none⟩, ⟨"b", .zanni, none⟩] [] == .tarjih "a"
-- A proof its own source rebuts is left out by default: the other side prevails; under `all` it counts.
#guard reconcile sources none none ["a", "b"] [⟨"a", Tier.qiyas, some .man⟩, ⟨"b", .qiyas, none⟩] [] == .tarjih "b"
#guard reconcile all none none ["a", "b"] [⟨"a", Tier.qiyas, some .man⟩, ⟨"b", .qiyas, none⟩] [] == .tawaqquf
end

end Usul.Tarjih
