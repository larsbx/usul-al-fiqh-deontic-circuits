# IDA source catalog authentication boundary

`formal/ida-source-auth.mjs` authenticates a source catalog under an explicitly
configured Ed25519 issuer key and an explicitly configured **current manifest
SHA256**. It then reads each named file, checks its full byte count and SHA256,
and checks the SHA256 of its nonempty half-open passage byte range. A successful
result exports the exact `Usul.IDA.Judgment.SourceRef` fields, including 32-byte
digest arrays, for the derivation environment's `authenticatedSources` list.

This authenticates bytes named by a configured catalog issuer. It does not
establish a text's historical origin, the issuer's juristic authority, the
correctness of an interpretation, or the correctness of a normative conclusion.
No actual religious source or legal interpretation is used in the fixtures.

## Independently configured trust

The caller supplies the public key, issuer identifier, expected current
manifest hash, and source root separately from the candidate catalog. The
adapter never takes a key or a current-manifest assertion from the catalog.
An older, correctly signed catalog fails if it does not match the configured
current hash. A substituted source with freshly computed hashes and a valid
fixture signature also fails against the unchanged current hash.

The trusted configuration must itself be delivered by the intended authority.
This adapter does not implement secure key provisioning, authority governance,
signature revocation, or delivery of current catalog revisions. A caller that
replaces both the trusted key and the manifest pin has changed the trust input;
no theorem here establishes that such a caller is authorized.

The catalog schema permits only `schema`, `issuerId`, `catalogVersion`, and
`sources`. Each source has `sourceId`, `path`, `sourceHash`, `sourceBytes`,
`passageStart`, `passageEnd`, and `passageHash`. It cannot carry admission status,
an evidence grade, a supported-evidence decision, an interpretation version, or
a registry update. Even a correctly signed, explicitly repinned catalog is
rejected if it tries to add those fields. The existing judgment registry and
the derivation environment's current interpretation pins and evidence
decisions remain separate trusted inputs. Catalog version and interpretation
version are different concepts.

## Exact encoding and source references

The local versioned canonical encoding sorts JSON object keys, preserves array
order, uses JSON string escaping and UTF-8, permits only safe integer numbers,
and has no whitespace outside strings or trailing newline. Parsing must
reproduce exactly the signed bytes; duplicate keys, invalid UTF-8, noncanonical
numbers, and ambiguous encodings fail. This is a restricted project encoding,
not a claim of RFC 8785 conformance. Catalogs are limited to 1 MiB and 4,096
references. Safe integer checks avoid rounding a Lean natural number in the
JavaScript boundary.

Source identifiers cannot be rebound within one catalog to different files,
digests, or byte counts. One source may have several distinct passage ranges;
an identical range cannot appear twice. The output preserves catalog order.
Passage coordinates count bytes rather than characters, lines, or normalized
text. Two identical excerpts at different byte ranges have different source
references. The manifest signature and independent manifest pin bind those
coordinates even when the passage hashes happen to be equal.

Paths are restricted to simple relative ASCII components. Absolute paths,
parent traversal, backslashes, symbolic links, and nonregular files fail. Reads
use a bounded buffer, count all bytes, and compute full and passage hashes on
the same read. The returned references are frozen values. These checks do not
provide an atomic filesystem snapshot or a general filesystem sandbox. Use a
stable source directory while verifying; subsequent file changes require a new
authentication call. The result attests to the bytes read by this invocation.

## Reproduce

The adapter and checker require Node 22 or later and only native Node modules.
There is no dependency installation and no network access in these checks.

```sh
node formal/check-ida-source-auth.mjs
```

The checker emits one JSON object on stdout with `status: "passed"`,
`synthetic_fixtures: true`, `authenticated_sources`, manifest and key hashes,
fixture hashes, and individual negative-control outcomes. It fails nonzero if
a control is accepted or fails for an unrelated reason. It writes no registry,
admission decision, or evidence classification. The parent derivation gate
records this result separately from Lean's theorem checks and binds it to the
repository revision and all input file hashes.

An explicit invocation using the committed, publicly known test key is:

```sh
node formal/ida-source-auth.mjs \
  --manifest formal/fixtures/ida-source-auth/catalog.json \
  --signature formal/fixtures/ida-source-auth/catalog.sig \
  --trusted-key formal/fixtures/ida-source-auth/test-only-issuer-public.pem \
  --trusted-issuer ida-source-auth-fixture-only \
  --expected-manifest-sha256 4c670ca14868e175371f269c391795c0329e341cd24c1ad53bc260bfb066a34f \
  --source-root formal/fixtures/ida-source-auth
```

Both committed source files are synthetic ASCII: `IDA\n` and `IDB\n`, each four
bytes, with range `[1,3)`. The private keys are intentionally published test
data with no production authority. Test controls cover substituted or resized
files, rehashed and re-signed replacements with stale pins, changed passage
coordinates including repeated text, stale catalog versions, unknown issuers
and signing keys, corrupt signatures, unauthorized promotion fields, unsafe
integers, path escapes, symlinks, duplicate references, and noncanonical JSON.
A binary passage crossing the read-buffer boundary exercises byte slicing.

## Connection to the formal model

The source-bound derivation gate compares the authenticated fixture references
with independently exported Lean and Quint fixture references. That comparison
establishes the concrete fixture linkage. Lean proves the derivation properties
for its explicit trusted inputs; native Node crypto performs the byte and
signature checks. There is no claimed Lean proof of SHA256, Ed25519, the Node
runtime, the filesystem adapter, or an end-to-end refinement from arbitrary
adapter executions to the formal environment. Those are separate obligations.

The interpretation-currentness, evidence-conflict, cross-context, missing-
premise, suspended-premise, and unauthorized normative-promotion obligations
are checked by the derivation model. Authenticating a source is one necessary
input to that model and cannot itself produce an admitted normative judgment.
