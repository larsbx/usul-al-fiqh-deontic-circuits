# Sheaf Obstruction Fixtures

## Purpose

This note records the first concrete fixture layer after the v38 contextual affect-deontic bridge. The v38 bridge defines how ADQ-shaped facts can constrain local paths. The v39 fixtures make the sheaf-style language testable by adding small worlds, paths, local sections, gluable cases, and obstruction records.

The fixture implementation is now split by concern. The original public path remains as a compatibility aggregator.

## Companion files

```text
examples/v39_affect_concern.pl
examples/v39_temporal_concern.pl
examples/v39_sheaf_concern.pl
examples/v39_sheaf_obstruction_fixtures.pl   # aggregator only
```

Related architecture note:

```text
docs/architecture/separated-concerns.md
```

## Boundary

These fixtures are not source-derived fiqh claims. They are executable design probes. Their job is to verify that the kernel can distinguish:

- valid contextual realization;
- forbidden affect realization;
- missing required affect realization;
- anti-pair displacement;
- outside-taklif somatic panic;
- deliberately generated operator conflict.

The fixture facts may later be replaced by canonical imports from the ADQ bundle, but the expected obstruction categories should survive that migration.

## Concern ownership

| Concern | File | Owns | Does not own |
|---|---|---|---|
| Affect | `examples/v39_affect_concern.pl` | ADQ-shaped `deontic_obligation/6`, `deontic_anti_pair/4`, and local `ctx_affect/6` observations | path topology or gluing |
| Temporal/path | `examples/v39_temporal_concern.pl` | `ctx/3`, `path_realizes/4`, and `path_obligation_scope/4` | hukm/operator meaning or obstruction |
| Sheaf/gluing | `examples/v39_sheaf_concern.pl` | `local_section/3`, compatibility, world/path gluing, obstruction, and fixture expectations | source facts or temporal topology |
| Aggregator | `examples/v39_sheaf_obstruction_fixtures.pl` | stable load target and smoke-query comments | any domain facts |

## Fixture worlds

| World | Intended behavior |
|---|---|
| `w_allah_fear` | `khawf` toward Allah with comparative strength condition should glue. |
| `w_other_fear_defect` | `khawf` toward other-than-Allah when it displaces taqwa should emit forbidden-path obstruction. |
| `w_rahmah_balance` | `qunut` without `raja` should emit forbidden and anti-pair style obstruction. |
| `w_yusuf_brothers` | action-guiding `hasad` toward a creation blessing should emit forbidden-path obstruction. |
| `w_involuntary_panic` | panic-grade somatic khawf with outside-direct-taklif control status should not create direct path liability. |
| `w_fixture_conflict` | artificial same-scope `o`/`f` conflict should fail closed through `world_obstruction/2`. |

## Gluing vocabulary

The sheaf concern introduces the following finite sheaf-style predicates:

```prolog
local_section(World, Agent, Section).
section_conflict(Section1, Section2, ConflictKind).
world_obstruction(World, Reason).
path_obstruction(World, Path, Reason).
world_gluable(World).
path_gluable(World, Path).
```

This keeps the architecture finite and inspectable. A world glues only when active local sections do not conflict. A path glues only when the world glues and the v38 affect-path filter accepts the path.

## Why fixture conflicts are useful

The generated conflict facts remain in the affect concern:

```prolog
deontic_obligation(test_conflict_affect, test_object, all_mukallafin,
    o, unconditional, fixture(wajib_side)).

deontic_obligation(test_conflict_affect, test_object, all_mukallafin,
    f, unconditional, fixture(haram_side)).
```

They are intentionally not claims about the source corpus. They prove that the gluing layer can reject a same-scope incompatible operator pair instead of silently accepting inconsistent sections.

## Expected smoke queries

The sheaf concern records named fixture expectations such as:

```prolog
fixture_expectation(allah_fear_path_glues,
    query(path_gluable(w_allah_fear, path_allah_fear_ok)),
    expect_true).
```

## Executable vectors

`tests/run_all.sh` runs in CI (`.github/workflows/fixtures.yml`) and has three stages:

| Stage | File | Fails when |
|---|---|---|
| Runner self-tests | `tests/test_fixture_runner.pl` | the runner passes or skips a wrong, raising, unknown-kind, duplicate, or premise-free vector |
| Fixture vectors | `tests/run_fixture_expectations.pl` | any `fixture_expectation/3` vector fails |
| Guard mutants | `tests/mutation_test.sh` | disabling a kernel guard leaves every vector green |

Kinds are `expect_true` (the query succeeds) and `expect_false` (the query fails finitely).

A query over a world, agent, or fact that does not exist fails trivially, so an `expect_false` vector must declare at least one `fixture_premise(Name, query(Premise))`. Every premise must hold before the vector is judged. This makes a negative vector fail if its data disappears, instead of passing vacuously.

Each implemented guard is pinned from both sides. The guard-withdrawal worlds below remove exactly one lifting condition from an existing world:

| Guard | Positive vector | Withdrawal world / negative vector |
|---|---|---|
| capacity (`under_taklif_control/1`) | `yusuf_brothers_hasad_blocks` | `w_involuntary_panic`: `involuntary_panic_lifts_no_section` |
| conditional modality | `other_fear_displacing_taqwa_blocks` | `w_other_fear_no_displacement` |
| comparative modality | `allah_fear_with_precedence_lifts_obligation` | `w_allah_fear_no_precedence` |
| subject (`subject_matches/2`) | `subject_scoped_fact_lifts_inside_subject` | `w_subject_outside` |
| same-scope operator conflict | `operator_conflict_emits_obstruction` | `distinct_affects_do_not_conflict` |
| obligation discharge | `qunut_without_raja_emits_missing_required` | `raja_path_has_no_missing_required` |

`test_scoped_affect` / `test_subject_class` is a fixture fact like the conflict pair. It is not source-derived. It exists because every ADQ-shaped fact is addressed to `all_mukallafin`, which would leave the subject guard untested.

Every guard in `tests/mutation_test.sh` is killed by at least one vector.

## Promotion path

1. ~~Convert `fixture_expectation/3` into executable tests.~~ Done, see *Executable vectors*. Generated Ash fixture tests remain open.
2. Add a canonical import adapter from accepted ADQ facts into the v38 predicates.
3. Replace artificial sample facts with fixture bundles generated from canonical JSON.
4. Keep affect import, temporal case fixtures, and sheaf obstruction checks independently replaceable.
5. Add negative tests for tier quarantine, alias gluing failure, and object collision. These need new obstruction emitters. Subject and modality guards are covered by withdrawal vectors; the named `subject_collision` and `modality_unsatisfied` obstruction records are not emitted yet.
6. Preserve the rule that LLM text can propose fixture candidates but cannot turn them into accepted normative facts without deterministic review.
