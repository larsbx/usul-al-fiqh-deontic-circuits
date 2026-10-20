# scripts.ExportTypes in Plain English

Source: [`formal/lean/scripts/ExportTypes.lean`](../../../formal/lean/scripts/ExportTypes.lean)

Lean is the authority for the type system of situations and encoders. This script reads that type system straight from Lean's own declarations and writes it out as Prolog facts, so the Prolog typing rules always run on exactly what Lean defines.

## 1. What it produces

The output is `examples/v41_types.pl`. The Prolog rules in `examples/v41_typing.pl` run on it. The file is regenerated and compared in CI, so a stale copy fails the build.

Each fact kind:

- **`qaida_type(T, Doc)`**: one per structure in `Usul.Typing.Qaida`, with its docstring. The docstring is the qāʿida's (legal maxim's) statement.
- **`type_extends(T, P)`**: a qāʿida type that builds on another (for example, Q52 extends Q11).
- **`type_field(T, F, LeanType)`**: each fact a qāʿida type declares itself, with its Lean type.
- **`type_value(LeanType, C)`**: the possible values of each enumerated type a field uses. `Option` wrappers are stripped first.
- **`encoder_type(E, Out)`**: each typed encoder (a `Typed Situation Out`) and the ruling type it returns.
- **`encoder_reads(E, I, F)`**: the facts each encoder reads, numbered in order.
- **`implies(R, Premises, Consequents)`**: each `Implication` between facts (from `Usul.Typing.Relations`), as lists of `Field-Value`.

## 2. How it reads Lean

| Definition | Plain English |
| --- | --- |
| `snake`, `atom` | Turn a Lean name into a Prolog atom: `trustLoss` becomes `trust_loss`, matching the Python encoder names. |
| `quoted` | Quote a string safely for Prolog (escapes, newlines removed). |
| `isParent` | Tell a link to a parent structure (such as `toYaqin`) apart from a real fact field. |
| `reads` | Walk an encoder's elaborated term and collect, in order, every situation field it projects. Parent links are skipped. |
| `fieldPairs` | Decode a literal list `[(field, b), …]` inside an `Implication` into (field name, Boolean) pairs. |
| `pairs` | Print those pairs as a Prolog list. |
| `run_meta` block | Scan the environment, sort names, emit every fact kind above and write the file. |

Values of enumerated types are found by asking Lean which constructors the type has, not by guessing from names. Encoder reads come from the compiled term, not from source text.

Run it from `formal/lean` with `lake env lean scripts/ExportTypes.lean`.

## In one line

The Prolog mirror of the type system is generated from Lean's own kernel declarations, so the two cannot drift apart without CI noticing.
