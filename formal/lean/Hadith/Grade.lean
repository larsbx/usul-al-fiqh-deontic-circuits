import Usul.Signature

/-!
# Narrator grades and ḥadīth verdicts (al-Albānī track §2.1, H2)

Ibn Ḥajar, *Taqrīb al-Tahdhīb*, muqaddima: twelve *marātib* for narrators, best first. The
*Taqrīb* is al-Albānī's default valuation; individual verdicts may override it, and those
overrides are data (H4), not changes to this scale. Wording of each rung is from recall and
is checked against the pinned edition in H0.

The verdict scale is the *Nuzha*'s partition of the *maqbūl* / *mardūd*, coarsened to the
five values al-Albānī's *Silsilatān* actually emit. `grade` bridges into the uṣūl kernel's
epistemic scale, so a ḥadīth verdict enters a deontic derivation only as a `Usul.Grade`.
-/

namespace Hadith

/-- The twelve *marātib* of the *Taqrīb*, in order. -/
inductive Martaba where
  | sahabi      --  1 Companion: ʿudūl by consensus
  | awthaq      --  2 emphasised praise: awthaq al-nās, thiqa thiqa
  | thiqa       --  3 thiqa, mutqin, thabt, ʿadl
  | saduq       --  4 ṣadūq, lā baʾs bihi
  | saduqYahim  --  5 ṣadūq yahim / sayyiʾ al-ḥifẓ / lahu awhām / ikhtilāṭ
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

/-- Verdicts, worst first: mawḍūʿ < ḍaʿīf jiddan < ḍaʿīf < ḥasan < ṣaḥīḥ. -/
inductive Verdict where
  | mawdu | daifJiddan | daif | hasan | sahih
  deriving DecidableEq, Repr

namespace Verdict

def rank : Verdict → Nat
  | mawdu => 0 | daifJiddan => 1 | daif => 2 | hasan => 3 | sahih => 4

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
def Shadid (v : Verdict) : Prop := v.rank ≤ 1
instance (v : Verdict) : Decidable v.Shadid := inferInstanceAs (Decidable (v.rank ≤ 1))

/-- *Ḥujja*: usable as dalīl, in aḥkām and faḍāʾil alike (al-Albānī rejects ʿamal bi'l-ḍaʿīf). -/
def Hujja (v : Verdict) : Prop := hasan ≤ v
instance (v : Verdict) : Decidable v.Hujja := inferInstanceAs (Decidable (hasan ≤ v))

/-- Bridge into the uṣūl kernel's epistemic scale (`Usul.Grade`). Āḥād ṣaḥīḥ yields ẓann;
qaṭʿ is reserved for tawātur, which is not a property of a single chain. -/
def grade : Verdict → Usul.Grade
  | sahih | hasan => .zann
  | daif => .shakk
  | daifJiddan | mawdu => .wahm

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
  | .matruk | .muttaham => .daifJiddan
  | .kadhdhab => .mawdu

/-- The valuation is antitone in rank: a lower (better) martaba never yields a worse verdict. -/
theorem Martaba.verdict_antitone {a b : Martaba} (h : a.rank ≤ b.rank) : b.verdict ≤ a.verdict := by
  cases a <;> cases b <;> first | decide | exact absurd h (by decide)

/-- Ḥujja band = marātib 1–4; shadīd band = marātib 10–12; the rest is the iʿtibār band. -/
theorem Martaba.hujja_iff (m : Martaba) : m.verdict.Hujja ↔ m.rank ≤ 4 := by cases m <;> decide
theorem Martaba.shadid_iff (m : Martaba) : m.verdict.Shadid ↔ 10 ≤ m.rank := by cases m <;> decide

end Hadith
