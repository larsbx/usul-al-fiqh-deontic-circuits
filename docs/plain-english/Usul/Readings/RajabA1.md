# Usul.Readings.RajabA1 in Plain English

Source: [`formal/lean/Usul/Readings/RajabA1.lean`](../../../../formal/lean/Usul/Readings/RajabA1.lean)

Four of Ibn Rajab's qawāʿid (60, 67, 69, 71) become small Boolean rules, each read from the qāʿida's own statement. They cover rescinding harmful contracts, recourse after a returned right, delegating contracted work, and eating from another's property. A takhrīj suite tests them against the furūʿ (derived cases). Status: candidate.

## 1. Qāʿida 60: rescinding a non-binding contract

- **`Rescission`**: barred, allowed with the harm made good, or free.
- **`rescission harm remediable`**: without harm, rescission is free. With harm that liability or the like can repair, it goes ahead with that remedy. With irreparable harm to a party or someone connected to the contract, it is barred.

## 2. Qāʿida 67: a right that came back by gift or release

- **`recourseAfterReturn`**: one owed recourse whose right came back by gift (hiba) still has recourse for its substitute; by release (ibrāʾ) he does not. A gift means ownership left and returned; a release means it never left. This follows Ibn Rajab's own takhrīj that separates the two.

## 3. Qāʿida 69: delegating contracted work

- **`mayDelegate binding personalRequired permissionIndicated`**:
  - Under a binding contract (like hire), he may delegate unless a condition or indication requires him personally.
  - Acting by bare permission, he may not delegate unless explicit permission or an indication of it is present.
  - Guardians (wilāya) fall on one side or the other through the same facts.

| Theorem | Plain English |
| --- | --- |
| `delegation_defaults_differ` | With no condition or indication, the bound party may delegate and the permitted one may not. |

## 4. Qāʿida 71: eating from property without its owners' permission

- **`mayEat`**: eating is allowed under necessity (ḍarūra); or by a guardian over a ward, in return for his work, unless he is paid otherwise; or from unguarded things people crave.

| Theorem | Plain English |
| --- | --- |
| `necessity_permits` | Necessity permits eating whatever the other facts. |

## In one line

Four maxims of Ibn Rajab become exact Boolean rules: harm bars rescission unless repairable, a gift founds recourse and a release does not, binding work may be delegated by default, and necessity always permits eating.
