# Usul.Hukm in Plain English

Source: [`formal/lean/Usul/Hukm.lean`](../../../formal/lean/Usul/Hukm.lean)

The five rulings of obligation (al-ḥukm al-taklīfī) form a scale from forbidden to obligatory. Flipping an act to its omission reverses that scale, and only the permitted is unchanged by the flip. The definition's split into "demand" and "choice" pins down each ruling exactly.

## 1. The five rulings

- **`Hukm`**: the five statuses an act can have.
  - wājib (obligatory), mandūb (recommended), mubāḥ (permitted), makrūh (disliked), ḥarām (forbidden).
- **Source**: Ibn ʿUthaymīn's definition of the ḥukm as what the Lawgiver's address requires of the acts of the legally responsible, by demand (ṭalab), choice (takhyīr), or setting (waḍʿ). This file covers only the first two.
- **`valence`**: a score from 0 to 4. Ḥarām 0, makrūh 1, mubāḥ 2, mandūb 3, wājib 4.
- **Order (`≤`)**: one ruling is below another when its valence is lower. So ḥarām < makrūh < mubāḥ < mandūb < wājib.

| Theorem | Plain English |
| --- | --- |
| `valence_injective` | Different rulings have different scores. |
| `valence_le_four` | No score exceeds 4. |

## 2. The omission map σ

- **`σ`**: the status of *leaving* an act (tark), given the act's own status.
  - Obligatory to do → forbidden to leave. Recommended → disliked to leave. Permitted stays permitted. Disliked → recommended to leave. Forbidden → obligatory to leave.
- This encodes the principle *al-amr bi'l-shayʾ nahy ʿan ḍiddih*: commanding a thing forbids its opposite.

| Theorem | Plain English |
| --- | --- |
| `σ_σ`, `σ_involutive` | Omitting the omission returns the original ruling. |
| `σ_valence` | σ mirrors the score: new score = 4 − old score. |
| `σ_antitone` | σ reverses the order. If a ≤ b, then σ b ≤ σ a. |
| `amr_nahy_didd` | If an act is wājib, leaving it is ḥarām. |
| `σ_fixed_iff` | σ h = h ⟺ h is mubāḥ. Only permission (ibāḥa) is indifferent to omission. |

## 3. Demand, choice, and bindingness

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

## In one line

The five rulings sit on a 0–4 scale, omission mirrors that scale (4 − score), only mubāḥ is its own mirror, and (mode, bindingness) identifies every ruling uniquely.
