# UsulTest.ExtensionSemantics in Plain English

Source: [`formal/lean/UsulTest/ExtensionSemantics.lean`](../../../formal/lean/UsulTest/ExtensionSemantics.lean)

Boundary checks for ADR 0001: a stable extension need not exist, so "stable" cannot stand in for "preferred". The executable grounded extension also gives the right answer on small attack graphs.

## 1. Vocabulary

- **Attack graph**: arguments, and which argument attacks which.
- **Stable set**: no member attacks another, and every outsider is attacked by a member.
- **Preferred set**: a maximal set that is free of internal attack and defends its members.
- **Grounded extension**: the arguments accepted by repeatedly adding everything defended so far, starting from nothing.

## 2. The theorems

| Theorem | Plain English |
| --- | --- |
| `cycle_no_stable` | Three arguments attacking in a cycle (a → b → c → a) have no stable set. |
| `mutual_singleton_stable` | Two arguments attacking each other: each alone is a stable set. |
| `mutual_singleton_preferred` | Each alone is also preferred, as every stable set is. |

The cycle shows a stable set can fail to exist. Code must not assume one exists where it would rely on a preferred set.

## 3. Grounded checks

| Check | Plain English |
| --- | --- |
| `grounded 3 [(0,1), (1,2), (2,0)] == []` | An odd cycle: nothing is accepted. |
| `grounded 2 [(0,1), (1,0)] == []` | Mutual attack: nothing is accepted. |
| `grounded 3 [] == [0,1,2]` | No attacks: everything is accepted. |
| `grounded 3 [(0,1), (1,0)] == [2]` | Only the uninvolved argument is accepted. |
| `grounded 4 [(0,1), (1,2), (2,0), (3,0)] == [1,3]` | An outside attacker (3) breaks the cycle: 3 is accepted, 0 falls, and 1 is defended. |

## In one line

A cycle of three has no stable extension, mutual attack keeps both sides as alternatives, and the grounded computation accepts exactly what should be accepted on each small graph.
