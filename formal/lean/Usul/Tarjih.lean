import Usul.Signature
import Usul.Taarud

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
  affirming report), and between ʿilal (p397–401). Advantages the source reports as disputed
  or weak («وقيل: لا يرجح بذلك», «وهي ترجيحات ضعيفة») are recorded but do not count.
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
  -- reported as disputed or weak: recorded, not counted
  | hazir | khiffa | hissiyya | fewerAwsaf
  deriving DecidableEq, Repr

/-- Whether the source lets the advantage decide. Prohibition over permission is al-Qāḍī's,
«وقيل: لا يرجح بذلك» (p396); lightness of the ruling «ترجيحات ضعيفة» (p398); the sensible ʿilla
and the fewer properties «ترجيح ضعيف», Abū al-Khaṭṭāb choosing «التسوية» (p398–399). -/
def Murajjih.counts : Murajjih → Bool
  | .hazir | .khiffa | .hissiyya | .fewerAwsaf => false
  | _ => true

/-- One stated advantage: the proof for `winner` is preferred to the proof for `loser`. -/
structure Advantage (P : Type) where
  winner : P
  loser : P
  by_ : Murajjih
  deriving DecidableEq, Repr

variable {P : Type} [DecidableEq P]

/-- The strongest tier any proof cited for `p` reaches; `none` if it cites none. -/
def top (ps : List (P × Tier)) (p : P) : Option Nat :=
  ((ps.filter (·.1 = p)).map (·.2.rank)).max?

/-- Some counted advantage prefers `p` to `q`. -/
def favours (as : List (Advantage P)) (p q : P) : Bool :=
  as.any fun a => a.winner = p && a.loser = q && a.by_.counts

/-- `p` outweighs `q`: a proof of a higher tier, or of the same tier with a counted advantage over
`q` and none from `q` back. A position citing no proof outweighs nothing. -/
def beats (ps : List (P × Tier)) (as : List (Advantage P)) (p q : P) : Bool :=
  match top ps p, top ps q with
  | some _, none => true
  | some a, some b => a > b || (a == b && favours as p q && !favours as q p)
  | none, _ => false

/-- Tarjīḥ: the reported ruling that outweighs every other, if any. -/
def prevail (rs : List P) (ps : List (P × Tier)) (as : List (Advantage P)) : Option P :=
  rs.find? fun p => rs.all fun q => q = p || beats ps as p q

/-- The whole procedure: the kernel's `resolve`, its tarjīḥ by proof. -/
def reconcile (jam naskh : Option P) (rs : List P) (ps : List (P × Tier)) (as : List (Advantage P)) :
    Resolution P :=
  resolve ⟨jam, naskh, prevail rs ps as⟩

/-- Tarjīḥ never invents a ruling. -/
theorem prevail_mem {rs : List P} {ps : List (P × Tier)} {as : List (Advantage P)} {p : P}
    (h : prevail rs ps as = some p) : p ∈ rs :=
  List.mem_of_find?_eq_some h

/-- A position that cites no proof outweighs nothing, whoever holds it. -/
theorem beats_unproven {ps : List (P × Tier)} {as : List (Advantage P)} {p q : P}
    (h : top ps p = none) : beats ps as p q = false := by
  simp [beats, h]

/-- A higher tier decides, whatever advantages the lower one has (p390). -/
theorem beats_of_tier {ps : List (P × Tier)} {as : List (Advantage P)} {p q : P} {a b : Nat}
    (hp : top ps p = some a) (hq : top ps q = some b) (h : b < a) : beats ps as p q = true := by
  simp [beats, hp, hq, h]

/-- No advantage lifts a lower tier. -/
theorem not_beats_of_tier {ps : List (P × Tier)} {as : List (Advantage P)} {p q : P} {a b : Nat}
    (hp : top ps p = some a) (hq : top ps q = some b) (h : a < b) : beats ps as p q = false := by
  have : ¬ b < a := Nat.lt_asymm h
  have : a ≠ b := Nat.ne_of_lt h
  simp_all [beats]

/-- Outweighing is asymmetric, so at most one reported ruling prevails. -/
theorem beats_asymm {ps : List (P × Tier)} {as : List (Advantage P)} {p q : P}
    (h : beats ps as p q = true) : beats ps as q p = false := by
  unfold beats at *
  cases hp : top ps p <;> cases hq : top ps q <;> simp_all
  rename_i a b
  rcases h with h | ⟨⟨rfl, h₁⟩, h₂⟩
  · exact ⟨Nat.le_of_lt h, fun e => absurd h (e ▸ Nat.lt_irrefl _)⟩
  · simp_all

/-- Advantages the source does not count never decide. -/
theorem favours_uncounted {as : List (Advantage P)} {p q : P}
    (h : ∀ a ∈ as, a.by_.counts = false) : favours as p q = false := by
  simp only [favours, List.any_eq_false]
  intro a ha; simp [h a ha]

theorem reconcile_jam_first {jam : P} {naskh : Option P} {rs : List P} {ps : List (P × Tier)}
    {as : List (Advantage P)} : reconcile (some jam) naskh rs ps as = .jam jam := rfl

theorem reconcile_tawaqquf_iff {jam naskh : Option P} {rs : List P} {ps : List (P × Tier)}
    {as : List (Advantage P)} :
    reconcile jam naskh rs ps as = .tawaqquf ↔ jam = none ∧ naskh = none ∧ prevail rs ps as = none :=
  resolve_tawaqquf_iff

-- A report outweighs a qiyās, whatever the qiyās's advantages.
#guard prevail ["a", "b"] [("a", Tier.zanni), ("b", .qiyas)] [⟨"b", "a", .muaththira⟩] == some "a"
-- Two reports: the connected one over the mursal.
#guard prevail ["a", "b"] [("a", Tier.zanni), ("b", .zanni)] [⟨"a", "b", .muttasil⟩] == some "a"
-- Advantages on both sides: the weighing is the mujtahid's own, so tawaqquf.
#guard prevail ["a", "b"] [("a", Tier.zanni), ("b", .zanni)] [⟨"a", "b", .muttasil⟩, ⟨"b", "a", .muthbit⟩] == none
-- A disputed advantage does not decide.
#guard prevail ["a", "b"] [("a", Tier.zanni), ("b", .zanni)] [⟨"a", "b", .hazir⟩] == none
-- A position citing no proof loses to one that cites any.
#guard prevail ["a", "b"] [("b", Tier.istishab)] [] == some "b"
-- Nothing cited on either side: tawaqquf.
#guard prevail ["a", "b"] ([] : List (String × Tier)) [] == none
#guard reconcile none none ["a", "b"] [("a", Tier.qati), ("b", .zanni)] [] == .tarjih "a"

end Usul.Tarjih
