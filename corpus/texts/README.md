# Public-domain witness texts

The full text of every public-domain witness in [`../registry.json`](../registry.json): 89 files, about 352 MB. These are the witnesses of works with `rights: public_domain_text`, which are all OpenITI mARkdown. Modern texts (Ibn Bāz, Ibn ʿUthaymīn, al-Albānī, al-Saʿdī, al-Lajna al-Dāʾima, al-Shinqīṭī, Ibn Badrān, …) are never committed. They are fetched into `.cache/corpus` by `make fetch`.

- **Storage.** The files are stored with Git LFS (`.gitattributes`). A clone without LFS gets pointer files; run `git lfs pull` to get the content.
- **Identity.** Each `<witness-id>.txt` is byte-identical to the file at the pinned OpenITI commit in the registry, and its sha256 is the one in [`../lock.json`](../lock.json). `test_committed_texts_are_public_domain_and_match_the_lock` checks this, including on bare LFS pointers, whose `oid` is that same sha256. It also checks that no file here belongs to a modern work.
- **Use.** `python -m usul_corpus fetch` fills `.cache/corpus` from these files when they match the lock, and only downloads what is missing.
- **Updating.** Run `python -m usul_corpus texts` after a fetch. It copies only cached texts that match the lock, and never replaces a committed text with drifted bytes.
