# Usul.Tarjih in Plain English

Source: [`formal/lean/Usul/Tarjih.lean`](../../../formal/lean/Usul/Tarjih.lean)

Tarjīḥ (preferring one position over another) weighs the proofs each position cites, never who holds it. A proof of a higher tier beats a lower one outright. Within one tier, a stated advantage (murajjiḥ) decides only if the other side has none back. When nothing settles it, the bank suspends judgement. The source is Ibn Qudāma's *Rawḍat al-Nāẓir*, with additions from Ibn al-Najjār's *Sharḥ al-Kawkab al-Munīr* and al-Ṭūfī's *Sharḥ Mukhtaṣar al-Rawḍa*.

## 1. Tiers of proof

- **`Tier`**: eight tiers, weakest first: istiṣḥāb (presumption of continuity), qiyās (analogy), mursal or ḍaʿīf report, the Companion view nearest the text, the undisputed fatwā of a ṣaḥābī (Companion), a ẓannī (probable) text, a qaṭʿī (certain) text, and ijmāʿ (consensus).
- **`Tier.kind`**: maps each tier to its kind in Aḥmad's order. A qaṭʿī text is certain in both transmission and meaning; a ẓannī text is an āḥād (single-chain) report or a text read by generality, apparent sense or interpretation.
- Ibn Qudāma: «لا يتصور أن يتعارض علم وظن», knowledge and probable belief cannot conflict. So a higher tier is never weighed against a lower one.

| Theorem | Plain English |
| --- | --- |
| `Tier.rank_injective` | Distinct tiers have distinct ranks. |
| `Tier.refines_resort` | The tiers never invert Aḥmad's order of resort: a stronger tier is never consulted later. |

## 2. The advantages (murajjiḥāt)

- **`Murajjih`**: 46 advantages, grouped by where they bear:
  - **the chain**: more narrators, a more precise or more pious narrator, the one the event concerned, one who took part;
  - **the text**: corroboration, agreed raising to the Prophet, a narrator who does not contradict himself, a connected chain;
  - **from outside**: what moves away from the original state, the affirming report;
  - **between ʿilal** (legal causes in qiyās): such as an effective cause, a suitable cause, a cause attested by more sources;
  - **the indication** (al-Kawkab, al-Ṭūfī): the Prophet's saying over his deed, prohibition over command, the specific over the general, the explicit over the implied, the literal over the figurative, agreement of the two Ṣaḥīḥs, the view of the more learned Companion;
  - **called weak or rejected**: a lighter ruling, a sensible cause, fewer properties, warding off the ḥadd (fixed penalty). These are recorded, not dropped.
- **`Standing`**: how the sources hold each advantage: asserted, disputed, weak or rejected. **`Murajjih.standing`** assigns it, with the sources quoted.
- **`Domain`** and **`Murajjih.domain`**: what an advantage weighs: reports, texts, ʿilal, or Companion views. **`Domain.admits`** says which tiers each domain can weigh.
- **`Murajjih.admitsRank`**: an advantage can weigh two proofs of a given tier only if its domain admits that tier.
- **`Basis`**: an advantage is *stated* (a source compares the two proofs itself) or *applied* (the bank applies a murajjiḥ to properties the proofs show).

| Theorem | Plain English |
| --- | --- |
| `admitsRank_ijma` | No advantage weighs ijmāʿ: it is not weighed. |
| `admitsRank_istishab` | No advantage weighs istiṣḥāb: it is the last resort. |

## 3. Policies

- **`Policy`**: which standings count, and whether applied advantages count.
- **`strict`**: only stated, undisputed advantages.
- **`sources`**: the default. Stated advantages a source asserts, disputed or not.
- **`applying`**: as the default, plus the bank's own applications.
- **`all`**: everything recorded, weak, rejected and applied included.

| Theorem | Plain English |
| --- | --- |
| `strict_le_sources`, `sources_le_applied`, `le_all` | The policies are nested: strict ⊆ sources ⊆ applying ⊆ all. |
| `sources_false_iff` | The default leaves out exactly the weak and the rejected. |
| `sources_stated_only` | The default counts only stated advantages. |

## 4. The weighing

- **`Advantage`**: one recorded preference: winner, loser, which murajjiḥ, and its basis. **`Advantage.counts`** says whether a policy counts it.
- **`top`**: the highest tier among the proofs a position cites, or none.
- **`favours`**: some counted advantage, of a kind that fits the tier, prefers p to q.
- **`beats`**: p outweighs q ⟺ p cites a proof and q none; or p's top tier is higher; or the tiers are equal, an advantage favours p, and none favours q.
- **`prevail`**: the reported position that outweighs every other, if any.
- **`reconcile`**: the full procedure: the kernel's `resolve` (jamʿ, naskh, then this tarjīḥ, else tawaqquf).

| Theorem | Plain English |
| --- | --- |
| `prevail_mem` | Tarjīḥ never invents a ruling; the winner is a reported position. |
| `beats_unproven` | A position citing no proof outweighs nothing, whoever holds it. |
| `beats_of_tier` | A higher tier wins, whatever advantages the lower one has. |
| `not_beats_of_tier` | No advantage lifts a lower tier. |
| `beats_policy_irrelevant` | Across tiers the policy makes no difference. |
| `beats_asymm` | Outweighing is one-way, so at most one position prevails. |
| `favours_uncounted` | Advantages the policy does not count never decide. |
| `favours_sources_weak` | Under the default, weak or rejected advantages never decide. |
| `favours_applied_ignored` | A policy that ignores applied advantages is decided by stated ones only. |
| `favours_out_of_domain` | An advantage outside its domain never decides; a report's murajjiḥ cannot weigh two qiyāsāt. |
| `reconcile_jam_first` | Reconciliation, if available, comes first. |
| `reconcile_tawaqquf_iff` | Suspension ⟺ no reconciliation, no abrogation, and no prevailing position. |

## 5. Checked examples

Fifteen `#guard` checks run the procedure on small cases. Representative ones:

- A report outweighs a qiyās, whatever the qiyās's advantages.
- Two reports: the connected one beats the mursal.
- Advantages on both sides: no winner, so tawaqquf.
- A weak advantage (lighter ruling) decides only under `all`.
- An advantage outside its domain decides nothing, even under `all`.
- A disputed advantage decides by default but not under `strict`.
- An applied advantage decides under `applying` but not under `sources`.
- Nothing cited on either side gives tawaqquf; a qaṭʿī text beats a ẓannī one, giving `.tarjih`.

## In one line

Positions are weighed by the tier of the proofs they cite and, within a tier, by advantages the sources state, under an explicit policy; when that does not settle it, the bank suspends rather than choose by who holds the view.
