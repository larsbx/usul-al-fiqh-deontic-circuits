/-!
# Joint agency: a finite transition pilot (candidate readings)

One fixed principal appoints agents A and B for one fixed task. The source is the pinned
*al-Mughnī* witness `openiti-ibnqudama-mughni-shamela8463`: §3747, printed 5:70
(joint agents), and §3776, printed 5:88–89 (revocation and knowledge).
The web witness for the latter is `https://www.islamweb.net/ar/library/content/15/3149/`.
See `docs/research/agency-source-profile.md` for the source ledger and candidate status.

`immediate` and `onKnowledge` keep the two reported revocation positions separate. Requiring
both joint actors to retain effective authority in a mixed-knowledge situation is a candidate
composition of the passages, not a separately quoted ruling. Independent permission is
symmetric; asymmetric grants, delegation, death, incapacity, financial liability and
compensation (al-ḍamān, الضمان), and third-party effects are outside this pilot.
At-most-once acceptance and no reappointment are implementation
assumptions for the single fixed task, not claims about all wakāla contracts.

The state contains no unbounded history, so its 256 raw states are exhaustible. `Run` carries
arbitrarily long histories on the proof side. In particular, authority is checked at the act;
later revocation or notification preserves the recorded receipt. Receipt persistence does
not decide whether the underlying act is void (al-bāṭil, الباطل).
-/

namespace Usul.Agency

inductive Profile where
  | immediate | onKnowledge
  deriving DecidableEq, Repr

structure Config where
  profile : Profile
  independent : Bool
  deriving DecidableEq, Repr

/-- The accepted actor set, or no accepted execution yet. -/
inductive Receipt where
  | none | a | b | joint
  deriving DecidableEq, Repr

structure State where
  appointed : Bool
  revoked : Bool
  knownA : Bool
  knownB : Bool
  withdrawnA : Bool
  withdrawnB : Bool
  accepted : Receipt
  deriving DecidableEq, Repr

/-- Outside-scope attempts are explicit negative events. They never enable a transition. -/
inductive Event where
  | appoint | revoke | notifyA | notifyB | withdrawA | withdrawB
  | executeA | executeB | executeJoint | stutter
  | executeAOutsideScope | executeBOutsideScope | executeJointOutsideScope
  deriving DecidableEq, Repr

def initial : State := ⟨false, false, false, false, false, false, .none⟩

def pending (s : State) : Bool := decide (s.accepted = .none)

def effectiveA (c : Config) (s : State) : Bool :=
  s.appointed && !s.withdrawnA &&
    match c.profile with
    | .immediate => !s.revoked
    | .onKnowledge => !s.knownA

def effectiveB (c : Config) (s : State) : Bool :=
  s.appointed && !s.withdrawnB &&
    match c.profile with
    | .immediate => !s.revoked
    | .onKnowledge => !s.knownB

def enabled (c : Config) (s : State) : Event → Bool
  | .appoint => !s.appointed
  | .revoke => s.appointed && !s.revoked
  | .notifyA => s.revoked && !s.knownA
  | .notifyB => s.revoked && !s.knownB
  | .withdrawA => s.appointed && !s.withdrawnA
  | .withdrawB => s.appointed && !s.withdrawnB
  | .executeA => pending s && c.independent && effectiveA c s
  | .executeB => pending s && c.independent && effectiveB c s
  | .executeJoint => pending s && effectiveA c s && effectiveB c s
  | .stutter => true
  | .executeAOutsideScope | .executeBOutsideScope | .executeJointOutsideScope => false

/-- The update is only used after `enabled`; disabled attempts have no transition. -/
def update (s : State) : Event → State
  | .appoint => { s with appointed := true }
  | .revoke => { s with revoked := true }
  | .notifyA => { s with knownA := true }
  | .notifyB => { s with knownB := true }
  | .withdrawA => { s with withdrawnA := true }
  | .withdrawB => { s with withdrawnB := true }
  | .executeA => { s with accepted := .a }
  | .executeB => { s with accepted := .b }
  | .executeJoint => { s with accepted := .joint }
  | .stutter | .executeAOutsideScope | .executeBOutsideScope |
      .executeJointOutsideScope => s

def step (c : Config) (s : State) (e : Event) : Option State :=
  if enabled c s e then some (update s e) else none

def Step (c : Config) (s : State) (e : Event) (t : State) : Prop :=
  enabled c s e = true ∧ t = update s e

theorem step_eq_some_iff (c : Config) (s : State) (e : Event) (t : State) :
    step c s e = some t ↔ Step c s e t := by
  cases h : enabled c s e <;> simp [step, Step, h, eq_comm]

inductive Run (c : Config) : State → List Event → State → Prop where
  | nil (s : State) : Run c s [] s
  | cons {s t u : State} {e : Event} {es : List Event} :
      Step c s e t → Run c t es u → Run c s (e :: es) u

def Reachable (c : Config) (s : State) : Prop := ∃ es, Run c initial es s

/-- Replay fails at the first disabled attempt; failed attempts are not successful events. -/
def replay (c : Config) : State → List Event → Option State
  | s, [] => some s
  | s, e :: es => (step c s e).bind (fun next => replay c next es)

theorem replay_eq_some_iff {c : Config} {s t : State} (es : List Event) :
    replay c s es = some t ↔ Run c s es t := by
  induction es generalizing s with
  | nil =>
    constructor
    · intro h
      have he : s = t := Option.some.inj h
      subst t
      exact .nil s
    · intro h
      cases h
      rfl
  | cons e es ih =>
    cases hstep : step c s e with
    | none =>
      constructor
      · simp [replay, hstep]
      · intro h
        cases h with
        | cons hs _ =>
          have he := (step_eq_some_iff c s e _).mpr hs
          simp [hstep] at he
    | some middle =>
      simp only [replay, hstep, Option.bind_some]
      rw [ih]
      constructor
      · intro h
        exact .cons ((step_eq_some_iff c s e middle).mp hstep) h
      · intro h
        cases h with
        | cons hs hr =>
          have he := (step_eq_some_iff c s e _).mpr hs
          rw [hstep] at he
          cases Option.some.inj he
          exact hr

theorem run_deterministic {c : Config} {s t u : State} {es : List Event}
    (ht : Run c s es t) (hu : Run c s es u) : t = u := by
  exact Option.some.inj (((replay_eq_some_iff es).mpr ht).symm.trans
    ((replay_eq_some_iff es).mpr hu))

/-- The causal facts that hold from the empty initial state. Raw wire states need not satisfy
these implications, so the parity table tests the relation on those states as well. -/
def Coherent (s : State) : Prop :=
  (s.revoked = true → s.appointed = true) ∧
  (s.knownA = true → s.revoked = true) ∧
  (s.knownB = true → s.revoked = true) ∧
  (s.withdrawnA = true → s.appointed = true) ∧
  (s.withdrawnB = true → s.appointed = true) ∧
  (s.accepted ≠ .none → s.appointed = true)

theorem initial_coherent : Coherent initial := by simp [Coherent, initial]

theorem step_coherent {c : Config} {s t : State} {e : Event}
    (h : Step c s e t) (hs : Coherent s) : Coherent t := by
  rcases h with ⟨he, rfl⟩
  cases e <;>
    simp_all [enabled, update, Coherent, effectiveA, effectiveB, pending]

theorem run_invariant {c : Config} {s t : State} {es : List Event} {P : State → Prop}
    (preserve : ∀ {x y : State} {e : Event}, Step c x e y → P x → P y)
    (h : Run c s es t) : P s → P t := by
  induction h with
  | nil => exact id
  | cons hstep _ ih =>
    intro hs
    exact ih (preserve hstep hs)

theorem reachable_coherent {c : Config} {s : State} (h : Reachable c s) : Coherent s := by
  obtain ⟨es, hr⟩ := h
  exact run_invariant step_coherent hr initial_coherent

theorem step_receipt_persistent {c : Config} {s t : State} {e : Event}
    (h : Step c s e t) (hs : s.accepted ≠ .none) : t.accepted = s.accepted := by
  rcases h with ⟨he, rfl⟩
  cases e <;> simp_all [enabled, update, pending]

/-- Revocation, notice and withdrawal after acceptance leave its historical receipt intact. -/
theorem run_receipt_persistent {c : Config} {s t : State} {es : List Event}
    (h : Run c s es t) (hs : s.accepted ≠ .none) : t.accepted = s.accepted := by
  induction h with
  | nil => rfl
  | cons hstep _ ih =>
    have heq := step_receipt_persistent hstep hs
    have hn := heq ▸ hs
    exact (ih hn).trans heq

def acceptedCount (s : State) : Nat := if s.accepted = .none then 0 else 1

def Event.executionCount : Event → Nat
  | .executeA | .executeB | .executeJoint | .executeAOutsideScope |
      .executeBOutsideScope | .executeJointOutsideScope => 1
  | _ => 0

def executions : List Event → Nat
  | [] => 0
  | e :: es => e.executionCount + executions es

theorem acceptedCount_le_one (s : State) : acceptedCount s ≤ 1 := by
  unfold acceptedCount
  split <;> decide

theorem step_execution_count {c : Config} {s t : State} {e : Event}
    (h : Step c s e t) : acceptedCount t = acceptedCount s + e.executionCount := by
  rcases h with ⟨he, rfl⟩
  cases e <;> cases hs : s.accepted <;>
    simp_all [enabled, update, pending, acceptedCount, Event.executionCount]

/-- A conservation law over arbitrary finite histories, not only a guard lemma. -/
theorem run_execution_count {c : Config} {s t : State} {es : List Event}
    (h : Run c s es t) : acceptedCount t = acceptedCount s + executions es := by
  induction h with
  | nil => simp [executions]
  | cons hstep _ ih =>
    have hc := step_execution_count hstep
    simp only [executions]
    omega

theorem run_at_most_once {c : Config} {s : State} {es : List Event}
    (h : Run c initial es s) : executions es ≤ 1 := by
  have hc := run_execution_count h
  have hb := acceptedCount_le_one s
  have hz : acceptedCount initial = 0 := rfl
  rw [hz, Nat.zero_add] at hc
  omega

/-- Successful completion is equivalent to exactly one execution in the recorded history. -/
theorem run_accepted_iff_one_execution {c : Config} {s : State} {es : List Event}
    (h : Run c initial es s) : s.accepted ≠ .none ↔ executions es = 1 := by
  have hc := run_execution_count h
  have hz : acceptedCount initial = 0 := rfl
  rw [hz, Nat.zero_add] at hc
  cases hs : s.accepted <;> simp_all [acceptedCount] <;> omega

def Event.inScope : Event → Bool
  | .executeAOutsideScope | .executeBOutsideScope | .executeJointOutsideScope => false
  | _ => true

theorem step_in_scope {c : Config} {s t : State} {e : Event}
    (h : Step c s e t) : e.inScope = true := by
  rcases h with ⟨he, _⟩
  cases e <;> simp_all [enabled, Event.inScope]

/-- Every event in every successful history respects the fixed mandate. -/
theorem run_in_scope {c : Config} {s t : State} {es : List Event}
    (h : Run c s es t) : ∀ e ∈ es, e.inScope = true := by
  induction h with
  | nil => simp
  | @cons s t u e es hstep _ ih =>
    intro x hx
    rcases List.mem_cons.mp hx with hxe | hxe
    · subst x; exact step_in_scope hstep
    · exact ih x hxe

def JointOnly (s : State) : Prop := s.accepted = .none ∨ s.accepted = .joint

theorem step_joint_only {c : Config} {s t : State} {e : Event}
    (hc : c.independent = false) (h : Step c s e t) (hs : JointOnly s) : JointOnly t := by
  rcases h with ⟨he, rfl⟩
  cases e <;> simp_all [enabled, update, JointOnly]

theorem reachable_joint_only {c : Config} {s : State}
    (hc : c.independent = false) (h : Reachable c s) : JointOnly s := by
  obtain ⟨es, hr⟩ := h
  exact run_invariant (step_joint_only hc) hr (Or.inl rfl)

theorem step_revoked_persistent {c : Config} {s t : State} {e : Event}
    (h : Step c s e t) (hs : s.revoked = true) : t.revoked = true := by
  rcases h with ⟨_, rfl⟩
  cases e <;> simp_all [update]

theorem step_knownA_persistent {c : Config} {s t : State} {e : Event}
    (h : Step c s e t) (hs : s.knownA = true) : t.knownA = true := by
  rcases h with ⟨_, rfl⟩
  cases e <;> simp_all [update]

theorem step_knownB_persistent {c : Config} {s t : State} {e : Event}
    (h : Step c s e t) (hs : s.knownB = true) : t.knownB = true := by
  rcases h with ⟨_, rfl⟩
  cases e <;> simp_all [update]

theorem step_immediate_revoked_no_execution {c : Config} {s t : State} {e : Event}
    (hc : c.profile = .immediate) (hs : s.revoked = true) (h : Step c s e t) :
    e.executionCount = 0 := by
  rcases h with ⟨he, _⟩
  cases e <;> simp_all [enabled, effectiveA, effectiveB, Event.executionCount]

/-- Under immediate revocation, no length of subsequent execution can accept another act. -/
theorem run_immediate_revoked_no_execution {c : Config} {s t : State} {es : List Event}
    (hc : c.profile = .immediate) (h : Run c s es t) :
    s.revoked = true → executions es = 0 := by
  induction h with
  | nil => simp [executions]
  | cons hstep _ ih =>
    intro hs
    have hz := step_immediate_revoked_no_execution hc hs hstep
    have ht := step_revoked_persistent hstep hs
    simp [executions, hz, ih ht]

theorem step_fully_notified_no_execution {c : Config} {s t : State} {e : Event}
    (hc : c.profile = .onKnowledge) (ha : s.knownA = true) (hb : s.knownB = true)
    (h : Step c s e t) : e.executionCount = 0 := by
  rcases h with ⟨he, _⟩
  cases e <;> simp_all [enabled, effectiveA, effectiveB, Event.executionCount]

theorem run_fully_notified_no_execution {c : Config} {s t : State} {es : List Event}
    (hc : c.profile = .onKnowledge) (h : Run c s es t) :
    s.knownA = true → s.knownB = true → executions es = 0 := by
  induction h with
  | nil => simp [executions]
  | cons hstep _ ih =>
    intro ha hb
    have hz := step_fully_notified_no_execution hc ha hb hstep
    have hta := step_knownA_persistent hstep ha
    have htb := step_knownB_persistent hstep hb
    simp [executions, hz, ih hta htb]

def Event.receipt : Event → Receipt
  | .executeA | .executeAOutsideScope => .a
  | .executeB | .executeBOutsideScope => .b
  | .executeJoint | .executeJointOutsideScope => .joint
  | _ => .none

def Event.usesA (e : Event) : Bool := decide (e.receipt = .a ∨ e.receipt = .joint)
def Event.usesB (e : Event) : Bool := decide (e.receipt = .b ∨ e.receipt = .joint)

/-- The facts at the actual act, rather than at a later state. -/
def AuthorizedExecution (c : Config) (s : State) (e : Event) : Prop :=
  e.executionCount = 1 ∧ s.appointed = true ∧ s.accepted = .none ∧ e.inScope = true ∧
  (e.usesA = true → effectiveA c s = true) ∧
  (e.usesB = true → effectiveB c s = true) ∧
  (c.independent = false → e.receipt = .joint)

theorem step_execution_authorized {c : Config} {s t : State} {e : Event}
    (h : Step c s e t) (he : e.executionCount = 1) : AuthorizedExecution c s e := by
  rcases h with ⟨hen, rfl⟩
  cases e <;>
    simp_all [Event.executionCount, enabled, pending, AuthorizedExecution, Event.inScope,
      Event.usesA, Event.usesB, Event.receipt, effectiveA, effectiveB]

theorem step_execution_receipt {c : Config} {s t : State} {e : Event}
    (h : Step c s e t) (he : e.executionCount = 1) :
    t.accepted = e.receipt ∧ t.accepted ≠ .none := by
  rcases h with ⟨hen, rfl⟩
  cases e <;> simp_all [Event.executionCount, enabled, update, Event.receipt]

theorem run_append_iff {c : Config} {s t : State} (pre post : List Event) :
    Run c s (pre ++ post) t ↔ ∃ middle, Run c s pre middle ∧ Run c middle post t := by
  induction pre generalizing s with
  | nil =>
    constructor
    · intro h; exact ⟨s, .nil s, h⟩
    · rintro ⟨middle, hfirst, hsecond⟩
      cases hfirst
      exact hsecond
  | cons e pre ih =>
    constructor
    · intro h
      cases h with
      | cons hstep hrest =>
        obtain ⟨middle, hfirst, hsecond⟩ := ih.mp hrest
        exact ⟨middle, .cons hstep hfirst, hsecond⟩
    · rintro ⟨middle, hfirst, hsecond⟩
      cases hfirst with
      | cons hstep hrest =>
        exact .cons hstep (ih.mpr ⟨middle, hrest, hsecond⟩)

/-- Every accepted event in a history has a reachable pre-state with the required authority;
the final receipt still identifies that same event even after later termination or notice. -/
theorem run_execution_witness {c : Config} {t : State} {pre post : List Event} {e : Event}
    (h : Run c initial (pre ++ e :: post) t) (he : e.executionCount = 1) :
    ∃ before after, Run c initial pre before ∧ Step c before e after ∧
      Run c after post t ∧ AuthorizedExecution c before e ∧ t.accepted = e.receipt := by
  obtain ⟨before, hpre, hrest⟩ := (run_append_iff pre (e :: post)).mp h
  cases hrest with
  | cons hstep hpost =>
    have hr := step_execution_receipt hstep he
    exact ⟨before, _, hpre, hstep, hpost, step_execution_authorized hstep he,
      (run_receipt_persistent hpost hr.2).trans hr.1⟩

theorem execution_event_of_count_one {es : List Event} (h : executions es = 1) :
    ∃ e ∈ es, e.executionCount = 1 := by
  induction es with
  | nil => simp [executions] at h
  | cons e es ih =>
    simp only [executions] at h
    by_cases he : e.executionCount = 1
    · exact ⟨e, List.mem_cons_self, he⟩
    · obtain ⟨event, hm, hc⟩ := ih (by omega)
      exact ⟨event, List.mem_cons_of_mem _ hm, hc⟩

/-- A receipt in a run from the initial state identifies an actual authorized step in that run.
The witness concerns modeled authority in the pre-state of the act. -/
theorem run_receipt_origin {c : Config} {t : State} {es : List Event}
    (h : Run c initial es t) (hr : t.accepted ≠ .none) :
    ∃ pre e post before after, es = pre ++ e :: post ∧ Run c initial pre before ∧
      Step c before e after ∧ Run c after post t ∧ AuthorizedExecution c before e ∧
      t.accepted = e.receipt := by
  obtain ⟨e, hm, he⟩ := execution_event_of_count_one ((run_accepted_iff_one_execution h).mp hr)
  obtain ⟨pre, post, rfl⟩ := List.append_of_mem hm
  obtain ⟨before, after, hp, hs, ht, ha, heq⟩ := run_execution_witness h he
  exact ⟨pre, e, post, before, after, rfl, hp, hs, ht, ha, heq⟩

/-! ## Exhaustive wire format shared with Quint

State bits 0..5 are `appointed, revoked, knownA, knownB, withdrawnA, withdrawnB`;
bits 6..7 encode `none, a, b, joint`. Configuration is `2 * profile + independent`,
where `immediate = 0` and `onKnowledge = 1`. Event order is declared below. The
exporter evaluates all 4 × 256 × 13 inputs, including disabled transitions.
-/

def flag : Bool → Nat | false => 0 | true => 1

def receiptCode : Receipt → Nat | .none => 0 | .a => 1 | .b => 2 | .joint => 3

def encodeState (s : State) : Nat :=
  flag s.appointed + 2 * flag s.revoked + 4 * flag s.knownA + 8 * flag s.knownB +
    16 * flag s.withdrawnA + 32 * flag s.withdrawnB + 64 * receiptCode s.accepted

def decodeState (n : Nat) : State :=
  ⟨n % 2 == 1, n / 2 % 2 == 1, n / 4 % 2 == 1, n / 8 % 2 == 1,
    n / 16 % 2 == 1, n / 32 % 2 == 1,
    match n / 64 % 4 with | 0 => .none | 1 => .a | 2 => .b | _ => .joint⟩

theorem encodeState_lt (s : State) : encodeState s < 256 := by
  cases s with
  | mk a r ka kb wa wb receipt =>
    cases a <;> cases r <;> cases ka <;> cases kb <;> cases wa <;> cases wb <;>
      cases receipt <;> decide

/-- Every semantic state occurs in the exported finite universe. -/
theorem decodeState_encodeState (s : State) : decodeState (encodeState s) = s := by
  cases s with
  | mk a r ka kb wa wb receipt =>
    cases a <;> cases r <;> cases ka <;> cases kb <;> cases wa <;> cases wb <;>
      cases receipt <;> rfl

def encodeConfig (c : Config) : Nat :=
  (match c.profile with | .immediate => 0 | .onKnowledge => 2) + flag c.independent

def decodeConfig (n : Nat) : Config :=
  ⟨if n / 2 % 2 == 0 then .immediate else .onKnowledge, n % 2 == 1⟩

theorem encodeConfig_lt (c : Config) : encodeConfig c < 4 := by
  cases c with
  | mk p i => cases p <;> cases i <;> decide

theorem decodeConfig_encodeConfig (c : Config) : decodeConfig (encodeConfig c) = c := by
  cases c with
  | mk p i => cases p <;> cases i <;> rfl

def encodeEvent : Event → Nat
  | .appoint => 0 | .revoke => 1 | .notifyA => 2 | .notifyB => 3
  | .withdrawA => 4 | .withdrawB => 5 | .executeA => 6 | .executeB => 7
  | .executeJoint => 8 | .stutter => 9 | .executeAOutsideScope => 10
  | .executeBOutsideScope => 11 | .executeJointOutsideScope => 12

def decodeEvent : Nat → Event
  | 0 => .appoint | 1 => .revoke | 2 => .notifyA | 3 => .notifyB
  | 4 => .withdrawA | 5 => .withdrawB | 6 => .executeA | 7 => .executeB
  | 8 => .executeJoint | 9 => .stutter | 10 => .executeAOutsideScope
  | 11 => .executeBOutsideScope | _ => .executeJointOutsideScope

theorem encodeEvent_lt (e : Event) : encodeEvent e < 13 := by
  cases e <;> decide

theorem decodeEvent_encodeEvent (e : Event) : decodeEvent (encodeEvent e) = e := by
  cases e <;> rfl

/-- `-1` means disabled; a nonnegative value encodes the unique successor. -/
def transitionCode (config state event : Nat) : Int :=
  match step (decodeConfig config) (decodeState state) (decodeEvent event) with
  | none => -1
  | some next => Int.ofNat (encodeState next)

end Usul.Agency
