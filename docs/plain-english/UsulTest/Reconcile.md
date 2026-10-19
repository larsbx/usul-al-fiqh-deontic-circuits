# UsulTest.Reconcile in Plain English

Source: [`formal/lean/UsulTest/Reconcile.lean`](../../../formal/lean/UsulTest/Reconcile.lean)

Every disputed farʿ (a derived case) in the reconciliation ledger is run through the kernel's taʿāruḍ (conflict of proofs) procedure, and the result is pinned. Each case is decided twice: by the proofs its positions cite, under four policies, and by who holds each position, as a record only. The suite freezes both answers so that any change to the ledger or the kernel shows up as a failed check.

## 1. What the file is

- **Generated, not hand-written**: produced by `python -m usul_corpus reconcile` from `corpus/reconciliation/ledger.json`. It must not be edited by hand.
- **Scope**: 596 ledger entries. 588 come from Ibn Rajab's *Taqrīr al-Qawāʿid* (across 130 qawāʿid, legal maxims) and 8 from Ibn al-Laḥḥām's *al-Qawāʿid wa-l-Fawāʾid*.
- **Shape**: each entry is a comment with its ledger id (e.g. `ibn_rajab.taqrir_qawaid.openiti_rajab_shamela21730.q007.f001`), then five `#guard` checks. That gives 2,384 checks by proof and 596 by attribution, 2,980 in all.
- **Rulings as strings**: most entries ask whether a ruling holds, with positions `"true"` and `"false"`. Others name the options, such as `"whole"` vs `"part"`, `"lot"` (casting lots) or `"divide"`.

## 2. The procedure being checked

Both checks feed the kernel's `resolve` (from `Usul.Taarud`), which tries four stages in order:

1. **jamʿ** (reconciling the two sides), if the entry records one;
2. **naskh** (abrogation), if the entry records which proof came later;
3. **tarjīḥ** (preferring the stronger side);
4. otherwise **tawaqquf** (suspending judgement).

The two checks differ only in how stage 3 is filled.

- **By proof (`Usul.Tarjih.reconcile`)**: each position lists the tiers of proof it cites, such as `.zanni` (a probable text), `.qiyas` (analogy) or `.istishab` (presumption of continuity). A higher tier wins outright. Within one tier, a recorded advantage (murajjiḥ) can decide, if the policy counts it and it fits that tier.
- **By attribution (`byAttribution`)**: each position lists the madhhab labels behind it, such as `.tashih` (labelled the madhhab's sound view), `.nass` (a riwāya, a reported view of Aḥmad), `.jazm` (asserted by al-Qāḍī and followers) or `.wajh` (a bare derived view). It records what the labels favour. It never decides a case.

## 3. The four policies

Every entry is checked under all four policies from `Usul.Tarjih.Policy`, nested from narrow to wide:

| Policy | Which advantages count |
| --- | --- |
| `strict` | Only stated advantages no cited source disputes. |
| `sources` | Stated advantages a cited source asserts, disputed or not. The bank's default. |
| `applying` | As `sources`, plus advantages the bank itself applies to the proofs. |
| `all` | Every recorded advantage, weak, rejected and applied included. |

In 591 of 596 entries the four policies give the same answer. Only 11 entries record any advantage at all; the other 585 are settled by tiers or stages 1–2 alone.

The 5 exceptions show the policies at work. Each has one applied advantage (`.khass`, the specific over the general; `.sahihayn`, agreement of the two Ṣaḥīḥs; `.qawl`, the Prophet's saying over his deed; `.usulMany`, an ʿilla with more supporting cases). `strict` and `sources` ignore it and give `.tawaqquf`. `applying` and `all` count it and give tarjīḥ. Entry `q007.f001` is one: two probable texts and two qiyāsāt on each side, with "true" favoured as the more specific text only by the bank's own application.

## 4. Outcomes by proof

Under the default `sources` policy the 596 entries resolve as follows.

| Outcome | Entries | Plain English |
| --- | --- | --- |
| `.jam` | 20 | A recorded reconciliation settles it before any weighing. |
| `.naskh` | 1 | A later proof abrogates the earlier (`q100.f003`, `"false"`). |
| `.tarjih` | 235 | One position's proofs outweigh every other's. |
| `.tawaqquf` | 340 | Neither side outweighs the other; the bank suspends. |

Under `applying` and `all`, tarjīḥ rises to 240 and tawaqquf falls to 335, the 5 entries of §3. Tawaqquf is the commonest result. Typical cause: both sides cite only qiyās and no advantage separates them. For example, `q043.f005` has three qiyāsāt for "true" and two for "false". Tarjīḥ by proof does not count heads, so the result is `.tawaqquf`. 17 entries cite no proof on either side: 15 suspend, and 2 are settled by jamʿ.

## 5. Proof against attribution

The attribution check runs the same stages with the madhhab labels in the tarjīḥ slot. Its outcomes: 20 jamʿ, 1 naskh, 561 tarjīḥ, 14 tawaqquf. Labels almost always favour someone; proofs often do not.

Compared with the default `sources` result:

- **Agree**: 215 entries.
- **Proofs suspend, labels decide**: 330 entries. `q043.f005` again: the labels favour "true" (two taṣḥīḥ labels and a jazm against one naṣṣ), though neither side's proofs outweigh the other's.
- **Both decide, but differently**: 47 entries. In `q052.f001` the proofs favour "false" (two qiyāsāt over an istiṣḥāb), while the labels favour "true".
- **Proofs decide, labels suspend**: 4 entries.

This is the point of keeping the record: it shows where the madhhab's labels and the weight of the cited proofs part ways.

## 6. Why the suite matters

- It locks the ledger's verdicts. A change to an entry's proofs, labels or advantages changes a result and fails a guard until the file is regenerated.
- It locks the kernel. A change to `resolve`, to tier ranks, to the policies or to `prevail` that shifts any of 2,980 results is caught.
- It keeps the principle visible: "a ruling stands by its proof, not by who holds it". The proof checks are the verdicts; the attribution checks are a description beside them.

## In one line

For each of 596 disputed cases from Ibn Rajab and Ibn al-Laḥḥām, the suite pins what jamʿ, naskh, tarjīḥ by proof under four policies, and the madhhab's labels each conclude, so any drift in the data or the kernel is caught.
