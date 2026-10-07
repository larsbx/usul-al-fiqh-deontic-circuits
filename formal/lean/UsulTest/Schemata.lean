import Usul

/-!
Each rule tagged with a schema in `corpus/proposals/sadi_qawaid.json` is pinned here by a
typed `example` stating the schema's predicate of the rule's reading. The build fails if an
instance no longer has its schema's shape; `test_schemata_tags_are_pinned` fails if a tag and
a pin disagree. Tag lines: `-- @schema Q<n> <schema>`.
-/

namespace UsulTest.Schemata

open Usul Usul.Schema Usul.Muamalat Usul.Kulliyyat Usul.Qiyas Usul.Jadal

-- @schema Q2 S4-closure
example {Act : Type} (needs : Act → Act → Prop) (base : Act → Prop) (a : Act) :
    Qawaid.Wajib needs base a ↔ Closure needs base a := wajib_is_closure needs base a

-- @schema Q5 S3-gate
example (w : Worship) : Worship.gate.Holds w ↔ w.sincere = true ∧ w.follows = true := q05_both_foundations w

-- @schema Q6 S2-priority
example (d : Domain) (h : Option Hukm) : Sadi.ruled d h = resolveD [h] d.default := ruled_is_priority d h

-- @schema Q8 S3-gate
example {α β : Type} (g h : Sadi.Gate α) (φ : β → α) (y : β) :
    ((g.meet h).comap φ).Holds y ↔ g.Holds (φ y) ∧ h.Holds (φ y) := by
  rw [Sadi.Gate.holds_comap, Sadi.Gate.holds_meet]

-- @schema Q9 S2-priority
example {α : Type} (l : Option α) (c : α) : measure l c = resolveD [l] c := q09_is_priority l c

-- @schema Q10 S1-invariance
example : Factors (fun pc : Bool × Bool => burdenOf pc.1 pc.2) (fun pc => decide (pc.2 = pc.1)) :=
  burden_factors

-- @schema Q10 S6-presumption
example (p : Party) : burden p = burdenOf false p.claim := q10_from_presumption p

-- @schema Q11 S5-inert
example {V : Type} (cur : Qawaid.Held V) (hy : cur.IsYaqin) (evs : List (Qawaid.Held V))
    (hs : ∀ e ∈ evs, e.grade = .shakk) : evs.foldl Qawaid.update cur = cur :=
  yaqin_doubts_inert cur hy evs hs

-- @schema Q12 S3-gate
example (d : Deal) : Deal.gate.Holds d ↔ Exchange.gate.Holds d.exchange ∧ d.motive = .lawful :=
  deal_holds_iff d

-- @schema Q13 S1-invariance
example : Ignores itlafLiable := q13_ignores_intent

-- @schema Q15 S1-invariance
example : Ignores (fun h r => mayInflict r h) := q15_ignores_received

-- @schema Q17 S3-gate
example (e h : Bool) : obtains e h = true ↔ (Sadi.Gate.ofBools [Prod.fst] [Prod.snd]).Holds (e, h) :=
  q17_is_gate e h

-- @schema Q19 S2-priority
example (s : Option Nat) (v : Nat) : priceDue s v = resolveD [s] v := q19_is_priority s v

-- @schema Q20 S2-priority
example (b : Bool) : recipient b = resolveD [if b then some .owner else none] .publicInterest :=
  q20_is_priority b

-- @schema Q26 S6-presumption
-- @schema Q43 S6-presumption
example (h : HeldFor) (c : Bool) :
    returnClaimAccepted h c = (burdenOf (returnPresumption h c) true == .yamin) :=
  q26_q43_from_presumption h c

-- @schema Q29 S3-gate
example {α : Type} (u : Utterance α) (x : α) :
    u.meaning x = true ↔ (Sadi.Gate.ofBools (u.base :: u.qualifiers) []).Holds x := q29_is_gate u x

-- @schema Q36 S1-invariance
example : Factors (fun pm : Purpose × MentalState => itlafLiable (withRight pm.1) pm.2) (withRight ·.1) :=
  q13_q36_factor_through_right

-- @schema Q39 S1-invariance
example (t s : Nat) : Ignores (fun (_ : Unit) c => timelyPerformance t s c) := q39_ignores_condition t s

-- @schema Q41 S7-merge
example {K P O : Type} [DecidableEq K] [DecidableEq P] (owed : List (Act K P O)) :
    Covers Merges (reps Merges owed) owed := (q41_representatives owed).1

-- @schema Q47 S1-invariance
example : Factors obligationStatus (fun _ => ()) := q47_ignores_source

-- @schema Q50 S4-closure
example {α : Type} (follows : α → α → Prop) (proved : α → Prop) :
    Established follows proved = Closure follows proved := rfl

-- @schema Q51 S3-gate
example (e : Exchange) : Deal.gate.Holds ⟨e, .unlawful⟩ → False := fun h =>
  nomatch ((deal_holds_iff ⟨e, .unlawful⟩).1 h).2

-- @schema Q52 S6-presumption
example {V : Type} [DecidableEq V] (cur ev : Qawaid.Held V) (h : cur.grade ≤ ev.grade) (c : V) :
    burdenOf (Qawaid.update cur ev).value c = burdenOf ev.value c := burden_after_update cur ev h c

-- @schema Q53 S4-closure
example {C : Type} (builtOn : C → C → Prop) (ending : C → Option Ending) :
    Voided builtOn ending = Closure builtOn (fun c => ending c = some .provedVoid) := rfl

-- @schema Q54 S1-invariance
example : Ignores dispositionValid := q54_ignores_belief

-- @schema Q55 S5-inert
example (pre post : List Plea) : (pre ++ Plea.confess :: post).foldl plead false = true :=
  q55_confession_absorbs pre post

-- @schema Q57 S2-priority
example {M : Type} (l : M) (i : Option M) (p : M → Bool) :
    reading l i p = resolveD [i.bind fun m => if p m then some m else none] l := q57_is_priority l i p

-- @schema Q58 S1-invariance
example {Case F : Type} (H : Case → Hukm) (e : Case → F) : Sadi.DependsOn H e ↔ Factors H e :=
  dependsOn_iff_factors H e

-- @schema Q4 S3-gate
example (c d : Bool) : Sadi.operative c d .wajib = .wajib ↔ (Sadi.Gate.ofBools [Prod.fst] []).Holds (c, d) :=
  (operative_is_gate c d).1

-- @schema Q14 S1-invariance
example : Factors (fun x : Hand × Bool × Bool => lossLiable x.1 x.2.1 x.2.2)
    (fun x => authorizedHold x.1 x.2.1 x.2.2) := q14_factors_through_authorization

-- @schema Q21 S3-gate
example (k : ContractKind) (g : Bool) : ghararForbidden k g = false ↔
    (Sadi.Gate.ofBools [] [fun x : ContractKind × Bool => x.2 && x.1 != .gift]).Holds (k, g) := q21_is_gate k g

-- @schema Q24 S8-optimal
example {P : Type} {claims : List (P × Nat)} {w : P × Nat} (h : firstClaimant claims = some w) :
    Optimal (fun c => -(c.2 : Int)) claims w := q24_is_optimal h

-- @schema Q25 S2-priority
example (k d : Bool) : allocation k d =
    resolveD [if k then some .toEntitled else none, if d then some .divide else none] .lot := rfl

-- @schema Q28 S2-priority
example (p : Bool) : Sadi.useSubstitute p = resolveD [if p then some false else none] true :=
  substitute_is_priority p

-- @schema Q33 S8-optimal
example {α : Type} (key : α → Int) {xs : List α} {b : α} (h : Sadi.best key xs = some b) :
    Optimal key xs b := best_optimal h

-- @schema Q34 S8-optimal
example {α : Type} (os : List α) (i : α → Nat) (p : α) :
    Admissible .other os i p ↔ Optimal (fun o => (i o : Int)) os p := q34_other_iff_optimal os i p

-- @schema Q37 S8-optimal
example {P : Type} {claims : List (P × Nat)} {w : P × Nat} (h : prevailing claims = some w) :
    Optimal (fun c => (c.2 : Int)) claims w := q37_is_optimal h

-- @schema Q40 S3-gate
example {P : Type} (parts : List P) (can pm : P → Bool) (p : P) :
    p ∈ Sadi.obligedParts parts can pm ↔ p ∈ parts ∧ (Sadi.Gate.ofBools [can] [pm]).Holds p :=
  obligedParts_is_gate parts can pm p

-- @schema Q32 S3-gate
example (g : Bool) {p : Nat} (hp : 0 < p) :
    0 < recourse g p ↔ (Sadi.Gate.ofBools [] [fun x : Bool => x]).Holds g := q32_is_gate g hp

-- @schema Q58 S3-gate
example {α β : Type} {a : Qiyas.Argument α β} (hg : Qiyas.gate.Holds a) {H : α → β}
    (hH : Qiyas.Agrees H a.known) (hf : Factors H a.illa) : H a.far = a.hukm := qiyas_sound hg hH hf

-- @schema Q58 S2-priority
example {β : Type} (s : Bool) (text illaQ shabahQ : Option β) (d : β) :
    farByOrder s text illaQ shabahQ d = resolveD [text, illaQ, if s then shabahQ else none] d := rfl

end UsulTest.Schemata
