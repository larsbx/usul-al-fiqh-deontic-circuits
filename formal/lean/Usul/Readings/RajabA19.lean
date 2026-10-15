/-!
# Shard rajab-a19: readings of Ibn Rajab's qawāʿid 142, 143 and 145

Each reading is formalised from the qāʿida's own statement in the pinned witness
(`openiti-rajab-shamela21730`), status `candidate`. Qāʿida 142 states its own question
(«هل يحكم على العائد بحكم الأول أم لا؟ فيه خلاف يطرد») without marking a side; the reading takes
the split between the qāʿida's two modes of return that the furūʿ's own grounds draw, and the
other side stays a recorded position in the takhrīj suite
`corpus/takhrij/rajab_m8_rajab_a19_furu.json` (RQ-02's policy in force).
-/

namespace Usul.Readings.RajabA19

/-- Qāʿida 142: «ما زال من الأعيان ثم عاد بأصل الخلقة أو بصنع آدمي هل يحكم على العائد بحكم الأول أم
لا؟ فيه خلاف يطرد». The reading splits the qāʿida's two modes of return: what returns by the
original creation (regrowth; a limb put back that takes hold and heals, «لعود الحياة إليه») is the
first thing and keeps its ruling; what a man rebuilds is another thing («لأن الثاني غير الأول»،
«لأنه غير الأول»), whatever it is built from. `restoredByLife`: what returned was restored by life
or growth, not rebuilt by human hand. `oldMaterials`: the record states that it was rebuilt with its
own former materials («بآلته العتيقة»); the reading gives it no weight (Ibn Rajab's «ويتوجه
التفريق» is a recorded position, not the reading). The output is that the returned thing takes the
ruling of the first. -/
def returnedIsFirst (restoredByLife _oldMaterials : Bool) : Bool := restoredByLife

/-- What a man rebuilds is never the first thing, even from its own former materials. -/
theorem rebuilt_is_not_first (m : Bool) : returnedIsFirst false m = false := rfl

/-- The former materials make no difference on this reading. -/
theorem materials_irrelevant (l : Bool) : returnedIsFirst l true = returnedIsFirst l false := rfl

/-- Qāʿida 143: «يقوم البدل مقام المبدل ويسد مسده ويبني حكمه على حكم مبدله في مواضع كثيرة». The bar
is the one the qāʿida's own furūʿ state against a substitute: the original given up for a price is
not replaced by a substitute standing in its place («بخلاف ما لو باعه بثمن»، «ولا على الاستبدال به
بعوض دنيوي بخلاف أخذ ثمنه»). `soldForPrice`: the original is given up for a price rather than
replaced by its substitute. The output is that the substitute stands in the original's place and its
ruling builds on the original's. -/
def badalStands (soldForPrice : Bool) : Bool := !soldForPrice

/-- A price taken for the original never stands in its place. -/
theorem price_is_not_badal : badalStands true = false := rfl

/-- Qāʿida 145: «المعتدة البائن في حكم الزوجات في مسائل». The bar is the one its furūʿ state: the
ruling holds «ما دامت علق الزوجية قائمة», and lapses «لانقطاع علق الزوجية عنه بموتها». `inIdda`:
the woman finally divorced (bāʾin) is still in her ʿidda; `tiesCut`: the remaining ties of the
marriage have been cut (by her death). The output is that she is treated as a wife in the respect
in question. -/
def bainAsWife (inIdda tiesCut : Bool) : Bool := inIdda && !tiesCut

/-- After the ʿidda she is not treated as a wife. -/
theorem after_idda_not_wife (t : Bool) : bainAsWife false t = false := rfl

/-- Once the ties of the marriage are cut she is not treated as a wife, even within the ʿidda. -/
theorem ties_cut_not_wife (i : Bool) : bainAsWife i true = false := by
  cases i <;> rfl

end Usul.Readings.RajabA19
