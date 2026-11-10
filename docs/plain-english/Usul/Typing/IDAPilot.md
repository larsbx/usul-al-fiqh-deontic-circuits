# Usul.Typing.IDAPilot in Plain English

Source: [`formal/lean/Usul/Typing/IDAPilot.lean`](../../../../formal/lean/Usul/Typing/IDAPilot.lean)

The pilot runs the existing exact premise admission, then projects the
reports on the admitted destination snapshot. The rule requires a positive
support report and an explicit negative exception report. Opposing reports
for either query block the guard.

The history check uses the plan's destination valuation and premises. An
empty population or a population without a compatible history blocks the
result. A successful receipt carries the admission proof, exact snapshot,
guard check, and robust assessment. The soundness theorem applies to the
grounded conclusion when the destination premises hold.

The frame theorem preserves the guard result when its complete projected
dependencies are equal. A change to the snapshot still requires its own
admission checks.
