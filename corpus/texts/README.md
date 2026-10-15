# Committed witness texts

The full text of every publishable witness in [`../registry.json`](../registry.json): 127 files, about 550 MB, as OpenITI mARkdown, Shamela pages rendered by the fetcher, or archive.org OCR text. These are the text witnesses of works with `rights: public_domain_text` (91) and of the modern works cleared for non-commercial study, `rights: noncommercial_text` (36: Ibn Bāz, Ibn ʿUthaymīn, al-Albānī, al-Saʿdī, al-Shinqīṭī, al-Muʿallimī, al-Lajna al-Dāʾima, Ibn Badrān, Shākir, *al-Durar al-Saniyya*, *al-Ghurar al-Naqiyya*, …). A cleared text is for study only and must not be reproduced commercially. pdf and doc witnesses are pinned as binaries and stay in `.cache/corpus`, as does any witness not yet fetched (`make fetch`).

- **Storage.** The files are stored with Git LFS (`.gitattributes`). A clone without LFS gets pointer files; run `git lfs pull` to get the content.
- **Identity.** Each `<witness-id>.txt` is byte-identical to the file at the pinned OpenITI commit in the registry, and its sha256 is the one in [`../lock.json`](../lock.json). `test_committed_texts_are_publishable_and_match_the_lock` checks this, including on bare LFS pointers, whose `oid` is that same sha256. It also checks that every file here belongs to a publishable work.
- **Use.** `python -m usul_corpus fetch` fills `.cache/corpus` from these files when they match the lock, and only downloads what is missing.
- **Updating.** Run `python -m usul_corpus texts` after a fetch. It copies only cached texts that match the lock, and never replaces a committed text with drifted bytes.
