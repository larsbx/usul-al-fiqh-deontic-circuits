# Usul.Typing.IDAOmissionEventBridge in Plain English

Source: [`formal/lean/Usul/Typing/IDAOmissionEventBridge.lean`](../../../../formal/lean/Usul/Typing/IDAOmissionEventBridge.lean)

The bridge compares an omission observation batch with a separate finite event
checkpoint. The synthetic checkpoint is independently verifiable by comparing
its entire typed value with a pin fixed by the fixture before supplying reports.
No production event source in this repository was found with the required
exact scope, two-mode capture, or cutoff guarantees. The signed observation
catalog authenticates submitted batch bytes. The agency and case workbench
traces replay configured or synthetic evidence. Neither supplies an independent
capture history for this scope.

## Evidence and checks

A checkpoint carries a source ID, revision, exact native omission scope,
recording cutoff, exclusive occurrence watermark, and ordered rows. Each row
has a source-local ID, a mode, an occurrence time, and a source capture time.
Every row must lie in the scope's half-open opportunity, with occurrence no
later than capture and capture no later than the cutoff. The watermark must
reach the opportunity's closing time and be at most the recording cutoff.
The trusted input is the active exact checkpoint or no active checkpoint.
Rotation replaces the pin. Revocation removes it in this bounded model.

The checker requires a timely, exact-content report for each row, with
occurrence ≤ capture ≤ report recording ≤ cutoff. Each report that would
match anywhere in the full opportunity at that cutoff must have a supporting
row. Because this check uses the full opportunity, the resulting soundness
premise works for any effective time. The checker also rejects visibly
malformed in-scope reports. Report order and repeated reports do not change
the existential meaning. Row IDs must be unique, but two distinct IDs can
project to the same modeled event content. The native report wire cannot
establish per-ID provenance or multiplicity.

| Theorem | Conclusion |
|---|---|
| `check_correspondence` | A successful check fixes the exact active checkpoint, proves `Exhaustive` and `SoundFor` for its rows, and excludes malformed visible in-scope reports. |
| `exhaustive_of_capture` | If the checkpoint captured every qualifying event of a separate history, the verified report list is exhaustive for that history. |
| `sound_of_capture` | If the checkpoint's event projections are true in a separate history, matching reports are sound for that history. |
| `covered_no_completion_iff_of_capture` | With both capture assumptions, effective closure and native structural coverage, the existing evaluator returns a covered negative exactly when the separate history has no qualifying event. |
| `wire_covered_no_completion_sound` | A covered native wire review and a successful check of the same decoded view prove exact current snapshot resolution and absence in the checkpoint. Extending absence to a separate history requires capture completeness alone. |

The native coverage claim continues to check its own scope, modes, and
recording bounds. The bridge never creates or authenticates that claim.
`checkView` consumes the existing typed view. The current signed host
adapter remains an independent byte-authentication stage. A caller combining
them must use one authenticated canonical payload for both the typed review
and the bridge, with the same resolved snapshot and current source pin.

## External assumptions and next interpretation steps

- **Authority and sealing.** A live service would need a separately authorized
  source and an authenticated current commitment to its complete ordered
  snapshot and watermark, bound to the exact scope and clock. It must protect
  against truncation, rollback and equivocation and resolve revocation at
  the declared review perspective. Exact equality to a synthetic pin does
  not prove any of those operational properties.
- **Capture and time.** A real-world negative needs evidence that all eligible
  occurrences, direct and alternate, reached the checkpoint, including a
  justified treatment of delayed capture and outages. The converse needs
  evidence that checkpoint rows faithfully represent real occurrences.
  To claim what was available as of a cutoff, independently bind the
  recording ticks to receipt of the exact reports. Comparing tick values
  does not establish independently when they were assigned. The action,
  opportunity, parties, and clocks must also have the asserted meanings.
- **ACT-04.** Choose a versioned predicate and typed ground arguments that
  explicitly identify the observed fact. Bind the ground inquiry to the
  same snapshot, including the accountable person and performer, definition
  and digest, occurrence, clock, opportunity, effective time, recording
  perspective, and profile. Prove that the selected `Semantics.History.truth`
  assignment agrees with qualifying event existence in the intended event
  history at that scope. Prove preservation of that binding under ACT-02
  substitution and grounding. An incomplete observation cannot supply the
  negative Boolean fact.
- **Affect.** `Substitution.Inquiry.toGround` currently constructs only
  performance and omission. Affect transport needs a typed inquiry branch,
  a versioned quality, a typed referent, and the subject and contextual
  coordinates retained under grounding and substitution. It also needs its
  own interpretation and evidentiary correspondence. A completion checkpoint
  supplies no premise about an affective state.

The result supplies a bounded observation fact for review. Capacity, case
admission, and juristic judgment remain separate applications.
