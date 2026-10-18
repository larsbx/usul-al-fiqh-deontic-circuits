# UsulTest.Interval in Plain English

Source: [`formal/lean/UsulTest/Interval.lean`](../../../formal/lean/UsulTest/Interval.lean)

The checks show the range-valued checker fixing what the single-ruling checker misreads, while keeping every real disagreement. Each runs when the kernel builds.

## 1. Named spans

| Check | Plain English |
| --- | --- |
| `permitted` | makrūh is inside "allowed"; ḥarām is not. |
| `talabFil` | mandūb and wājib are inside a command of disputed strength; mubāḥ is not. |
| `σ talabFil` | Omitting a commanded act lands in ḥarām … makrūh. |

## 2. False ikhtilāf

| Check | Plain English |
| --- | --- |
| `positions [mubah, mandub]` | Forced to single rulings, «يجوز» (as mubāḥ) and «يستحب» are reported as a disagreement. |
| `stances [permitted, point mandub]` | As ranges, they agree: mandūb is allowed. |

## 3. Real ikhtilāf is kept

- wājib against mandūb.
- A command against a prohibition, both of disputed strength.
- «يجوز» against ḥarām.

## 4. Suspension

| Check | Plain English |
| --- | --- |
| `stances [none, point haram]` | Tawaqquf beside a prohibition is no disagreement. |
| `positions [mubah, haram]` | Encoding the suspension as mubāḥ would have reported one. |

## 5. Helly and conservativity

- "Allowed", "commanded" and "not wājib" pairwise overlap, and all three contain mandūb (`maxLo`).
- On single-ruling positions the range checker returns exactly the old checker's list.

## In one line

The tests pin the two errors that ranges fix (false disagreement, suspension read as permission) and the two things they must not change (real disagreement, single-ruling results).
