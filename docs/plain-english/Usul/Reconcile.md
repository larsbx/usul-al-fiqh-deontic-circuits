# Usul.Reconcile in Plain English

Source: [`formal/lean/Usul/Reconcile.lean`](../../../formal/lean/Usul/Reconcile.lean)

A ruling stands by its proof, not by who holds it. This file grades reported positions by their madhhab labels only to describe what the labels favour, so that it can be set beside what the proofs favour. It never decides a case.

## 1. Grades of attribution

- **`Grade`**: the strength of a label on a reported position, strongest first:
  - **taṣḥīḥ**: labelled «المذهب», «الصحيح», «المشهور» or «الأشهر» (the school's settled view);
  - **naṣṣ**: a riwāya (report) or manṣūṣ (explicit statement) of Aḥmad;
  - **ẓāhir**: the apparent sense of Aḥmad's words;
  - **qiyās**: qiyās al-madhhab, analogy within the school;
  - **jazm**: the firm statement of al-Qāḍī and his followers, or of most aṣḥāb (the school's scholars);
  - **ashab**: one named companion's choice; **takhrij**: a derived view; **wajh**: a bare view or possibility.
- **`Grade.rank`**: numbers these 7 down to 0.
- **`Grade.marked`**: the marked grades, jazm and above.
- An author's own «الأظهر» or «الصواب» is a named choice, not a madhhab taṣḥīḥ by itself.

| Theorem | Plain English |
| --- | --- |
| `rank_injective` | Different grades have different ranks. |

## 2. Comparing support

- **`lexGt`**: compares two lists of ranks, strongest first, place by place. A longer list beats its own prefix: more holders of the same grade.
- **`support ps p`**: every grade reported for position `p`, strongest first. A marked grade counts once per holder. An unmarked grade counts once, however many hold it.
- **`prevail ps`**: the position whose support strictly beats every other's, if one exists.

| Theorem | Plain English |
| --- | --- |
| `lexGt_irrefl` | No support list beats itself. |
| `prevail_mem` | The labels' favourite is always one of the reported positions. |
| `prevail_unanimous` | A position reported by everyone prevails. |

## 3. Attribution in the resolution procedure

The kernel's `resolve` (from `Usul.Taarud`) tries jamʿ (reconciling), then naskh (abrogation), then tarjīḥ (preference), else tawaqquf (suspension).

| Definition / Theorem | Plain English |
| --- | --- |
| `byAttribution jam naskh ps` | Run `resolve` with the labels' favourite in the tarjīḥ slot: what the procedure would conclude if attribution were proof. For comparison only. |
| `byAttribution_jam_first` | A reconciliation, when there is one, comes first. |
| `byAttribution_tawaqquf_iff` | The result is suspension ⟺ no jamʿ, no naskh, and no prevailing position. |

## 4. Checks

Seven `#guard` checks run at build time:

- Two riwāyas, one labelled the madhhab: the taṣḥīḥ decides.
- Two bare wujūh: no position prevails.
- More holders of the top grade prevail.
- Named companions do not weigh by number.
- A weaker grade never outweighs a stronger one, however many hold it.
- `byAttribution` gives tawaqquf on two bare wujūh, and naskh when an abrogating position is given.

## In one line

Labels like «المذهب» or a riwāya of Aḥmad are ranked and compared to say which position the school's attributions favour, kept as a record to set against the proofs and never as a verdict.
