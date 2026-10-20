# UsulMathlib in Plain English

Source: [`formal/lean-mathlib/UsulMathlib.lean`](../../formal/lean-mathlib/UsulMathlib.lean)

The entry point of the Mathlib package. It lives beside the kernel, not inside it, so the kernel and its CI stay free of Mathlib.

## What it imports

- **`UsulMathlib.Hukm`**: the ruling scale and its spans, read as Mathlib orders and intervals.

## In one line

One import that shows the kernel connects to Mathlib at the pinned revision.
