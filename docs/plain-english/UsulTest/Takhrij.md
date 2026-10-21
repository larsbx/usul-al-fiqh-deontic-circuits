# UsulTest.Takhrij in Plain English

Source: [`formal/lean/UsulTest/Takhrij.lean`](../../../formal/lean/UsulTest/Takhrij.lean)

The generated suite checks candidate case annotations against their formal readings.
It contains 1,227 guards. A mismatch fails the Lean build; a passing guard does not
establish source interpretation, doctrinal consensus or human review.

An ordinary annotation provides all of its encoder’s facts. A `derivable` case may instead
explicitly list `quantified_facts`: every typed completion of those unsettled fields must yield
the stated result. No completion is asserted as a source fact. This is used for the M14
al-Mustaṣfā examples, whose five candidate records yield 31 author-scoped guards. The two
existing maqāṣid tarjīḥ cases remain, for 33 guards on `Usul.Readings.Maqasid`.

`genuine_ikhtilaf` annotations retain competing positions and check the recorded position
without resolving their dispute. Recorded encoding errors use inequality guards. Gap cases
are not silently supplied with missing facts. Second encoder annotations remain in
`UsulTest.TakhrijCo`.

Regenerate with `python -m usul_corpus takhrij` from `pipeline/`.
The Python mirror is separately checked against Lean over every encoder input in
`UsulTest.TakhrijMirror`. See [M14’s source-case audit](../../m14-istislah-cases.md).
