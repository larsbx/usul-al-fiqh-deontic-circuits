# Usul.Typing.IDAPilot in Plain English

Source: [`formal/lean/Usul/Typing/IDAPilot.lean`](../../../../formal/lean/Usul/Typing/IDAPilot.lean)

The pilot runs the existing exact premise admission, then projects the
reports on the admitted destination snapshot. The rule requires a positive
support report and an explicit negative exception report. Opposing reports
for either query block the guard.

Both the semantic assessment and report projection come from the type layer:
[`Usul.Typing.IDASemantics`](IDASemantics.md) and
[`Usul.Typing.IDAProjection`](IDAProjection.md). The pilot does not import their
downstream categorical adapters.

The history check uses the plan's destination valuation and premises. An
empty population or a population without a compatible history blocks the
result. A successful receipt carries the admission proof, exact snapshot,
guard check, and robust assessment. The soundness theorem applies to the
grounded conclusion when the destination premises hold.

The frame theorem preserves the guard result when its complete projected
dependencies are equal. A change to the snapshot still requires its own
admission checks.
