# Usul.Hukm in Plain English

Source: [`formal/lean/Usul/Hukm.lean`](../../../formal/lean/Usul/Hukm.lean)

Each of the five rulings of obligation (al-ḥukm al-taklīfī) is defined by what follows on doing the act and on leaving it: reward, liability to punishment, or neither. There is no score. The order forbidden < … < obligatory, the flip to the omission, and the split into demand and choice all follow from those two consequences.

## 1. The five rulings and their definitions

- **`Hukm`**: the five statuses an act can have.
  - wājib (obligatory), mandūb (recommended), mubāḥ (permitted), makrūh (disliked), ḥarām (forbidden).
- **Source**: Ibn ʿUthaymīn's definition of the ḥukm as what the Lawgiver's address requires of the acts of the legally responsible, by demand (ṭalab), choice (takhyīr), or setting (waḍʿ). This file covers only the first two.
- **`Jaza`**: what the Lawgiver attaches to doing or to leaving an act.
  - **thawāb**: rewarded, when done or left in obedience («امتثالاً»).
  - **ʿiqāb**: liable to punishment («يستحق العقاب»). This is liability, not certain punishment.
  - **neither**: no reward and no liability.
- **`fil`, `tark`**: the consequence of doing and of leaving. In Ibn ʿUthaymīn's words:

| Ruling | Doing (`fil`) | Leaving (`tark`) |
| --- | --- | --- |
| wājib | rewarded | liable |
| mandūb | rewarded | not punished |
| mubāḥ | neither | neither |
| makrūh | not punished | rewarded |
| ḥarām | liable | rewarded |

So the mandūb is not a weaker wājib: it is the wājib without liability for leaving. The makrūh is not a weaker ḥarām: it is the ḥarām without liability for doing.

| Theorem | Plain English |
| --- | --- |
| `jaza_injective` | The two consequences fix the ruling: no two rulings share them. |
| `not_both_thawab`, `not_both_iqab` | No ruling rewards both doing and leaving, and none makes both liable. |
| `mubah_iff` | Mubāḥ ⟺ neither reward nor liability on either side. |

## 2. The order, read off the definitions

- **Order (`≤`)**: b ranks at least as high as a when doing fares no worse under b and leaving fares no better. On each side, liability < neither < reward.
- The five rulings form a chain, ḥarām < makrūh < mubāḥ < mandūb < wājib, but the steps are of different kinds:

| Step | What changes |
| --- | --- |
| wājib → mandūb | leaving is no longer liable |
| mandūb → mubāḥ | doing is no longer rewarded |
| mubāḥ → makrūh | leaving becomes rewarded |
| makrūh → ḥarām | doing becomes liable |

Two steps are about punishment and two about reward, so no step is a unit and the chain has no arithmetic.

| Theorem | Plain English |
| --- | --- |
| `le_refl`, `le_trans`, `le_antisymm` | The order is a partial order. |
| `le_total` | Any two rulings compare: the five form a chain. |
| `haram_le`, `le_wajib` | Ḥarām is lowest, wājib highest. |

## 3. The omission map σ

- **`σ`**: the status of *leaving* an act (tark), given the act's own status.
  - Obligatory to do → forbidden to leave. Recommended → disliked to leave. Permitted stays permitted. Disliked → recommended to leave. Forbidden → obligatory to leave.
- Doing the omission is leaving the act, so σ swaps the two consequences. The map is therefore read off the definitions, not stipulated.
- This encodes the principle *al-amr bi'l-shayʾ nahy ʿan ḍiddih*: commanding a thing forbids its opposite.

| Theorem | Plain English |
| --- | --- |
| `σ_σ`, `σ_involutive` | Omitting the omission returns the original ruling. |
| `σ_fil`, `σ_tark` | Doing the omission has the consequence of leaving the act, and vice versa. |
| `σ_eq_iff` | σ h is the one ruling whose consequences are h's, swapped. |
| `σ_antitone`, `σ_le_σ` | σ reverses the order exactly. |
| `amr_nahy_didd` | If an act is wājib, leaving it is ḥarām. |
| `σ_fixed_iff` | σ h = h ⟺ h is mubāḥ. Only permission (ibāḥa) is indifferent to omission. |

## 4. Demand, choice, and bindingness

- **`Mode`**: three kinds of address.
  - **talabFil**: demand to do (wājib, mandūb).
  - **talabTark**: demand to refrain (ḥarām, makrūh).
  - **takhyir**: free choice (mubāḥ).
- **`binding`**: true for a binding demand (ilzām: wājib, ḥarām); false for a preferential one (afḍaliyya) or for choice.

| Theorem | Plain English |
| --- | --- |
| `mode_binding_injective` | Knowing the mode and whether it binds fixes the ruling. The five-way partition is faithful. |
| `σ_swaps_mode` | Omission swaps "demand to do" with "demand to refrain" and leaves choice as choice. |
| `σ_preserves_binding` | Omission keeps bindingness: a binding demand to act is a binding prohibition on leaving it. |
| `binding_iff` | Binding ⟺ one side carries liability to punishment. |
| `mode_talabFil_iff`, `mode_talabTark_iff` | A demand to do is reward for doing; a demand to refrain is reward for leaving. |

## 5. What the definitions leave out

- **The khiṭāb.** Leaving a mandūb has the makrūh's consequences, so σ(mandūb) = makrūh. Later Shāfiʿīs still separate it as khilāf al-awlā (not the better course), because the makrūh rests on a specific prohibition. That difference is in the address, not in the consequences.
- **Contrary vs omission.** σ models the omission (tark), while the maxim speaks of the contrary (ḍidd). An act can have several contraries.
- **Positions that fix a range** («يجوز», a command of disputed strength) are handled in `Usul.Cat.Interval`.

See `docs/architecture/hukm-interval-verdicts.md`.

## In one line

Each ruling is a pair (what follows on doing, what follows on leaving); the order, the flip to the omission and the demand/choice split are all read off that pair, and no number is involved.
