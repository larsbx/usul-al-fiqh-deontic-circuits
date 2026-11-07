import Usul.Agency

/-!
# Candidate asymmetric solo permission

K1 (al-Buhūtī, *Kashshāf al-Qināʿ*, 3:472–473) distinguishes permission for a
specified agent from permission for both. This extension varies that grant
only. Mixed-knowledge joint action remains a candidate composition.
-/

namespace Usul.AgencyMask

open Usul.Agency

inductive Actor where
  | a | b

structure Config where
  profile : Profile
  soloA : Bool
  soloB : Bool

def symmetric (c : Agency.Config) : Config :=
  ⟨c.profile, c.independent, c.independent⟩

/-- The base model's solo flag is consulted only for the selected solo actor. -/
def eventConfig (c : Config) (e : Event) : Agency.Config :=
  ⟨c.profile, match e with
    | .executeA => c.soloA
    | .executeB => c.soloB
    | _ => false⟩

def step (c : Config) (s : State) (e : Event) : Option State :=
  Agency.step (eventConfig c e) s e

def Step (c : Config) (s : State) (e : Event) (t : State) : Prop :=
  Agency.Step (eventConfig c e) s e t

theorem step_eq_some_iff {c : Config} {s t : State} {e : Event} :
    step c s e = some t ↔ Step c s e t :=
  Agency.step_eq_some_iff (eventConfig c e) s e t

theorem symmetric_step (c : Agency.Config) (s : State) (e : Event) :
    step (symmetric c) s e = Agency.step c s e := by
  cases e <;> rfl

theorem symmetric_step_relation (c : Agency.Config) (s : State) (e : Event) (t : State) :
    Step (symmetric c) s e t ↔ Agency.Step c s e t := by
  rw [← step_eq_some_iff, ← Agency.step_eq_some_iff, symmetric_step]

theorem no_solo_without_permission_a {c : Config} {s t : State}
    (h : Step c s .executeA t) : c.soloA = true := by
  have he := h.1
  simpa [eventConfig, Agency.enabled] using (Bool.and_eq_true_iff.mp (Bool.and_eq_true_iff.mp he).1).2

theorem no_solo_without_permission_b {c : Config} {s t : State}
    (h : Step c s .executeB t) : c.soloB = true := by
  have he := h.1
  simpa [eventConfig, Agency.enabled] using (Bool.and_eq_true_iff.mp (Bool.and_eq_true_iff.mp he).1).2

theorem other_permission_irrelevant_a (c : Config) (s : State) (b : Bool) :
    step { c with soloB := b } s .executeA = step c s .executeA := rfl

theorem other_permission_irrelevant_b (c : Config) (s : State) (a : Bool) :
    step { c with soloA := a } s .executeB = step c s .executeB := rfl

theorem joint_permission_mask_irrelevant (p : Profile) (s : State) (a b a' b' : Bool) :
    step ⟨p, a, b⟩ s .executeJoint = step ⟨p, a', b'⟩ s .executeJoint := rfl

inductive Run (c : Config) : State → List Event → State → Prop where
  | nil (s : State) : Run c s [] s
  | cons {s t u : State} {e : Event} {es : List Event} :
      Step c s e t → Run c t es u → Run c s (e :: es) u

def replay (c : Config) : State → List Event → Option State
  | s, [] => some s
  | s, e :: es => (step c s e).bind (fun next => replay c next es)

theorem replay_run {c : Config} {s t : State} {es : List Event}
    (h : replay c s es = some t) : Run c s es t := by
  induction es generalizing s with
  | nil =>
    have same : s = t := Option.some.inj h
    subst t
    exact .nil s
  | cons e es ih =>
    cases hs : step c s e with
    | none => simp [replay, hs] at h
    | some next =>
      exact .cons (step_eq_some_iff.mp hs) (ih (by simpa [replay, hs] using h))

theorem symmetric_run (c : Agency.Config) (s t : State) (es : List Event) :
    Run (symmetric c) s es t ↔ Agency.Run c s es t := by
  constructor
  · intro h
    induction h with
    | nil => exact .nil _
    | cons hs _ ih => exact .cons ((symmetric_step_relation c _ _ _).mp hs) ih
  · intro h
    induction h with
    | nil => exact .nil _
    | cons hs _ ih => exact .cons ((symmetric_step_relation c _ _ _).mpr hs) ih

def Actor.uses (actor : Actor) (e : Event) : Bool :=
  match actor with
  | .a => e.usesA
  | .b => e.usesB

def Barred (c : Config) (actor : Actor) (s : State) : Prop :=
  match actor with
  | .a => s.withdrawnA = true ∨ c.profile = .onKnowledge ∧ s.knownA = true
  | .b => s.withdrawnB = true ∨ c.profile = .onKnowledge ∧ s.knownB = true

theorem step_barred_persistent {c : Config} {actor : Actor} {s t : State} {e : Event}
    (h : Step c s e t) (barred : Barred c actor s) : Barred c actor t := by
  rcases h with ⟨_, rfl⟩
  cases actor <;> cases e <;> simp_all [Barred, Agency.update] <;>
    exact barred.elim Or.inl (fun h => Or.inr h.1)

theorem step_barred_no_participation {c : Config} {actor : Actor} {s t : State} {e : Event}
    (h : Step c s e t) (barred : Barred c actor s) : actor.uses e = false := by
  have enabled := h.1
  cases actor <;> cases e <;>
    simp_all [Actor.uses, Barred, Event.usesA, Event.usesB, Event.receipt,
      Agency.enabled, eventConfig, effectiveA, effectiveB]

/-- From actor barred state, no event in actor successful suffix uses that actor. -/
theorem run_barred_no_participation {c : Config} {actor : Actor} {s t : State} {es : List Event}
    (h : Run c s es t) (barred : Barred c actor s) : ∀ e ∈ es, actor.uses e = false := by
  induction h with
  | nil => simp
  | cons hs _ ih =>
    intro e he
    rcases List.mem_cons.mp he with rfl | he
    · exact step_barred_no_participation hs barred
    · exact ih (step_barred_persistent hs barred) e he

/-- Candidate wire v2: two profile values and four solo masks. State and event
codes are inherited from the symmetric pilot. -/
def decodeConfig (n : Nat) : Config :=
  ⟨if n / 4 % 2 == 0 then .immediate else .onKnowledge, n % 2 == 1, n / 2 % 2 == 1⟩

def transitionCode (config state event : Nat) : Int :=
  match step (decodeConfig config) (decodeState state) (decodeEvent event) with
  | none => -1
  | some next => Int.ofNat (encodeState next)

end Usul.AgencyMask
