# ADQ Contextual Path Lift

## Purpose

This note pulls the ADQ source pass into the deontic-circuits harness. It is a source-derived integration note, not a final fiqh ruling layer.

The uploaded ADQ bundle shows that the corpus has moved beyond a static `hukm_aff/4` lattice. The strongest current layer is the v3.7 normalized predicate:

```prolog
deontic_obligation(Affect, Object, Subject, Operator, Modality, Warrant).
```

That fact shape is already close to the target affect-deontic kernel. The missing layer is explicit execution context: worlds, agents, local action trees, paths, and path-realization predicates.

## Source-derived findings

### 1. ADQ already has a typed deontic fact shape

`ADQ/v37_02_deontic_facts.pl` defines affective deontic claims as six-place facts over affect, object, subject, operator, modality, and warrant. This is a better canonical migration target than the older four-place `hukm_aff/4` facts because it prevents the object, subject, and condition from being collapsed into prose.

The typed ontology in `ADQ/v37_01_ontology.pl` supplies:

- subject types such as `all_mukallafin`, `believers`, `prophets`, `leaders`, and `specific_situational`;
- object categories such as `allah`, `eschatological`, `self`, `creation`, `worldly`, and `other_than_allah`;
- deontic operators `o`, `f`, `r`, `d`, `p`, and `n`;
- modality forms `unconditional`, `conditional(_)`, `comparative(_)`, and `scalar(_)`.

This gives the migration a natural canonical record:

```text
Affect × Object × Subject × Operator × Modality × Warrant
```

### 2. Context-sensitive rulings are already present

The same affect can receive different operators depending on object and modality. For example, the v37 facts distinguish khawf directed toward Allah from khawf directed toward other-than-Allah when it displaces taqwa.

This directly supports the project thesis that deontic verdicts must be contextual rather than globally attached to a bare affect atom.

### 3. Capacity and involuntariness are already recognized

`ADQ/v3_6_usul_derivation.pl` records the principle that obligation is bounded by capacity and explicitly notes that affective obligation applies to cultivation, orientation, and consequent acts rather than to instantaneous feeling as such.

That should become a kernel guard:

```text
raw affect occurrence != accepted deontic liability
cultivated / dominant / endorsed / action-guiding affect => eligible for hukm
```

The contextual layer should therefore carry a control status for each observed affect token.

### 4. Evidence tiers can feed the context bus

`ADQ/00_spec-1.md`, `ADQ/02_signatures-1.pl`, `ADQ/03_behavioral-1.pl`, and `ADQ/04_somatic-1.pl` provide a source discipline for non-lexical affect:

- Tier 2 behavioral signatures and profiles, e.g. `hasad`, `kibr`, `makr`, and panic-grade khawf;
- Tier 3 somatic idioms such as heart, chest, face, hand, eye, skin, and earth idioms mapped into affect states;
- Tier 4 quarantine: inferential/profile-based material must not directly support normative derivations.

In the circuit architecture these become inputs to `Ctx(w)`, not verdicts by themselves.

### 5. Anti-pairs are ideal-path constraints

`ADQ/v37_04_anti_pairs.pl` defines `deontic_anti_pair/4`, and `ADQ/v37_07_reasoning.pl` derives `displaces/3` from those anti-pairs.

These are path-filter gates. If a path realizes a forbidden member of an anti-pair while failing to realize the commanded member in the relevant object scope, the path is not affect-deontically ideal.

Examples include commanded/forbidden pairings around khushu/qaswah, shukr/kufran, raja/qunut, raja/ya's, tawakkul/ya's, ikhlas/riya', tawadu'/kibr, iftiqar/ujb, and rifq/fazazah or ghilzah in authority contexts.

### 6. ADQ already separates affect-state deontics from behavioral deontics

`ADQ/v37_03_descriptive_and_cross_module.pl` marks behavioral act obligations as cross-module facts targeted for `behavioral_deontic`, rather than forcing non-affect acts into the affect lattice.

The contextual lift should preserve that boundary:

```text
affect_deontic      -- states, orientations, dominant dispositions
behavioral_deontic  -- acts and policies
somatic_context     -- evidence and context only
path_deontic        -- local tree/path filtering
```

## Missing execution layer

The inspected sources do not yet expose a local temporal execution vocabulary such as:

```prolog
world/1.
ctx/3.
action_node/3.
action_edge/4.
valid_path/2.
path_realizes/4.
ideal_path/2.
```

That gap is exactly where the contextual deontic-circuit architecture should attach.

## Target bridge

The bridge should wrap existing ADQ facts rather than replace them:

```prolog
ctx(World, Agent, Conditions).
ctx_affect(World, Agent, Affect, Object, Evidence, ControlStatus).
path_realizes(Path, Agent, Affect, Object).
path_obligation_scope(Path, Agent, Affect, Object).
local_affect_hukm(World, Agent, Affect, Object, Operator, Modality, Warrant).
path_affect_violation(World, Path, Reason).
ideal_path_affect_ok(World, Path).
```

The intended filter is:

```text
Ideal_w(Path) =
  ValidPath_w(Path)
  ∧ TierDisciplineOK(w, Path)
  ∧ CapacityOK(w, Path)
  ∧ AffectObligationsOK(w, Path)
  ∧ AntiPairsOK(w, Path)
  ∧ BehavioralModuleOK(w, Path)
```

## Operator mapping

| ADQ operator | Deontic reading | Path-filter use |
|---|---|---|
| `o` | obligatory | required when the path is in scope |
| `f` | forbidden | path violation if realized |
| `r` | recommended | positive weight / non-required ideal preference |
| `d` | discouraged | negative weight / non-fatal defect unless upgraded |
| `p` | permitted | admissible unless another rule blocks it |
| `n` | outside taklif | context evidence only; no direct path liability |

## Sheaf layer connection

The contextual path lift gives the execution vocabulary. The finite sheaf context site gives the compatibility vocabulary:

```text
local ADQ sections -> context restrictions -> gluing or obstruction -> path filter
```

This keeps context changes, concessions, anti-pair failures, and object-sensitive rulings from being collapsed into global contradiction.

## Immediate implementation discipline

1. Do not let Tier 4 material support `local_affect_hukm/7` directly.
2. Do not treat bare involuntary affect as culpable path realization.
3. Require object and subject matching before applying a deontic fact.
4. Require modality satisfaction from the world/path context.
5. Preserve `behavioral_deontic` as a separate target module.
6. Use anti-pairs as displacement constraints, not as contradictions.
7. Generate explanations from warrant traces and path-violation reasons, not free-form LLM verdicts.

## First buildable v38 slice

The first code slice should load the existing v37 ADQ modules and add only a small bridge file:

```text
examples/v38_contextual_affect_deontics.pl
```

That file should stay a thin adapter until the Ash schema is ready. The Ash resources should later mirror the same bridge concepts as database records and deterministic checks.
