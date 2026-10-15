import Usul.Typing.Encoders
import Usul.Judgement

/-!
# Typed encoders and the questions they answer

`Usul.Typing` types what an encoder reads (a `Situation`); `Usul.Judgement` types what its output
answers (a `Question`). `mapRun` relabels an encoder's output, such as a Bool read as `Validity`
(`Validity.ofEffects`) or a Bool whose `true` is the question's no (`not`), without changing what it
reads or when it applies. `UsulTest/EncoderTypes.lean` (generated) ascribes each judgement encoder to
`Typed Situation (Question.Answer q)` through it.
-/

namespace Usul.Typing.Typed

variable {S O O' : Type}

/-- The same encoder, its output relabelled by `f`. -/
def mapRun (f : O → O') (E : Typed S O) : Typed S O' :=
  ⟨E.Local, E.proj, E.embed, f ∘ E.run, E.proj_embed⟩

theorem judge_mapRun (f : O → O') (E : Typed S O) (s : S) : (E.mapRun f).judge s = (E.judge s).map f := by
  simp [judge, mapRun, Option.map_map]

theorem applies_mapRun (f : O → O') (E : Typed S O) (s : S) : (E.mapRun f).applies s = E.applies s := rfl

end Usul.Typing.Typed
