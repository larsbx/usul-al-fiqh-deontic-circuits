# Ḥukm as a verdict type: where the five-point chain loses meaning

The five taklīfī statuses are the right carrier. Treating them as a single chain of point verdicts
is what loses fidelity. As a set, {W, N, M, K, Ḥ} is the jumhūr inventory. Ibn ʿUthaymīn defines
each status by what follows on doing and on leaving (`src:shamela-9942/v01:p010`–`p011`), and
`Usul.Hukm` now takes that pair as the definition:

```
(fil, tark) : Hukm ↪ Jaza × Jaza,  Jaza = {thawāb, neither, ʿiqāb}       (jaza_injective)
(mode, binding) : Hukm ↪ {ṭalab al-fiʿl, ṭalab al-tark, takhyīr} × Bool  (mode_binding_injective)
```

The losses come from four choices layered on top: a numeric rank (now removed), point-valued
sections in `Usul.Cat.Sheaf`, the unary involution `σ`, and valuing each act on its own. This note
records each loss, what it can do to a derivation, and what the code does about it. The register
entries are PR-41 to PR-47 in [problem-register.md](../problem-register.md).

## Findings

| ID | Loss | Effect on a derivation | Status |
|---|---|---|---|
| PR-41 | A position that fixes a set of statuses is forced to a point | false ikhtilāf: «يجوز» encoded as M beside «يستحب» (N) is reported as an obstruction | prototyped: `Usul.Cat.Interval` |
| PR-42 | Tawaqquf has no value in the verdict type | suspension defaulted to M reads as a ruling of ibāḥa and can obstruct, or be glued into, a real ruling | prototyped: `stances` makes suspension a hole in the cover |
| PR-43 | `σ` reads the maxim on statuses | `σ` models tark where the maxim speaks of ḍidd; khilāf al-awlā has the makrūh's consequences and differs only in its khiṭāb, which no status records | `σ` is now derived (the swap of doing and leaving, `σ_fil`, `σ_tark`); the ḍidd and khiṭāb gaps are recorded |
| PR-44 | Valuing each act on its own cannot state some obligations | wājib mukhayyar (one of the kaffāra options) and wājib kifāʾī (depends on others' acts) have no faithful encoding | open |
| PR-45 | Agreement in value is taken as agreement in ground | ḥarām li-dhātihi and li-ghayrihi glue, yet only the second yields to ḥāja; a narrower context splits them | open |
| PR-46 | A scheme with more statuses mapped into the five is not injective | Ḥanafī farḍ / wājib and karāha taḥrīmiyya / tanzīhiyya collapse, giving false agreement | open; `Grade` is the axis that recovers most of it |
| PR-47 | A numeric rank (`valence`, 0–4) stood for the statuses | it made the mandūb a weaker wājib and the makrūh a weaker ḥarām, and every step of the chain one unit, though the steps change different things | closed: `valence` removed; statuses are defined by reward and liability for doing and leaving, and the order and `σ` are derived from them |

### PR-41: point-forcing

Fatwā wording often fixes only part of the chain:

| Wording | Statuses it fixes | Span |
|---|---|---|
| «يجوز» | not ḥarām: K, M, N, W | `permitted` |
| amr of disputed strength | ṭalab al-fiʿl: N, W | `talabFil` |
| nahy of disputed strength | ṭalab al-tark: Ḥ, K | `talabTark` |
| «لا يجب» | not wājib: Ḥ, K, M, N | `notObligatory` |
| «لا بأس», «لا ينبغي» | jurist-dependent | not fixed here |

Early «يكره» often meant taḥrīm (Ibn al-Qayyim notes this salaf usage). It needs a reading per
author, not a fixed span.

The repair is to let a section take spans, the convex subsets of the chain, with two patches
matching when their spans meet. The obstruction theory survives unchanged in shape. Convex sets
in a line obey Helly's theorem: spans that meet pairwise share a status. Obstruction therefore
stays a pairwise witness, and the finite sheaf condition keeps its form (`iglues_iff`).

### PR-47: consequences, not ranks

Ibn ʿUthaymīn's definitions say what follows on doing and on leaving:

| Status | Doing | Leaving |
|---|---|---|
| wājib | «يثاب فاعله امتثالاً» | «يستحق العقاب تاركُه» |
| mandūb | «يثاب فاعله امتثالاً» | «لا يعاقب تاركه» |
| mubāḥ | «لا يترتب عليه ثواب ولا عقاب» | the same |
| makrūh | «لا يعاقب فاعله» | «يثاب تاركه امتثالاً» |
| ḥarām | «يستحق العقاب فاعله» | «يثاب تاركه امتثالاً» |

A rank of 0 to 4 loses this. The mandūb is not "three quarters of a wājib". It is the wājib with
no liability for leaving: whoever does it is rewarded, and whoever leaves it is not punished. The
makrūh should be avoided, but doing it incurs no punishment; it is the ḥarām with no liability
for doing. The four steps of the chain change four different things:

| Step | Change |
|---|---|
| W → N | leaving is no longer liable |
| N → M | doing is no longer rewarded |
| M → K | leaving becomes rewarded |
| K → Ḥ | doing becomes liable |

`Usul.Hukm` now defines each status by `fil` and `tark` (`Jaza`: thawāb, neither, ʿiqāb). Several
things are derived from that pair:

* **The order.** b ≥ a when doing fares no worse under b and leaving no better. It is still a
  chain (`le_total`), but there is no rank to add or average.
* **σ.** The omission swaps doing and leaving (`σ_fil`, `σ_tark`).
* **ilzām.** It is liability on one side (`binding_iff`).
* **The modes.** Ṭalab is reward on the demanded side (`mode_talabFil_iff`, `mode_talabTark_iff`).

Two caveats sit in the wording. Reward is conditioned on obedience («امتثالاً»), and punishment
is liability («يستحق»), not its certain infliction. `Jaza` records what the Lawgiver attaches,
not what befalls an agent.

### PR-42: tawaqquf

Not-knowing is not ibāḥa. `UsulTest.Reconcile` already resolves 340 entries to tawaqquf under the default policy, outside the verdict type.
In `Usul.Cat.Interval` a suspending position contributes no patch, so it never obstructs and is
never read as M.

### PR-43: the contested readings in `σ`

* **Khilāf al-awlā.** Leaving a mandūb has the makrūh's consequences (neither on doing, reward
  on leaving), so `σ mandub = makruh` follows from the definitions. Later Shāfiʿīs still name it
  khilāf al-awlā, because they require a specific nahy for karāha. The distinction is in the
  khiṭāb, which a status does not record.
* **Ḍidd vs tark.** *Al-amr bi'l-shayʾ nahy ʿan ḍiddih* speaks of the contrary acts. An act can
  have several contraries (a command to stand has sitting and lying as contraries), and a unary
  map on statuses cannot say which of them is forbidden.
* **The maxim itself.** Whether the command *is* the prohibition of its contrary or only entails
  it is disputed. `amr_nahy_didd` is an encoding choice.

### PR-44: obligations that are not per act

* **Wājib mukhayyar.** One of {a, b, c} is obligatory. No single option is wājib, and none is
  mandūb, so no map Act → Hukm states it. The obligation sits on a disjunction of acts.
* **Wājib kifāʾī.** Whether the duty binds one person depends on whether others have discharged
  it. The situation type would have to include other agents' acts.
* ʿAynī/kifāʾī, muḍayyaq/muwassaʿ and ʿazīma/rukhṣa likewise depend on subject and time. They
  survive only if the context carries them.

### PR-45: value without ground

Two sources that both rule Ḥ glue in `Sheaf`, though ḥarām li-dhātihi and ḥarām li-ghayrihi
(sadd al-dharāʾiʿ) restrict differently: need lifts only the second. A gluing on bare labels can
certify a consensus that comes apart in a narrower context. The ʿilla, or at least the
dhāt/ʿāriḍ tag, belongs in the verdict or in the patch.

### PR-46: other schemes

The Ḥanafī seven-way scheme is largely evidential grade folded into the status:
farḍ ≈ (W, qaṭʿ), Ḥanafī wājib ≈ (W, ẓann), makrūh taḥrīman ≈ (Ḥ, ẓann). The kernel keeps `Grade`
and the waḍʿī signs on their own axes, which is right. The risk is reading Ḥanafī positions
through the five statuses alone. The bank is Ḥanbalī today, so this matters only when another
madhhab's sources enter.

## The prototype: `Usul.Cat.Interval`

| Result | Statement |
|---|---|
| `meets_iff_exists` | two spans meet ⟺ they share a status |
| `meets_point` | on points, meeting is equality |
| `helly` | spans that meet pairwise all contain `maxLo`, the greatest lower end |
| `iglues_iff` | ∃ point verdict refining every patch ⟺ `iobstructions = []` |
| `iobstructions_ofPatch` | on point patches, `iobstructions` = `Sheaf.obstructions`, list for list |
| `stances_glue_iff` | a case's positions glue ⟺ every two rulings meet; suspensions are ignored |
| `mem_σ`, `meets_σ` | `Span.σ` reverses the span and preserves membership and meeting |
| `mem_talabFil`, `mem_talabTark`, `mem_takhyir`, `mem_permitted` | the named spans are exactly the modes and «يجوز» |

The test vectors (`UsulTest.Interval`) cover these cases:

* the false ikhtilāf of «يجوز» beside «يستحب», which the point checker reports and the span
  checker does not;
* real ikhtilāf, which is kept: W against N, ṭalab al-fiʿl against ṭalab al-tark, «يجوز» against Ḥ;
* tawaqquf against Ḥ, which is not an obstruction;
* three spans glued by Helly at N;
* conservativity on points.

Not done here:

* migrating fixtures or the reconciliation ledger to spans;
* a wording-to-span table per author;
* the per-act and ground-tagging gaps (PR-44, PR-45).

`Sheaf` stays the point-valued case, and `Interval` extends it conservatively.
