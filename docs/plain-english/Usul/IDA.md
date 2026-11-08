# Usul.IDA in Plain English

Source: [`formal/lean/Usul/IDA.lean`](../../../formal/lean/Usul/IDA.lean)

This foundation adds algebraic operations to the existing five ruling values and
separately combines two required partial answers about the same question. It proves
properties of those operations. Source interpretation, evidence admission, and an
application's mapping into the model remain obligations outside this module. The
[foundation guide](../../research/ida-foundation.md) records the acceptance boundary.

## 1. Algebra on the existing carrier

The order is `haram < makruh < mubah < mandub < wajib`, inherited from
[Usul.Hukm](Hukm.md) and its doing/omitting consequences. `meet` selects the lower
bound and `join` the upper bound. These are algebraic operations on that order;
they do not choose between competing source readings or school positions.

| Operation or law | Plain English |
| --- | --- |
| `meet`, `join` | Compute the greatest lower bound and least upper bound of two values. |
| Commutativity, associativity, and idempotence | Order, grouping, and duplicate values do not change the respective operation's result. |
| Absorption and distributivity | The two operations satisfy the bounded distributive lattice laws. |
| Bottom and top | `haram` is the least value and `wajib` the greatest in this order. |
| `sigma` | Reuses the omission duality: `haram` swaps with `wajib`, `makruh` with `mandub`, and `mubah` stays fixed. |
| Omission laws | Applying `sigma` twice returns the original value; it reverses the order and exchanges meet with join. |

Applying the omission operation to an actual case still requires its action,
opportunity, time, and source profile to be established.

## 2. Known partial answers and scope

`HukmSet` records membership of each of the five values. A `Constraint` includes a
proof that its set is nonempty. A known answer may therefore be a singleton or a
broader set of remaining possibilities. `{mubah}` is a specific answer; the explicit
all-five set is a supplied but maximally broad constraint. `Input.noRuling` supplies
no known answer, and `Input.suspended` separately records suspension.

Every `Key` contains seven coordinates: question, subject, target, context, time,
profile, and profile version. All must match. The target now contains a complete checked expression; the
other six coordinates remain opaque natural-number identifiers. A performed
act includes its qualified operation, complete signature, and named typed
operands. An omitted act also specifies its opportunity. An affect describes
its quality and typed object. None of these structural checks authenticates
the source or establishes contextual applicability.

## 3. Conjunction of two required premises

`combine` applies the following cases in order:

| Condition | Result |
| --- | --- |
| The keys differ in any coordinate | `outOfScope` |
| Keys match and either input is suspended | `suspended` |
| Keys match, neither is suspended, and either lacks a ruling | `noRuling` |
| Both inputs are known and their sets have a common member | `known`, containing exactly their intersection |
| Both inputs are known and their sets have no common member | `conflict` |

Both premises are required. Missing information cannot be dropped as though it
were the all-five set. A suspension cannot be discarded to recover the other
answer, and a scope mismatch takes precedence even over suspension or absence.

| Theorem | Plain English |
| --- | --- |
| `outOfScope_iff`, `inScope_iff_all_fields` | The scope guard succeeds exactly when all seven coordinates agree. |
| `known_requires_two_known` | A known result requires two known inputs with equal keys and is their exact intersection. |
| `known_result_subset_both`, `known_result_nonempty` | A known output preserves both constraints and contains at least one value. |
| `missing_left_not_known`, `missing_right_not_known` | A missing required premise cannot produce a known result. |
| `suspended_left_preserved`, `suspended_right_preserved` | With matching keys, either suspended premise keeps the result suspended. |
| `conflict_iff_no_common_ruling` | Two known, same-key premises conflict exactly when they share no ruling value. |
| `unknown_ne_all`, `unknown_ne_mubah`, `all_ne_mubah` | No ruling, the explicit all-five constraint, and a specific mubāḥ answer are distinct. |

These scope and conjunction theorems range over arbitrary keys and typed inputs.
They establish the stated computation, without certifying the inputs' interpretation.

## 4. Serialization and independent comparison

The checked wire interfaces use carrier tags `0..4`, nonempty-set masks `1..31`,
and separate tags for no ruling (`0`), suspension (`32`), conflict (`33`), and
out of scope (`34`). Carrier and partial-answer tags belong to different interfaces.
The numerical tags are serialization choices, not normative scores. Out-of-range
codes are rejected, and mask zero cannot construct a known empty set.

[UsulTest.IDA](../UsulTest/IDA.md) checks the wire cases;
[UsulTest.IDAContracts](../UsulTest/IDAContracts.md) fixes the required proposition
types. [scripts.ExportIDA](../scripts/ExportIDA.md) emits the declared finite family
for independent Quint comparison. That family checks all 33 inputs on each side
for eight key variants; it does not enumerate every pair of arbitrary keys.

## 5. Structured target contracts

| Theorem or group | Plain English |
| --- | --- |
| operation_wellFormed_parameter_roles / unique_roles | Declared roles have nonempty names and cannot be duplicated. |
| action_wellFormed_operation / signature / references | Operands fit the complete supplied signature and every reference has a qualified nonempty name. |
| action_eq_iff_fields | Equality preserves both operation and ordered operands. |
| opportunity_wellFormed_bounds / omit_wellFormed_iff | An omission names an action and a strictly increasing opportunity interval on a named clock. |
| perform_ne_omit / perform_ne_affect / omit_ne_affect | The three target forms remain distinct. |
| perform_eq_iff / omit_eq_iff / affect_eq_iff | Equality preserves all data carried by each constructor. |
| target_eq_iff_expression_eq | Proof objects do not create hidden identity differences. |
| target_validate_eq_some_iff / eq_none_iff / roundTrip | Structural checking preserves the supplied expression exactly and rejects precisely malformed expressions. |
| target_mismatch_outOfScope | Different target expressions prevent conjunction, regardless of premise status. |
| known_result_same_target | Every known conjunction result preserves the complete target on both sides. |

The symbols and operation signatures are supplied descriptions. Source/profile
admission, reference resolution and real-world identity remain separate.
Control and intention stay in context. Opportunity clock positions are numeric
quantities; the target itself is structured data. The 28 fixture numbers select
explicit test expressions only. Fixture-boundary tag 35 denotes a rejected
target shape and is not a ruling or a Result value.
