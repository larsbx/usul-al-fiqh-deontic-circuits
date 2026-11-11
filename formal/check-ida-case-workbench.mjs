#!/usr/bin/env node
/** Integration/adversarial controls for the verifier-bound case workbench. */
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { cp, mkdir, mkdtemp, readFile, rm, symlink, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { admit } from './ida-premise-ingestion.mjs';
import { canonicalJsonBytes, sha256 } from './ida-source-auth.mjs';
import { answerRequest, build, fixtureInputs, generateDossier, implementationRevision,
  replayDossier, validateRequest, REQUEST_SCHEMA } from './ida-case-workbench.mjs';

const root = fileURLToPath(new URL('..', import.meta.url));
const output = join(root, '.cache/ida-case-workbench-host');
await mkdir(output, { recursive: true });
await rm(join(output, 'report.json'), { force: true });
const work = await mkdtemp(join(tmpdir(), 'ida-workbench-controls-'));
const passed = [];
const check = async (name, action) => { await action(); passed.push(name); };
const request = (method, params = {}) => ({ schema: REQUEST_SCHEMA, method, params });

try {
  const { head } = await implementationRevision();
  const dossier = await generateDossier();
  const baselineHash = sha256(canonicalJsonBytes(dossier));
  const cell = (mask, population = 2, authorityMode = 0) => dossier.scenarios.cells.find(row =>
    row.selection.mask === mask && row.selection.population === population && row.selection.authorityMode === authorityMode);
  await check('exact revision and complete source inventory', () => {
    assert.equal(dossier.verification.revision, head);
    assert.equal(dossier.binding.receipt.statement.revision, head);
    for (const name of ['formal/ida-case-workbench.mjs', 'formal/lean/Usul/Typing/IDACaseWorkbench.lean',
      'formal/lean/scripts/ExportIDACaseWorkbench.lean', 'web/ida-case-workbench/app.js']) {
      assert.equal(dossier.binding.sourceSha256[name], sha256(execFileSync('git', ['show', `${head}:${name}`], { cwd: root })));
    }
  });
  await check('all four source occurrences retain their own context', () => {
    const premises = dossier.claims.filter(c => c.kind === 'premise');
    assert.equal(premises.length, 4);
    assert.deepEqual(premises.map(c => c.binding.certificateToken), [1, 2, 3, 4]);
    assert.deepEqual(premises.map(c => c.sourceIds), [['source-1'], ['source-2'], ['source-1'], ['source-2']]);
    assert.notEqual(premises[0].binding.snapshotRepresentation, premises[2].binding.snapshotRepresentation);
    assert.equal(premises[2].binding.snapshotRepresentation, dossier.binding.snapshot.representation);
    assert.equal(premises[0].binding.formulaSyntax.arguments[0].symbol.name, 'bob');
    assert.equal(premises[2].binding.formulaSyntax.arguments[0].symbol.name, 'alice');
  });
  await check('four report states retain both signs', () => {
    assert.deepEqual([0, 1, 2, 3].map(mask => cell(mask).support.status),
      ['unknown', 'supported', 'refuted', 'conflicted']);
    assert.deepEqual([0, 4, 8, 12].map(mask => cell(mask).exception.status),
      ['unknown', 'supported', 'refuted', 'conflicted']);
  });
  await check('missing exclusion and opposing reports block the guard', () => {
    assert.equal(cell(9).result, 'accepted');
    for (const mask of [1, 11, 13, 15]) {
      assert.equal(cell(mask).guard, false);
      assert.equal(cell(mask).result, 'guardRejected');
    }
  });
  await check('empty and incompatible histories never become accepted', () => {
    assert.equal(cell(9, 0).result, 'noCandidateHistories');
    assert.equal(cell(9, 1).result, 'incompatibleHistories');
    assert.equal(cell(9, 3).result, 'accepted');
  });
  await check('each destination admission failure remains explicit', () => {
    assert.deepEqual([0, 1, 2, 3, 4, 5].map(mode => cell(9, 2, mode).result),
      ['accepted', 'destinationPremiseListMismatch', 'destinationPremiseListMismatch',
        'destinationEvidenceMissing', 'destinationSnapshotStale', 'destinationGrantMissing']);
  });
  await check('agent can inspect a source-side premise without losing source scope', () => {
    const result = answerRequest(request('claim.explain', { claimId: 'premise-1' }), dossier);
    assert.equal(result.result.claim.binding.side, 'source');
    assert.equal(result.result.sources.length, 1);
    assert.deepEqual(result.result.proofs.map(p => p.id), ['occurrences']);
  });
  await check('hypothetical output cannot reuse the baseline admission', () => {
    const result = answerRequest(request('scenario.explore', { mask: 13, population: 2, authorityMode: 0 }), dossier);
    assert.equal(result.result.baselineAdmissionApplies, false);
    assert.equal(result.result.hypothetical, true);
    assert.equal(result.result.result, 'guardRejected');
    assert.equal(sha256(canonicalJsonBytes(dossier)), baselineHash);
  });
  await check('next questions respond to actual missing evidence', () => {
    const result = answerRequest(request('questions.next', { mask: 1, population: 2, authorityMode: 0 }), dossier);
    assert.ok(result.result.some(q => q.id === 'exception'));
    assert.ok(!dossier.questions.some(q => q.id === 'exception'));
  });
  await check('all five bounded operations preserve fixture and revision binding', () => {
    for (const input of [request('dossier.read'), request('dossier.reverify'), request('questions.next'),
      request('claim.explain', { claimId: 'conditional-conclusion' }),
      request('scenario.explore', { mask: 9, population: 2, authorityMode: 0 })]) {
      const response = answerRequest(input, dossier);
      assert.equal(response.scope.revision, head);
      assert.equal(response.scope.caseMode, 'synthetic-scenario');
    }
  });
  await check('caller cannot supply a truth, admission, trust, or decision capability', () => {
    for (const input of [
      { ...request('dossier.read'), verified: true },
      request('dossier.read', { trustedPublicKey: 'attacker' }),
      request('dossier.read', { evidenceAccepted: true }),
      request('decision.publish'), request('admission.accept'), request('source.trust'),
      { ...request('dossier.read'), schema: 'ida-omission-observations-v1' },
    ]) assert.throws(() => validateRequest(input));
  });
  await check('malformed and out-of-domain scenario requests fail closed', () => {
    for (const params of [{ mask: -1, population: 2, authorityMode: 0 },
      { mask: 16, population: 2, authorityMode: 0 }, { mask: '9', population: 2, authorityMode: 0 },
      { mask: 9, population: 4, authorityMode: 0 }, { mask: 9, population: 2, authorityMode: 6 },
      { mask: 9, population: 2 }, { mask: 9, population: 2, authorityMode: 0, accepted: true }]) {
      assert.throws(() => validateRequest(request('scenario.explore', params)));
    }
  });
  const { candidate, trust } = await fixtureInputs(head);
  const receipt = await admit(join(work, 'test.sqlite'), candidate, trust);
  await check('tampered receipt cannot yield a dossier', async () => {
    await assert.rejects(replayDossier({ ...receipt, result: 'real-fact-proved' }, candidate, trust), /RECEIPT_REPLAY_MISMATCH/);
  });
  await check('revoked authority blocks re-presentation', async () => {
    await assert.rejects(replayDossier(receipt, candidate, { ...trust, active: false }), /AUTHORITY_REVOKED/);
  });
  await check('invalid premise signature blocks re-presentation', async () => {
    await assert.rejects(replayDossier(receipt, { ...candidate, attestationSignature: Buffer.alloc(64) }, trust), /ATTESTATION_SIGNATURE/);
  });
  await check('changed displayed source bytes cannot yield a dossier', async () => {
    const sourceRoot = join(work, 'source');
    await cp(join(root, 'formal/fixtures/ida-source-auth'), sourceRoot, { recursive: true });
    await writeFile(join(sourceRoot, 'source-1.txt'), 'IXA\n');
    await assert.rejects(replayDossier(receipt, candidate, { ...trust, source: { ...trust.source, sourceRoot } }),
      { code: 'SOURCE_HASH_MISMATCH' });
  });
  await check('untracked executable source cannot be attributed to old HEAD', async () => {
    const probe = join(root, 'formal/lean/Usul/CaseWorkbenchUntrackedProbe.lean');
    await writeFile(probe, '-- Untracked implementation negative control.\n', { flag: 'wx' });
    try { await assert.rejects(implementationRevision(), /UNCOMMITTED_IMPLEMENTATION/); }
    finally { await rm(probe); }
  });
  await check('package assets and dossier match the exact verified revision', async () => {
    const destination = join(work, 'package');
    const manifest = await build(destination);
    assert.equal(manifest.revision, head);
    assert.equal(manifest.scenarioCells, 384);
    assert.equal(manifest.dossierSha256, sha256(await readFile(join(destination, 'dossier.json'))));
    for (const name of ['index.html', 'app.js', 'style.css']) {
      assert.deepEqual(await readFile(join(destination, name)),
        execFileSync('git', ['show', `${head}:web/ida-case-workbench/${name}`], { cwd: root }));
    }
    // A rebuild whose verifier cannot run must invalidate the package marker.
    const onlyGit = join(work, 'git-only');
    await mkdir(onlyGit);
    const gitPath = execFileSync('which', ['git'], { encoding: 'utf8' }).trim();
    await symlink(gitPath, join(onlyGit, 'git'));
    assert.throws(() => execFileSync(process.execPath, [join(root, 'formal/ida-case-workbench.mjs'), 'build', destination],
      { env: { ...process.env, PATH: onlyGit }, stdio: 'pipe' }));
    await assert.rejects(readFile(join(destination, 'verification.json')), { code: 'ENOENT' });
  });
  assert.equal((await implementationRevision()).head, head);
  await writeFile(join(output, 'report.json'), JSON.stringify({
    schema: 'ida-case-workbench-host-verification-v1', revision: head, status: 'passed',
    checks: passed, checkCount: passed.length, scenarioCells: 384,
    receiptSha256: dossier.verification.receiptSha256,
    implementationSha256: dossier.binding.implementationSha256,
    boundary: 'Published test keys and synthetic fixture only; no general case admission or human decision.',
  }, null, 2) + '\n');
  process.stdout.write(`IDA case workbench: ${passed.length} host controls passed at ${head}.\n`);
} finally { await rm(work, { recursive: true, force: true }); }
