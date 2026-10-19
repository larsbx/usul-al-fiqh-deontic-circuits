# Usul.Mahall in Plain English

Source: [`formal/lean/Usul/Mahall.lean`](../../../formal/lean/Usul/Mahall.lean)

Every farʿ (case) rules on something: its **maḥall**. A maḥall is one of three kinds:

- an **item** (ʿayn), such as water, a dog or a pledged house;
- an **act** (fiʿl), such as a prayer, a sale or a vow;
- an **issue** (ḥāl), such as doubt, ignorance or compulsion.

Maḥalls are labels in a tree whose roots are the chapters (bābs) of fiqh. Each label is defined by the canonical text that names it: a Qurʾānic verse, a ḥadīth, or a reported consensus (ijmāʿ). Separately, the author has placed each farʿ under a qāʿida (legal maxim). This module puts the two together as one graph and proves how a qāʿida is tied, through its furūʿ (cases), to the labels and the texts.

## 1. The picture

- **Edges.** The graph has four kinds of edge:
  - a farʿ is placed *under* a qāʿida;
  - a farʿ has a *maḥall* label;
  - a label has a *broader* label;
  - a text *defines* a label.
- **Footprint.** A qāʿida's footprint is every label its furūʿ fall under, together with all the broader labels above them.
- **Grounds.** A qāʿida's grounds are the canonical texts that define some label in its footprint.

## 2. Definitions and theorems

| Definition / Theorem | Plain English |
| --- | --- |
| `Graph` | Furūʿ, qawāʿid, labels and texts, with the four kinds of edge. |
| `Below l m` | `m` is `l` itself, or a broader label above it. |
| `footprint q l` | Some farʿ of qāʿida `q` has a maḥall at or below `l`. |
| `grounds q n` | Text `n` defines some label in `q`'s footprint. |
| `footprint_upClosed` | A footprint contains the broader label of everything it contains. |
| `footprint_least`, `footprint_iff` | A qāʿida's footprint is exactly the smallest upward-closed set of labels holding its furūʿ's maḥalls. The qāʿida reaches labels only through its furūʿ. |
| `grounded` | A text defining any label on the path from a farʿ's maḥall up to its chapter grounds that farʿ's qāʿida. This is how a text leads back to the qāʿida. |
| `bab_in_footprint` | A qāʿida's footprint holds the chapter of each of its furūʿ. |
| `bridge` | Two furūʿ that share a maḥall put a common label into the footprints of their two qawāʿid, so a shared maḥall connects the qawāʿid. |
| `Data`, `Data.graph` | The finite graph the pipeline exports: furūʿ with their qāʿida and labels, label–parent pairs, and text–label pairs. |
| `belowB`, `footprintB`, `groundsB` | Yes/no computations of the same relations, given a bound on how many steps up to climb. |
| `belowB_sound`, `footprintB_sound`, `groundsB_sound` | When a computation says yes, the relation holds. |
| `belowB_complete` | When the relation holds, the computation says yes for some bound. |
| `restrict`, `footprintB_restrict`, `groundsB_restrict` | Keeping only one qāʿida's furūʿ does not change that qāʿida's answers, so the checks can run on the smaller graph. |
| `rootedB` | Every label reaches a chapter within the bound, so the bound is enough to decide everything. |

`UsulTest.MahallGraph` evaluates these computations on the exported graph. The soundness theorems carry each check over to the relations above.
