# Source-bound derivation replay wire contract

This is the independently specified finite fixture contract for the Lean and Quint derivation models. The current files were reconstructed from the retained semantic contract after loss of an unpublished workspace. They require fresh validation; byte identity with the lost files is not claimed. No juristic position is selected by these synthetic fixtures.

## Semantic boundary

A candidate supplies a question identifier and registry request, or a topologically ordered program of `Source` and `Both` instructions. The separately supplied environment contains the admitted registry, authenticated exact source references, current interpretation pins, full-premise evidence decisions, and a nonempty implementation revision. A source succeeds only after registry validation, the source rule check, exact authentication, a unique current version, a unique matching supported evidence decision, and a known typed answer. The complete ordered list of source premises is retained in successful and rejected outputs.

A required conjunction preserves both ordered provenance lists. Its homogeneous-scope check compares question identifier, question family, and every existing scope field. An out-of-scope issue is prepended to inherited issues. Otherwise inherited issues are retained in order. Known Taklifi answers use the accepted IDA intersection; sign and validity answers combine only when equal. Missing conclusions without inherited issues are malformed. Accepted results are classified Admitted; all other results are Candidate. This is formal acceptance under an environment, not a claim of correctness of a juristic interpretation.

## Diagnostic codes and projection

Registry errors retain codes 1 through 8 from the existing judgment codec. Further codes are: 9 bad source rule, 10 source unauthenticated, 11 stale interpretation, 12 conflicting versions, 13 missing evidence, 14 conflicting evidence, 15 evidence mismatch, 16 disputed evidence, 17 suspended evidence, 18 unauthenticated evidence, 19 missing ruling, 20 suspended ruling, 21 out of scope, 22 conflicting answers, 23 malformed program, 24 bad environment. Accepted outcomes have code 0. Rejected primary codes are their first issue.

Each evaluation exports eight cells, in coordinate order:

| Coordinate | Value |
| --- | --- |
| 0 | primary outcome code |
| 1 | Admitted = 1, Candidate = 0 |
| 2 | known conclusion question identifier + 1, otherwise 0 |
| 3 | known conclusion question-family code + 1, otherwise 0 |
| 4 | known conclusion answer code + 1, otherwise 0 |
| 5 | number of provenance premises |
| 6 | ordered issue fold, starting at 0, `acc * 32 + issueCode` |
| 7 | ordered provenance entry-ID fold, starting at 0, `acc * 16 + entryId` |

Complete-record preservation assertions are separate from these finite numeric projections. A replay receipt binds the full environment, program, and full evaluation. Accepted replay requires exact current-environment equality, recomputed full-evaluation equality, and an accepted stored evaluation.

## Source fixture authentication

Source 1 is the exact four ASCII bytes `IDA\n`; source 2 is `IDB\n`. Both use the half-open passage range `[1,3)`. The adapter independently hashes the full bytes and the selected passage. For each source the 68 exported cells are `[sourceId] ++ sourceHash32 ++ [sourceBytes, passageStart, passageEnd] ++ passageHash32`. This connects 136 cells to the real source-authentication adapter, not merely to agreement between formal models.

## Common fixture constructor

`P(q,a,i)` starts from the accepted judgment module's synthetic baseline for question family `q`, sets answer code `a` and interpretation ID `i`, and uses source 1 when `i` is odd and source 2 when `i` is even. Its wrapper question ID is 7, request snapshot is 1, and entry ID is `i`. All other baseline fields are retained. Known baseline answer codes are 16 for Taklifi (q = 0), 36 for validity (q = 4), and 34 for the three sign families.

`E(ps)` contains exactly the premises' raw records as Admitted registry entries at snapshot 1, their source references in order (including duplicates), their interpretation pins, their exact full-premise Supported evidence decisions, and implementation revision `derivation-v1`.

## Leaf cases

For every q in 0 through 4, start from `p = P(q,knownAnswerCode(q),1)` and `E([p])`. Unless specified as rebuilt, mutations change only the indicated field of the original environment or candidate.

| Case | Modification | Expected primary code |
| --- | --- | --- |
| 0 | none | 0 |
| 1 | registry Candidate | 7 |
| 2 | registry Quarantined | 7 |
| 3 | registry Revoked | 7 |
| 4 | no authenticated sources | 10 |
| 5 | catalog source hash replaced by zero digest | 10 |
| 6 | catalog passage start changed to 2 | 10 |
| 7 | catalog passage hash replaced by zero digest | 10 |
| 8 | no current pins | 11 |
| 9 | pin profile version 2 | 11 |
| 10 | pin interpretation version 2 | 11 |
| 11 | duplicate identical pins | 12 |
| 12 | original pin plus interpretation-version-2 pin | 12 |
| 13 | no evidence decisions | 13 |
| 14 | duplicate Supported decisions | 14 |
| 15 | Supported plus Disputed decisions | 14 |
| 16 | Disputed evidence | 16 |
| 17 | EvidenceMissing | 13 |
| 18 | EvidenceSuspended | 17 |
| 19 | Unauthenticated evidence | 18 |
| 20 | evidence wrapper question ID 8 | 15 |
| 21 | candidate answer 0; rebuild environment | 19 |
| 22 | candidate answer 32; rebuild environment | 20 |
| 23 | source premise IDs `[2]`; rebuild environment | 9 |
| 24 | source rule ID 2; rebuild environment | 9 |
| 25 | empty environment revision | 24 |
| 26 | candidate request snapshot 2 | 4 |
| 27 | candidate source hash zero digest | 8 |
| 28 | candidate passage start 2 | 8 |
| 29 | candidate interpretation version 2 | 8 |
| 30 | candidate grade Zann | 8 |
| 31 | evidence premise grade Zann | 15 |

Every rejected leaf has one issue and retains the exact candidate as its sole provenance premise. Accepted leaves have vector `[0,1,8,q+1,answer+1,1,0,1]`; rejected leaves have `[code,0,0,0,0,1,code,1]`.

## Conjunction cases

Taklifi pairs cover all answer codes a and b from 0 through 32 inclusive, with premises `P(0,a,1)` and `P(0,b,2)` and a rebuilt environment. Answer 0 produces issue 19 and answer 32 issue 20. Inherited issues remain in left-to-right order. When both are known, the answer is the bitwise intersection; an empty intersection produces issue 22. Every pair retains provenance IDs `[1,2]`, count 2, fold 18.

For each sign family q = 1, 2, 3, answers are `[0,32,33,34]`; for validity q = 4, answers are `[0,32,35,36]`. Case k from 0 through 15 chooses left index `k / 4` and right index `k % 4`. The same blocker rules apply. Known unequal answers conflict; equal answers are preserved.

Scope cases start from sign-family q = 1, answer 34, entries 1 and 2. Case 0 is unchanged. Right-premise modifications are: 1 question ID 8; 2 family code 2; 3 subject ID 2; 4 baligh false; 5 aqil false; 6 target ID 2; 7 Affect target; 8 context 2; 9 time 2; 10 profile 2; 11 profile version 2; 12 Ibada domain. Rebuild the environment after each change. Both source leaves remain accepted. Only case 0 combines; cases 1 through 12 yield issue 21, provenance count 2 and fold 18.

## Nested cases

Start with `first=P(0,31,1)`, `middle=P(0,16,2)`, `last=P(0,16,3)`, and their rebuilt environment. Case 0 is unchanged. Cases 1 and 2 change middle to answer 0 or 32 and rebuild. Case 3 changes registry entry 2 to Candidate. Case 4 changes its evidence to Disputed. Case 5 removes authenticated source 2. Case 6 changes interpretation 2's pin to version 2. Case 7 changes middle's question ID to 8 and rebuilds. Case 8 changes its answer to 1 and rebuilds. Case 9 changes its evidence to EvidenceMissing.

Shapes:

- 0: `(first AND middle) AND last`, instruction references `[Source first, Source middle, Both 0 1, Source last, Both 2 3]`.
- 1: `first AND (middle AND last)`, references `[Source first, Source middle, Source last, Both 1 2, Both 0 3]`.
- 2: `(first AND middle) AND (middle AND last)`, references `[Source first, Source middle, Source last, Both 0 1, Both 1 2, Both 3 4]`.

Shapes 0 and 1 preserve IDs `[1,2,3]`, count 3, fold 291; shape 2 preserves `[1,2,2,3]`, count 4, fold 4643. Case 0 accepts answer 16. Cases 1,2,3,4,5,6,9 yield respective issue codes 19,20,7,16,10,11,13, once for shapes 0 and 1 and twice for shape 2. Case 7 has two issues 21 for shapes 0 and 1 and three for shape 2. Case 8 has one issue 22 for every shape.

## Alternatives and replay

Alternative scenarios use `P(0,1,1)` and `P(0,16,2)` as two independent source programs in one environment. Scenario 0 preserves both accepted outputs in input order. Scenario 1 makes entry 2 Candidate, preserving the first accepted output and the second rejected output. No preferred interpretation is chosen.

Replay baseline is the pair of `P(0,31,1)` and `P(0,16,2)`. Case 0 is unchanged and returns 1. Cases 1 through 6 alter the current environment respectively: implementation revision, registry snapshot, authentication list emptied, second interpretation pin version, second evidence Disputed, second registry entry Candidate. Cases 7 through 15 alter the stored receipt respectively: conclusion answer to Haram, provenance reduced to its head, conclusion context to 2, stored environment revision, program reduced to first Source, conclusion question ID 8, issues replaced by MissingRuling, conclusion removed, stored environment evidence reduced to its head. All return 0.

## Canonical row order

The CSV header is `section,a,b,c,result`. The Quint exporter emits one deterministic ITF state with a `results` list in precisely this order:

| Section | a | b | c | Cells |
| --- | --- | --- | --- | --- |
| source | 1..2 | 0..67 | 0 | 136 |
| leaf | 0..4 | 0..31 | 0..7 | 1280 |
| taklifi | 0..32 | 0..32 | 0..7 | 8712 |
| typed | 1..4 | 0..15 | 0..7 | 512 |
| scope | 0..12 | 0 | 0..7 | 104 |
| tree | 0..9 | 0..2 | 0..7 | 240 |
| alternatives | 0..1 | 0..1 | 0..7 | 32 |
| replay | 0..15 | 0 | 0 | 16 |
| **Total** | | | | **11032** |

All ranges are inclusive. Iterate coordinates from left to right in the table, smallest to largest, with c as the innermost coordinate.

## Independent fixed vectors

The fixed-vector inventory contains all 160 leaf cases, 64 typed cases, 13 scope cases, 30 nested cases, 4 alternatives, 16 replay flags, and 14 selected Taklifi pairs: 301 cases in total. The retained gate record specifies these pairs: `(0,0), (0,4), (4,0), (0,32), (32,0), (32,32), (32,4), (4,32), (4,4), (30,31), (30,16), (1,16), (2,8), (31,31)`. Their vectors follow the independently specified blocker and intersection rules above. The exhaustive parity family covers all 1089 pairs.

The 136 authenticated source cells are checked separately against adapter output. Finite parity, fixed examples, mutation detection, and universal Lean proofs are different forms of evidence and must be reported separately. Neither the projection nor the synthetic fixtures establish correctness of an interpretation of religious source material.
