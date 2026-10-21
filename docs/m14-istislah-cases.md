# M14: al-Ghazālī’s istiṣlāḥ examples

Five source-grounded **candidate** cases connect the existing reading to al-Mustaṣfā.
The scope is whether a proposed maṣlaḥa counts as a proof under a specified reading.
It is not a legal permission engine, and no candidate has been reviewed or adopted.

The witness is [OpenITI Shamela 5459 at the pinned commit](https://raw.githubusercontent.com/OpenITI/0525AH/6290621b58e063ed1aa47ffd0a6fc1630191e7cb/data/0505Ghazali/0505Ghazali.Mustasfa/0505Ghazali.Mustasfa.Shamela0005459-ara1),
1,807,610 bytes, SHA-256 `59cda7d5424b26ab73aa2d7d8130d1fbe28fc465ab6075d759dc782ebe1697ac`.
OpenITI markers close pages. Local `m00001`–`m00005` identifiers are editorial and are not printed source numbers.
The existing registry and byte lock are unchanged.

| Case | Location | Candidate facts | Unsettled fields | al-Mustaṣfā result / checks |
| --- | --- | --- | --- | --- |
| King’s fast | v01 p174 | Cancelled (`ilgha`) | Rank, certainty, universality | false / 12 |
| Tatarrus | v01 p175–176; qualification p177 | Unattested, necessary, certain, universal | None within the stated hypothetical | true / 1 |
| Fortress | v01 p176 | Unattested, not certain; text also denies necessity | Rank, universality | false / 6 |
| Ship | v01 p176 | Unattested, not universal | Rank, certainty | false / 6 |
| Famine | v01 p176 | Unattested, not universal | Rank, certainty | false / 6 |

`mustasfa` names the author reading being replayed. It is explicitly separate from scenario
facts in the receipt. In the takhrīj annotation it supplies the existing required stance input.
`derivable` means agreement with this conditional reading, not a reviewed conclusion or
consensus among the three modeled stances. These component checks have `routing_label=false`.

For the fortress, denial of necessity does not identify either `haji` or `tahsini`.
All three ranks are therefore checked: this over-approximation proves that the certainty
objection suffices even under the strongest rank; it does not assert that the fortress is necessary.
The ship also has an objection concerning selection by lot, which the five-field encoder cannot express.
The famine segment ends before the distinct discussion of cutting diseased tissue or one’s own flesh.

The later tatarrus passage expressly places the issue within ijtihād and allows prohibition.
Its certainty threshold includes near-certainty but not ordinary probability. The source qualification
is retained as separately located evidence; the existing positive theorem is not promoted into an
unconditional authorial, normative or consensus ruling.

## Three positions retained

| Case | `rawda` | `mustasfa` | `malik` as reported by the Rawḍa |
| --- | --- | --- | --- |
| King’s fast | {false} | {false} | {false} |
| Tatarrus | {false} | {true} | {true} |
| Fortress (source denies necessity) | {false} | {false} | {false} |
| Ship, famine | {false} | {false} | {false, true} |

These are computed reachable outputs, not new historical attributions. The two-valued results
retain the unknown rank in the ship and famine: on the modeled `malik` stance an unattested necessary benefit is accepted,
whereas the lower ranks are not. No default fills this uncertainty. The fortress’s explicit exclusion of `daruri` is enforced for source-compatible reach; a separate report field retains its stronger all-ranks guard over-approximation. The source comparison remains
Rawḍa v01 p482 and al-Mustaṣfā v01 p176–177, as recorded by the existing dossier.

## Auditable path and replay

- `corpus/segmentation/openiti-mustasfa-shamela5459-istislah.json`: exact raw source spans,
  per-span hashes, page ranges, source quotations, stated scenarios, candidate facts and pending review.
- `corpus/records/openiti-mustasfa-shamela5459.jsonl`: five schema-valid masʾala records;
  excerpts are capped at 400 characters; receipts retain the complete spans and their context.
- `corpus/takhrij/istislah_furu.json`: five author-scoped annotations. `quantified_facts`
  explicitly names unsettled fields. Every completion must agree; existential agreement is insufficient.
- `corpus/typing/istislah-cases.json`: existing exported field types and `deduction.reach`
  give the stance comparison. `istislah` stays epistemic.
- `UsulTest/Takhrij.lean`: 31 generated author-case assertions in five conjunctive guards. The unchanged exhaustive mirror
  additionally checks 108 `istislah` and 162 `maqasid_tarjih` inputs, including all stances.

From `pipeline/`, run:

```sh
python -m usul_corpus.istislah_cases
python -m pytest -q tests/test_istislah_cases.py tests/test_takhrij.py tests/test_deduction.py tests/test_typing_export.py
```

To regenerate deliberately: `python -m usul_corpus.istislah_cases --write`, then
`python -m usul_corpus takhrij` and `python -m usul_corpus judgement`.
The new replay also runs in `make generated` and in pytest. Missing or substituted source bytes
fail; no witness cache absence turns these tests into skips. Run `make source-verify validate lean`
from the repository root for the broader gates.

## Remaining review

Review the segment boundaries, the candidate `irsal` readings and the treatment of unspecified
attributes. Consider whether the formal representation should encode tatarrus’s expressly unresolved
ijtihād status and the ship’s additional objection. Preserve the existing three policy points;
al-Ṭūfī remains future work. This is five selected examples, not complete chapter coverage.

## Validation on 2026-10-21

The 200 focused source/takhrīj/deduction/typing/roadmap/companion/judgement tests passed, including corruption regressions.
Registry and schema validation passed for all 53,673 records; roadmap consistency passed.
The repository-wide source gate failed closed on 23 unavailable witnesses, reporting 5,196
verified excerpt checks, 135 failed checks and 2,068 exclusions. The new al-Mustaṣfā receipts
are checked independently and do not skip. The initial full pytest attempt was stopped after
missing-witness failures. The local pinned Lean binary could not locate its application path. CI at `ed9d8a8` passed
`make lean` and the no-sorry gate, including the 270 M14 differential inputs and all 31
completion assertions. A subsequent guard-format repair keeps those assertions conjunctive
inside one guard per case, preserving the existing case-inventory contract; fresh CI is pending
for that formatting change. The broader local regression selection passed 4,433 tests before
that repair. The final source/guard/typing/companion/judgement selection passed 230 tests with one unrelated SWI-Prolog-dependent skip; six routing tests passed with one external-source test deselected. No new M14 source test skips.
The corpus CI job at that first head failed its initial integration step. Locally reproducing the guard inventory exposed the one-guard-per-case incompatibility; the new
conjunctive guards address the reproduced regression without weakening the inventory check.
