#!/usr/bin/env node
/** Synthetic, test-key-only authentication controls. Stdout is one JSON receipt. */
import assert from 'node:assert/strict';
import { createHash, createPrivateKey, createPublicKey, generateKeyPairSync, sign, verify } from 'node:crypto';
import { mkdir, mkdtemp, readFile, readdir, rm, symlink, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  authenticateSourceCatalog, canonicalJsonBytes, sha256, SourceAuthenticationError,
} from './ida-source-auth.mjs';

const FIXTURES = fileURLToPath(new URL('./fixtures/ida-source-auth/', import.meta.url));
// These fixed vectors are also exported by the independently checked Lean and
// Quint fixtures. The parent gate checks the linkage; this is not a refinement
// proof of the JavaScript implementation by Lean.
const EXPECTED_SOURCES = [
  { sourceId: 1,
    sourceHash: [186,29,212,220,231,84,88,79,207,141,146,254,115,4,103,238,6,112,140,192,4,251,252,68,37,94,197,6,229,77,11,90],
    sourceBytes: 4, passageStart: 1, passageEnd: 3,
    passageHash: [65,165,86,179,131,19,10,60,154,253,106,235,174,55,83,203,233,237,227,132,205,125,78,197,92,180,180,31,175,219,49,5] },
  { sourceId: 2,
    sourceHash: [15,1,238,239,235,128,119,75,25,217,36,106,154,23,175,166,163,180,228,198,32,60,70,245,81,18,23,166,136,3,230,222],
    sourceBytes: 4, passageStart: 1, passageEnd: 3,
    passageHash: [207,58,188,131,38,100,107,153,10,73,22,170,34,235,191,13,208,89,233,123,250,27,82,242,175,170,149,135,191,14,196,77] },
];

async function fixtureHashes() {
  const hashes = {};
  for (const entry of (await readdir(FIXTURES, { withFileTypes: true })).sort((a, b) => a.name.localeCompare(b.name))) {
    assert(entry.isFile(), 'Authentication fixtures must be regular files');
    hashes[`formal/fixtures/ida-source-auth/${entry.name}`] = sha256(await readFile(join(FIXTURES, entry.name)));
  }
  return hashes;
}

async function main() {
  const before = await fixtureHashes();
  const catalogBytes = await readFile(join(FIXTURES, 'catalog.json'));
  const signatureBytes = await readFile(join(FIXTURES, 'catalog.sig'));
  const publicPem = await readFile(join(FIXTURES, 'test-only-issuer-public.pem'), 'utf8');
  const privateKey = createPrivateKey(await readFile(join(FIXTURES, 'test-only-issuer-private.pem')));
  const unknownKey = createPrivateKey(await readFile(join(FIXTURES, 'test-only-untrusted-private.pem')));
  const trust = JSON.parse(await readFile(join(FIXTURES, 'test-only-trust.json'), 'utf8'));
  assert.equal(trust.schema, 'ida-source-auth-test-trust-v1');
  assert.equal(trust.syntheticFixtures, true);
  assert.equal(sha256(createPublicKey(publicPem).export({ format: 'der', type: 'spki' })),
    trust.trustedPublicKeySha256);
  assert.equal(privateKey.asymmetricKeyType, 'ed25519');
  assert.deepEqual(sign(null, catalogBytes, privateKey), signatureBytes,
    'The explicitly public test private key must reproduce the committed signature');
  assert(verify(null, catalogBytes, createPublicKey(publicPem), signatureBytes));
  assert.deepEqual(await readFile(join(FIXTURES, 'source-1.txt')), Buffer.from('IDA\n', 'ascii'));
  assert.deepEqual(await readFile(join(FIXTURES, 'source-2.txt')), Buffer.from('IDB\n', 'ascii'));

  const base = {
    catalogBytes, signatureBytes,
    expectedManifestSha256: trust.expectedManifestSha256,
    trustedIssuerId: trust.trustedIssuerId,
    trustedPublicKeyPem: publicPem,
    sourceRoot: FIXTURES,
  };
  const authenticated = await authenticateSourceCatalog(base);
  assert.deepEqual(authenticated.authenticated_sources, EXPECTED_SOURCES);
  assert.equal(authenticated.issuer_public_key_sha256, trust.trustedPublicKeySha256);
  assert(Object.isFrozen(authenticated) && Object.isFrozen(authenticated.authenticated_sources));
  for (const reference of authenticated.authenticated_sources) {
    assert(Object.isFrozen(reference) && Object.isFrozen(reference.sourceHash)
      && Object.isFrozen(reference.passageHash));
    assert.deepEqual(Object.keys(reference).sort(),
      ['sourceId', 'sourceHash', 'sourceBytes', 'passageStart', 'passageEnd', 'passageHash'].sort());
  }

  const positiveControls = ['committed_signature_reproduced_with_public_test_key',
    'exact_source_ref_vectors', 'source_ref_only_frozen_output'];
  const negativeControls = [];
  const controlResults = [];
  const catalog = JSON.parse(catalogBytes.toString('utf8'));

  async function rejects(name, code, action) {
    let rejected = false;
    try {
      await action();
    } catch (error) {
      assert(error instanceof SourceAuthenticationError, `${name} failed for an unrelated error: ${error}`);
      assert.equal(error.code, code, `${name} failed at an unexpected boundary`);
      rejected = true;
      controlResults.push({ name, expected_error: code, observed_error: error.code });
    }
    assert(rejected, `${name} was incorrectly authenticated`);
    negativeControls.push(name);
  }

  // The tests can deliberately re-sign candidates because this private key is
  // public test data. Re-pinning is explicit so schema/byte controls are tested
  // independently of signature and current-manifest checks.
  function signedBytes(bytes, overrides = {}) {
    return { ...base, catalogBytes: bytes, signatureBytes: sign(null, bytes, privateKey),
      expectedManifestSha256: sha256(bytes), ...overrides };
  }
  function signedMutation(edit, overrides = {}) {
    const changed = structuredClone(catalog);
    edit(changed);
    return signedBytes(canonicalJsonBytes(changed), overrides);
  }
  const scratch = await mkdtemp(join(tmpdir(), 'ida-source-auth-'));
  try {
    for (const source of catalog.sources) {
      await writeFile(join(scratch, source.path), await readFile(join(FIXTURES, source.path)));
    }
    async function changedFirstFile(bytes, action) {
      const target = join(scratch, 'source-1.txt');
      await writeFile(target, bytes);
      try { await action(); } finally { await writeFile(target, Buffer.from('IDA\n', 'ascii')); }
    }
    await rejects('substituted_source_same_byte_count', 'SOURCE_HASH_MISMATCH', () =>
      changedFirstFile(Buffer.from('IDX\n'), () => authenticateSourceCatalog({ ...base, sourceRoot: scratch })));
    await rejects('truncated_source', 'SOURCE_BYTE_COUNT_MISMATCH', () =>
      changedFirstFile(Buffer.from('IDA'), () => authenticateSourceCatalog({ ...base, sourceRoot: scratch })));
    await rejects('padded_source', 'SOURCE_BYTE_COUNT_MISMATCH', () =>
      changedFirstFile(Buffer.from('IDA\nX'), () => authenticateSourceCatalog({ ...base, sourceRoot: scratch })));

    await rejects('rehashed_resigned_substitution_without_current_pin', 'MANIFEST_PIN_MISMATCH', () => {
      const replacement = Buffer.from('IDX\n');
      return changedFirstFile(replacement, () => authenticateSourceCatalog(signedMutation(changed => {
        changed.sources[0].sourceHash = sha256(replacement);
        changed.sources[0].passageHash = sha256(replacement.subarray(1, 3));
      }, { sourceRoot: scratch, expectedManifestSha256: base.expectedManifestSha256 })));
    });
    await rejects('changed_passage_range_with_old_digest', 'PASSAGE_HASH_MISMATCH', () =>
      authenticateSourceCatalog(signedMutation(changed => { changed.sources[0].passageStart = 0; })));
    await rejects('signed_incorrect_passage_digest', 'PASSAGE_HASH_MISMATCH', () =>
      authenticateSourceCatalog(signedMutation(changed => { changed.sources[0].passageHash = '00'.repeat(32); })));
    await rejects('signed_incorrect_source_digest', 'SOURCE_HASH_MISMATCH', () =>
      authenticateSourceCatalog(signedMutation(changed => { changed.sources[0].sourceHash = '00'.repeat(32); })));

    // Equal passage bytes at another location do not make the location equal.
    // Both candidates are signed; the unchanged independent pin rejects moving
    // [0,2) to [2,4) in DADA even though both passage digests are identical.
    await changedFirstFile(Buffer.from('DADA'), async () => {
      const anchored = structuredClone(catalog);
      Object.assign(anchored.sources[0], { sourceHash: sha256(Buffer.from('DADA')),
        passageStart: 0, passageEnd: 2, passageHash: sha256(Buffer.from('DA')) });
      const current = signedBytes(canonicalJsonBytes(anchored), { sourceRoot: scratch });
      await authenticateSourceCatalog(current);
      positiveControls.push('repeated_text_passage_has_explicit_anchor');
      anchored.sources[0].passageStart = 2;
      anchored.sources[0].passageEnd = 4;
      const moved = signedBytes(canonicalJsonBytes(anchored), { sourceRoot: scratch,
        expectedManifestSha256: current.expectedManifestSha256 });
      await rejects('equal_text_at_changed_passage_locator', 'MANIFEST_PIN_MISMATCH', () =>
        authenticateSourceCatalog(moved));
    });

    await rejects('stale_signed_catalog_version', 'MANIFEST_PIN_MISMATCH', () =>
      authenticateSourceCatalog(signedMutation(changed => { changed.catalogVersion = 0; },
        { expectedManifestSha256: base.expectedManifestSha256 })));
    const current = await authenticateSourceCatalog(signedMutation(changed => { changed.catalogVersion = 2; }));
    assert.equal(current.catalog_version, 2);
    assert.deepEqual(current.authenticated_sources, EXPECTED_SOURCES);
    positiveControls.push('explicitly_repinned_catalog_version');

    await rejects('unknown_catalog_issuer', 'UNTRUSTED_ISSUER', () =>
      authenticateSourceCatalog(signedMutation(changed => { changed.issuerId = 'untrusted-issuer'; })));
    await rejects('unknown_signing_key', 'SIGNATURE_INVALID', () =>
      authenticateSourceCatalog({ ...base, signatureBytes: sign(null, catalogBytes, unknownKey) }));
    const corruptSignature = Buffer.from(signatureBytes);
    corruptSignature[0] ^= 1;
    await rejects('corrupted_signature', 'SIGNATURE_INVALID', () =>
      authenticateSourceCatalog({ ...base, signatureBytes: corruptSignature }));
    await rejects('catalog_changed_without_resigning', 'SIGNATURE_INVALID', () =>
      authenticateSourceCatalog(signedMutation(changed => { changed.catalogVersion = 2; },
        { signatureBytes: base.signatureBytes })));
    await rejects('missing_signature', 'BAD_SIGNATURE_LENGTH', () =>
      authenticateSourceCatalog({ ...base, signatureBytes: Buffer.alloc(0) }));
    await rejects('missing_current_manifest_pin', 'BAD_TRUST_PIN', () =>
      authenticateSourceCatalog({ ...base, expectedManifestSha256: undefined }));
    await rejects('non_ed25519_configured_key', 'BAD_TRUSTED_KEY', () =>
      authenticateSourceCatalog({ ...base, trustedPublicKeyPem:
        generateKeyPairSync('ec', { namedCurve: 'prime256v1' }).publicKey.export({ format: 'pem', type: 'spki' }) }));

    for (const [name, edit] of [
      ['unauthorized_admission_status', changed => { changed.sources[0].status = 'admitted'; }],
      ['unauthorized_evidence_promotion', changed => { changed.sources[0].evidence = 'supported'; }],
      ['unauthorized_interpretation_version', changed => { changed.sources[0].interpretationVersion = 2; }],
      ['catalog_embedded_trust_key', changed => { changed.trustedPublicKeyPem = publicPem; }],
      ['catalog_embedded_current_versions', changed => { changed.currentVersions = []; }],
    ]) {
      await rejects(name, 'BAD_SCHEMA', () => authenticateSourceCatalog(signedMutation(edit)));
    }
    await rejects('unsafe_integer_source_id', 'UNSAFE_JSON_NUMBER', () => {
      const changed = structuredClone(catalog);
      changed.sources[0].sourceId = Number.MAX_SAFE_INTEGER + 1;
      return authenticateSourceCatalog(signedBytes(Buffer.from(JSON.stringify(changed), 'utf8')));
    });
    await rejects('fractional_passage_offset', 'UNSAFE_JSON_NUMBER', () => {
      const changed = structuredClone(catalog);
      changed.sources[0].passageStart = 1.5;
      return authenticateSourceCatalog(signedBytes(Buffer.from(JSON.stringify(changed), 'utf8')));
    });
    await rejects('negative_passage_offset', 'BAD_NATURAL', () =>
      authenticateSourceCatalog(signedMutation(changed => { changed.sources[0].passageStart = -1; })));
    await rejects('empty_passage_range', 'BAD_PASSAGE_RANGE', () =>
      authenticateSourceCatalog(signedMutation(changed => { changed.sources[0].passageEnd = 1; })));
    await rejects('passage_range_past_source', 'BAD_PASSAGE_RANGE', () =>
      authenticateSourceCatalog(signedMutation(changed => { changed.sources[0].passageEnd = 5; })));
    await rejects('duplicate_source_reference', 'DUPLICATE_SOURCE_REFERENCE', () =>
      authenticateSourceCatalog(signedMutation(changed => { changed.sources.push(structuredClone(changed.sources[0])); })));
    await rejects('source_id_rebound_to_other_content', 'SOURCE_ID_CONFLICT', () =>
      authenticateSourceCatalog(signedMutation(changed => { changed.sources[1].sourceId = 1; })));

    for (const [name, path] of [['parent_path_traversal', '../source-1.txt'],
      ['absolute_source_path', '/source-1.txt'], ['backslash_source_path', '..\\source-1.txt']]) {
      await rejects(name, 'UNSAFE_SOURCE_PATH', () =>
        authenticateSourceCatalog(signedMutation(changed => { changed.sources[0].path = path; })));
    }
    await rm(join(scratch, 'source-1.txt'));
    await symlink(join(scratch, 'source-2.txt'), join(scratch, 'source-1.txt'));
    await rejects('source_file_symlink', 'UNSAFE_SOURCE_PATH', () =>
      authenticateSourceCatalog({ ...base, sourceRoot: scratch }));
    await rm(join(scratch, 'source-1.txt'));
    await writeFile(join(scratch, 'source-1.txt'), Buffer.from('IDA\n'));
    await symlink(FIXTURES, join(scratch, 'linked'));
    await rejects('source_parent_symlink', 'UNSAFE_SOURCE_PATH', () =>
      authenticateSourceCatalog(signedMutation(changed => { changed.sources[0].path = 'linked/source-1.txt'; },
        { sourceRoot: scratch })));
    await mkdir(join(scratch, 'directory'));
    await rejects('source_is_directory', 'SOURCE_NOT_REGULAR', () =>
      authenticateSourceCatalog(signedMutation(changed => { changed.sources[0].path = 'directory'; },
        { sourceRoot: scratch })));
    await rejects('source_file_missing', 'SOURCE_READ_FAILED', () =>
      authenticateSourceCatalog(signedMutation(changed => { changed.sources[0].path = 'absent.txt'; },
        { sourceRoot: scratch })));

    await rejects('noncanonical_catalog_whitespace', 'NONCANONICAL_CATALOG', () =>
      authenticateSourceCatalog(signedBytes(Buffer.concat([catalogBytes, Buffer.from('\n')]))));
    await rejects('duplicate_json_catalog_key', 'NONCANONICAL_CATALOG', () =>
      authenticateSourceCatalog(signedBytes(Buffer.from(`${catalogBytes.toString('utf8').slice(0, -1)},"catalogVersion":1}`))));
    await rejects('invalid_utf8_catalog', 'BAD_CATALOG_UTF8', () =>
      authenticateSourceCatalog(signedBytes(Buffer.concat([Buffer.from([255]), catalogBytes]))));

    // Exercise byte offsets across a read-buffer boundary, independently
    // calculating expected hashes with Node's native crypto operation.
    const large = Buffer.alloc(65542, 65);
    Buffer.from([0, 255, 195, 169, 13, 10, 66, 67]).copy(large, 65532);
    await writeFile(join(scratch, 'boundary.bin'), large);
    const digest = bytes => createHash('sha256').update(bytes).digest('hex');
    const boundaryCatalog = structuredClone(catalog);
    boundaryCatalog.sources = [{ sourceId: 3, path: 'boundary.bin', sourceHash: digest(large),
      sourceBytes: large.length, passageStart: 65533, passageEnd: 65540,
      passageHash: digest(large.subarray(65533, 65540)) }];
    const boundary = await authenticateSourceCatalog(signedBytes(canonicalJsonBytes(boundaryCatalog),
      { sourceRoot: scratch }));
    assert.equal(boundary.authenticated_sources[0].sourceBytes, 65542);
    assert.deepEqual(boundary.authenticated_sources[0].passageHash,
      [...createHash('sha256').update(large.subarray(65533, 65540)).digest()]);
    positiveControls.push('binary_passage_across_stream_buffer_boundary');
  } finally {
    await rm(scratch, { recursive: true, force: true });
  }

  assert.deepEqual(await fixtureHashes(), before, 'Authentication checks must not modify committed fixtures');
  assert(negativeControls.length >= 6);
  assert.equal(new Set(negativeControls).size, negativeControls.length);
  const receipt = {
    status: 'passed',
    synthetic_fixtures: true,
    fixture_private_keys_public_and_test_only: true,
    ...authenticated,
    positive_controls: positiveControls,
    negative_controls: negativeControls,
    control_results: controlResults,
    fixture_sha256: before,
    node_version: process.version,
    node_to_lean_refinement_proved: false,
    registry_or_evidence_decisions_produced: false,
    juristic_interpretation_correctness_established: false,
  };
  process.stdout.write(`${JSON.stringify(receipt)}\n`);
}

main().catch(error => {
  process.stderr.write(`${error.stack ?? error.message}\n`);
  process.exitCode = 1;
});
