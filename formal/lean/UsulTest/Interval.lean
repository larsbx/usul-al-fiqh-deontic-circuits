import Usul.Cat.Interval

/-!
Vectors for interval-valued verdicts (`Usul.Cat.Interval`): what the point checker misreads, and
what it still reads the same.
-/

namespace UsulTest.Interval

open Usul Usul.Cat.Sheaf Usul.Cat.Interval Usul.Cat.Interval.Span

/-- `Sheaf.positions` names a patch by its ruling. -/
local instance : ToString Hukm := ⟨reprStr⟩

/-! ## The definitions behind the chain: reward and liability, not a rank

Ibn ʿUthaymīn defines each status by what follows on doing and on leaving. The mandūb is the
wājib without liability for leaving, the makrūh the ḥarām without liability for doing. -/

#guard Hukm.mandub.fil == Hukm.wajib.fil && Hukm.mandub.tark != Hukm.wajib.tark
#guard Hukm.makruh.tark == Hukm.haram.tark && Hukm.makruh.fil != Hukm.haram.fil
-- Neither the mandūb's leaver nor the makrūh's doer is liable.
#guard Hukm.mandub.tark == .neither && Hukm.makruh.fil == .neither
-- Each step of the chain changes one side only, and the sides alternate.
#guard [(Hukm.wajib, Hukm.mandub), (.mandub, .mubah), (.mubah, .makruh), (.makruh, .haram)].map
    (fun (a, b) => (a.fil == b.fil, a.tark == b.tark)) == [(true, false), (false, true), (true, false), (false, true)]
-- The omission swaps doing and leaving.
example (h : Hukm) : (Hukm.σ h).fil = h.tark ∧ (Hukm.σ h).tark = h.fil := ⟨Hukm.σ_fil h, Hukm.σ_tark h⟩

/-! ## Spans of the khiṭāb and of fatwā wording -/

#guard decide (Mem .makruh permitted) && !decide (Mem .haram permitted)
#guard decide (Mem .mandub talabFil) && decide (Mem .wajib talabFil) && !decide (Mem .mubah talabFil)
#guard (σ talabFil).lo == .haram && (σ talabFil).hi == .makruh

/-! ## False ikhtilāf: «يجوز» beside «يستحب» -/

-- As points the encoder must pick one status for «يجوز»; mubāḥ is the usual pick.
#guard obstructions [()] (positions [Hukm.mubah, Hukm.mandub]) != []
-- As spans the two positions agree: mandūb is not ḥarām.
#guard iobstructions [()] (stances [some permitted, some (point .mandub)]) == []

/-! ## Real ikhtilāf is kept -/

#guard iobstructions [()] (stances [some (point .wajib), some (point .mandub)]) != []
#guard iobstructions [()] (stances [some talabFil, some talabTark]) != []
-- «يجوز» against a prohibition.
#guard iobstructions [()] (stances [some permitted, some (point .haram)]) != []

/-! ## Tawaqquf is a hole, not ibāḥa -/

#guard iobstructions [()] (stances [none, some (point .haram)]) == []
#guard obstructions [()] (positions [Hukm.mubah, Hukm.haram]) != []

/-! ## Helly: three spans that pairwise meet glue to one status -/

#guard iobstructions [()] (stances [some permitted, some talabFil, some notObligatory]) == []
example : maxLo [permitted, talabFil, notObligatory] = .mandub := rfl

/-! ## Conservativity on points -/

example : iobstructions [()] ((positions [Hukm.wajib, Hukm.mandub]).map IPatch.ofPatch)
    = obstructions [()] (positions [Hukm.wajib, Hukm.mandub]) := iobstructions_ofPatch

end UsulTest.Interval
