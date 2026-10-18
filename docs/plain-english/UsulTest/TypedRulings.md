# UsulTest.TypedRulings in Plain English

Source: [`formal/lean/UsulTest/TypedRulings.lean`](../../../formal/lean/UsulTest/TypedRulings.lean)

Rulings that look alike but have different JSON types stay different rulings. A Boolean `false`, the number `0` and the text `"false"` never merge, so a proof cited for one never counts for another.

## 1. The problem guarded against

The Python pipeline writes each ruling as a canonical JSON key, passed to Lean as a string. A careless encoding could let `true` and `1`, or `1` and `"1"`, collapse into one key. Then two sides of a dispute, or two attributions, would silently become one.

- **`pairs`**: five fixed pairs that must stay apart: `false`/`0`, `true`/`1`, `false`/`"false"`, `true`/`"true"`, `1`/`"1"`.

The expectations are written by hand, independent of Python's resolver.

## 2. The checks

| Check | Plain English |
| --- | --- |
| `pairs.all (a != b)` | Each pair really is two distinct keys. |
| `Tarjih.top [(a, .qiyas)] b == none` | A proof cited for `a` gives `b` no tier at all. Evidence does not leak across the pair. |
| `Reconcile.prevail [(a, .nass), (b, .nass)] == none` | Two sides, each with one naṣṣ (text) label: neither prevails. They are counted as two equal sides, not one side with two labels. |
| `reconcile … [(a, .qiyas), (b, .qiyas)] == .tawaqquf` | Under every policy (`strict`, `sources`, `applying`, `all`), two equal qiyās proofs with no advantage end in tawaqquf (suspension of judgement). |
| `reconcile … [(a, .zanni), (b, .qiyas)] == .tarjih a` | Under every policy, a probable text (ẓannī) beats a qiyās, so tarjīḥ (preference) picks `a`. |

Each check runs over all five pairs.

## In one line

Type-distinct rulings stay distinct all the way through tarjīḥ and reconciliation: a tie stays a tie, a stronger proof wins, and no proof is credited to the wrong side.
