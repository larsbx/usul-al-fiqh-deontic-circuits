# Usul.Readings.RajabA28 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA28.lean`](../../../../formal/lean/Usul/Readings/RajabA28.lean)

Ibn Rajab's qāʿida 82 sorts the separated growth (namāʾ munfaṣil) of a thing, such as a child, fruit, milk, earnings or an arsh, by the right attached to the thing: contracts, fusūkh (rescissions), and rights that are neither. Each kind states its own ruling, so the module gives one yes/no reading per kind.

## 1. How the readings work

- **Qāʿida**: a general maxim from Ibn Rajab's Ḥanbalī *Taqrīr al-qawāʿid*, from the pinned witness `openiti-rajab-shamela21730`. Status: candidate.
- **`lazim`**: the contract or right is lāzim, so the party cannot undo it alone.
- **`fromSubstance`**: the growth is born of the thing (a child, fruit), not earned.
- Where a kind leaves two sides unmarked, the reading takes the side its docstring names. The other side stays recorded in `corpus/takhrij/rajab_m8_rajab_a28_furu.json`.

## 2. The rules

| Definition / Theorem | Plain English |
| --- | --- |
| `towardOwnershipFollows lazim fromSubstance` | A contract leading to ownership (kitāba, a bequest after the death) carries the growth ⟺ it is lāzim. When it is not lāzim, the disputed child is read as not following. |
| `lazim_growth_follows`, `not_lazim_earnings_stay`, `not_lazim_child_read_as_staying` | The three cases of that rule. |
| `growthInContract onSubstance lazim` | In a contract that does not transfer the thing (rahn, ijāra, ʿāriya), the growth is inside the contract ⟺ the contract bears on the thing itself and is lāzim. |
| `lazim_on_substance_within`, `dhimma_reaches_no_growth`, `not_lazim_reaches_no_growth` | The pledge carries its growth. A right in the dhimma, or a contract that is not lāzim, carries none. |
| `growthFollowsHand sharesGround` | Outside the contract, the growth follows its aṣl in ḍamān (liability) or amāna (trust). This is the first of the two wujūh, which the reading takes. |
| `growthFollowsHandSecondWajh`, `wujuh_agree_on_shared_ground`, `wujuh_part_off_shared_ground` | The second wajh: the growth follows only where it shares the ground of its aṣl's ḍamān or amāna. The two wujūh differ only where it does not. |
| `faskhGrowthFollows fromSubstance liftsFromOrigin` | In a faskh, the growth goes back ⟺ it is born of the thing and the faskh lifts the contract from its origin. Earnings never go back. |
| `faskh_returns_only_part`, `right_reaches_only_part` | Link to qawāʿid 20–21 (`growthKind`): what goes back, or what a right reaches, is always growth that counts as part of the thing. |
| `rightGrowthFollows lazimRight fromSubstance` | A right that is neither a contract nor a faskh reaches the growth ⟺ the right is lāzim and the growth is born of the thing. Istīlād reaches the children but not the earnings. |

## In one line

Whether a thing's offspring and yield go with it depends on the right attached to it: lāzim contracts and rights carry them, a faskh returns them only if it undoes the contract from the start, and outside the contract they follow their source in liability or trust.
