# Publication files

[Read the manuscript](../ida-guarded-context-preservation.md),
[download the PDF](ida-context-abstraction-paper.pdf), or edit the
[LaTeX source](ida-context-abstraction-paper.tex).

The Markdown and LaTeX editions contain the same argument and claim boundaries.
Keep both editions aligned when changing the paper. The PDF is generated from
the LaTeX edition and is not an independent proof receipt.

## Rebuild the PDF

With a standard TeX Live installation providing `pdflatex`, `lmodern`,
`microtype`, `amsmath`, `amsthm`, `booktabs`, `tabularx`, `fancyhdr`, and
`hyperref`, run from this directory:

```sh
pdflatex -interaction=nonstopmode -halt-on-error ida-context-abstraction-paper.tex
pdflatex -interaction=nonstopmode -halt-on-error ida-context-abstraction-paper.tex
```

Check the final log for unresolved references and layout warnings, then render
and inspect all pages. Commit the `.tex` and `.pdf`, not temporary LaTeX outputs.

## Recheck the proofs

The source modules live in the repository's normal Lean package:

- [Generic criterion and separate mathematical controls](../../../formal/lean/UsulTest/IDAGuardedContext.lean).
- [Native omission evaluator and guard witnesses](../../../formal/lean/UsulTest/IDAOmissionGuardWitness.lean).
- [Conditional semantic adequacy of omission observations](../../../formal/lean/Usul/Typing/IDAOmissionSemantics.lean).
- [Independent contracts and semantic necessity controls](../../../formal/lean/UsulTest/IDAOmissionSemantics.lean).

From the repository root, `make lean` builds the pinned package, inventories
compiled axiom dependencies, and checks the entries in
[`formal/lean-proof-claims.json`](../../../formal/lean-proof-claims.json).
The revision-bound receipt is `.cache/lean-axioms/core.json`.

The manuscript's original November 11 local audit, the first publication's
successful hosted checks, and the semantic extension's verification are
recorded separately. The conditional adequacy theorem is compiled; applying
it requires an independently justified event history and report-to-history
assumptions. It does not by itself verify a real observation mechanism or
establish a juristic ruling.
