# scripts.ExportAgency in Plain English

Source: [`formal/lean/scripts/ExportAgency.lean`](../../../formal/lean/scripts/ExportAgency.lean)

This executable evaluates every input of the finite joint-agency transition model and prints
the resulting transition table as CSV. It is used to compare Lean with the independently written
Quint model.

## 1. Output

The header is exactly `config,state,event,next`. The following **13,312 rows** enumerate four
configuration codes, 256 raw state codes, and thirteen event codes in numeric order. A successor
of `-1` means that the event is disabled; every other result encodes the unique successor state.

The comparison includes malformed but representable raw states, such as knowledge before
revocation. `Usul.Agency` separately proves that such states cannot be reached from the initial
state. Including them makes the relation comparison exhaustive over the whole wire domain.

## 2. Running it

From `formal/lean`, first build the imported module and then run the exporter:

```sh
lake build Usul.Agency
lake env lean --run scripts/ExportAgency.lean
```

| Definition | Plain English |
| --- | --- |
| `main` | Prints the CSV header, loops over the complete finite input domain, evaluates `Usul.Agency.transitionCode`, and prints each outcome. |

The state/configuration/event bounds and encoding round trips are proved in
[Usul.Agency](../Usul/Agency.md). Agreement of the exported executable results checks finite
conformance. It does not prove the correctness of the source interpretation, the compiler and
runtime implementations, or an application built on top of the model.
