# A Short Primer on Specifying and Applying Rulings

In the name of Allah, the Most Merciful, the Especially Merciful. Praise be to Allah, and blessings and peace be upon the Messenger of Allah.

## 1. The five rulings on conduct

A ruling on conduct (*taklīfī*) classifies an act as obligatory (*wājib*) if it must be done, recommended (*mandūb*) if doing it is encouraged, permitted (*mubāḥ*) if either choice is allowed, disliked (*makrūh*) if leaving it is encouraged, or forbidden (*ḥarām*) if it must be avoided.

## 2. Kinds of legal question

Ask separately how an act is classified and whether it is valid. Other questions concern what triggers a ruling (*sabab*), what it requires as a condition (*sharṭ*), or what prevents it from applying (*māniʿ*).

## 3. Who and what the ruling concerns

Identify the person to whom the ruling applies. Then specify the act, omission, or state under inquiry. For an act such as payment, identify the payer, the recipient, and what is paid. The person who performs the act may differ from the person to whom the ruling applies.

For an omission, identify the act and the particular occasion on which it could have been performed. State how time is measured and when the opportunity begins and ends. For a state such as fear, name the state and what it concerns.

## 4. When two premises concern the same inquiry

Record the question, the person to whom the ruling applies, what the ruling concerns, the circumstances, and the time. Also record the adopted interpretive profile, which specifies how the sources are interpreted for the inquiry, and the version of that profile. The rule in the next chapter applies only when the two required premises match on all seven points.

## 5. Combining required premises

A premise may specify one ruling or leave several possible. Ruling out prohibition leaves four possibilities.

Apply these rules in order.

1. If either premise expressly withholds judgment, withhold judgment.
2. Otherwise, if either supplies no ruling, give no combined ruling.
3. If both supply possible rulings, keep those they share. If they share none, record a conflict.

Keep distinct juristic views with their attributions.

## 6. Performing an act and leaving it undone

For the same act and opportunity, doing it is obligatory if leaving it is forbidden, and vice versa. Doing it is recommended if leaving it is disliked, and vice versa. If doing it is permitted, so is leaving it.

Observation establishes nonperformance only after the opportunity ends, when it covers every recognized way to perform the act and shows no completion.

## 7. Evidence and application

For each premise, record its source and exact passage, the interpretation used and its version, and the evidence grade. Check three things separately. Does the reference point to the stated passage? Does the premise meet the requirements for use in this inquiry? Does the conclusion follow from the premises?

To use the same form of inquiry in a new case, fill each role with the appropriate kind of person or thing. Check again that each premise meets the requirements for use in the new case.

## An example of specifying a case

In this example, a debt can be repaid by the debtor or an authorized agent. Identify the debtor, creditor, debt, permitted payer, and payment window. If the deadline passes and records covering only the debtor’s payments show none, those records leave open whether the agent paid.

## Source and verification note

This is an original teaching adaptation of the [Islamic Deontic Algebra specification](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/10ec32734e3e8c953536e9c999c3d50a8bed8a6a/docs/research/islamic-deontic-algebra-spec.md) and its implemented fragments on [main at `10ec327`](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/commit/10ec32734e3e8c953536e9c999c3d50a8bed8a6a). The specification names Ḥanbalī source profiles as its initial doctrinal scope. The wording of this primer is an editorial synthesis, and the repayment example is synthetic. Lean proves properties of the encoded rules, including the scope guard, and Quint independently checks outputs over declared finite cases. The source inspection for this primer did not rerun those checks. A judgment about an actual case also requires juristic assessment of the sources, their interpretation, and the facts.

- Rulings and the omission operation. [Hukm.lean](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/10ec32734e3e8c953536e9c999c3d50a8bed8a6a/formal/lean/Usul/Hukm.lean) · [IDA.lean](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/10ec32734e3e8c953536e9c999c3d50a8bed8a6a/formal/lean/Usul/IDA.lean) · [ida.qnt](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/10ec32734e3e8c953536e9c999c3d50a8bed8a6a/formal/quint/ida.qnt)
- Answer types, exact scope, and required premises. [ida-judgment-records.md](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/10ec32734e3e8c953536e9c999c3d50a8bed8a6a/docs/research/ida-judgment-records.md) · [ida-foundation.md](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/10ec32734e3e8c953536e9c999c3d50a8bed8a6a/docs/research/ida-foundation.md) · [ida-source-derivations.md](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/10ec32734e3e8c953536e9c999c3d50a8bed8a6a/docs/research/ida-source-derivations.md)
- Typed objects and accepted context theory. [ida-act-reference.md](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/10ec32734e3e8c953536e9c999c3d50a8bed8a6a/docs/research/ida-act-reference.md) · [ida-context-theory.md](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/10ec32734e3e8c953536e9c999c3d50a8bed8a6a/docs/research/ida-context-theory.md) · [ida-context.qnt](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/10ec32734e3e8c953536e9c999c3d50a8bed8a6a/formal/quint/ida-context.qnt)
- Substitution, interpretation, and admission. [ida-substitution.md](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/10ec32734e3e8c953536e9c999c3d50a8bed8a6a/docs/research/ida-substitution.md) · [ida-semantics.md](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/10ec32734e3e8c953536e9c999c3d50a8bed8a6a/docs/research/ida-semantics.md) · [ida-admission.md](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/10ec32734e3e8c953536e9c999c3d50a8bed8a6a/docs/research/ida-admission.md)
- Observation and the repayment exercise. [ida-omission-coverage.md](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/10ec32734e3e8c953536e9c999c3d50a8bed8a6a/docs/research/ida-omission-coverage.md) · [ida-omission.qnt](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/10ec32734e3e8c953536e9c999c3d50a8bed8a6a/formal/quint/ida-omission.qnt) · [ida-pilot-trace.md](https://github.com/larsbx/usul-al-fiqh-deontic-circuits/blob/10ec32734e3e8c953536e9c999c3d50a8bed8a6a/docs/research/ida-pilot-trace.md)