import Usul.Dung
import Usul.Grounded

/-! Boundary regressions for ADR 0001: stable existence is not preferred existence. -/
namespace UsulTest.ExtensionSemantics
open Usul.Dung

inductive Node where
  | a | b | c
  deriving DecidableEq, Repr

def cycle : Node → Node → Prop
  | .a, .b => True
  | .b, .c => True
  | .c, .a => True
  | _, _ => False

theorem cycle_no_stable (S : ASet Node) : ¬ Stable cycle S := by
  intro h
  have noA : ¬ S .a := by
    intro ha
    have noB : ¬ S .b := fun hb => h.1 .a .b ha hb (by trivial)
    have noC : ¬ S .c := fun hc => h.1 .c .a hc ha (by trivial)
    obtain ⟨x, hx, hxc⟩ := h.2 .c noC
    cases x <;> simp_all [cycle]
  have noB : ¬ S .b := by
    intro hb
    have noC : ¬ S .c := fun hc => h.1 .b .c hb hc (by trivial)
    obtain ⟨x, hx, hxa⟩ := h.2 .a noA
    cases x <;> simp_all [cycle]
  obtain ⟨x, hx, hxb⟩ := h.2 .b noB
  cases x <;> simp_all [cycle]

/-- Mutual attack preserves both singleton alternatives under both semantics. -/
theorem mutual_singleton_stable (a : Bool) :
    Stable (fun x y : Bool => x ≠ y) (fun x => x = a) := by
  refine ⟨?_, ?_⟩
  · intro x y hx hy
    subst x
    subst y
    exact fun h => h rfl
  · intro x hx
    exact ⟨a, rfl, fun h => hx h.symm⟩

theorem mutual_singleton_preferred (a : Bool) :
    Preferred (fun x y : Bool => x ≠ y) (fun x => x = a) :=
  stable_preferred (mutual_singleton_stable a)

-- Grounded iteration tests include an externally attacked odd cycle.
#guard Usul.Grounded.grounded 3 [(0,1), (1,2), (2,0)] == []
#guard Usul.Grounded.grounded 2 [(0,1), (1,0)] == []
#guard Usul.Grounded.grounded 3 [] == [0,1,2]
#guard Usul.Grounded.grounded 3 [(0,1), (1,0)] == [2]
#guard Usul.Grounded.grounded 4 [(0,1), (1,2), (2,0), (3,0)] == [1,3]

end UsulTest.ExtensionSemantics
