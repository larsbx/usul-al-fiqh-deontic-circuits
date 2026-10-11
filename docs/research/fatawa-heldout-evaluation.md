# Frozen fatāwā oracle evaluation, v1

Status: preparation only; **no held-out result exists yet**. The Arabic answer
LFS object is not available in the current execution environment. No cases have
been selected or annotated. No existing rules or tranche-1 scores were changed.

## Freeze and sampling

`corpus/fatawa/heldout/protocol.json` pins baseline commit, SHA-256 of rules,
Python scoring/mirrors, development annotations, sampler, and Arabic source
bytes. The freeze precedes new source inspection and annotation. Run:

```sh
python scripts/fatawa_heldout_sample.py \
  --answers data/islamqa/answers/islamqa-ar.jsonl.gz \
  --output corpus/fatawa/heldout/selection.json
```

The sampler checks every pin and rejects LFS pointers, duplicate answers and
existing output. It excludes all 53 development answers and explicit rule-source
answer IDs. Eligibility uses title/question keywords only. A fixed hash ranks
answers, and overlapping retrieval domains are assigned once by a second hash.
Select at most 20 answers per encoder, retain pool sizes and shortfalls, and keep
all cases from each selected answer in evaluation. This is a keyword-selected
challenge sample, not a representative sample of IslamQA or jurisprudence.
An assigned retrieval domain does not guarantee a valid case for that encoder.
Record exclusions and their reasons, including no encodable case, without
replacement after predictions are seen. Count selected answers, excluded
answers, cases and encoders separately. Future rule changes require a new,
answer-disjoint evaluation sample; this sample becomes development data.

## Annotation before predictions

For each case retain answer ID, canonical URL, snapshot, source attribution,
exact original Arabic ruling quotation and its field/character offsets, and
SHA-256 of the source field. Check exact substring equality without Arabic
normalization. Fact annotations also require exact supporting quotations and
scope/condition notes. Unknown facts stay unknown, never false by default.
Record annotator method, tool/version, timestamp and provenance; automated or
LLM-assisted labels remain `candidate`. Human review is a separate record with
reviewer identity and actual decision; never populate it automatically.

Seal the selection and annotation hashes before querying the frozen oracle.
Keep labels out of Prolog inputs: supply encoder and supported facts only.
Do not drop unsupported cases from the reported denominator. Preserve raw
predictions, rule fired, abstentions and annotation revisions. If annotations
are corrected after predictions, publish both the first-sealed and corrected
results with a reason for each revision. Exact Arabic passages and source data
stay in this private repository under its existing source policy.

## Evaluation and error review

Report each encoder's case/answer counts, oracle coverage, exact single-label
agreement over all valid cases and answered cases, and bank coverage/agreement.
Report candidate-label and actually human-reviewed strata separately. The text
classifier's 1,460-answer test result is not a Prolog result. Any uncertainty
estimate must resample answers, keeping their cases together.

For every abstention/disagreement, record supported evidence and one or more
review diagnoses: unsupported or missing fact; missing rule; representation or
segmentation error; candidate annotation error; or potential interpretive
difference. `Genuine legal interpretation difference` requires reviewed evidence
for both positions, not merely failure to agree. Audit negative premises in the
frozen rules: absence of `fault`, `bayyina`, or `muslim_buried` may decide cases
whose source leaves that fact unknown. Report this explicitly.

Keep the historical `hold`/`handToAuthority` equivalence as a separately named
legacy score; strict equality is the primary new single-label score. Neither
retaining property nor transferring it to officials should silently be declared
legally identical. Preserve the original 119/122 report unchanged.

## Set-valued representation: development analysis only

A finite set can represent expressly permitted alternatives for the **same
case, conditions, addressee and time**. Conditional branches and competing
reported scholarly opinions need tagged conditions/attributions, not a flat
union. A set label must have evidence for each alternative; absence of evidence
is not permission. No change to the legal kernel follows from this data format.

For a single prediction r and source alternatives S, `r in S` measures option
compatibility, not complete agreement. For a predicted set P, report exact
`P = S`, soundness `P subset S`, and completeness `S subset P` separately;
empty predictions abstain. A proposed set-producing oracle needs its own
version pin and a fresh answer-disjoint test after development.

The three existing gaps are development examples, not held-out evidence:

- 126387.f001: the recorded alternatives are charity, officials or announcement;
  adding these options cannot justify a finder-ownership prediction. Check the
  Arabic source and the distinctions from 126502 before assigning a label.
- 107436.f001: public expenditure versus return to an identifiable state owner
  suggests a missing context/rule or interpretive issue. A flat set alone is
  not an established repair.
- 287215.f002: holding a beneficiary's share or charity is a plausible explicit
  alternative set. Verify conditions and quotation in the Arabic source before
  treating the oracle's charity route as compatible.

These observations derive from the existing gap notes; source review and tests
of any representation change remain pending. Neither automatic predictions nor
candidate source labels are authoritative fatāwā or scholarly adjudication.
