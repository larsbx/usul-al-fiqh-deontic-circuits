# Usul.Cat.Interval in Plain English

Source: [`formal/lean/Usul/Cat/Interval.lean`](../../../../formal/lean/Usul/Cat/Interval.lean)

Many positions fix a range of rulings, not one. Treating each as a range keeps real ikhtilāf (disagreement), stops reporting false ones, and leaves pairwise disagreement as the complete test. On single rulings it finds exactly what `Usul.Cat.Sheaf` finds.

## 1. Spans

- **Span**: a nonempty range `[lo, hi]` on the chain ḥarām < makrūh < mubāḥ < mandūb < wājib, the order `Usul.Hukm` reads off each ruling's reward and liability for doing and leaving. A position can say "somewhere in here" without picking a point.
- **`point h`**: the span of exactly one ruling, the old point verdict.
- **Named spans**:

| Span | Rulings | What fixes it |
| --- | --- | --- |
| `permitted` | makrūh … wājib | «يجوز» (it is allowed): not ḥarām |
| `notObligatory` | ḥarām … mandūb | «لا يجب»: not wājib |
| `talabFil` | mandūb, wājib | a command (amr) whose strength is disputed |
| `talabTark` | ḥarām, makrūh | a prohibition (nahy) whose strength is disputed |
| `point .mubah` | mubāḥ | takhyīr, free choice |
| `any` | all five | the position fixes nothing |

| Theorem | Plain English |
| --- | --- |
| `mem_point` | A ruling is in `point h` ⟺ it is h. |
| `mem_permitted`, `mem_notObligatory` | The named spans are exactly "not ḥarām" and "not wājib". |
| `mem_talabFil`, `mem_talabTark`, `mem_takhyir` | The spans match the three modes of address in `Usul.Hukm`. |
| `mem_σ` | `Span.σ` gives the span for omitting the act. The ends swap, because omission reverses the scale. |

## 2. Meeting

- **Meets**: two spans share at least one ruling.

| Theorem | Plain English |
| --- | --- |
| `meets_iff_exists` | Spans meet ⟺ some ruling lies in both. |
| `meets_point` | Two single rulings meet ⟺ they are equal, so nothing the old checker accepts is lost. |
| `meets_σ` | Two positions on an act meet ⟺ their positions on its omission meet. |

## 3. Helly's theorem on a line

- **`maxLo`**: the highest lower end among a list of spans (ḥarām for an empty list).
- **`helly`**: if every two spans in a list meet, then `maxLo` lies in all of them. On a line, pairwise agreement is enough for agreement of the whole group. This is why disagreement can stay a pair of positions.

## 4. Gluing on finite sites

- **`IPatch`**: a named source with the situations it speaks to and a span at each.
- **`iobstructions`**: every (patch, patch, situation) where the two spans do not meet.
- **`IGlues`**: one ruling per situation that lies inside every patch's span.

| Theorem | Plain English |
| --- | --- |
| `iobstructions_nil_iff` | The checker returns nothing ⟺ every two patches meet wherever both speak. |
| `iglues_iff` | **Finite sheaf condition.** One consistent ruling exists ⟺ the checker returns nothing. Helly supplies the ruling. |
| `iobstructions_ofPatch` | **Conservativity.** On single-ruling patches the result equals `Sheaf.obstructions`, list for list. |

## 5. A takhrīj case: spans and suspensions

- **`stances`**: each reported position of a farʿ (derived case) becomes a patch. `none` is tawaqquf (suspension), and adds no patch.
- **`stances_glue_iff`**: the positions glue ⟺ every two rulings meet. A suspension never conflicts, and it is never read as mubāḥ.

## In one line

A position is a range of rulings. Positions agree when their ranges overlap, pairwise overlap is enough on a line, suspension is a gap rather than a ruling, and on single rulings nothing changes.
