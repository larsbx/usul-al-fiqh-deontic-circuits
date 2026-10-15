# PR #88: source-publication and LFS audit

Audit date: 2026-10-15. Original PR head: `cfae12154bf92a7fec24a8e0f408fc0124bf6d9f`.
This is a documentary-evidence audit, not a finding of infringement or scholarly acceptance.

## Decision and scope

The blanket `noncommercial_text` publication rule is withdrawn. None of the 36
proposed noncommercial text witnesses had a located grant sufficient to establish
this repository's authority to redistribute the **complete pinned file**, including
all modern contributions. All 35 affected works (34 reclassifications plus the new
*Ghurar*) return to `modern_cache_only`; one work has only binary witnesses.

Every one of the 36 text witnesses has a `publication` assessment on its existing
witness entry in `corpus/registry.json`, bound to the existing lock digest. No IDs,
source locks, source files or scholarly records were rewritten. An additional two
new al-Shawkānī edition files are held at witness level while their underlying
historical works retain `public_domain_text`. The existing 89 committed files
retain legacy eligibility; this audit does not certify their modern editions.

| Source group | Witnesses | Evidence located | Missing basis for full-file redistribution |
|---|---:|---|---|
| OpenITI | 11 | General CC BY-NC-SA 4.0 corpus license; exact pinned source bytes and edition headers | Coverage of modern authors, commentary, compilations and editorial contributions in each complete file |
| Shamela with publisher gift | 3 | Catalogues for 266, 282 and 337 credit ʿAṭāʾāt al-ʿIlm with providing the books to Shamela | Documentary scope allowing onward redistribution by a third-party repository |
| Other Shamela | 20 | Accessible catalogue identifies the book/edition; repository source identity is locked | A grant from the relevant rights holders covering complete rendered files |
| Internet Archive OCR | 2 | Item metadata fetched for `Pdf1995` and `20210501_20210501_0220` | Neither metadata record supplies `rights` or `licenseurl`; uploader authority and edition-specific grant remain unverified |

**Adequately evidenced:** source identity/provenance as specified below, the
OpenITI provider-level license, and the three named gifts to Shamela. **Needs
additional documentation:** those partial grants' coverage and scope. **Not
independently verified:** complete-file redistribution permission for all 36.
No individual private permission document was present in the registry, rights
policy or examined PR discussion. That absence does not establish that no such
permission exists elsewhere.

## Distinct rights layers

1. **Underlying work:** a historical matn's age and author do not decide the status
   of a modern commentary, abridgment, compilation or edition.
2. **Editorial contributions:** the locked *Madkhal* header names al-Turkī; the
   *Bāʿith* header names Ibn Kathīr and Aḥmad Shākir separately. Shamela 9293 combines
   al-Shawkānī, Ṣiddīq Ḥasan Khān, al-Albānī and al-Ḥalabī. Shamela 22592 also
   includes modern supplementary takhrīj. Each complete file needs a basis covering
   all included layers, or an independently pinned and reviewed extraction that
   actually removes unlicensed contributions.
3. **Provider terms:** [OpenITI documentation](https://openiti.org/documentation/#how-can-i-use-openiti-what-license-is-used)
   states CC BY-NC-SA 4.0 and separately requires removal of protected editorial
   matter during annotation. [Its platform terms](https://openiti.org/docs/Terms%20of%20Use.html)
   do not provide an edition-specific clearance; their mixed license wording must
   not replace the corpus-specific statement. [The CC license](https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode.en)
   covers rights the licensor has authority to grant and requires attribution,
   applicable notices and noncommercial use (plus ShareAlike for adaptations).
4. **Study access:** Shamela's [project description](https://shamela.ws/) describes
   reading/search/copy access. Its [MCP terms](https://shamela.ws/page/terms), dated
   September 19, 2026, expressly preserve book/edition rights. Those terms are
   service-specific, not a general license for its HTML corpus. The three catalogue
   gift notices evidence provision to Shamela, not an express downstream grant.
   [Internet Archive](https://help.archive.org/help/rights/) does not guarantee
   item copyright status. Availability, a download button, or a noncommercial
   purpose is insufficient evidence for this publication decision.
5. **Repository distribution:** the GitHub API reported this repository as
   **private**, contrary to the task's public-repository premise. Privacy does not
   supply third-party rights. The gate assesses complete-file **public**
   redistribution so a later visibility change cannot silently turn a study label
   into publication approval.

The two additional holds are `openiti-shawkani-durarbahiyya-shamay34280` (Ḥallāq,
Dār al-Nadā 1413 AH) and `openiti-shawkani-dararimudiyya-shamela7264` (Dār al-Kutub
al-ʿIlmiyya 1407/1987, no editor identified in the header). Neither has a documented
complete-edition clearance or editorial-removal assessment. *Ghurar*'s full file
also contains its modern commentary endnotes: stopping the **segmenter** at
`|EDITOR|` does not strip those bytes from a published source file.

## Byte integrity and availability

At the original head, **127/127 Git blobs were LFS pointers**. Each declared oid
and size matched `corpus/lock.json`; their sizes sum to **558,484,421 bytes**
(558.5 MB, about 0.520 GiB). This proves pointer/lock consistency only. The old
test did not check pointer size and did not download complete LFS objects.

Separately, all **13 pinned OpenITI source URLs** in this audit (the 11
noncommercial witnesses plus the two new al-Shawkānī editions) were downloaded
from their source provider and matched the lock SHA-256. This establishes source
byte identity, **not GitHub LFS delivery**. Shamela's direct HTTP requests returned
403 in the audit runtime; catalogue metadata was readable through web retrieval.
Both Archive item metadata endpoints were readable. A later source download of
`archive-pdf1995` also matched its lock (328,323 bytes); the other OCR source,
`archive-manzuma-djvu`, returned HTTP 500. No complete Shamela byte recheck is
claimed. These source-provider results still do not establish LFS delivery.

After the holds, the retained LFS inventory is **89 files, 368,538,677 declared
bytes** (about 0.343 GiB). The new `text-publication.yml` workflow downloads only
that retained inventory, hashes actual bytes and checks sizes against the lock.
It records `pointer_only`, `unhydrated`, `bytes_verified`, missing and mismatch
states separately. A missing or quota-blocked download is a failed byte gate;
source-provider fallback cannot make it pass. Read the run's
`text-publication-verification` artifact for the actual outcome. This document
records no LFS delivery success until such a run succeeds. The 38 removed files'
LFS delivery remains outside the retained-inventory run.

[GitHub's current billing documentation](https://docs.github.com/en/billing/concepts/product-billing/git-lfs)
lists 10 GiB storage and monthly download bandwidth for Free/Pro and 250 GiB for
Team/Enterprise Cloud, not a universal 1 GB/month allowance. Actual remaining
account quota, budgets and billing configuration were not accessible to this
audit. Actions downloads count against the owner's bandwidth; cached objects are
rehashed locally. A fresh retained-inventory download is about 0.343 GiB; repeatedly
downloading the original corpus would use about 0.520 GiB each time. All historical
LFS objects can contribute to storage, so current-tree size is not account usage.
Removing pointers here does **not** purge earlier commits, PR refs or hosted LFS
objects. Squash integration avoids importing the PR's intermediate source-addition
commits into main, but is not a server-side purge. Do not describe this change as
complete historical removal or make the repository public on that assumption.

## Validation and integration

The registry remains authoritative. Its schema requires a dated, digest-bound
publication assessment and evidence addressing work, edition and provider for a
`redistribute` decision. The staging and committed-file checks reject a bare
`noncommercial_text` label, a cache-only hold, changed digests and conflicting
aliases. These checks establish documentary completeness, not legal validity of
an assertion. Approval still requires reviewing the evidence.

Preserved: `body_headings`, `kitab_headings`, the nikāḥ correction, the 123 *Ghurar*
and 127 *Darārī* units, reception distinctions, and `IncompleteRead` retry handling.
No review status is promoted. Local focused publication and segmentation tests
pass; the full integrated corpus, Lean and TLA checks remain CI obligations.

To lift a hold, attach evidence to the **existing witness entry** that identifies
the authorized grantor, the exact edition/content covered, full-file public
redistribution scope, attribution and applicable conditions, and bind it to the
current lock hash. For a modern work, also change its work classification to
`noncommercial_text`; unapproved sibling witnesses must retain their individual
holds. Alternatively retain the hold and use the permitted local study workflow. No rights-holder contact or billing changes were made. Integration is conditioned on the corrected publication gate and
repository checks, not on silently asserting that missing rights were granted.
