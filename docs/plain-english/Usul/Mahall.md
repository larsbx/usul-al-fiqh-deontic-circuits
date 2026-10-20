# Usul.Mahall in Plain English

Source: [`formal/lean/Usul/Mahall.lean`](../../../formal/lean/Usul/Mahall.lean)

Every farʿ (case) rules on something: its **maḥall**. A maḥall is one of three kinds:

- an **item** (ʿayn), such as water, a dog or a pledged house;
- an **act** (fiʿl), such as a prayer, a sale or a vow;
- an **issue** (ḥāl), such as doubt, ignorance or compulsion.

Maḥalls are labels under broader labels, up to the chapters (bābs) of fiqh. Each label is defined by the canonical texts that name it: Qurʾānic verses, ḥadīths, or a reported consensus (ijmāʿ). This module puts these together with the qawāʿid (legal maxims) as one graph. It proves how a qāʿida is tied, through its furūʿ (cases), to the labels and the texts.

None of the links is one-to-one, and the graph does not force any of them to be:

- a farʿ may turn on several qawāʿid;
- a qāʿida type may cite several qawāʿid, and a qāʿida may have several types;
- a label may sit under several broader labels, even under two chapters (debt under sale and under loan);
- a label may be defined by several texts, and one text may define several labels.

## 1. The picture

- **Edges.** The graph has four kinds of edge, each a relation:
  - a farʿ is *tied* to a qāʿida. The author's placement, the qawāʿid its encoder reads, the qawāʿid cited by the types that encoder reads, and co-annotations all count;
  - a farʿ has a *maḥall* label;
  - a label has a *broader* label;
  - a text *defines* a label.
- **Footprint.** A qāʿida's footprint is every label the furūʿ tied to it fall under, together with all the broader labels above them.
- **Grounds.** A qāʿida's grounds are the canonical texts that define some label in its footprint.

## 2. Definitions and theorems

| Definition / Theorem | Plain English |
| --- | --- |
| `Graph` | Furūʿ, qawāʿid, labels and texts, with the four kinds of edge, each a relation. |
| `Below l m` | `m` is `l` itself, or a label above it along some path of broader labels. |
| `footprint q l` | Some farʿ tied to qāʿida `q` has a maḥall at or below `l`. |
| `grounds q n` | Text `n` defines some label in `q`'s footprint. |
| `footprint_upClosed` | A footprint contains every broader label of everything it contains. |
| `footprint_least`, `footprint_iff` | A qāʿida's footprint is exactly the smallest upward-closed set of labels holding the maḥalls of the furūʿ tied to it. The qāʿida reaches labels only through its furūʿ. |
| `grounded` | A text defining any label on a path from a farʿ's maḥall up to a chapter grounds every qāʿida that farʿ is tied to. This is how a text leads back to the qawāʿid. |
| `shared_far` | A farʿ tied to two qawāʿid puts its maḥall, and everything above it, into both footprints. |
| `bridge` | Two furūʿ that share a maḥall put that label into the footprints of all their qawāʿid, so a shared maḥall connects the qawāʿid. |
| `Data`, `Data.graph` | The finite graph the pipeline exports: furūʿ with their qawāʿid and labels, label–broader pairs, and text–label pairs. |
| `ups`, `mem_ups` | The broader labels of a label, read off the pairs. |
| `belowB`, `footprintB`, `groundsB` | Yes/no computations of the same relations, given a bound on how many steps up to climb. |
| `belowB_sound`, `footprintB_sound`, `groundsB_sound` | When a computation says yes, the relation holds. |
| `belowB_complete` | When the relation holds, the computation says yes for some bound. |
| `restrict`, `footprintB_restrict`, `groundsB_restrict` | Keeping only the furūʿ tied to one qāʿida does not change that qāʿida's answers, so the checks can run on the smaller graph. |
| `upClosedB`, `holdsB`, `groundsClosedB`, `exactB`, `footprint_sub`, `exactB_sound` | To show a list is exactly a qāʿida's footprint, it is enough that each label in it is computed in, that it is closed upwards, and that it holds the furūʿ's maḥalls; the same for the grounds. |
| `heightL`, `rootedB` | Every upward path from every label ends within the bound, so no label is its own ancestor. |

`UsulTest.MahallGraph` evaluates these computations on the exported graph. The soundness theorems carry each check over to the relations above.
