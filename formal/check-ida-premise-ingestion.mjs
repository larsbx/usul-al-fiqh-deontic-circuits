import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { createPublicKey, sign } from 'node:crypto';
import { mkdtemp, readFile, writeFile, cp, rm, mkdir } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { admit, attestation, leanReplay, recover, revision, verifyReceipt } from './ida-premise-ingestion.mjs';
import { canonicalJsonBytes } from './ida-source-auth.mjs';

if (process.argv[2] === 'recover') {
  process.stdout.write(JSON.stringify(recover(process.argv[3], process.argv[4])));
} else {
  const here = fileURLToPath(new URL('.', import.meta.url));
  const fixture = join(here, 'fixtures/ida-source-auth');
  const work = await mkdtemp(join(tmpdir(), 'ida-premise-'));
  try {
    const sourceRoot = join(work, 'source');
    await cp(fixture, sourceRoot, { recursive: true });
    const read = (name) => readFile(join(fixture, name));
    const pins = JSON.parse(await read('test-only-trust.json'));
    const signer = await read('test-only-untrusted-private.pem');
    const trust = {
      active: true,
      issuer: 'synthetic-premise-authority',
      publicKey: createPublicKey(signer),
      source: {
        sourceRoot, trustedIssuerId: pins.trustedIssuerId,
        expectedManifestSha256: pins.expectedManifestSha256,
        trustedPublicKeyPem: (await read('test-only-issuer-public.pem')).toString(),
      },
    };
    const head = revision();
    const statement = attestation(head, pins.expectedManifestSha256, trust.issuer, [1, 2, 3, 4]);
    function signed(fields) {
      const attestationBytes = canonicalJsonBytes(fields);
      return { attestationBytes, attestationSignature: sign(null, attestationBytes, signer) };
    }
    const candidate = {
      catalogBytes: await read('catalog.json'), catalogSignature: await read('catalog.sig'),
      ...signed(statement),
    };
    const database = join(work, 'admissions.sqlite');
    const attempt = (change, policy = trust) => admit(database, { ...candidate, ...change }, policy);

    await assert.rejects(attempt({}, { ...trust, active: false }), /AUTHORITY_REVOKED/);
    await assert.rejects(attempt(signed({ ...statement, revision: 'stale-revision' })), /ATTESTATION_SCOPE/);
    await assert.rejects(attempt(signed({ ...statement, certificateTokens: [1, 2] })), /ATTESTATION_SCOPE/);
    await assert.rejects(attempt({ attestationSignature: Buffer.alloc(64) }), /ATTESTATION_SIGNATURE/);
    await assert.rejects(attempt(signed({ ...statement, schema: 'ida-omission-observations-v1' })), /ATTESTATION_SCOPE/);
    await writeFile(join(sourceRoot, 'source-1.txt'), 'IXA\n');
    await assert.rejects(attempt({}), { code: 'SOURCE_HASH_MISMATCH' });
    await writeFile(join(sourceRoot, 'source-1.txt'), await read('source-1.txt'));

    const receipt = await attempt({});
    assert.equal(await verifyReceipt(receipt, candidate, trust), true);
    assert.equal(await verifyReceipt({ ...receipt, result: 'altered' }, candidate, trust), false);
    const restarted = JSON.parse(execFileSync(process.execPath, [
      fileURLToPath(import.meta.url), 'recover', database, head,
    ], { encoding: 'utf8' }));
    assert.deepEqual(restarted, receipt);
    await assert.rejects(attempt({}), /DUPLICATE_ADMISSION/);

    const controls = leanReplay('controls');
    assert.deepEqual(controls, [0, 2, 4, 5, 6, 6, 3, 7, 1]);
    const trace = join(work, 'quint.json');
    const quint = join(here, 'quint/node_modules/.bin/quint');
    const model = join(here, 'quint/ida-premise-ingestion.qnt');
    execFileSync(quint, ['run', model, '--main', 'idaPremiseIngestion',
      '--backend', 'typescript', '--max-samples', '1', '--max-steps', '0',
      '--seed', '20261106', '--out-itf', trace, '--verbosity', '0']);
    const replay = JSON.parse(await readFile(trace));
    assert.deepEqual(replay.states[0].results.map(cell => Number(cell['#bigint'])), controls);
    assert.equal(revision(), head);
    const output = join(here, '../.cache/ida-premise-ingestion');
    await mkdir(output, { recursive: true });
    await writeFile(join(output, 'report.json'), JSON.stringify({
      schema: 'ida-premise-ingestion-verification-v1', revision: head, controls, receipt,
      hostChecks: ['revocation', 'wrong revision', 'missing premises', 'invalid signature',
        'wrong signature domain', 'altered source', 'receipt replay', 'altered receipt',
        'cross-process recovery', 'duplicate admission'],
    }, null, 2) + '\n');
    process.stdout.write(`IDA premise ingestion: nine matching Lean–Quint rows and ten host checks at ${head}.\n`);
  } finally {
    await rm(work, { recursive: true, force: true });
  }
}
