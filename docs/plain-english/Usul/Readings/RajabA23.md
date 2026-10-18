# Usul.Readings.RajabA23 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA23.lean`](../../../../formal/lean/Usul/Readings/RajabA23.lean)

Two of Ibn Rajab's qawāʿid (legal maxims) become yes/no rules. A grandchild counts as a child always, only in the child's absence, or never, by kind of ruling. A woman whose state changes in her ʿidda moves to the new ʿidda only if her husband could still restore the marriage, or in the excepted deathbed case.

## 1. How the readings work

- **Qāʿida**: a general maxim from Ibn Rajab's Ḥanbalī *Taqrīr al-qawāʿid*, from the pinned witness `openiti-rajab-shamela21730`.
- **Reading**: a Boolean function of named facts. Status: candidate.
- Other sides of reported splits stay in `corpus/takhrij/rajab_m8_rajab_a23_furu.json`.

## 2. The grandchild as child (qāʿida 153)

Three kinds of ruling: the grandchild is included always; only when the child is absent; or never.

| Definition / Theorem | Plain English |
| --- | --- |
| `grandchildCountsAsChild firstKind secondKind childPresent` | The grandchild takes the child's ruling ⟺ the ruling is of the first kind, or of the second kind with the intermediate child absent. |
| `first_kind_always` | First kind: included whether or not the child is present. |
| `second_kind_barred_by_child` | Second kind: excluded while the child is present. |
| `second_kind_absent_child` | Second kind: included when the child is absent. |
| `third_kind_never` | Third kind: never included. |

## 3. Moving to a new ʿidda (qāʿida 157)

A woman in her ʿidda (waiting period) may be freed, or her husband may die. Does she move to a free woman's or a widow's ʿidda?

| Definition / Theorem | Plain English |
| --- | --- |
| `transfersToNewIdda statusChanges canRemedy sickIbana` | She moves ⟺ her state changed, and either the husband could restore the marriage within the ʿidda or it is the excepted case of separation by a husband in his final illness. |
| `no_change_no_transfer` | No change, no move. |
| `no_remedy_no_transfer` | A husband who could not restore the marriage, outside the exception, does not move her. |
| `remedy_transfers` | A change while he can restore the marriage moves her. |

## In one line

A grandchild stands as a child according to the ruling's kind, and a changed state moves a woman to a new ʿidda only while her husband could still take her back, or when he divorced her on his deathbed.
