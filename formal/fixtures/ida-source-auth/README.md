# Synthetic source authentication fixtures

These files contain no fiqh text or legal interpretation. `source-1.txt` is
exactly ASCII `IDA\n`; `source-2.txt` is exactly ASCII `IDB\n`. Both have four
bytes, and the signed catalog identifies the half-open passage range `[1,3)`.
The resulting passage bytes are `DA` and `DB` respectively.

All keys in this directory are **public test data**. The committed private keys
have no production authority and must never be used to authenticate real
sources. The checker deliberately signs adversarial catalogs with the fixture
issuer key so it can distinguish current-manifest, schema, and content checks
from invalid-signature checks. The other private key supplies an unknown-signer
control. No runtime key generation or network access is needed for Ed25519
fixture verification.

`catalog.json` is canonical UTF-8 JSON without a trailing newline. `catalog.sig`
contains the 64-byte Ed25519 signature of those exact bytes.
`test-only-trust.json` provides a separately configured test issuer identifier,
current manifest SHA256, and SPKI public-key fingerprint. The candidate catalog
cannot supply these trust inputs. The parent verification gate fingerprints
all these files together with the checker and records the repository revision.

Run `node formal/check-ida-source-auth.mjs` from the repository root. Its stdout
is a single JSON result. See `docs/research/ida-source-auth.md` for the trust
boundary and the adapter command-line interface.
