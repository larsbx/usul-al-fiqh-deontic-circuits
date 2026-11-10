import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { sign } from 'node:crypto';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { reviewAuthenticatedOmission } from './ida-omission-auth.mjs';
import { canonicalJsonBytes, sha256 } from './ida-source-auth.mjs';

const fixture = new URL('./fixtures/ida-source-auth/', import.meta.url);
const [issuerKey, publicKey, untrustedKey] = await Promise.all([
  'test-only-issuer-private.pem', 'test-only-issuer-public.pem', 'test-only-untrusted-private.pem',
].map(name => readFile(new URL(name, fixture))));
const issuerId = 'synthetic-omission-fixture';
const sourceId = 42;
const file = 'observations.json';

function lean(scenario, text) {
  return JSON.parse(execFileSync('lake', ['env', 'lean', '--run',
    'scripts/CheckIDAOmissionWire.lean', scenario], {
    cwd: new URL('./lean/', import.meta.url),
    input: text,
    encoding: 'utf8', timeout: 30_000,
  }));
}

const template = lean('template');
const direct = { mode: 'direct', occurredAt: 10, recordedAt: 10 };
const recordedLate = { ...direct, occurredAt: 11, recordedAt: 14 };
const coverage = template.coverage;
const cases = {};
const path = await mkdtemp(join(tmpdir(), 'ida-omission-auth-'));

async function inputs(batch, { key = issuerKey, issuer = issuerId, partial = false } = {}) {
  const observationBytes = Buffer.isBuffer(batch) ? batch : canonicalJsonBytes(batch);
  await writeFile(join(path, file), observationBytes);
  const passageStart = partial ? 1 : 0;
  const catalogBytes = canonicalJsonBytes({
    schema: 'ida-source-catalog-v1', issuerId: issuer, catalogVersion: 1,
    sources: [{ sourceId, path: file, sourceHash: sha256(observationBytes),
      sourceBytes: observationBytes.length, passageStart, passageEnd: observationBytes.length,
      passageHash: sha256(observationBytes.subarray(passageStart)) }],
  });
  return { observationBytes, trustedObservationSourceId: sourceId, catalog: {
    catalogBytes, signatureBytes: sign(null, catalogBytes, key),
    expectedManifestSha256: sha256(catalogBytes), trustedIssuerId: issuerId,
    trustedPublicKeyPem: publicKey.toString('utf8'), sourceRoot: path,
  } };
}

async function authenticated(name, batch, scenario, expected) {
  const request = await inputs(batch);
  let calls = 0;
  const response = await reviewAuthenticatedOmission({
    ...request, evaluateVerified: text => {
      calls++;
      assert.deepEqual(Buffer.from(text, 'utf8'), request.observationBytes);
      return lean(scenario, text);
    },
  });
  assert.equal(calls, 1);
  assert.equal(response.issuer_id, issuerId);
  assert.equal(response.catalog_version, 1);
  assert.equal(response.manifest_sha256, request.catalog.expectedManifestSha256);
  assert.match(response.issuer_public_key_sha256, /^[0-9a-f]{64}$/);
  assert.equal(response.source.sourceId, sourceId);
  assert.equal(response.source.passageStart, 0);
  assert.equal(response.source.passageEnd, request.observationBytes.length);
  assert.equal(Buffer.from(response.source.sourceHash).toString('hex'), sha256(request.observationBytes));
  assert.deepEqual(response.source.sourceHash, response.source.passageHash);
  assert.deepEqual(response.assessment, expected, name);
  cases[name] = { stage: 'lean', ...response };
}

async function denied(name, request, code) {
  let calls = 0;
  await assert.rejects(reviewAuthenticatedOmission({
    ...request, evaluateVerified: () => { calls++; },
  }), { code }, name);
  assert.equal(calls, 0, name);
  cases[name] = { stage: 'authentication', failure: code, evaluator_calls: calls };
}

const outcome = name => ({ outcome: 'Usul.IDA.Omission.Outcome.' + name });
const failure = name => ({ failure: 'Usul.IDA.Omission.Wire.Failure.' + name });
const withReports = (...reports) => ({ ...template, reports });

try {
  await authenticated('closed_complete', template, 'closed', outcome('coveredNoCompletion'));
  await authenticated('open', template, 'open', outcome('pending'));
  await authenticated('direct_completion', withReports(direct), 'closed', outcome('completionObserved'));
  await authenticated('alternate_completion', withReports({ ...direct, mode: 'alternate' }),
    'closed', outcome('completionObserved'));
  await authenticated('closing_tick', withReports({ ...direct, occurredAt: 12, recordedAt: 12 }),
    'closed', outcome('coveredNoCompletion'));
  await authenticated('late_report_as_known', withReports(recordedLate), 'closed', outcome('coveredNoCompletion'));
  await authenticated('late_report_retrospective', withReports(recordedLate),
    'retrospective', outcome('completionObserved'));
  await authenticated('no_coverage', { ...template, coverage: null }, 'closed', outcome('coverageMissing'));
  await authenticated('one_mode', { ...template, coverage: { ...coverage, modes: ['direct'] } },
    'closed', outcome('coverageMissing'));
  await authenticated('impossible_chronology', withReports({ ...direct, occurredAt: 11 }),
    'closed', outcome('invalidObservation'));
  await authenticated('stale_snapshot', template, 'stale',
    failure('context (Usul.IDA.Context.Failure.stale)'));
  await authenticated('no_omission', template, 'none', failure('noOpportunity'));
  await authenticated('unknown_schema', { ...template, schema: 'unknown' }, 'closed', failure('wrongSchema'));
  await authenticated('unknown_mode', withReports({ ...direct, mode: 'other' }), 'closed', failure('unknownMode'));
  await authenticated('extra_report_field', withReports({ ...direct, scope: template.scope }),
    'closed', { failure: 'non-exact wire shape' });

  const scope = template.scope;
  const variants = {
    accountable: { accountable: scope.performer.referent },
    performer: { performer: { ...scope.performer, referent: scope.accountable } },
    action: { action: { ...scope.action, operands: scope.action.operands.slice(1) } },
    occurrence: { opportunity: { ...scope.opportunity, occurrence: { space: 'synthetic.event', name: 'other' } } },
    interval: { opportunity: { ...scope.opportunity, closesAt: 13 } },
    clock: { opportunity: { ...scope.opportunity, clock: { space: 'clock', name: 'other' } } },
    clock_version: { clockVersion: 2 },
    definition_version: { definition: { ...scope.definition, version: 2 } },
    definition_digest: { definitionDigest: [0] },
  };
  for (const [name, patch] of Object.entries(variants)) {
    await authenticated('wrong_' + name, { ...template, scope: { ...scope, ...patch } },
      'closed', failure('wrongScope'));
  }

  const signedCompletion = await inputs(withReports(direct));
  await denied('stripped_completion', { ...signedCompletion, observationBytes: canonicalJsonBytes(template) },
    'OBSERVATION_BYTES_MISMATCH');
  await denied('same_length_substitution', {
    ...signedCompletion,
    observationBytes: canonicalJsonBytes(withReports({ ...direct, occurredAt: 11, recordedAt: 11 })),
  }, 'OBSERVATION_BYTES_MISMATCH');
  await denied('wrong_designated_source', { ...signedCompletion, trustedObservationSourceId: sourceId + 1 },
    'OBSERVATION_SOURCE_MISSING');
  await denied('stale_catalog', { ...signedCompletion, catalog: {
    ...signedCompletion.catalog, expectedManifestSha256: '0'.repeat(64),
  } }, 'MANIFEST_PIN_MISMATCH');
  await denied('wrong_signer', await inputs(template, { key: untrustedKey }), 'SIGNATURE_INVALID');
  await denied('wrong_issuer', await inputs(template, { issuer: 'other' }), 'UNTRUSTED_ISSUER');
  await denied('signed_partial_passage', await inputs(template, { partial: true }), 'OBSERVATION_SOURCE_MISSING');
  await denied('duplicate_json_key', await inputs(Buffer.from('{"reports":[],"reports":[]}')),
    'NONCANONICAL_OBSERVATION_JSON');
  await denied('invalid_utf8', await inputs(Buffer.from([0xff])), 'BAD_OBSERVATION_JSON');
  console.log(JSON.stringify({ node: process.version, cases }));
} finally {
  await rm(path, { recursive: true, force: true });
}
