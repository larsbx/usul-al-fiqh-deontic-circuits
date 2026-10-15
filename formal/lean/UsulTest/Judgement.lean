import Usul

/-!
Guards for the judgement form (`Usul.Judgement`): the khiṭāb of each taklīfī status, the
validity signs, and the typing of a judgement by its question, subject and dalīl.
-/

namespace UsulTest.Judgement

open Usul

-- h002 with h003–h007: takhyīr is ibāḥa, ṭalab the other four.
#guard [Hukm.wajib, .mandub, .mubah, .makruh, .haram].map Hukm.khitab
  == [.talab, .talab, .takhyir, .talab, .talab]

-- h008, h009: validity is whether the act's effects follow.
#guard [Validity.sahih, .fasid].map Validity.effectsFollow == [true, false]
#guard [true, false].map Validity.ofEffects == [Validity.sahih, .fasid]

def child : Subject := ⟨false, true⟩
def adult : Subject := ⟨true, true⟩

/-- A child breaks a neighbour's vessel: is the destruction a sabab of liability? -/
def childDaman : Judgement String :=
  ⟨Question.daman, "breaking a vessel", child, .ada, (true : Bool), .zann, true, [.nass]⟩

/-- The same act asked as a taklīfī question of the child: not well-typed. -/
def childTaklifi : Judgement String :=
  ⟨.taklifi, "breaking a vessel", child, .ada, Hukm.haram, .zann, true, [.nass]⟩

/-- A taklīfī answer that names no dalīl. -/
def adultNoDalil : Judgement String :=
  ⟨.taklifi, "breaking a vessel", adult, .ada, Hukm.haram, .zann, true, []⟩

#guard decide childDaman.WellTyped
#guard !decide childTaklifi.WellTyped
#guard !decide adultNoDalil.WellTyped
#guard decide ({ childTaklifi with subject := adult } : Judgement String).WellTyped
#guard childDaman.khitab == .wad && childTaklifi.khitab == .talab

-- Liability and the taklīfī status of the same act answer different questions.
example : ¬ childDaman.Conflicts childTaklifi :=
  Judgement.not_conflicts_of_question_ne (by decide)

end UsulTest.Judgement
