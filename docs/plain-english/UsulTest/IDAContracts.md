# UsulTest.IDAContracts in Plain English

Source: [`formal/lean/UsulTest/IDAContracts.lean`](../../../formal/lean/UsulTest/IDAContracts.lean)

This module states 84 required propositions explicitly and supplies each proof
by directly referencing its corresponding implementation theorem. The contracts
keep the promised statements fixed: retaining a theorem's name while replacing
its type with a weaker proposition must fail to compile this module.

## 1. What the contracts require

| Group | Contracts | Plain English |
| --- | ---: | --- |
| Algebra and omission | 27 | Meet and join have the stated bounds and lattice laws; the existing omission operation is involutive, reverses the order, and exchanges the two operations. |
| Scope, required premises, partial answers, and decoding | 20 | All seven key fields matter; known outputs require both known premises and their nonempty intersection; missing, suspended, broad, and specific answers stay distinct; specified decoding bounds hold. |
| Finite wire format and scenarios | 12 | Carrier tags, complete declared input domains, scope priority, conjunction cases, and listed out-of-range rejections retain their exact statements. |
| Structured targets | 20 | Supplied signatures, typed operands, opportunity bounds, constructor separation, complete payload identity, exact validation, and conjunction target preservation. |
| Target fixture scenarios | 5 | Structural admission, positive reconstruction, represented distinctions, malformed targets and selector bounds. |

The first two groups refer to [Usul.IDA](../Usul/IDA.md); the third refers to
[UsulTest.IDA](IDA.md). Each witness is named `require_` followed by the required
theorem's qualified name with underscores.

## 2. Why the types are explicit

An axiom audit can show that a compiled declaration uses only the allowed logical
foundations. It cannot by itself show that the declaration still states the intended
property. These independently written proposition types check that additional
requirement. They are not inferred aliases, and their proofs are not independent
reproofs that would keep passing after the implementation theorem disappeared.

The [IDA gate](../../research/ida-foundation.md#reproduce) checks the required
declaration inventory, compiles these witnesses, audits the dependency closure, and
exercises negative controls. A compiled target control also replaces the target mismatch conclusion with
True and checks that the fixed witness rejects it. Acceptance remains scoped
to this foundation and its structured target representation.
These contracts do not certify source interpretation, evidence admission, or the
repository's other integration gates.
