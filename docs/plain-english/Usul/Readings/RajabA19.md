# Usul.Readings.RajabA19 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA19.lean`](../../../../formal/lean/Usul/Readings/RajabA19.lean)

Three of Ibn Rajab's qawāʿid (legal maxims) become yes/no rules. What returns by life or growth keeps its first ruling, but a rebuilt thing does not. A substitute stands in the original's place unless the original was sold. A finally divorced woman in her ʿidda is treated as a wife while the marriage's ties last.

## 1. How the readings work

- **Qāʿida**: a general maxim from Ibn Rajab's Ḥanbalī *Taqrīr al-qawāʿid*, from the pinned witness `openiti-rajab-shamela21730`.
- **Reading**: a Boolean function of named facts. Status: candidate.
- Qāʿida 142 states its question without taking a side. The reading takes the split its furūʿ's grounds draw. The other side stays in `corpus/takhrij/rajab_m8_rajab_a19_furu.json`, under research question RQ-02's policy.

## 2. What disappears and returns (qāʿida 142)

| Definition / Theorem | Plain English |
| --- | --- |
| `returnedIsFirst restoredByLife _oldMaterials` | The returned thing takes the first one's ruling ⟺ it was restored by life or growth (regrowth, a limb that heals back), not rebuilt by hand. |
| `rebuilt_is_not_first` | What a man rebuilds is never the first thing. |
| `materials_irrelevant` | Rebuilding with the old materials makes no difference. Ibn Rajab's «ويتوجه التفريق» stays a recorded position. |

## 3. The substitute (qāʿida 143)

| Definition / Theorem | Plain English |
| --- | --- |
| `badalStands soldForPrice` | The badal (substitute) stands in the original's place, its ruling built on the original's ⟺ the original was not given up for a price. |
| `price_is_not_badal` | A price taken for the original never stands in its place. |

## 4. The finally divorced woman in ʿidda (qāʿida 145)

| Definition / Theorem | Plain English |
| --- | --- |
| `bainAsWife inIdda tiesCut` | A woman divorced irrevocably (bāʾin) is treated as a wife on the qāʿida's points ⟺ she is still in her ʿidda (waiting period) and the marriage's ties are not cut. |
| `after_idda_not_wife` | After the ʿidda, she is not treated as a wife. |
| `ties_cut_not_wife` | Once the ties are cut (by her death), she is not, even within the ʿidda. |

## In one line

Life restores identity and human rebuilding does not, a substitute inherits the original's ruling unless the original was sold, and the bāʾin woman keeps a wife's standing only while her ʿidda and the marriage's ties last.
