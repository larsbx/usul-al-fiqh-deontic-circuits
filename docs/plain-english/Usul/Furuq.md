# Usul.Furuq in Plain English

Source: [`formal/lean/Usul/Furuq.lean`](../../../formal/lean/Usul/Furuq.lean)

Al-Saʿdī's principle for distinctions (furūq) is that the Lawgiver never separates cases alike in every respect: a real separation needs a meaningful feature (maʿnā), and a merely formal (ṣūrī) one is very weak. The file states this as factoring and works out several of his graded furūq from theorems already in the bank.

## 1. Grading a farq

A farq (distinction) is a claimed reason to rule two masāʾil (legal questions) differently.

- **`Grade`**: al-Saʿdī's verdict on a farq of the jurists (fuqahāʾ).
  - **sahih**: ruled apart, and a meaningful feature separates them.
  - **daif**: ruled apart, but nothing meaningful separates them, so "the ruling in both is one".
  - **jamDaif**: ruled alike, but a text (naṣṣ) or meaning separates them.
  - **reported**: he reports the jurists' farq without grading it.
- **`apart`**: does his grade rule the two apart? False only for daif.
- **`madhhab`**: does the school (madhhab) he answers rule them apart? False only for jamDaif.
- **`his`**: is the ruling his own? False only for a bare report.

| Theorem | Plain English |
| --- | --- |
| `confirms_iff_sahih` | His ruling matches the school's ⟺ the grade is sahih or reported. Every weak grade overturns it. |
| `overturn_iff_daif` | A later item can overturn an earlier one only if the earlier is a bare report and the later is his own. Then the overturn is exactly a daif grade. |

## 2. The aṣl (founding principle)

"The ruling factors through the meaningful features" (`Factors H m`) means: masāʾil equal on those features get the same ruling.

| Theorem | Plain English |
| --- | --- |
| `alike_unless_farq` | Masāʾil alike in every meaningful feature are ruled alike. |
| `farq_is_maana` | If two masāʾil are ruled apart, they differ in a meaningful feature. |
| `suri_farq_idle` | A feature the ruling does not turn on separates nothing, however much the cases differ in it. |

## 3. Worked furūq

- **F06, imāma (leading prayer)**: the jurists bar one praying an obligatory prayer (muftariḍ) behind one praying a voluntary one (mutanaffil), citing the difference of intention (niyya). But intention also differs in the reverse arrangement, which they allow. So the cited ʿilla (ratio) is broken by naqḍ (counter-case).
- **F13, shaving vs perfume in iḥrām**: the school excuses the ignorant and forgetful for perfume but not for shaving, calling shaving "destruction" (itlāf). Al-Saʿdī: destruction binds everyone only in human rights; here the right is purely God's. Under the reconciliation T-01 from `Usul.Tanaqud`, the excused owes nothing in either.
- **F15, game killed deliberately or not**: the verse names the deliberate killer. Under T-01 the two fall on different sides.
- **F18, omitting a command vs committing a prohibition**: a sound farq, the same as al-Saʿdī's Q27.
- **F109, destruction by someone not legally responsible**: in human rights, whoever destroys is liable, whatever his state. F109, F13 and T-01 agree.

| Theorem | Plain English |
| --- | --- |
| `f06_naqd` | Any ruling that allows the voluntary-behind-obligatory case yet bans the reverse cannot turn on intention alone. |
| `f13_alike` | In God's right, anyone not acting deliberately owes nothing, shaving included. |
| `f15_apart` | In God's right, the deliberate killer is liable and the forgetful one is not. |
| `f18_sahih` | An excuse discharges a committed prohibition but not an omitted command. |
| `f109_adami` | In human rights, the destroyer is liable in every mental state. |

## In one line

Rule two cases apart only on a meaningful feature: that is factoring, and with it al-Saʿdī's grades and several of his furūq become theorems.
