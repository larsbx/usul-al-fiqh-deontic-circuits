# Reconciliation: the bank's taʿāruḍ procedure applied to its own furūʿ

The bank's kernel already has a procedure for conflicting adilla: `Usul.resolve` (`formal/lean/Usul/Taarud.lean`), after Ibn ʿUthaymīn. It tries jamʿ first, then naskh, then tarjīḥ, and suspends judgement (tawaqquf) when all three fail. `Usul.Reconcile` (`formal/lean/Usul/Reconcile.lean`) points that procedure at the bank itself, so the bank works through its apparent contradictions by its own rule rather than by an outside judgement.

## What counts as an apparent contradiction

An **apparent contradiction** is an ikhtilāf farʿ where the reading does not land on the madhhab's marked side (`matches_madhhab` is false). There are two adilla in play:

- the reading, which is the qāʿida as formalised;
- the reported positions on that farʿ.

All of them sit in `corpus/reconciliation/ledger.json`. When a new tranche adds one, `reconcile.check` fails until it gets a ledger entry, and `python -m usul_corpus reconcile --draft` proposes grades for the reviewer to correct.

## The four stages

`reconcile jam naskh ps = resolve ⟨jam, naskh, prevail ps⟩`

| Stage | Offered when | Checked by |
|---|---|---|
| jamʿ | The source cites a farq. The case is re-encoded under a refinement whose dossier entry names a conservativity theorem over the earlier reading. | Python checks that every farʿ the refinement moves away from the earlier reading lands on its prevailing side, and that at least one farʿ moves. Lean checks the theorem and the re-encoded guards. |
| naskh | A later riwāya or a retraction (rujūʿ) with reported chronology. | The ledger's `naskh.ref`. |
| tarjīḥ | Some ruling's graded support strictly exceeds every other ruling's. | `prevail`, which carries `prevail_mem` (it never invents a ruling) and `prevail_unanimous`. |
| tawaqquf | Every earlier stage fails. | `reconcile_tawaqquf_iff`. |

**Grades (`Usul.Reconcile.Grade`), strongest first.** The first five are the annotation convention's marked sides (`Grade.marked`):

1. **taṣḥīḥ:** the aṣḥāb label a position «المذهب», «المشهور», «الأشهر» or «الصحيح».
2. **naṣṣ:** a riwāya or a manṣūṣ of Aḥmad.
3. **ẓāhir:** the ẓāhir of Aḥmad's words.
4. **qiyās:** qiyās al-madhhab, or qiyās al-manṣūṣ.
5. **jazm:** the aṣḥāb at large: «الأصحاب», most of them, or the ẓāhir of the aṣḥāb.
6. **aṣḥāb:** one named companion's choice. This includes an author's own «الأظهر» or «الصواب»: an author weighing the evidence is not labelling the madhhab.
7. **takhrīj:** a takhrīj or an iḥtimāl.
8. **wajh:** a bare wajh.

**Tarjīḥ.** Each position lists the distinct grades of the people who hold it. Positions with the same ruling pool their grades, and a ruling's support is its pooled grades sorted strongest first. Supports are compared lexicographically, so a weaker grade never outweighs a stronger one, however many hold it. When two supports share every grade, the longer one wins, following «الأكثرون». Named companions do not count individually, so two of them against one is still a tie.

**Lean is the authority.** `UsulTest/Reconcile.lean` holds one generated guard per entry, so the Python mirror cannot drift from `Usul.Reconcile.reconcile`. A test also pins the grade ranks to the Lean definition.

## First pass over the bank (128 contradictions)

| Stage | Entries | Standing |
|---|---|---|
| jamʿ | 3 | for the reading |
| tarjīḥ | 54 | 29 for the reading, 25 against |
| tawaqquf | 71 | — |

- **The one jamʿ is qāʿida 37 (`successive_by_binding`).**
  - The tranche-6 reading let the later contract always govern. That ran against Majd's ẓāhir of Aḥmad on the pledge used with permission (37.f000) and against Aḥmad's riwāya on the pledge with a void condition (37.f006).
  - Abū al-Barakāt's own farq is the jamʿ: «ويسقط ضمان العارية لأنها ليست لازمة، وعقد هذه الأمانة لازم» (37.f003). Under it, the later contract governs where it binds, or where the earlier one did not.
  - Two theorems show the refinement is the old reading on every farʿ where that holds: `laterBindingGoverns_conservative` and `laterBindingGoverns_unbound_earlier`. So 37.f002–f005 keep their rulings.
  - 37.f000 and 37.f006 move to the higher-graded side.
  - 37.f001 (the deposit) stays liable, and Majd's own «وفرق صاحب المحرر بينهما» separates it from the pledge.
  - Madhhab coverage rises from 0.642 to 0.647.
- **The 25 residues are the refinement worklist** (`corpus/reconciliation/report.json`, `worklist`). These are furūʿ where tarjīḥ goes against the reading, grouped by encoder. The largest groups:
  - `lots` (7): the manṣūṣ and the mashhūr exclude lots where the reading allows them.
  - `asl_zahir` (3) and `tadakhul` (3): the mashhūra riwāya against the reading.
  - `words_out_of_nature` (2): qāʿida 38, where the madhhab follows the wording. No farq is cited there, so no jamʿ is possible, and the residue stands as the record.
- **Nine reviews** (`review`): tarjīḥ gives the reading a marked side while the annotation says no madhhab matches. Examples are the naṣṣ of Aḥmad against a takhrīj (75.f005, 75.f007) and al-Talkhīṣ's qiyās al-madhhab (133.f018). These are questions for the human reviewer. Annotations are never rewritten from here.
- **No naskh yet.** None of the annotated paragraphs reports the chronology of a retraction.

Everything here has status `candidate`. The grades are a reading of the annotated paragraph. A resolution is "derivable under the encoding", never a fatwā.
