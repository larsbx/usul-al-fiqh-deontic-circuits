# Usul.Typing.Relations in Plain English

Source: [`formal/lean/Usul/Typing/Relations.lean`](../../../../formal/lean/Usul/Typing/Relations.lean)

Some facts are one notion stated at two levels: a farʿ (branch case) settles a fact of the qāʿida above it. These links are recorded as one-way implications, applied only where a situation leaves a fact open. A fact a text states is never overridden.

## 1. Fields and implications

- **`BoolField`**: a yes/no fact of a `Situation`, with a way to read it and a way to write it. The `Field` namespace defines twelve, e.g. `yearPassed`, `despair`, `unknown`, `ownerIdentifiable`, `negligentQ95`.
- **`Implication`**: a list of premises and a list of consequents, each a field with a value.
- **`fire`**: if every premise holds, fill each consequent that is still unknown. Known facts are left as they are.
- **`saturate`**: run every implication, repeated once per implication, so chains of links settle.

## 2. The relations

| Relation | From | To |
| --- | --- | --- |
| `rukhsaNeedsFirm` | 68.f001: a rukhṣa (dispensation) needs its permission established | 68: firm intention is required |
| `yearDespair` | 106.f002: the luqaṭa after its year | 106: despair of finding the owner |
| `unidentifiedIsMajhul` / `majhulIsUnidentified` | al-Saʿdī Q20: right-holder unknowable | 106: unknown and despaired of, and back |
| `knownIsIdentified`, `hopedIsIdentified` | 106: not unknown, or not despaired of | Q20: owner identifiable |
| `consumedIsMajhul` | Ibn Rajab 22: a thing absorbed without trace | 106: unknown and despaired of |
| `q95IsInquiry…`, `inquiryIsQ95…` | 95: negligence by not checking | 6: negligence in inquiry, both ways, both values |
| `despairedIsDespair`, `hopedIsNotDespair` | 97: owner's return despaired of / hoped for | 106: despair |
| `knownOwner…`, `unknownOwner…` | 97: owner known | 98: owner unknown, both ways, negated |
| `unknownOwnerIsMajhul` | 98: owner unknown | 106: unknown |

The texts fix the direction. 106's despair is wider than 97's (it covers the mustaḥāḍa's blood), so only 97 ⇒ 106. 106's unknown is wider than 98's (an heir, a time), so only 98 ⇒ 106. 95 and 6 describe the same negligence and neither builds on the other, so they are linked both ways.

## 3. The relations at work

| Theorem | Plain English |
| --- | --- |
| `year_settles_despair` | A luqaṭa past its year is a case of despair. |
| `rukhsa_settles_firmness` | A rukhṣa that needs certainty needs firm intention. |
| `stated_fact_kept` | If a text says the year passed but the owner is still hoped for, despair stays false. |
| `consumed_is_unidentified` | Chains settle: consumed ⇒ unknown and despaired of ⇒ the right-holder cannot be identified. |
| `luqata_routes_to_majhul` | After saturation, a luqaṭa past its year reaches 106's encoder `unknownAsNonexistent`. |
| `istihlak_agrees` | On a consumed thing, 106's encoder rules as the `istihlak` encoder does. The kernel already assumed this link. |

## 4. The look-alikes at work

| Theorem | Plain English |
| --- | --- |
| `q95_negligence_is_inquiry` | 95's negligence settles 6's; 6's diligent qibla-seeker settles 95's. |
| `q97_despair_is_106` | 97's despaired-of owner, known by identity, gives 106's despair and leaves 106's "unknown" open. |
| `q97_unknown_owner_is_unidentified` | 97's unknown owner, despaired of, chains through 98 and 106 to Q20: not identifiable. |
| `q98_owner_is_106_unknown` | 98's unknown owner settles 106's unknown; 106's unknown does not settle 98's. |

All are proved by running the computation (`decide`).

## In one line

Where texts say one fact is another stated at a different level, the link is recorded in the direction the texts give, fills only what is still open, and lets a case reach every maxim its facts imply.
