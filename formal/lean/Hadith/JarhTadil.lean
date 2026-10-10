import Hadith.Grade

/-!
# Jarḥ wa-taʿdīl in conflict (al-Albānī track §2.4, H3)

al-Muʿallimī, *al-Tankīl* (al-Albānī's edition), al-qism al-awwal, qawāʿid 4, 5, 7, 8; with
al-Albānī, *Tamām al-Minna*, qāʿida 5 (Ibn Ḥibbān's tawthīq of the majhūl is not relied on).
Each rule is quoted and linked in `corpus/hadith/kernel_scales.json`.

**What counts.** Only a statement made «على وجه الحكم» counts; words said in anger, as advice
or in passing are set aside (Q4, first wajh). Only a critic who is relied on for that judgement
counts (*Tamām* Q5: «إمام معتمد في توثيقه»).

**Strength = how remote the error is.** A statement is `mujmal` (no cause given), `mufassar`
(cause given, still open to error), or `qati`: so explained and established that rejecting it
means imputing deliberate falsehood to an ʿadl critic (Q7: «بحيث لا يظهر دفعه إلا بنسبة الجارح
إلى تعمد الكذب»). Q4 applies the same test to taʿdīl, so strength is symmetric.

**Resolution** (Q5 «التحقيق», Q7 «القضيتان»):
* jarḥ, no taʿdīl ⇒ majrūḥ, even if mujmal;
* taʿdīl, no jarḥ ⇒ ʿadl; neither ⇒ tawaqquf (majhūl);
* a qāṭiʿ side against a non-qāṭiʿ side wins «وإن كثر المعدلون»;
* otherwise tarjīḥ: the side whose error is more remote, by qarāʾin (e.g. the Shaykhān's
  iḥtijāj, the critic's town, the length of acquaintance); with no qarīna, tawaqquf «حتى
  يسفر البحث».

**Bias** (Q4): sukhṭ or friendship is a qarīna inside tarjīḥ only. It never defeats a qāṭiʿ
statement (`qati_jarh_wins` holds for every qarīna). Counting critics is irrelevant: the
resolution reads the strongest statement on each side, never the number.

The *Tankīl* also separates narrator from witness. For a shāhid, an unexplained jarḥ yields to
taʿdīl; for a rāwī it does not (`rawi_not_shahid`).
-/

namespace Hadith.JarhTadil

inductive Strength where
  | mujmal | mufassar | qati
  deriving DecidableEq, Repr

def Strength.rank : Strength → Nat | .mujmal => 0 | .mufassar => 1 | .qati => 2

inductive Side where
  | jarh | tadil
  deriving DecidableEq, Repr

/-- One critic's statement about a narrator. -/
structure Qawl where
  side     : Side
  strength : Strength
  hukm     : Bool := true   -- made as a judgement (Q4)
  mutamad  : Bool := true   -- the critic is relied on for it (Tamām Q5)
  deriving DecidableEq, Repr

def Qawl.counts (q : Qawl) : Bool := q.hukm && q.mutamad

/-- The stronger of two optional strengths. -/
def top : Option Strength → Strength → Option Strength
  | none, s => some s
  | some a, s => some (if a.rank ≤ s.rank then s else a)

/-- Strongest counting statement on one side. -/
def strongest (side : Side) (qs : List Qawl) : Option Strength :=
  qs.foldl (fun acc q => if q.counts && q.side == side then top acc q.strength else acc) none

inductive Status where
  | majruh | tawaqquf | adl
  deriving DecidableEq, Repr

def Status.rank : Status → Nat | .majruh => 0 | .tawaqquf => 1 | .adl => 2

/-- Resolution from the strongest jarḥ `j`, the strongest taʿdīl `t`, and the side the
qarāʾin favour in tarjīḥ (`none`: no qarīna yet). -/
def resolve : Option Strength → Option Strength → Option Side → Status
  | none, none, _ => .tawaqquf
  | some _, none, _ => .majruh
  | none, some _, _ => .adl
  | some .qati, some .qati, _ => .tawaqquf
  | some .qati, some _, _ => .majruh
  | some _, some .qati, _ => .adl
  | some _, some _, some .jarh => .majruh
  | some _, some _, some .tadil => .adl
  | some _, some _, none => .tawaqquf

/-- The verdict on a narrator from everything said about him. -/
def judge (qs : List Qawl) (qarina : Option Side) : Status :=
  resolve (strongest .jarh qs) (strongest .tadil qs) qarina

/-! ## The rules as theorems -/

/-- Q5: an unexplained jarḥ wounds whoever has no taʿdīl. -/
theorem jarh_alone_wounds (j : Strength) (q : Option Side) : resolve (some j) none q = .majruh := rfl

/-- Q7.2: an established jarḥ wins against any non-qāṭiʿ taʿdīl, whatever the qarāʾin (so bias
cannot defeat it, Q4). -/
theorem qati_jarh_wins (t : Strength) (ht : t ≠ .qati) (q : Option Side) :
    resolve (some .qati) (some t) q = .majruh := by
  cases t <;> simp_all [resolve]

/-- Q4, the same test applied to taʿdīl. -/
theorem qati_tadil_wins (j : Strength) (hj : j ≠ .qati) (q : Option Side) :
    resolve (some j) (some .qati) q = .adl := by
  cases j <;> simp_all [resolve]

/-- Q5 «ويوجب التوقف فيمن قد عدل حتى يسفر البحث»: an unexplained jarḥ against a taʿdīl,
with no qarīna, is tawaqquf: neither side wins by default. -/
theorem mujmal_against_tadil (t : Strength) (ht : t ≠ .qati) :
    resolve (some .mujmal) (some t) none = .tawaqquf := by
  cases t <;> simp_all [resolve]

/-- The witness rule the *Tankīl* contrasts: for a shāhid, an unexplained jarḥ yields to taʿdīl. -/
def shahid (j t : Option Strength) : Status :=
  match j, t with
  | some .mujmal, some _ => .adl
  | _, _ => resolve j t none

theorem rawi_not_shahid :
    resolve (some .mujmal) (some .mujmal) none ≠ shahid (some .mujmal) (some .mujmal) := by decide

/-- Qarāʾin decide only in tarjīḥ: outside it, the result is the same for every qarīna. -/
theorem qarina_only_in_tarjih (j t : Option Strength) (q q' : Option Side)
    (h : ¬ ((∃ a, j = some a ∧ a ≠ .qati) ∧ (∃ b, t = some b ∧ b ≠ .qati))) :
    resolve j t q = resolve j t q' := by
  rcases j with _ | ⟨_ | _ | _⟩ <;> rcases t with _ | ⟨_ | _ | _⟩ <;> simp_all [resolve]

/-- A stronger jarḥ never improves the status; a stronger taʿdīl never worsens it. -/
theorem antitone_in_jarh (a b : Strength) (t : Option Strength) (q : Option Side)
    (h : a.rank ≤ b.rank) : (resolve (some b) t q).rank ≤ (resolve (some a) t q).rank := by
  cases a <;> cases b <;> rcases t with _ | ⟨_ | _ | _⟩ <;> rcases q with _ | ⟨_ | _⟩ <;>
    simp_all [resolve, Status.rank, Strength.rank]

theorem monotone_in_tadil (a b : Strength) (j : Option Strength) (q : Option Side)
    (h : a.rank ≤ b.rank) : (resolve j (some a) q).rank ≤ (resolve j (some b) q).rank := by
  cases a <;> cases b <;> rcases j with _ | ⟨_ | _ | _⟩ <;> rcases q with _ | ⟨_ | _⟩ <;>
    simp_all [resolve, Status.rank, Strength.rank]

/-! ## What does not count -/

theorem strongest_skip {side : Side} {x : Qawl} (hx : x.counts = false) (qs : List Qawl)
    (acc : Option Strength) :
    (x :: qs).foldl (fun acc q => if q.counts && q.side == side then top acc q.strength else acc) acc
      = qs.foldl (fun acc q => if q.counts && q.side == side then top acc q.strength else acc) acc := by
  simp [List.foldl, hx]

/-- Q4 and *Tamām* Q5: a statement not made as a judgement, or from a critic not relied on for
it (Ibn Ḥibbān's tawthīq of a majhūl), changes nothing. -/
theorem not_counting_ignored {x : Qawl} (hx : x.counts = false) (qs : List Qawl) (q : Option Side) :
    judge (x :: qs) q = judge qs q := by
  simp only [judge, strongest, strongest_skip hx]

/-- «وإن كثر المعدلون»: an established jarḥ stands against any number of ordinary taʿdīlāt. -/
example (q : Option Side) :
    judge [⟨.jarh, .qati, true, true⟩, ⟨.tadil, .mufassar, true, true⟩, ⟨.tadil, .mujmal, true, true⟩,
           ⟨.tadil, .mufassar, true, true⟩] q = .majruh := by
  rcases q with _ | ⟨_ | _⟩ <;> decide

/-- Ibn Ḥibbān's lone tawthīq of a narrator nobody else graded: still majhūl (tawaqquf). -/
example : judge [⟨.tadil, .mujmal, true, false⟩] none = .tawaqquf := by decide

/-- Tawaqquf is the mastūr's status («موقوفة إلى استبانة حاله», *Nuzha* via *Tamām* Q4), so it
lands in the kernel's iʿtibār band. -/
def Status.martaba : Status → Option Martaba
  | .tawaqquf => some .mastur
  | _ => none   -- ʿadl and majrūḥ need the ḍabṭ / cause to fix a rung

theorem tawaqquf_itibar : ∀ m, Status.tawaqquf.martaba = some m → ¬ m.verdict.Hujja ∧ ¬ m.verdict.Shadid := by
  intro m h; cases h; decide

end Hadith.JarhTadil
