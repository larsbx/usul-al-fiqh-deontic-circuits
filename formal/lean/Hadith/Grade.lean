import Usul.Signature

/-!
# Narrator grades and ḥadīth verdicts (al-Albānī track §2.1, H2)

Ibn Ḥajar, *Taqrīb al-Tahdhīb*, muqaddima: twelve *marātib* for narrators, best first
(`src:openiti-taqrib-jk121/v01:p074`–`p075`; each rung is quoted and linked to its constructor
in `corpus/hadith/kernel_scales.json`). The *Taqrīb* is al-Albānī's default valuation;
individual verdicts may override it, and those overrides are data (H4), not changes to this scale.

The verdict scale is the *Nuzha*'s partition of the *maqbūl* / *mardūd*, coarsened to the
four values al-Albānī's *Silsilatān* emit for a narrated route. `grade` bridges into the uṣūl
kernel's epistemic scale, so a ḥadīth verdict enters a deontic derivation only as a `Usul.Grade`.

**Mawḍūʿ is not on this scale (decision D5, project owner, 2026-10-10).** A fabricated matn
has no possibility of being authentic, so it is a different category, not the bottom rung of
the riwāya scale. `Hukm` adjoins it as a separate branch. A route through a kadhdhāb is sāqiṭ,
the bottom of the scale («قد يصدق الكذوب»); only a finding of fabrication (a critic's ḥukm
bi'l-waḍʿ, naqd al-matn) or the absence of any isnād (لا أصل له) reaches the mawḍūʿ branch.
Rules over grades and routes return a `Verdict`, so by type they never fabricate.
-/

namespace Hadith

/-- The twelve *marātib* of the *Taqrīb*, in order. -/
inductive Martaba where
  | sahabi      --  1 Companion: ʿudūl by consensus
  | awthaq      --  2 emphasised praise: awthaq al-nās, thiqa thiqa
  | thiqa       --  3 thiqa, mutqin, thabt, ʿadl
  | saduq       --  4 ṣadūq, lā baʾs bihi
  | saduqYahim  --  5 ṣadūq yahim / sayyiʾ al-ḥifẓ / lahu awhām / taghayyar; also one accused of bidʿa
  | maqbul      --  6 maqbūl where followed, else layyin
  | mastur      --  7 mastūr, majhūl al-ḥāl
  | daif        --  8 ḍaʿīf
  | majhul      --  9 majhūl (al-ʿayn): a single narrator from him, no tawthīq
  | matruk      -- 10 matrūk, wāhī, sāqiṭ
  | muttaham    -- 11 muttaham bi'l-kadhib
  | kadhdhab    -- 12 kadhdhāb, waḍḍāʿ
  deriving DecidableEq, Repr

namespace Martaba

def rank : Martaba → Nat
  | sahabi => 1 | awthaq => 2 | thiqa => 3 | saduq => 4 | saduqYahim => 5 | maqbul => 6
  | mastur => 7 | daif => 8 | majhul => 9 | matruk => 10 | muttaham => 11 | kadhdhab => 12

theorem rank_injective {a b : Martaba} (h : a.rank = b.rank) : a = b := by
  cases a <;> cases b <;> simp_all [rank]

theorem rank_mem (m : Martaba) : 1 ≤ m.rank ∧ m.rank ≤ 12 := by cases m <;> decide

end Martaba

/-- Verdicts on a narrated route, worst first: ḍaʿīf jiddan (sāqiṭ) < ḍaʿīf < ḥasan < ṣaḥīḥ. -/
inductive Verdict where
  | daifJiddan | daif | hasan | sahih
  deriving DecidableEq, Repr

namespace Verdict

def rank : Verdict → Nat
  | daifJiddan => 0 | daif => 1 | hasan => 2 | sahih => 3

instance : LE Verdict := ⟨fun a b => a.rank ≤ b.rank⟩
instance (a b : Verdict) : Decidable (a ≤ b) := inferInstanceAs (Decidable (a.rank ≤ b.rank))

theorem rank_injective {a b : Verdict} (h : a.rank = b.rank) : a = b := by
  cases a <;> cases b <;> simp_all [rank]

theorem le_refl' (a : Verdict) : a ≤ a := Nat.le_refl _
theorem le_trans' {a b c : Verdict} : a ≤ b → b ≤ c → a ≤ c := Nat.le_trans
theorem le_antisymm' {a b : Verdict} (h₁ : a ≤ b) (h₂ : b ≤ a) : a = b :=
  rank_injective (Nat.le_antisymm h₁ h₂)

/-- Meet (weakest link) and join (best ṭarīq). -/
def meet (a b : Verdict) : Verdict := if a ≤ b then a else b
def join (a b : Verdict) : Verdict := if a ≤ b then b else a

theorem meet_le_left (a b : Verdict) : meet a b ≤ a := by
  unfold meet; split <;> first | exact le_refl' a | exact Nat.le_of_lt (Nat.lt_of_not_le ‹_›)
theorem meet_le_right (a b : Verdict) : meet a b ≤ b := by
  unfold meet; split <;> first | assumption | exact le_refl' b
theorem le_meet {a b c : Verdict} (ha : c ≤ a) (hb : c ≤ b) : c ≤ meet a b := by
  unfold meet; split <;> assumption
theorem meet_mono {a b a' b' : Verdict} (ha : a ≤ a') (hb : b ≤ b') : meet a b ≤ meet a' b' :=
  le_meet (le_trans' (meet_le_left a b) ha) (le_trans' (meet_le_right a b) hb)
theorem meet_eq_or (a b : Verdict) : meet a b = a ∨ meet a b = b := by
  unfold meet; split <;> simp
theorem join_eq_or (a b : Verdict) : join a b = a ∨ join a b = b := by
  unfold join; split <;> simp

/-- *Shadīd*: weakness that no number of ṭuruq repairs (*Tamām al-Minna*, «taqwiyat
al-ḥadīth bi-kathrat al-ṭuruq laysa ʿalā iṭlāqihi»). -/
def Shadid (v : Verdict) : Prop := v.rank ≤ 0
instance (v : Verdict) : Decidable v.Shadid := inferInstanceAs (Decidable (v.rank ≤ 0))

/-- *Ḥujja*: usable as dalīl, in aḥkām and faḍāʾil alike (al-Albānī rejects ʿamal bi'l-ḍaʿīf). -/
def Hujja (v : Verdict) : Prop := hasan ≤ v
instance (v : Verdict) : Decidable v.Hujja := inferInstanceAs (Decidable (hasan ≤ v))

/-- Bridge into the uṣūl kernel's epistemic scale (`Usul.Grade`). Āḥād ṣaḥīḥ yields ẓann;
qaṭʿ is reserved for tawātur, which is not a property of a single chain. -/
def grade : Verdict → Usul.Grade
  | sahih | hasan => .zann
  | daif => .shakk
  | daifJiddan => .wahm

theorem grade_mono {a b : Verdict} (h : a ≤ b) : a.grade ≤ b.grade := by
  cases a <;> cases b <;> first | decide | exact absurd h (by decide)

/-- A verdict is ḥujja exactly when its grade reaches yaqīn-for-action (ẓann ghālib). -/
theorem hujja_iff_yaqin (v : Verdict) : v.Hujja ↔ v.grade.IsYaqin := by cases v <;> decide

theorem grade_ne_qat (v : Verdict) : v.grade ≠ .qat := by cases v <;> decide

end Verdict

/-- Prima-facie verdict carried by a narrator of a given martaba. -/
def Martaba.verdict : Martaba → Verdict
  | .sahabi | .awthaq | .thiqa => .sahih
  | .saduq => .hasan
  | .saduqYahim | .maqbul | .mastur | .daif | .majhul => .daif
  | .matruk | .muttaham | .kadhdhab => .daifJiddan

/-- The valuation is antitone in rank: a lower (better) martaba never yields a worse verdict. -/
theorem Martaba.verdict_antitone {a b : Martaba} (h : a.rank ≤ b.rank) : b.verdict ≤ a.verdict := by
  cases a <;> cases b <;> first | decide | exact absurd h (by decide)

/-- Ḥujja band = marātib 1–4; shadīd band = marātib 10–12; the rest is the iʿtibār band. -/
theorem Martaba.hujja_iff (m : Martaba) : m.verdict.Hujja ↔ m.rank ≤ 4 := by cases m <;> decide
theorem Martaba.shadid_iff (m : Martaba) : m.verdict.Shadid ↔ 10 ≤ m.rank := by cases m <;> decide

/-! ## The two branches (decision D5) -/

/-- The judgement on a matn: narrated, with a verdict on the scale, or mawḍūʿ (fabricated, or
with no isnād at all: لا أصل له). Ordered with mawḍūʿ adjoined below the whole scale, so that a
ruling can cap; no rank arithmetic crosses the branches. -/
inductive Hukm where
  | mawdu
  | marwi (v : Verdict)
  deriving DecidableEq, Repr

namespace Hukm

def leb : Hukm → Hukm → Bool
  | mawdu, _ => true
  | marwi _, mawdu => false
  | marwi a, marwi b => decide (a ≤ b)

instance : LE Hukm := ⟨fun a b => leb a b = true⟩
instance (a b : Hukm) : Decidable (a ≤ b) := inferInstanceAs (Decidable (leb a b = true))

theorem le_refl' (a : Hukm) : a ≤ a := by
  cases a with
  | mawdu => rfl
  | marwi v => exact decide_eq_true (Verdict.le_refl' v)

theorem le_trans' {a b c : Hukm} (h₁ : a ≤ b) (h₂ : b ≤ c) : a ≤ c := by
  cases a with
  | mawdu => rfl
  | marwi x => cases b with
    | mawdu => exact absurd h₁ (by simp [LE.le, leb])
    | marwi y => cases c with
      | mawdu => exact absurd h₂ (by simp [LE.le, leb])
      | marwi z => exact decide_eq_true (Verdict.le_trans' (of_decide_eq_true h₁) (of_decide_eq_true h₂))

theorem total (a b : Hukm) : a ≤ b ∨ b ≤ a := by
  cases a with
  | mawdu => exact .inl rfl
  | marwi x => cases b with
    | mawdu => exact .inr rfl
    | marwi y => exact (Nat.le_total x.rank y.rank).imp decide_eq_true decide_eq_true

/-- Meet: the stricter of two judgements (a ruling caps a verdict this way). -/
def meet (a b : Hukm) : Hukm := if a ≤ b then a else b

theorem meet_le_left (a b : Hukm) : meet a b ≤ a := by
  unfold meet; split
  · exact le_refl' a
  · exact (total a b).resolve_left ‹_›
theorem meet_le_right (a b : Hukm) : meet a b ≤ b := by
  unfold meet; split <;> first | assumption | exact le_refl' b

theorem marwi_le {a b : Verdict} : marwi a ≤ marwi b ↔ a ≤ b := ⟨of_decide_eq_true, decide_eq_true⟩
theorem mawdu_le (a : Hukm) : mawdu ≤ a := rfl
theorem le_mawdu {a : Hukm} (h : a ≤ mawdu) : a = mawdu := by cases a <;> simp_all [LE.le, leb]

/-- *Ḥujja* on a judgement: narrated and at least ḥasan; a mawḍūʿ is never ḥujja. -/
def Hujja (h : Hukm) : Prop := marwi .hasan ≤ h
instance (h : Hukm) : Decidable h.Hujja := inferInstanceAs (Decidable (marwi .hasan ≤ h))

/-- Bridge: a mawḍūʿ gives the claim no support (wahm); a narrated matn grades as its verdict. -/
def grade : Hukm → Usul.Grade
  | mawdu => .wahm
  | marwi v => v.grade

theorem hujja_iff_yaqin (h : Hukm) : h.Hujja ↔ h.grade.IsYaqin := by
  cases h with
  | mawdu => decide
  | marwi v => cases v <;> decide

theorem not_hujja_mawdu : ¬ mawdu.Hujja := by decide

end Hukm

end Hadith
