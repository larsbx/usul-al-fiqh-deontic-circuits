# Usul.DerivedTypes in Plain English

Source: [`formal/lean/Usul/DerivedTypes.lean`](../../../formal/lean/Usul/DerivedTypes.lean)

Existing Boolean readings get typed counterparts that carry their own proof. A value of such a type is a certificate: an admitted case, a certain belief, an optimal choice, a valid analogy. Each certificate vouches only for the formal reading it refines, not for the reading's admission from the sources. Terminology is in `docs/architecture/derived-types-glossary.md`.

## 1. Certified values

Each is a value bundled with a proof that it passes a test.

- **`Admitted g`**: a case that passes the gate g (all conditions met, no impediment).
- **`CertainHeld`**: a held belief that is certain (yaqīn).
- **`GroundedHeld`**: a held belief that is not suspended. A ẓann (preponderant belief) whose preponderance is unknown counts as suspended.
- **`NecessityAllowance need`**: an amount of a forbidden thing taken under necessity (ḍarūra), no more than the need.
- **`CoherentRequirement`**: a contract requirement where knowledge is required only if consent is (al-Saʿdī Q45).
- **`AdmittedDeal`**: a transaction that passes the deal gate.
- **`OptimalChoice key options`**: an option no other option outscores.

## 2. Certifying functions

| Definition / Theorem | Plain English |
| --- | --- |
| `normalizeRequirement` | Turns any requirement into a coherent one, by dropping an unsupported knowledge requirement. |
| `certifyChoice` | Picks the best option with a proof that it is optimal, or none if the list is empty. |
| `certifyChoice_erases` | Dropping the proof gives exactly al-Saʿdī's `best`. |
| `doubt_preserves` | A certain belief is not displaced by doubt (al-yaqīn lā yazūl bi'l-shakk). |

## 3. Applying a ruling

- **`Applicable w`**: an act and a subject with evidence of all four premises: the cause (sabab), the condition (sharṭ), absence of the impediment (māniʿ), and legal responsibility (taklīf).
- **`applyRuling`**: apply a ruling once those premises are certified. It certifies this one application, not general validity.

## 4. Factored rulings and analogy

- **`FactoredRuling`**: a ruling given explicitly as "read a feature, then evaluate it", with proof the two agree.
- **`FactoredRuling.factors`**: such a ruling factors through its feature.
- **`destructionLiability`**: example. Liability for destroying property depends only on whether it was done by right (al-Saʿdī Q13), not on the mental state.
- **`ObservedDawaran`**: a certificate that a description co-varies with the ruling across the known cases (dawarān). It is not a certificate of a transferable ʿilla.
- **`AdmittedQiyas`**: an analogy argument that passes the qiyās gate.
- **`CertifiedTransfer H`**: an admitted analogy, plus proof that the ruling H agrees with the known cases and factors through the ʿilla.
- **`CertifiedTransfer.conclusion`**: then H gives the new case (farʿ) the source case's ruling.

## 5. Discharging owed acts (Q41)

- **`DischargePlan r owed`**: a list of performed acts with proof that each owed act is discharged by one of them.
- **`representativePlan`**: builds one by keeping representatives, for any reflexive merging relation.
- **`DischargePlan.dischargesEach`**: each owed act has a performed witness. No equivalence assumption is needed.
- **`worshipPlan`**: the Q41 instance. Acts of worship of the same kind and purpose merge. Extra source conditions must come from a different relation.

## 6. Taking one's due (Q46)

A creditor whose claim is evident may take his due from a refusing debtor's property, up to the amount owed.

- **`TakingContext`**: whether the cause is evident, whether the debtor refuses, and the claim.
- **`TakingPermission`**: a certificate for an amount, with proofs of all three conditions.
- **`certifyTaking`**: issues a certificate when the conditions hold.

| Theorem | Plain English |
| --- | --- |
| `TakingPermission.permitted` | A certificate implies the Boolean rule `mayTake` says yes. |
| `certifyTaking_complete` | A certificate is issued ⟺ `mayTake` says yes. |
| `hiddenCause_noPermission` | A hidden cause ⇒ no certificate. |
| `excessiveTaking_noPermission` | No certificate covers more than the claim. |

## In one line

Boolean readings gain proof-carrying types, so admitted cases, certain beliefs, optimal choices, valid analogies and bounded permissions come with their justification, certifying the formal reading but not its source.
