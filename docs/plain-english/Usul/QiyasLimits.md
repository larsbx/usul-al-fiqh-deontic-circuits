# Usul.QiyasLimits in Plain English

Source: [`formal/lean/Usul/QiyasLimits.lean`](../../../formal/lean/Usul/QiyasLimits.lean)

Qiyās (analogy) has limits: how it fails, where it applies, and how clear it is. Adding an extra description to the ʿilla keeps an analogy sound but narrow, while omitting a needed one makes it unsound. A qiyās against a text is never sound. The Ḥanafī scope for qiyās is strictly inside the Ḥanbalī one.

## 1. Fallibility: the ʿilla as several descriptions

Ibn Qudāma lists ways qiyās goes wrong, including omitting part of the ʿilla and adding an extraneous description. Ibn al-Qayyim's charge against over-eager analogists (considering causes the Lawgiver did not, ignoring ones he did) is these two errors.

- **`conj`**: an ʿilla made of several descriptions, all required.

| Theorem | Plain English |
| --- | --- |
| `conj_iff` | A case has the combined ʿilla ⟺ it has every part. |
| `addition_sound` | Adding a description keeps it sound: every case the proposed ʿilla marks has the true one. It is only narrower. |
| `omission_unsound` | Omitting a part makes it unsound: a case can have the proposed ʿilla but lack the true one. |
| `addition_never_overextends` | So with an added description, the ruling never spreads to a case outside the true ʿilla. |

## 2. No sound qiyās against a text

"Nothing in the sharīʿa is against sound qiyās" (Ibn al-Qayyim, Ibn Taymiyya).

| Theorem | Plain English |
| --- | --- |
| `qiyas_against_text_unsound` | If a text rules a case differently while the ʿilla is present, that text is a naqḍ (counter-case). No ruling fitting the texts depends only on that ʿilla. |

## 3. Scope

- **`Domain`**: worship, transactions, ḥudūd (fixed penalties), kaffārāt (expiations), rukhaṣ (concessions), fixed amounts, causes (asbāb), original negation, and incidental negation.
- **`Kind`**: qiyās al-ʿilla or qiyās al-dalāla.
- **`hanbaliAdmits`**: qiyās runs wherever the rationale is understood. Causes depend on a parameter (an inner dispute). Original negation takes only qiyās al-dalāla.
- **`hanafiAdmits`**: the Ḥanbalī scope minus ḥudūd, kaffārāt, rukhaṣ and fixed amounts, as Ḥanbalī sources report it.

| Theorem | Plain English |
| --- | --- |
| `hanbali_hudud` | In ḥudūd and kaffārāt, the Ḥanbalī test is only whether the rationale is understood. |
| `no_qiyas_without_rationale` | Where the rationale is not understood (e.g. the number of rakʿas), no domain admits qiyās. |
| `nafy_asli_only_dalala` | Original negation never takes qiyās al-ʿilla. |
| `hanafi_within_hanbali` | Whatever the Ḥanafī scope admits, the Ḥanbalī scope admits. |
| `hanafi_strictly_narrower` | An intelligible ḥadd separates them: Ḥanbalīs admit it, Ḥanafīs do not. |

## 4. Clear and hidden qiyās

- **`clarity`**: jalī (clear) when the ʿilla is stated by text or the absence of a difference is certain; otherwise khafī (hidden).

| Theorem | Plain English |
| --- | --- |
| `textual_is_jali` | A text-stated ʿilla always gives a clear qiyās. |
| `khafi_iff` | Hidden ⟺ the ʿilla is inferred and no difference is certainly absent. |

## 5. Testimony of the uṣūl

- **`shahadatUsul`**: the source cases (uṣūl) testify for a feature when there are some and none contradicts it. Its acceptance is disputed, so it is not a gate condition here.

| Theorem | Plain English |
| --- | --- |
| `shahada_restrict` | Testimony from many uṣūl survives restriction to any non-empty subset. |

## 6. Analogy and syllogism

Ibn Taymiyya: the jurists' analogy (tamthīl) and the first-figure syllogism (shumūl) carry the same content; the middle term is the ʿilla.

| Theorem | Plain English |
| --- | --- |
| `tamthil_iff_shumul` | Once some case has the common feature: "any two cases with it share the ruling" ⟺ "one ruling holds of everything with it". |
| `shumul_of_factors` | Both follow when the ʿilla determines the ruling. |

## In one line

An analogy errs safely by adding to its ʿilla and dangerously by omitting from it; it never stands against a text; and its Ḥanbalī scope strictly contains the Ḥanafī one.
