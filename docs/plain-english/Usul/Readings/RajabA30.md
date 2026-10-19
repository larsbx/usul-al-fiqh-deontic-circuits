# Usul.Readings.RajabA30 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA30.lean`](../../../../formal/lean/Usul/Readings/RajabA30.lean)

Ibn Rajab's qāʿida 85 sorts rights into five kinds: «الحقوق خمسة أنواع». Each kind gets the yes/no ruling the text gives for it. Which kind a particular cause produces (for example, whether conquest makes the ghanīma owned at once) is something the text reports as disputed and leaves to each chapter (bāb). Those furūʿ are recorded as gaps (missing_rule) and are not forced onto a kind.

## 1. How the reading works

- **Qāʿida**: a general maxim from Ibn Rajab's Ḥanbalī *Taqrīr al-qawāʿid*, from the pinned witness `openiti-rajab-shamela21730`. Status: candidate.
- **`Haqq`**: the five kinds. These are ḥaqq milk (ownership), ḥaqq tamalluk (a right to come to own), ḥaqq intifāʿ (a right of use), ḥaqq ikhtiṣāṣ (exclusive holding of what is not owned wealth), and ḥaqq al-taʿalluq (a right attached to property so that another right can be recovered from it).
- The cases are in `corpus/takhrij/rajab_m8_rajab_a30_furu.json`.

## 2. The rules

| Definition / Theorem | Plain English |
| --- | --- |
| `Haqq.ownedWithoutChoice` | Only ḥaqq milk is ownership already in hand. A ḥaqq tamalluk waits on the holder's choice. |
| `Haqq.takesExchange` | A ḥaqq ikhtiṣāṣ cannot be sold or exchanged («غير قابل للشمول والمعاوضات»). |
| `awaitsChoice causeConcluded causeCompletesMilk` | He holds a ḥaqq tamalluk ⟺ a cause of owning has been concluded for him and that cause does not by itself make him owner. |
| `unclaimed_tamalluk_not_inherited` | Link to qāʿida 144: an unclaimed right to come to own does not pass to the heirs. |
| `tamalluk_disposal_does_not_take` | Link to qāʿida 55: one whose ownership waits on his choice does not become owner by disposing of the thing. |
| `mayPassBenefit useRightOnly` | A bare right of use cannot be lent or leased to someone else («كما لا يملك الجار إعارة غيره»). |
| `useRightForNeed needed harmful` | A right of use in another's property, without his leave ⟺ it is needed and does no harm. |
| `use_right_is_q99` | This is qāʿida 99's rule on needed things given free of charge, applied to the same cases (beams on a wall, water over land). |
| `handStands permittedBenefit mayBecomeMal` | A hand of ikhtiṣāṣ stands on a thing (it must be returned if taken) ⟺ the thing has a permitted use, or can become wealth again (wine that may turn to vinegar). |
| `firstComerAhaqq preceded leftByChoice` | The first to reach a shared place (a market stall, a seat in the mosque) has more right to it until he leaves by choice. |
| `wholeBound pledgeTie jinayaTie` | Under a pledge's tie or an injury's tie, the whole thing is held for the right, not only the right's measure. |
| `recoverFrom tied` | A right tied to property (by pledge, injury, ḥajr or designation) is recovered from that property. |
| `tiedPrecedes tied rivalInDhimmaOnly` | A tied right is paid from the property before claims that are owed only as personal debts (in the dhimma). Example: the poor's right in a designated sacrificial animal, ahead of creditors. |

## In one line

Five kinds of right, each with its own consequences. The reading applies those consequences, and leaves to each chapter the question of which kind a given cause produces.
