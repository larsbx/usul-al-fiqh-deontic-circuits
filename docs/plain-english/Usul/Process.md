# Usul.Process in Plain English

Source: [`formal/lean/Usul/Process.lean`](../../../formal/lean/Usul/Process.lean)

The project's own review of interpretive questions runs on the same uṣūl it formalises: cited text before analogy, analogy only through a shared ʿilla, and no "adopted" status without outside authority. The file proves this process cannot deadlock, provided the rules it uses are not themselves under open review.

## 1. Status by priority

A question in the review register gets a status from the evidence on file.

- **`Status`**: referenced (an established answer is cited), analogized (only analogies are offered), or open (tawaqquf, suspension).
- **`status`**: cited answer first, else analogy, else open. Nothing changes it but new evidence (istiṣḥāb, presumption of continuity).

| Theorem | Plain English |
| --- | --- |
| `status_cited` | With a cited answer, the status is referenced. |
| `analogy_never_outranks_text` | When a text is cited, the status is never "analogized". Qiyās comes after transmitted reports (athar). |
| `open_iff` | Open ⟺ nothing is on file. |
| `order_is_resort` | This mirrors Aḥmad's order of resort: every transmitted source comes before qiyās. |
| `never_adopts` | Every status is referenced, analogized or open. The process never adopts; adoption needs a SHARIAH-AUTHORITY gate the repository does not hold. |

## 2. Analogy as qiyās

- **`Licensed tags asl far s`**: an analogy from one rule (the aṣl) to another (the farʿ) is licensed when both carry the same schema tag s. The shared schema plays the ʿilla.

| Theorem | Plain English |
| --- | --- |
| `licensed_transfers` | Anything computed from the schema tag alone agrees on both sides. |
| `man` | **Manʿ** (denial). If the cited ʿilla is missing on either side, the analogy is not licensed. The process relies only on manʿ, whose force is undisputed, not on the disputed doctrine of naqḍ. |

## 3. Deadlock freedom

A principle cannot be used to *run* the review while its own reading is *under* review: each would wait on the other.

- **`WaitsOn`**: question q waits on q′ when the process uses a rule that q′ has open.
- **`Stratified`**: no rule the process uses is under any open question.

| Theorem | Plain English |
| --- | --- |
| `no_deadlock_of_stratified` | If the process is stratified, no question waits on any other. |
| `no_cycle_of_rank` | General form: if every wait strictly lowers some rank, no question waits on itself through any chain. |

The register lists the rules it uses and those it must avoid (Q33, since question IQ-10 is about its tie-breaking). A test checks stratification on the data.

## In one line

The review process ranks text over analogy over suspension, admits analogy only through a shared ʿilla, never claims adoption, and is provably deadlock-free when its tools are kept apart from what is under review.
