# Hadith.JarhTadil in Plain English

Source: [`formal/lean/Hadith/JarhTadil.lean`](../../../formal/lean/Hadith/JarhTadil.lean)

When critics disagree about a narrator, the outcome depends on the strongest statement on each side, never on how many critics speak. An established criticism (jarḥ) beats any ordinary praise (taʿdīl), and supporting clues (qarāʾin) matter only when neither side is decisive. The rules follow al-Muʿallimī's *al-Tankīl* and al-Albānī's *Tamām al-Minna*.

## 1. Vocabulary

- **Jarḥ / taʿdīl**: criticism and praise of a narrator (`Side.jarh`, `Side.tadil`).
- **`Strength`**: how remote error is in a statement.
  - `mujmal`: no cause given.
  - `mufassar`: cause given, still open to error.
  - `qati`: so well established that rejecting it means calling an upright critic a deliberate liar.
- **`Qawl`**: one critic's statement, with its side and strength, and two flags.
  - `hukm`: made as a judgement, not in anger, advice or passing.
  - `mutamad`: the critic is relied on for this kind of judgement.
- **`Qawl.counts`**: both flags are true. Statements that fail either are ignored.
- **`strongest`**: the strongest counting statement on one side.
- **`Status`**: `majruh` (wounded), `tawaqquf` (suspended judgement), `adl` (upright).

## 2. The resolution rule

**`resolve`** takes the strongest jarḥ, the strongest taʿdīl, and which side the qarāʾin favour (if any):

- Jarḥ only ⇒ majrūḥ, even if unexplained.
- Taʿdīl only ⇒ ʿadl. Neither ⇒ tawaqquf (the narrator is majhūl, unknown).
- Both decisive ⇒ tawaqquf.
- A decisive side against a non-decisive side ⇒ the decisive side wins, "even if the praisers are many".
- Otherwise tarjīḥ (weighing): the qarāʾin decide. With no qarīna, tawaqquf.

**`judge`** applies `resolve` to everything said about a narrator.

## 3. The rules as theorems

| Theorem | Plain English |
| --- | --- |
| `jarh_alone_wounds` | Any jarḥ with no taʿdīl wounds the narrator. |
| `qati_jarh_wins` | Decisive jarḥ beats non-decisive taʿdīl, whatever the qarāʾin. Bias can never defeat it. |
| `qati_tadil_wins` | The same test for praise: decisive taʿdīl beats non-decisive jarḥ. |
| `mujmal_against_tadil` | Unexplained jarḥ against non-decisive taʿdīl, with no qarīna ⇒ tawaqquf. |
| `rawi_not_shahid` | Narrators differ from witnesses. For a witness (`shahid`), unexplained jarḥ yields to taʿdīl; for a narrator it does not. |
| `qarina_only_in_tarjih` | Outside the case where both sides are non-decisive, the qarāʾin change nothing. |
| `antitone_in_jarh` | Stronger jarḥ never improves the status. |
| `monotone_in_tadil` | Stronger taʿdīl never worsens it. |

## 4. What does not count

| Theorem / check | Plain English |
| --- | --- |
| `strongest_skip` | A non-counting statement is skipped when finding the strongest. |
| `not_counting_ignored` | Adding a non-counting statement never changes the verdict, e.g. Ibn Ḥibbān's praise of an unknown. |
| example (many praisers) | One decisive jarḥ against three ordinary taʿdīls ⇒ majrūḥ, for every qarīna. |
| example (Ibn Ḥibbān) | A lone praise from a critic not relied on for it ⇒ tawaqquf. |

## 5. Link to the narrator ladder

- **`Status.martaba`**: tawaqquf maps to mastūr (rank 7). ʿAdl and majrūḥ need more detail to fix a rung, so they map to nothing.
- **`tawaqquf_itibar`**: that rung is in the repairable middle band: neither ḥujja nor shadīd.

## In one line

Conflicting critics are resolved by comparing the strongest statement on each side: decisive beats non-decisive, qarāʾin break only genuine ties, headcount never matters, and unresolved cases land in the repairable band.
