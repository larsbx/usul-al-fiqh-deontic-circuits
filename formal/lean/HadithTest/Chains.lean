import Hadith

/-!
Synthetic regression vectors for the isnād and ṭuruq kernels. Each vector names the rule it
pins; none is a transcribed entry from al-Albānī. Real entries from *al-Ḍaʿīfa*, *al-Ṣaḥīḥa*
and *al-Irwāʾ* enter as data in H4 (`corpus/takhrij/albani_*.json`), not here.
-/

namespace HadithTest
open Hadith
open Hadith.ClassicalCriteria

def chain (ls : List Link) : Verdict := Isnad.verdict .ibnHajar ls

def thiqa : Link := ⟨.thiqa, true, none, .tasrih⟩
def sahabi : Link := ⟨.sahabi, true, none, .tasrih⟩

-- Prima-facie score for the project profile.
#guard chain [thiqa, thiqa, sahabi] = .sahih
-- One ṣadūq link gives the profile's ḥasan score.
#guard chain [thiqa, ⟨.saduq, true, none, .tasrih⟩, sahabi] = .hasan
-- Taʿrīf: tier-2 ʿanʿana tolerated; tier-3 ʿanʿana not; tier-3 taṣrīḥ cures it.
#guard chain [⟨.thiqa, true, some .t2, .anana⟩, sahabi] = .sahih
#guard chain [⟨.thiqa, true, some .t3, .anana⟩, sahabi] = .daif
#guard chain [⟨.thiqa, true, some .t3, .tasrih⟩, sahabi] = .sahih
-- Tier 5: taṣrīḥ cures the tadlīs, not the other weakness carried by the martaba.
#guard chain [⟨.daif, true, some .t5, .tasrih⟩, sahabi] = .daif
-- Inqiṭāʿ caps at ḍaʿīf; matrūk is shadīd; kadhdhāb is mawḍūʿ.
#guard chain [⟨.thiqa, false, none, .tasrih⟩, sahabi] = .daif
#guard chain [thiqa, ⟨.matruk, true, none, .tasrih⟩, sahabi] = .daifJiddan
#guard chain [thiqa, ⟨.kadhdhab, true, none, .tasrih⟩, sahabi] = .mawdu

-- Ṭuruq: two independent ḍaʿīf ⇒ ḥasan li-ghayrihi; ḥasan + ḍaʿīf ⇒ ṣaḥīḥ li-ghayrihi.
#guard judge [⟨.daif, 1⟩, ⟨.daif, 2⟩] 1 [] = .hasan
#guard judge [⟨.hasan, 1⟩, ⟨.daif, 2⟩] 1 [] = .sahih
-- Shadīd ṭuruq neither lift nor support.
#guard judge [⟨.daif, 1⟩, ⟨.daifJiddan, 2⟩, ⟨.mawdu, 3⟩] 1 [] = .daif
-- ʿIlla defeats; jawāb reinstates; an unanswered second ʿilla defeats again.
#guard judge [⟨.daif, 1⟩, ⟨.daif, 2⟩] 2 [(1, 0)] = .daif
#guard judge [⟨.daif, 1⟩, ⟨.daif, 2⟩] 3 [(1, 0), (2, 1)] = .hasan
#guard judge [⟨.daif, 1⟩, ⟨.daif, 2⟩] 4 [(1, 0), (2, 1), (3, 0)] = .daif

-- Source criteria. Keep the old chain score fixed while varying critical findings.
private def reviewed : RouteFindings :=
  ⟨.established, .established, .full, .established, .established⟩

#guard chain [thiqa, sahabi] = .sahih
#guard intrinsicGrade .established reviewed = some .sahihLiDhatihi
#guard intrinsicGrade .established { reviewed with ittisal := .unresolved } = none
#guard intrinsicGrade .established { reviewed with adala := .unresolved } = none
#guard intrinsicGrade .established { reviewed with dabt := .light } = some .hasanLiDhatihi
#guard intrinsicGrade .established { reviewed with dabt := .unresolved } = none
#guard intrinsicGrade .established { reviewed with freeOfShudhudh := .refuted } = none
#guard intrinsicGrade .established { reviewed with freeOfQadihIlla := .unresolved } = none
#guard intrinsicGrade .unresolved reviewed = none

#guard sixthRankStatus .established = some .maqbul
#guard sixthRankStatus .refuted = some .layyinAlHadith
#guard sixthRankStatus .unresolved = none

-- A profile lift on distinct labels neither supplies a follower finding nor changes the
-- Nuzha passage's list of causes. Rank 9's jahāla is outside that list.
#guard judgeRI .strict [(⟨.daif, 1⟩, 9), (⟨.daif, 2⟩, 9)] 1 [] [] = .hasan
#guard Nukhba.jabr (.taan .jahala) .established = false
#guard Nukhba.jabr .mastur .unresolved = false
#guard Nukhba.jabr .mastur .established = true

private def tawaturFindings : Nukhba.TawaturFindings :=
  ⟨.established, .established, .established, .established⟩

#guard Nukhba.knowledge (.tawatur tawaturFindings (by decide)) .sahih = .qat
#guard Nukhba.knowledge (.routes 999) .sahih = .zann
-- Nuzha v01:p048–p049 cites the singular early transmission of the intentions report.
#guard Nukhba.kathra (.routes 0) = .gharib
#guard ¬ ({ tawaturFindings with sensoryBasis := .unresolved }).Established
#guard ¬ ({ tawaturFindings with impartsKnowledge := .unresolved }).Established

end HadithTest
