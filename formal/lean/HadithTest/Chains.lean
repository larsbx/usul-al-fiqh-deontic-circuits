import Hadith

/-!
Synthetic regression vectors for the isnād and ṭuruq kernels. Each vector names the rule it
pins; none is a transcribed entry from al-Albānī. Real entries from *al-Ḍaʿīfa*, *al-Ṣaḥīḥa*
and *al-Irwāʾ* enter as data in H4 (`corpus/takhrij/albani_*.json`), not here.
-/

namespace HadithTest
open Hadith

def chain (ls : List Link) : Verdict := Isnad.verdict .ibnHajar ls

def thiqa : Link := ⟨.thiqa, true, none, .tasrih⟩
def sahabi : Link := ⟨.sahabi, true, none, .tasrih⟩

-- Nuzha: ʿadl + tāmm al-ḍabṭ + ittiṣāl at every link ⇒ ṣaḥīḥ (prima facie).
#guard chain [thiqa, thiqa, sahabi] = .sahih
-- One ṣadūq link ⇒ ḥasan li-dhātihi.
#guard chain [thiqa, ⟨.saduq, true, none, .tasrih⟩, sahabi] = .hasan
-- Taʿrīf: tier-2 ʿanʿana tolerated; tier-3 ʿanʿana not; tier-3 taṣrīḥ cures it.
#guard chain [⟨.thiqa, true, some .t2, .anana⟩, sahabi] = .sahih
#guard chain [⟨.thiqa, true, some .t3, .anana⟩, sahabi] = .daif
#guard chain [⟨.thiqa, true, some .t3, .tasrih⟩, sahabi] = .sahih
-- Tier 5: taṣrīḥ cures the tadlīs, not the other weakness carried by the martaba.
#guard chain [⟨.daif, true, some .t5, .tasrih⟩, sahabi] = .daif
-- Inqiṭāʿ caps at ḍaʿīf; matrūk is shadīd; a kadhdhāb route is sāqiṭ, not mawḍūʿ (D5).
#guard chain [⟨.thiqa, false, none, .tasrih⟩, sahabi] = .daif
#guard chain [thiqa, ⟨.matruk, true, none, .tasrih⟩, sahabi] = .daifJiddan
#guard chain [thiqa, ⟨.kadhdhab, true, none, .tasrih⟩, sahabi] = .daifJiddan

-- Ṭuruq: two independent ḍaʿīf ⇒ ḥasan li-ghayrihi; ḥasan + ḍaʿīf ⇒ ṣaḥīḥ li-ghayrihi.
#guard judge [⟨.daif, 1⟩, ⟨.daif, 2⟩] 1 [] = .hasan
#guard judge [⟨.hasan, 1⟩, ⟨.daif, 2⟩] 1 [] = .sahih
-- Shadīd ṭuruq neither lift nor support.
#guard judge [⟨.daif, 1⟩, ⟨.daifJiddan, 2⟩, ⟨.daifJiddan, 3⟩] 1 [] = .daif
-- ʿIlla defeats; jawāb reinstates; an unanswered second ʿilla defeats again.
#guard judge [⟨.daif, 1⟩, ⟨.daif, 2⟩] 2 [(1, 0)] = .daif
#guard judge [⟨.daif, 1⟩, ⟨.daif, 2⟩] 3 [(1, 0), (2, 1)] = .hasan
#guard judge [⟨.daif, 1⟩, ⟨.daif, 2⟩] 4 [(1, 0), (2, 1), (3, 0)] = .daif

-- D5: no route at all is the mawḍūʿ branch (لا أصل له); any route is narrated; only a surviving
-- ruling crosses over, and a jawāb against it crosses back.
#guard judgeH .strict [] 1 [] = .mawdu
#guard judgeH .strict [(⟨chain [thiqa, ⟨.kadhdhab, true, none, .tasrih⟩, sahabi], 0⟩, 12)] 1 [] = .marwi .daifJiddan
#guard judgeRI .strict [(⟨.daifJiddan, 0⟩, 12)] 2 [] [⟨1, .hukm, .mawdu⟩] = .mawdu
#guard judgeRI .strict [(⟨.daifJiddan, 0⟩, 12)] 3 [(2, 1)] [⟨1, .hukm, .mawdu⟩] = .marwi .daifJiddan

end HadithTest
