import Usul.Taarud

/-!
# Reconciliation: the bank's taʿāruḍ procedure applied to its own furūʿ

An *apparent contradiction* is a farʿ on which the bank's reading and a reported position of
the madhhab disagree. The bank works it through its own `Usul.resolve`, in the kernel's order:

* *jamʿ*: a conservative refinement of the reading (a cited farq, with a theorem that it is the
  old reading wherever the farq is absent) under which the reading gives the preferred ruling;
* *naskh*: a later riwāya or a retraction (*rujūʿ*) whose chronology is reported;
* *tarjīḥ*: the ruling whose support is strongest under the Ḥanbalī grades below;
* *tawaqquf*: otherwise.

Grades follow the annotation convention's marked sides, strongest first: taṣḥīḥ (a position
labelled «المذهب», «الصحيح», «المشهور», «الأشهر», «الأظهر»), naṣṣ (a riwāya or manṣūṣ of
Aḥmad), ẓāhir of Aḥmad's words, qiyās al-madhhab, the jazm of al-Qāḍī and his followers (or
of most aṣḥāb), then the unmarked: one named companion's choice, a takhrīj, a bare wajh or
iḥtimāl.
-/

namespace Usul.Reconcile

inductive Grade where
  | tashih | nass | zahir | qiyas | jazm | ashab | takhrij | wajh
  deriving DecidableEq, Repr

def Grade.rank : Grade → Nat
  | .tashih => 7 | .nass => 6 | .zahir => 5 | .qiyas => 4
  | .jazm => 3 | .ashab => 2 | .takhrij => 1 | .wajh => 0

/-- The annotation convention's marked sides: exactly the grades above a single companion. -/
def Grade.marked (g : Grade) : Bool := g.rank ≥ 3

theorem rank_injective : ∀ a b : Grade, a.rank = b.rank → a = b := by
  intro a b; cases a <;> cases b <;> decide

/-- Strict lexicographic order on supports sorted strongest first; a longer support beats its
prefix (more holders of the same grade, «الأكثرون»). -/
def lexGt : List Nat → List Nat → Bool
  | [], _ => false
  | _ :: _, [] => true
  | a :: as, b :: bs => a > b || (a == b && lexGt as bs)

theorem lexGt_irrefl : ∀ l : List Nat, lexGt l l = false
  | [] => rfl
  | a :: as => by simp [lexGt, lexGt_irrefl as]

variable {P : Type} [DecidableEq P]

/-- Every grade reported for ruling `p`, strongest first. A marked grade counts per holder; an
unmarked one (a companion, a takhrīj, a wajh) once, however many hold it. -/
def support (ps : List (P × Grade)) (p : P) : List Nat :=
  let rs := (ps.filter (·.1 = p)).map (·.2.rank)
  (rs.filter (· ≥ Grade.jazm.rank) ++ (rs.filter (· < Grade.jazm.rank)).eraseDups).mergeSort (fun a b => a ≥ b)

/-- Tarjīḥ: the ruling whose support strictly exceeds every other ruling's, if any. -/
def prevail (ps : List (P × Grade)) : Option P :=
  (ps.map (·.1)).find? fun p => (ps.map (·.1)).all fun q => q = p || lexGt (support ps p) (support ps q)

/-- Tarjīḥ never invents a ruling: the winner is one of the reported positions. -/
theorem prevail_mem {ps : List (P × Grade)} {p : P} (h : prevail ps = some p) :
    p ∈ ps.map (·.1) :=
  List.mem_of_find?_eq_some h

/-- A unanimous report prevails. -/
theorem prevail_unanimous (p : P) (g : Grade) (gs : List Grade) :
    prevail ((p, g) :: gs.map (p, ·)) = some p := by
  simp [prevail]

/-- The whole procedure: the kernel's `resolve` on the three stages' offers. -/
def reconcile (jam naskh : Option P) (ps : List (P × Grade)) : Resolution P :=
  resolve ⟨jam, naskh, prevail ps⟩

theorem reconcile_jam_first {jam : P} {naskh : Option P} {ps : List (P × Grade)} :
    reconcile (some jam) naskh ps = .jam jam := rfl

theorem reconcile_tawaqquf_iff {jam naskh : Option P} {ps : List (P × Grade)} :
    reconcile jam naskh ps = .tawaqquf ↔ jam = none ∧ naskh = none ∧ prevail ps = none :=
  resolve_tawaqquf_iff

-- Two riwāyas, one labelled the madhhab: taṣḥīḥ decides.
#guard prevail [("a", Grade.nass), ("b", .nass), ("b", .tashih)] == some "b"
-- Equal grades: no tarjīḥ.
#guard prevail [("a", Grade.wajh), ("b", .wajh)] == none
-- More holders of the top grade prevail.
#guard prevail [("a", Grade.nass), ("a", .nass), ("b", .nass)] == some "a"
-- Named companions do not weigh by number.
#guard prevail [("a", Grade.ashab), ("a", .ashab), ("b", .ashab)] == none
-- A weaker grade never outweighs a stronger one, however many hold it.
#guard prevail [("a", Grade.zahir), ("b", .jazm), ("b", .jazm), ("b", .ashab)] == some "a"
#guard reconcile none none [("a", Grade.wajh), ("b", .wajh)] == .tawaqquf
#guard reconcile none (some "b") [("a", Grade.nass)] == .naskh "b"

end Usul.Reconcile
