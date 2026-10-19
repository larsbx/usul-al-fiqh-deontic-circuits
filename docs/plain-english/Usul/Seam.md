# Usul.Seam in Plain English

Source: [`formal/lean/Usul/Seam.lean`](../../../formal/lean/Usul/Seam.lean)

A ḥadīth offered as a dalīl (proof text) in legal reasoning is admitted only when al-Albānī grades it ḥujja (usable as proof), that is, ḥasan or ṣaḥīḥ. The rule holds in every slot of Aḥmad's order of sources. This file is the single point where the ḥadīth track feeds the uṣūl (legal theory) kernel.

## 1. The ḥadīth dalīl

- **`HadithDalil`**: a ḥadīth offered as proof. It records two things: its slot in Aḥmad's order of sources (`DalilKind`) and al-Albānī's verdict on it (`Verdict`).
- **Verdicts**, worst first: mawḍūʿ (fabricated), ḍaʿīf jiddan (very weak), ḍaʿīf (weak), ḥasan (good), ṣaḥīḥ (sound).
- **`admitted`**: the gate of decision D4. A ḥadīth passes exactly when its verdict is ḥujja. The slot it is offered in plays no part.

## 2. The theorems

| Theorem | Plain English |
| --- | --- |
| `admitted_iff_yaqin` | Admitted ⟺ its grade reaches the yaqīn (certainty-for-action) floor on the kernel's epistemic scale. |
| `daif_not_admitted` | A ḍaʿīf ḥadīth is never admitted, in any slot. |
| `mursalDaif_admits_only_hasan_up` | Aḥmad's fourth source, the "mursal or ḍaʿīf" slot, admits a ḥadīth ⟺ it is ḥasan or better. |

The last result follows Ibn al-Qayyim's gloss. When Aḥmad put the ḍaʿīf before qiyās (analogy), his ḍaʿīf was «قسم من أقسام الحسن», a kind of ḥasan. So the slot keeps its place in the order but lets in nothing the gate rejects.

## 3. A worked example

- **`q24Dalil`**: the ḥadīth al-Saʿdī cites under his qāʿida (legal maxim) 24, «من سبق إلى ما لم يسبق إليه مسلم فهو أحق به» ("whoever first reaches what no Muslim reached before has the better right to it"). Al-Albānī grades it ḍaʿīf (al-Irwāʾ 1555).
- **`q24_dalil_not_admitted`**: offered as naṣṣ (explicit text), it still fails the gate. Under D4 it is not a dalīl.

## In one line

A ḥadīth counts as proof in the uṣūl track only if al-Albānī grades it ḥasan or ṣaḥīḥ, whatever slot it is offered in; a ḍaʿīf report never gets through.
