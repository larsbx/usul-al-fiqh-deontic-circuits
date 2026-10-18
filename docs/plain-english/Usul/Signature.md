# Usul.Signature in Plain English

Source: [`formal/lean/Usul/Signature.lean`](../../../formal/lean/Usul/Signature.lean)

The basic vocabulary of the uṣūl kernel: who is addressed by the law, how sure a belief is, which sources are consulted in what order, what the default ruling is, and the conditions a ruling needs before it applies. Definitions (ḥudūd) here distinguish things by marks; they do not claim to capture essences.

## 1. The subject of address

- **`Subject`**: a person, described by two capacities: bulūgh (maturity) and ʿaql (sound mind).
- **`Subject.IsMukallaf`**: the person is mukallaf (legally responsible) ⟺ mature and sane. This is sharṭ al-taklīf, the condition of legal obligation (Ibn al-Laḥḥām, qāʿida 2).
- **`Mukallaf`**: the type of subjects who meet that condition.

## 2. Epistemic grades

- **`Grade`**: four degrees of belief, weakest first: wahm (fancy), shakk (doubt), ẓann (probable belief), qaṭʿ (certainty).
- **`Grade.IsYaqin`**: the floor of yaqīn (certainty for acting) is ẓann or above. It is necessary but not enough.
- **`Grade.YaqinFor`**: yaqīn for acting holds for qaṭʿ, or for ẓann whose preponderance is itself known on a proof. This follows Ibn Taymiyya: knowing that one side prevails is ʿilm (knowledge); otherwise the scholar "suspends and has no view".

| Theorem | Plain English |
| --- | --- |
| `YaqinFor.isYaqin` | Certainty for acting always meets the ẓann floor. |
| `yaqinFor_known` | When the preponderance is known, certainty for acting ⟺ the grade is ẓann or qaṭʿ. |
| `zann_unknown_not_yaqin` | A ẓann of unknown preponderance is not certain enough to act on. |

## 3. Sources in Aḥmad's order

- **`DalilKind`**: the kinds of proof, in Aḥmad's order of resort as Ibn al-Qayyim reports it in *Iʿlām al-Muwaqqiʿīn*: naṣṣ (text) and ijmāʿ (consensus); the undisputed fatwā of a ṣaḥābī (Companion); the Companion view closest to the text; the mursal or ḍaʿīf report; qiyās (analogy); and istiṣḥāb (presumption of continuity) as fallback.
- **`DalilKind.resort`**: a number for each kind; lower means consulted first.

| Theorem | Plain English |
| --- | --- |
| `DalilKind.qiyas_after_athar` | Every source other than qiyās and istiṣḥāb is consulted before qiyās. |

## 4. Default rulings by domain

- **`Domain`**: ʿādāt (customs, ordinary affairs) or ʿibādāt (acts of worship).
- **`Domain.default`**: with no proof, ordinary affairs are mubāḥ (permitted), and acts of worship are ḥarām (forbidden). These are the maxims "the default in things is permission" and "the default in worship is restriction to what is revealed" (tawqīf).

## 5. Conditions on applying a ruling

- **`Wad`**: the waḍʿī (declaratory) conditions for an act and a subject: sabab (cause), sharṭ (condition), and māniʿ (impediment).
- **`applies`**: a ruling can be applied only when given evidence of the cause, of the condition, of no impediment, and that the subject is mukallaf. Without all four, the function cannot be called.

| Theorem | Plain English |
| --- | --- |
| `no_taklif_without_mukallaf` | Someone lacking ʿaql is not mukallaf, so no ruling can be applied to them. |

## In one line

The kernel fixes who is responsible (mature and sane), how sure one must be to act (qaṭʿ, or ẓann known to prevail), the order of sources, the default rulings, and the gate of cause, condition and no impediment that every ruling must pass.
