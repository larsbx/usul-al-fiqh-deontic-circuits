# Committed witness texts

`registry.json` is the source of truth for works, witnesses and witness-level
`publication` decisions; `lock.json` is the source of truth for byte identity.
No separate permissions registry is maintained.

The PR #88 audit retains **89 legacy text witnesses** (368,538,677 declared
bytes). The 36 proposed noncommercial text publications and two new modern-edition
al-Shawkānī witnesses are **cache-only** pending evidence covering complete-file
redistribution. Their source pins, scholarly records and segmentation remain.
See the [audit](../../docs/architecture/pr88-source-publication-audit-2026-10-15.md).
The retained legacy classifications are not a new edition-by-edition clearance.

## Publication rule

`noncommercial_text` describes intended use, not an automatic grant. Publication
requires an inline witness record with `decision: redistribute`, the current
locked SHA-256, a dated assessment, the granting authority, attribution and
conditions, and evidence addressing the underlying work, edition contributions
and source provider. Evidence must cover `complete_text_public_redistribution`.
A `cache_only` decision overrides even a public-domain work label. PDF and DOC
witnesses remain unstaged. The schema and gate validate record structure and
byte binding; reviewers must assess whether the cited evidence actually supports
its claims. A repository owner's study authorization is not a third-party grant.

## Reproducible checks

- `make texts-check`: publication eligibility and pointer oid **and size** against
  the lock. `pointer_only` means no source bytes were checked.
- `git lfs pull --include='corpus/texts/*.txt' --exclude=''`, then
  `make texts-verify-bytes`: hashes complete local objects and verifies sizes;
  unhydrated pointers fail. The CI workflow captures the tracked inventory before
  hydration so missing files also fail. It retains coverage reports, not texts.
- `python -m usul_corpus texts` (from `pipeline`): stage only eligible cached
  witnesses whose full bytes match the lock. `fetch` may restore complete matching
  committed bytes into the local cache. A pointer cannot populate the cache.

CI caches downloaded LFS objects but rehashes every retained text. Source-provider
fetches are a separate route for local study and quotation checks; they cannot
substitute for an LFS-object availability check. Download only the needed subset.

OpenITI's corpus is offered under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/).
Preserve its attribution, license notices, source metadata and applicable sharing
conditions; the [documentation](https://openiti.org/documentation/) also requires
removing protected editorial contributions. A provider license does not clear
rights it cannot grant. The registry's OpenITI repository, commit and path identify
the source of each unchanged witness; no blanket license for third-party editions
is asserted here.
