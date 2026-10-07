import Usul.Qiyas
import Usul.Taarud

/-!
# Jadal: the objections as a whole, the kinds of qiyās, and tarjīḥ

The uṣūl works list twelve objections to qiyās (Rawḍat al-Nāẓir v2 p301; al-Ṭūfī v3 p458) or
twenty-five (al-Kawkab v4 p229, after Ibn al-Ḥājib and Ibn Mufliḥ), and state that «they all
reduce to manʿ or muʿāraḍa» (al-Ṭūfī v3 p565; al-Kawkab v4 p229; Ādāb al-Baḥth p351).

Here that statement becomes a theorem. A `Debate` carries everything the objections speak
about. Each objection (`Qadih`) has a success condition and a kind:

* **manʿ**: it denies something the qiyās needs, so it is the negation of a gate condition;
* **muʿāraḍa**: it brings a competing source, so it is a gate impediment.

`debateGate` is built from that classification alone, and `debateGate_holds_iff` proves
that the gate holds exactly when no objection succeeds. `objection_blocks` gives the
reduction, `debateGate_sound` the conclusion. Which objection is of which kind is this
encoding's reading of the reduction claim; the sources do not tabulate it.

Then the kinds of qiyās: al-ʿaks, al-dalāla, al-awlā / al-musāwī (Rawḍa v2 pp. 187, 246;
al-Kawkab v4 pp. 8, 105, 209), shabah as a fallback after qiyās al-ʿilla (al-Kawkab v4 p190),
and tarjīḥ between ʿilal under the constraints the sources state (al-Kawkab v4 p718; Rawḍa
v2 p401; al-Ṭūfī v3 p716).
-/

namespace Usul.Jadal

open Usul Usul.Schema Usul.Qiyas

/-! ## The debate -/

/-- Positions the objections presuppose; each disputed one is a parameter (see IQ-13..IQ-17). -/
structure Policy where
  allowTakhsis : IllaSource → Bool
  allowPlural : Bool
  admitKasr : Bool

/-- Everything an objection can speak about. -/
structure Debate (α β : Type) extends Argument α β where
  /-- the ruling claimed for the farʿ -/
  claimed : β
  /-- the ruling actually in dispute (al-qawl bi'l-mūjab) -/
  disputed : β
  /-- how the ʿilla was established -/
  source : IllaSource
  /-- an impediment offered to answer a naqḍ (takhṣīṣ) -/
  impediment : Wasf α
  /-- the purpose (ḥikma) the waṣf stands for (kasr) -/
  hikma : Wasf α
  /-- other ʿilal offered for the ruling (plurality, against ʿadam al-taʾthīr) -/
  others : List (Wasf α)
  /-- the aṣl's ruling is intelligible (maʿqūl al-maʿnā), not purely devotional -/
  intelligible : Bool
  /-- some maslak establishes that the waṣf is the ʿilla (the answer to muṭālaba) -/
  provedCausal : Bool
  /-- the waṣf is a fixed criterion (munḍabiṭ) -/
  crisp : Bool
  /-- the same controlling factor (ḍābiṭ) in aṣl and farʿ -/
  sameDabit : Bool
  /-- the ruling leads to the maṣlaḥa it was legislated for (against ifḍāʾ) -/
  servesPurpose : Bool
  /-- the senses the term naming the ʿilla can bear (istifsār, taqsīm) -/
  senses : List (Wasf α)
  /-- a second waṣf the objector finds in the aṣl (farq, muʿāraḍa fī al-aṣl) -/
  rival : Option (Wasf α)
  /-- a ruling the law attaches to this waṣf elsewhere (fasād al-waḍʿ) -/
  lawAttaches : Option β
  /-- a counter-ruling for the farʿ, and whether it is drawn from the same ʿilla and aṣl (qalb) -/
  counter : Option β
  counterSameIlla : Bool

inductive Qadih where
  | istifsar | fasadItibar | fasadWad | man | taqsim | mutalaba | naqd | qawlBiMujab | qalb
  | adamTathir | muarada | farq | tarkib | kasr | ikhtilafDabit | mukhalafatHukm | ifda | indibat
  deriving DecidableEq, Repr

inductive Kind where
  | man | muarada
  deriving DecidableEq, Repr

/-- The reduction: denials are manʿ, competing sources are muʿāraḍa. -/
def Qadih.kind : Qadih → Kind
  | .fasadItibar | .fasadWad | .naqd | .qalb | .adamTathir | .muarada | .farq | .kasr => .muarada
  | _ => .man

def Qadih.all : List Qadih :=
  [.istifsar, .fasadItibar, .fasadWad, .man, .taqsim, .mutalaba, .naqd, .qawlBiMujab, .qalb,
   .adamTathir, .muarada, .farq, .tarkib, .kasr, .ikhtilafDabit, .mukhalafatHukm, .ifda, .indibat]

theorem Qadih.mem_all (q : Qadih) : q ∈ Qadih.all := by cases q <;> simp [Qadih.all]

variable {α β : Type}

/-- When each objection succeeds. -/
def Qadih.succeeds (P : Policy) (d : Debate α β) : Qadih → Prop
  | .istifsar => 2 ≤ d.senses.length ∧ ∃ m ∈ d.senses, m d.far = false
  | .taqsim => ∃ m ∈ d.senses, m d.asl = true ∧ m d.far = false
  | .man => d.illa d.asl = false ∨ d.illa d.far = false
  | .mutalaba => d.provedCausal = false
  | .qawlBiMujab => d.claimed ≠ d.disputed
  | .tarkib => (d.asl, d.hukm) ∉ d.known
  | .ikhtilafDabit => d.sameDabit = false
  | .mukhalafatHukm => d.claimed ≠ d.hukm
  | .ifda => d.servesPurpose = false
  | .indibat => d.crisp = false ∨ d.intelligible = false
  | .fasadItibar => d.textOnFar ≠ none
  | .fasadWad => ∃ b, d.lawAttaches = some b ∧ b ≠ d.claimed
  | .naqd => NaqdSucceedsBy P.allowTakhsis d.source d.illa d.impediment d.hukm d.known
  | .kasr => P.admitKasr = true ∧ Naqd d.hikma d.hukm d.known
  | .adamTathir => AdamTathirSucceeds P.allowPlural d.illa d.others d.hukm d.known
  | .farq => ∃ w', d.rival = some w' ∧ w' d.far ≠ w' d.asl
  | .qalb => ∃ c, d.counter = some c ∧ c ≠ d.claimed ∧ d.counterSameIlla = true
  | .muarada => ∃ c, d.counter = some c ∧ c ≠ d.claimed ∧ d.counterSameIlla = false

/-- The gate built from the classification: manʿ-kinds negated as conditions, muʿāraḍa-kinds
as impediments. -/
def debateGate (P : Policy) : Sadi.Gate (Debate α β) :=
  ⟨(Qadih.all.filter (·.kind == .man)).map fun q d => ¬ q.succeeds P d,
   (Qadih.all.filter (·.kind == .muarada)).map fun q d => q.succeeds P d⟩

/-- The objections are exactly the gate: it holds iff none succeeds. -/
theorem debateGate_holds_iff (P : Policy) (d : Debate α β) :
    (debateGate P).Holds d ↔ ∀ q : Qadih, ¬ q.succeeds P d := by
  constructor
  · rintro ⟨hc, hm⟩ q
    cases hk : q.kind
    · exact hc _ (List.mem_map.2 ⟨q, List.mem_filter.2 ⟨q.mem_all, by simp [hk]⟩, rfl⟩)
    · exact hm _ (List.mem_map.2 ⟨q, List.mem_filter.2 ⟨q.mem_all, by simp [hk]⟩, rfl⟩)
  · intro h
    refine ⟨?_, ?_⟩
    · intro c hc
      obtain ⟨q, _, rfl⟩ := List.mem_map.1 hc
      exact h q
    · intro m hm
      obtain ⟨q, _, rfl⟩ := List.mem_map.1 hm
      exact h q

/-- Every successful objection blocks the qiyās, as a missing condition (manʿ) or a present
impediment (muʿāraḍa). -/
theorem objection_blocks {P : Policy} {d : Debate α β} (q : Qadih) (h : q.succeeds P d) :
    ¬ (debateGate P).Holds d :=
  fun hg => (debateGate_holds_iff P d).1 hg q h

/-- The reduction made precise: a manʿ-kind objection is the negation of a gate condition, a
muʿāraḍa-kind one is a gate impediment. -/
theorem kind_spec (P : Policy) (q : Qadih) :
    (q.kind = .man → (fun d : Debate α β => ¬ q.succeeds P d) ∈ (debateGate P).conds) ∧
    (q.kind = .muarada → (fun d : Debate α β => q.succeeds P d) ∈ (debateGate P).impediments) := by
  refine ⟨fun hk => ?_, fun hk => ?_⟩
  · exact List.mem_map.2 ⟨q, List.mem_filter.2 ⟨q.mem_all, by simp [hk]⟩, rfl⟩
  · exact List.mem_map.2 ⟨q, List.mem_filter.2 ⟨q.mem_all, by simp [hk]⟩, rfl⟩

/-- Soundness: when no objection succeeds, every ruling agreeing with the given cases and
depending only on the ʿilla gives the farʿ the claimed ruling. -/
theorem debateGate_sound {P : Policy} {d : Debate α β} (hg : (debateGate P).Holds d) {H : α → β}
    (hH : Agrees H d.known) (hf : Factors H d.illa) : H d.far = d.claimed := by
  have h := (debateGate_holds_iff P d).1 hg
  have hman : ¬ (d.illa d.asl = false ∨ d.illa d.far = false) := h .man
  have htark : ¬ (d.asl, d.hukm) ∉ d.known := h .tarkib
  have hmuk : ¬ d.claimed ≠ d.hukm := h .mukhalafatHukm
  have ha : d.illa d.asl = true := by cases e : d.illa d.asl <;> simp_all
  have hfar : d.illa d.far = true := by cases e : d.illa d.far <;> simp_all
  rw [hf d.far d.asl (by rw [hfar, ha]), hH _ (Classical.not_not.1 htark), Classical.not_not.1 hmuk]

/-- Competing qiyāses (qalb, muʿāraḍa) are a taʿāruḍ: they go to `Usul.resolve`, where
reconciliation, abrogation and preference come before suspension. -/
def counterConflict (jam naskh tarjih : Option β) : Conflict β := ⟨jam, naskh, tarjih⟩

theorem counter_resolved_by_tarjih (b : β) : resolve (counterConflict none none (some b)) = .tarjih b := rfl

/-! ## Kinds of qiyās -/

/-- Qiyās al-ʿaks: where the ruling turns with the waṣf, its absence gives the contrary
(al-Kawkab v4 p8; Ibn ʿUthaymīn p74). -/
theorem qiyas_aks {α : Type} {H : α → Bool} {w : Wasf α} (h : ∀ x, w x = true ↔ H x = true) {far : α}
    (hfar : w far = false) : H far = false := by
  cases e : H far
  · rfl
  · simp [(h far).2 e] at hfar

/-- Qiyās al-dalāla: joining by an indicator of the ʿilla (its concomitant, effect or ruling)
verifies the ʿilla in the farʿ (Rawḍa v2 p246; al-Kawkab v4 p7). -/
theorem dalala_verifies {α : Type} {w dalil : Wasf α} (h : ∀ x, dalil x = true → w x = true)
    {far : α} (hd : dalil far = true) : TahqiqManat w far :=
  h far hd

/-- Qiyās al-awlā: where the ruling rises with a graded ʿilla, a farʿ with more of it has the
ruling a fortiori; equal degree is qiyās al-musāwī (Rawḍa v2 p187; al-Kawkab v4 pp. 105–106). -/
theorem qiyas_awla {α : Type} {H : α → Bool} (degree : α → Nat)
    (mono : ∀ x y, degree x ≤ degree y → H x = true → H y = true) {asl far : α}
    (hasl : H asl = true) (hd : degree asl ≤ degree far) : H far = true :=
  mono asl far hd hasl

theorem qiyas_musawi {α : Type} {H : α → Bool} (degree : α → Nat)
    (mono : ∀ x y, degree x ≤ degree y → H x = true → H y = true) {asl far : α}
    (hasl : H asl = true) (hd : degree asl = degree far) : H far = true :=
  qiyas_awla degree mono hasl (Nat.le_of_eq hd)

/-- Shabah only where qiyās al-ʿilla is unavailable («it is not resorted to where qiyās
al-ʿilla is possible … otherwise it is a proof for us», al-Kawkab v4 p190): text, then
qiyās al-ʿilla, then shabah (if admitted), else suspension. -/
def farByOrder (acceptShabah : Bool) (text illaQ shabahQ : Option β) (tawaqquf : β) : β :=
  resolveD [text, illaQ, if acceptShabah then shabahQ else none] tawaqquf

theorem shabah_never_overrides_illa (s : Bool) (b : β) (sh : Option β) (d : β) :
    farByOrder s none (some b) sh d = b := rfl

theorem shabah_only_as_fallback (b : β) (d : β) :
    farByOrder true none none (some b) d = b := rfl

theorem shabah_rejected (sh : Option β) (d : β) : farByOrder false none none sh d = d := rfl

/-! ## Tarjīḥ between ʿilal -/

inductive Maslak where
  | ijma | nass | ima | sabr | munasaba | shabah | dawaran | tard
  deriving DecidableEq, Repr

/-- Constraints the sources state on preference (a rank is any scale meeting them):
sabr over munāsaba over shabah (al-Kawkab v4 p718; Rawḍa v2 p401: munāsiba over shabahiyya),
consensual over textual over inferred (al-Ṭūfī v3 p716). -/
def RespectsSources (rank : Maslak → Nat) : Prop :=
  rank .munasaba < rank .sabr ∧ rank .shabah < rank .munasaba ∧
  rank .nass < rank .ijma ∧ rank .sabr < rank .nass

/-- One such scale exists, so the constraints are consistent. -/
def exampleRank : Maslak → Nat
  | .ijma => 7 | .nass => 6 | .ima => 5 | .sabr => 4 | .munasaba => 3 | .dawaran => 2
  | .shabah => 1 | .tard => 0

theorem exampleRank_respects : RespectsSources exampleRank := by
  simp [RespectsSources, exampleRank]

/-- Tarjīḥ picks an ʿilla of maximal rank (S8), under any admissible scale. -/
def preferred {ι : Type} (rank : Maslak → Nat) (via : ι → Maslak) (cands : List ι) : Option ι :=
  Sadi.best (fun c => (rank (via c) : Int)) cands

theorem preferred_optimal {ι : Type} {rank : Maslak → Nat} {via : ι → Maslak} {cands : List ι} {c : ι}
    (h : preferred rank via cands = some c) : Optimal (fun c => (rank (via c) : Int)) cands c :=
  best_optimal h

/-- Under any scale respecting the sources, an ʿilla by sabr beats one by shabah. -/
theorem sabr_beats_shabah {rank : Maslak → Nat} (h : RespectsSources rank) :
    rank .shabah < rank .sabr :=
  Nat.lt_trans h.2.1 h.1

end Usul.Jadal
