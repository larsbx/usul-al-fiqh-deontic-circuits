# Usul.Fixtures.TypingData in Plain English

Source: [`formal/lean/Usul/Fixtures/TypingData.lean`](../../../../formal/lean/Usul/Fixtures/TypingData.lean)

This generated module preserves the complete exported qāʿida types, field declarations, inheritance edges, encoder requirements, and implication metadata, together with the explicit fixture situations. It contains data, not precomputed query answers.

The strict data translator rejects unsupported declarations, duplicates, dangling type or encoder references, and gaps in encoder read indices. Source hashes and exact output regeneration bind these values to the committed Prolog export. Native Lean functions in the Typing fixture model evaluate routing and relation closure over this data; preserving a source label does not independently verify its interpretation.
