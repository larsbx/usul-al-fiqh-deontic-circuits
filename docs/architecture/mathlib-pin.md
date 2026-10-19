# Mathlib, pinned beside the kernel

The kernel (`formal/lean`) stays Mathlib-free, and `make lean` and CI never fetch Mathlib.
Mathlib is pinned in a sibling Lake package, `formal/lean-mathlib`. That package requires the
kernel by path, so work that needs Mathlib's order, lattice or category theory starts there.
It never starts in `usul`.

| Item | Pin |
|---|---|
| Lean toolchain | `leanprover/lean4:v4.34.1`, the same file as `formal/lean/lean-toolchain` |
| Mathlib | tag `v4.34.1`, commit `d13f23b723b8a846827a245b89c10fc7d3f11612` |
| Transitive packages | exact revisions in `formal/lean-mathlib/lake-manifest.json` (batteries, Qq, aesop, ProofWidgets, import-graph, LeanSearchClient, plausible, Cli) |

## Use

```
make lean-mathlib        # lake exe cache get && lake build, in formal/lean-mathlib
```

`lake exe cache get` downloads Mathlib's prebuilt `.olean` files for the pinned commit, so nothing
in Mathlib is compiled locally. The download unpacks to several GB under
`formal/lean-mathlib/.lake/`, which is git-ignored.

## The hook

`UsulMathlib.Hukm` shows that the bridge type-checks at the pin:

| Result | Statement |
|---|---|
| `LinearOrder Hukm` | the chain Ḥ < K < M < N < W from the kernel's own laws (`Hukm.le_total` …), with no rank behind it |
| `span_eq_Icc` | a kernel `Span` is `Set.Icc lo hi` |
| `meets_iff_Icc` | spans meet ⟺ their `Set.Icc`s intersect |

## Rules

1. Nothing under `formal/lean` imports `Mathlib` or `UsulMathlib`. The dependency points one way,
   so the kernel's proofs stay checkable without Mathlib.
2. Every module in `formal/lean-mathlib` has a plain-English companion, as the kernel's modules
   do. `pipeline/tests/test_plain_english.py` covers both roots.
3. Moving the pin means changing the toolchain in both packages together, setting `rev` to the
   matching Mathlib tag, and running `lake update` and `make lean-mathlib`.
