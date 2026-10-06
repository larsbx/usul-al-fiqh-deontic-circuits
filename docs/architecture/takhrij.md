# M4: the takhrīj suite

A formal reading is tested the way the jurists tested a qāʿida: against its furūʿ. Each case paragraph (`far` record) listed under a qāʿida is annotated with the facts the reading takes and the ruling the text states. The formal kernel then computes its own ruling, and the two are compared.

## Which furūʿ test which reading

The roadmap names Ibn al-Laḥḥām for M4. His rules, however, are almost all uṣūl proper (taklīf, the command, generality, particles), which belong to M5's inference schemata. What the kernel formalises today are al-Saʿdī's rules. Many of these are compressions of Ibn Rajab's *Taqrīr al-Qawāʿid*, sometimes nearly verbatim (Q45 ≈ Ibn Rajab 63, Q48 ≈ 103, Q50 ≈ 133, Q36 ≈ 26, Q35 ≈ 140, Q20 ≈ 106). So the first tranche tests each Saʿdī reading on the furūʿ Ibn Rajab derives from the corresponding qāʿida, and al-Saʿdī's generality rules (Q59/60) on Ibn al-Laḥḥām's furūʿ for qawāʿid 52–54. The rest of Ibn al-Laḥḥām follows with M5.

`pipeline/usul_corpus/takhrij.py` holds one table, `ENCODERS`, and everything else is derived from it. Each encoder gives:
- the Saʿdī rule and the qāʿida whose furūʿ test it;
- the fact fields and their domains;
- the Lean expression that computes the kernel's ruling;
- a Python mirror of that expression for annotators.

## Classes

| Class | Meaning | Checked by |
|---|---|---|
| `derivable` | the case falls under the rule, its deciding facts are the encoder's fields, and the kernel gives the text's ruling | `#guard expr == expected` |
| `genuine_ikhtilaf` | the text reports two or more positions; the kernel gives one of them (and `matches_madhhab` says whether it is the madhhab's) | `#guard expr == expected` |
| `encoding_error` | the case is fully expressible, but the kernel contradicts every stated position: a finding against the reading | `#guard expr != expected` |
| `missing_fact` | the ruling turns on a fact the encoder cannot express | — |
| `missing_rule` | the case is decided by a different principle | — |
| `segmentation_error` | the record is not a case (excluded from coverage) | — |

Coverage = (derivable + genuine_ikhtilāf) / (total − segmentation errors). As the roadmap requires, ikhtilāf cases count as recorded positions, not failures.

## Lean is the oracle, not the annotation

Annotation is LLM-assisted and stays `candidate`. Lean checks its claims at three levels:

- `UsulTest/TakhrijMirror.lean` guards every input of every encoder, so the Python mirror annotators compute with equals the Lean reading.
- `UsulTest/Takhrij.lean` guards each annotated agreement (`==`) and each recorded disagreement (`!=`). A case claimed derivable that the kernel does not derive fails the build.
- `check_case` rejects malformed annotations before generation: facts outside the domains, a class the kernel contradicts, or an ikhtilāf with fewer than two positions.

`python -m usul_corpus takhrij` regenerates both Lean files and `corpus/takhrij/report.json`. `test_takhrij.py` requires every furūʿ record of an annotated qāʿida to appear exactly once, and the generated files to be in sync.
