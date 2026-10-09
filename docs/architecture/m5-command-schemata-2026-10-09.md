# M5 command capabilities: Ibn al-Laḥḥām 43

This contribution makes four command questions expressible as **candidate capabilities**.
It does not select a preferred reading or revisit a live annotation. The aggregate remains
303 cases, coverage 0.980, madhhab coverage 0.659, zero encoding errors and six open gaps.
All four command gaps retain their original `missing_rule` records and `needs` values.

`Usul.CommandSchemata` supplies explicit reading parameters; Python encoders mirror them.
`unsettled` means the selected report supplies no answer to that branch. `notLiteral`
records denial of literal naming without inventing a positive figurative classification.
Command naming and the five-fold ruling of an act have separate types.

## Source contrasts and boundaries

The sole witness is `openiti-lahham-shamela8526`, the immutable OpenITI revision
`bae1fba53712c020fe43e3e60b37dfe61f2b64a8`, 722,414 bytes, SHA-256
`d1efbaa04ca15696f92db87137381a77415ca7b3dde39e105d8e503cdcc706b0`.
The full qāʿida spans pages 221–227. Evidence quotes, actual closing-page locators and
quote hashes are in `corpus/worklists/lahham_m5_commands_plan.json`.

| Case | Candidate capability | Preserved source contrast | Boundary |
|---|---|---|---|
| 43.f001, p224 | `command_nonverbal_usage` | The reported al-Qāḍī reading denies literal naming for writing and gesture; the Jāmiʿ writing argument supports the author's positive writing inference | Its positive inference supplies no gesture conclusion; that branch is `unsettled` |
| 43.f003, pp224–225 | `command_prophetic_act_usage` | Abū al-Barakāt's figurative report, the named Mālikī/Shāfiʿī literal report and the author's conditional inference are separate inputs | The author inference requires established imitation; naming an act does not derive its obligation |
| 43.f004, p225 | `command_obligation_status` | Al-Qāḍī permits reinterpretation of the three explicit expressions; Abū al-Barakāt treats them as naṣṣ | The question presupposes the obligation default. An admissible qarīna is an input. Neither its admissibility nor a preferred reading is inferred |
| 43.f007, pp226–227 | `command_intended_usage` | Recommendation and permission naming are disputed; the two al-Qāḍī permission reports conflict | The question's first command position and intended ruling are given. Partial reports stay partial; naming preserves the intended ruling |

The three explicit obligation expressions are an unqualified threat, the wujūb label and
the farḍ label. Bare commands retain `Dalala.amrStatus` under either modeled reading.
Ibn ʿAqīl's more limited report is not extended to all three expressions. The locked
witness's suspicious `القواعد` and `خقيقة` spellings remain unchanged in quotations;
interpretation of these spellings remains visible for source review.

For 43.f007, the Karkhī/Rāzī report concerns recommendation and the Abū al-Barakāt
report concerns permission. The capability supplies no answer for their other branches.
The later al-Qāḍī argument's permission inference is kept apart from the earlier literal
permission report. Both preserve the given permission ruling. No reconciliation or
scholarly acceptance is implied by executable outputs.

## Provenance and governed scope

The plan pins the full witness, the committed source-record file, four complete original
case receipts and their Arabic excerpt hashes. Validation compares each live case with
its original receipt and rejects an unrecorded reinterpretation or status promotion.
The historical case locators retain the parent's opening page, p221. Evidence locators
record the actual later pages without rewriting those historical records.

Four linked interpretation questions stay `open`; the plan and selected readings stay
`candidate`. The existing dossier, review registers, M8 receipts and revision ledger are
preserved. A future case revisit must record its own justification and provenance rather
than replacing these original receipts. The new encoder names deliberately do not claim
to satisfy the old gap requirements.

The other two live gaps also remain unchanged: Ibn al-Laḥḥām 52.f007 supplies no
transmitted ruling, and Ibn Rajab 22.f000 combines agreed and disputed cases requiring
segmentation or additional facts. A capability fixture is not an annotated case and does
not increase the 303-case denominator. Derivability under a candidate encoding is not an
accepted fatwā.

## Replay and checks

From the repository root:

```sh
cd pipeline
python -m usul_corpus m5-commands --fetch-source
cd ..
make test validate generated lean
```

The source replay restores the pinned witness into cache without changing `lock.json`.
It checks the full bytes and hash, then finds every evidence quote inside qāʿida 43 and
checks its closing-page marker. It fails if the source is missing unless fetching is
explicitly requested, and rejects a changed download rather than repinning it. CI runs
this replay before corpus tests, so these source checks cannot silently skip in CI.

There are 30 source-backed contrast fixtures, 66 exhaustive new Python/Lean domain
comparisons, 22 independent Lean guards and general proofs of bare-command preservation,
conditional imitation and preservation of the given intended ruling. The generated
signature check covers the plan's Lean constants. Receipt mutation tests reject changed
hashes, missing cases, crossed review links, premature acceptance, unknown inputs and
the unsupported literal gesture conclusion.
