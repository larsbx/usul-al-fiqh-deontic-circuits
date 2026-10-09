import Hadith.Grade

/-!
# Isnād: links, tadlīs, and the weakest-link verdict (al-Albānī track §2.2, H2–H3)

A chain is a list of links. Each link carries the narrator's martaba (`Hadith.Grade`), its
continuity, and, for a mudallis, his tier and the *ṣīgha* of transmission.

**Tadlīs.** Ibn Ḥajar, *Taʿrīf Ahl al-Taqdīs*: five *marātib* of mudallisīn. Tiers 1–2 have
their ʿanʿana accepted; tiers 3–4 need explicit *taṣrīḥ bi'l-samāʿ*; tier 5 are weak for a
further reason, which is already carried by their martaba, so taṣrīḥ cures the tadlīs but
not that weakness. Which tiers are tolerated is a `Policy`, because it is disputed (a
parameter with Ibn Ḥajar's position as the default), as the qiyās modules treat disputes.

**Verdict.** *Nuzha*: ṣaḥīḥ li-dhātihi needs ʿadāla, tamām al-ḍabṭ and ittiṣāl at every link.
So the prima-facie chain verdict is the meet over link verdicts. Absence of ʿilla and
shudhūdh is *not* decided here: those are qarāʾin-based and enter as defeaters (`Hadith.Turuq`).
-/

namespace Hadith

/-- Ibn Ḥajar's five tiers of mudallisīn. -/
inductive Tier where
  | t1 | t2 | t3 | t4 | t5
  deriving DecidableEq, Repr

def Tier.rank : Tier → Nat | .t1 => 1 | .t2 => 2 | .t3 => 3 | .t4 => 4 | .t5 => 5

/-- Explicit hearing (*ḥaddathanā*, *samiʿtu*) vs the ambiguous *ʿan*. -/
inductive Sigha where
  | tasrih | anana
  deriving DecidableEq, Repr

/-- Which tiers' ʿanʿana is accepted. -/
structure Policy where
  tolerated : Tier → Bool

/-- Ibn Ḥajar: tiers 1–2 only. -/
def Policy.ibnHajar : Policy := ⟨fun t => decide (t.rank ≤ 2)⟩

/-- `p` is at most as tolerant as `q`. -/
def Policy.Le (p q : Policy) : Prop := ∀ t, p.tolerated t = true → q.tolerated t = true

def acceptsTadlis (p : Policy) : Option Tier → Sigha → Bool
  | none, _ => true
  | some _, .tasrih => true
  | some t, .anana => p.tolerated t

structure Link where
  rawi     : Martaba
  muttasil : Bool := true
  tadlis   : Option Tier := none
  sigha    : Sigha := .tasrih
  deriving DecidableEq, Repr

/-- A link that breaks continuity, or an unaccepted ʿanʿana, caps the link at ḍaʿīf. -/
def Link.verdict (p : Policy) (l : Link) : Verdict :=
  if l.muttasil && acceptsTadlis p l.tadlis l.sigha then l.rawi.verdict
  else l.rawi.verdict.meet .daif

abbrev Isnad := List Link

/-- Weakest link. The empty chain is the unit (ṣaḥīḥ); real chains are non-empty. -/
def Isnad.verdict (p : Policy) (c : Isnad) : Verdict :=
  c.foldr (fun l v => (l.verdict p).meet v) .sahih

variable {p q : Policy}

theorem tasrih_cures_tadlis (p : Policy) (t : Option Tier) : acceptsTadlis p t .tasrih = true := by
  cases t <;> rfl

theorem acceptsTadlis_mono (h : p.Le q) {t s} (hp : acceptsTadlis p t s = true) :
    acceptsTadlis q t s = true := by
  cases t <;> cases s <;> simp_all [acceptsTadlis]; exact h _ hp

theorem Link.verdict_le_rawi (l : Link) : l.verdict p ≤ l.rawi.verdict := by
  unfold Link.verdict; split
  · exact Verdict.le_refl' _
  · exact Verdict.meet_le_left _ _

/-- Unaccepted tadlīs or a gap leaves the link at most ḍaʿīf. -/
theorem Link.verdict_le_daif_of_defect (l : Link)
    (h : (l.muttasil && acceptsTadlis p l.tadlis l.sigha) = false) : l.verdict p ≤ .daif := by
  simp only [Link.verdict, h]; exact Verdict.meet_le_right _ _

theorem Link.verdict_mono (h : p.Le q) (l : Link) : l.verdict p ≤ l.verdict q := by
  unfold Link.verdict
  by_cases hp : (l.muttasil && acceptsTadlis p l.tadlis l.sigha) = true
  · have hq : (l.muttasil && acceptsTadlis q l.tadlis l.sigha) = true := by
      simp only [Bool.and_eq_true] at hp ⊢; exact ⟨hp.1, acceptsTadlis_mono h hp.2⟩
    simp only [hp, hq]; exact Verdict.le_refl' _
  · simp only [hp, Bool.false_eq_true, ite_false]
    split
    · exact Verdict.meet_le_left _ _
    · exact Verdict.le_refl' _

/-- The chain is no stronger than any of its links. -/
theorem Isnad.verdict_le_link {c : Isnad} {l : Link} (hl : l ∈ c) : c.verdict p ≤ l.verdict p := by
  induction c with
  | nil => cases hl
  | cons x xs ih =>
    rcases List.mem_cons.1 hl with rfl | h
    · exact Verdict.meet_le_left _ _
    · exact Verdict.le_trans' (Verdict.meet_le_right _ _) (ih h)

/-- …and it *is* one of its links (or ṣaḥīḥ when empty): the verdict is the weakest link. -/
theorem Isnad.verdict_attained (c : Isnad) :
    c.verdict p = .sahih ∨ ∃ l ∈ c, c.verdict p = l.verdict p := by
  induction c with
  | nil => exact .inl rfl
  | cons x xs ih =>
    have e : Isnad.verdict p (x :: xs) = (x.verdict p).meet (Isnad.verdict p xs) := rfl
    rw [e]
    rcases Verdict.meet_eq_or (x.verdict p) (Isnad.verdict p xs) with h | h <;> rw [h]
    · exact .inr ⟨x, List.mem_cons_self .., rfl⟩
    · rcases ih with h' | ⟨l, hl, h'⟩
      · exact .inl h'
      · exact .inr ⟨l, List.mem_cons_of_mem _ hl, h'⟩

/-- A more tolerant tadlīs policy never weakens a chain. -/
theorem Isnad.verdict_mono_policy (h : p.Le q) (c : Isnad) : c.verdict p ≤ c.verdict q := by
  induction c with
  | nil => exact Verdict.le_refl' _
  | cons x xs ih => exact Verdict.meet_mono (Link.verdict_mono h x) ih

/-- `c` is pointwise no stronger than `d` (same length, link by link). -/
inductive Isnad.Weaker (p : Policy) : Isnad → Isnad → Prop
  | nil : Isnad.Weaker p [] []
  | cons {x y : Link} {xs ys : Isnad} :
      x.verdict p ≤ y.verdict p → Isnad.Weaker p xs ys → Isnad.Weaker p (x :: xs) (y :: ys)

/-- Improving any link never weakens the chain (pointwise monotonicity). -/
theorem Isnad.verdict_mono_links {c d : Isnad} (h : Isnad.Weaker p c d) :
    c.verdict p ≤ d.verdict p := by
  induction h with
  | nil => exact Verdict.le_refl' _
  | cons hx _ ih => exact Verdict.meet_mono hx ih

/-- One kadhdhāb anywhere makes the chain mawḍūʿ. -/
theorem Isnad.mawdu_of_kadhdhab {c : Isnad} {l : Link} (hl : l ∈ c) (hk : l.rawi = .kadhdhab) :
    c.verdict p = .mawdu := by
  have h := Isnad.verdict_le_link (p := p) hl
  have h' := Link.verdict_le_rawi (p := p) l
  rw [hk] at h'
  have := Verdict.le_trans' h h'
  cases hv : c.verdict p <;> simp_all [Martaba.verdict] <;> exact absurd this (by decide)

/-- A gap (inqiṭāʿ) anywhere keeps the chain out of the ḥujja band. -/
theorem Isnad.not_hujja_of_gap {c : Isnad} {l : Link} (hl : l ∈ c) (hg : l.muttasil = false) :
    ¬ (c.verdict p).Hujja := fun hh =>
  absurd (Verdict.le_trans' hh (Verdict.le_trans' (Isnad.verdict_le_link hl)
    (Link.verdict_le_daif_of_defect l (by simp [hg])))) (by decide)

end Hadith
