# Separated Concerns: Affect, Temporal Path, and Sheaf Gluing

## Purpose

This note records the repo boundary introduced after the v38 contextual bridge and v39 obstruction fixtures. The earlier fixture file proved the idea, but it mixed three concerns in one Prolog module:

1. affect-deontic facts and local affect evidence;
2. temporal/world/path fixture structure;
3. sheaf-style compatibility, gluing, and obstruction logic.

The repo should keep those concerns separate so future imports can replace one layer without rewriting the others.

## Concern 1 — affect-deontic kernel data

The affect concern owns ADQ-shaped local normative facts and affect observations:

```prolog
deontic_obligation(Affect, Object, Subject, Operator, Modality, Warrant).
deontic_anti_pair(Commanded, Forbidden, Object, Meta).
ctx_affect(World, Agent, Affect, Object, Evidence, ControlStatus).
```

It does **not** own path topology, action prefixes, gluing, or obstruction. It answers only: which affect/object/subject/modal facts and observed affect tokens are available?

Fixture module:

```text
examples/v39_affect_concern.pl
```

## Concern 2 — temporal/path execution context

The temporal concern owns finite worlds, context conditions, and path realization:

```prolog
ctx(World, Agent, Conditions).
path_realizes(Path, Agent, Affect, Object).
path_obligation_scope(Path, Agent, Affect, Object).
```

It does **not** decide whether a realized affect is forbidden, obligatory, or gluable. It only says what context and path data are present.

Fixture module:

```text
examples/v39_temporal_concern.pl
```

## Concern 3 — sheaf compatibility and obstruction

The sheaf concern owns finite local sections and gluing failure reports:

```prolog
local_section(World, Agent, Section).
section_conflict(Section1, Section2, ConflictKind).
world_obstruction(World, Reason).
path_obstruction(World, Path, Reason).
world_gluable(World).
path_gluable(World, Path).
```

It consumes the affect concern and temporal concern through the v38 bridge. It should emit explicit obstruction reasons rather than silently accepting inconsistent local sections.

Fixture module:

```text
examples/v39_sheaf_concern.pl
```

## Aggregator compatibility

The original public fixture path is retained as an aggregator:

```text
examples/v39_sheaf_obstruction_fixtures.pl
```

It loads the three concern modules and contains only smoke-query documentation. This keeps existing links stable while making the separation explicit.

## Boundary rules

- Affect data may be source-derived or fixture-generated, but fixture-generated conflict facts must remain marked as fixtures.
- Temporal/path facts may describe test worlds and paths but must not create normative verdicts.
- Sheaf predicates may derive gluing/obstruction status but must not invent new ADQ source facts.
- The v38 bridge remains the adapter between ADQ-shaped facts and path filters.
- LLM-authored fixtures remain proposals/test vectors, not accepted normative facts.

## Promotion path

1. Keep the Prolog fixture split as the executable reference.
2. Mirror the three concerns in the Ash schema as separate resource groups.
3. Add import adapters that populate affect facts independently from temporal/case fixtures.
4. Add test runners that can exercise the sheaf concern against multiple temporal fixtures.
5. Preserve the aggregator file until no downstream scripts rely on it.
