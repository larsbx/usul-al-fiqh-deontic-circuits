#!/usr/bin/env node
/** Read-only agent protocol over the closed, synthetic ACT-08 fixture.
 * No caller can supply a trust root, a verified label, or a human decision.
 */
import { execFileSync } from 'node:child_process';
import { createPublicKey, sign } from 'node:crypto';
import { mkdir, mkdtemp, readFile, readdir, rename, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { admit, attestation, revision, verifyReceipt } from './ida-premise-ingestion.mjs';
import { canonicalJsonBytes, sha256 } from './ida-source-auth.mjs';

const ROOT = fileURLToPath(new URL('..', import.meta.url));
const FIXTURE_ROOT = join(ROOT, 'formal/fixtures/ida-source-auth');
const FIXTURE = 'act08-synthetic-guarded-repayment-v1';
const REPOSITORY = 'https://github.com/larsbx/usul-al-fiqh-deontic-circuits';
export const REQUEST_SCHEMA = 'ida-case-workbench-request-v1';
export const DOSSIER_SCHEMA = 'ida-case-dossier-v1';
export const METHODS = Object.freeze([
  'dossier.read', 'dossier.reverify', 'claim.explain', 'scenario.explore', 'questions.next',
]);

function require(condition, message) {
  if (!condition) throw new Error(message);
}

/** A clean tracked worktree alone does not cover untracked executable files.
 * Inspect every executed source/fixture and renderer file against HEAD bytes.
 */
export async function implementationRevision() {
  const head = revision();
  const paths = [
    'formal/ida-case-workbench.mjs', 'formal/ida-premise-ingestion.mjs', 'formal/ida-source-auth.mjs',
    'web/ida-case-workbench/index.html', 'web/ida-case-workbench/app.js', 'web/ida-case-workbench/style.css',
  ];
  async function collect(directory) {
    for (const entry of await readdir(join(ROOT, directory), { withFileTypes: true })) {
      if (entry.name.startsWith('.')) continue;
      require(!entry.isSymbolicLink(), 'IMPLEMENTATION_SYMLINK');
      const path = `${directory}/${entry.name}`;
      if (entry.isDirectory()) await collect(path);
      else if (directory.startsWith('formal/fixtures/') || entry.name.endsWith('.lean')
        || ['lean-toolchain', 'lakefile.toml', 'lake-manifest.json'].includes(entry.name)) paths.push(path);
    }
  }
  await collect('formal/lean');
  await collect('formal/fixtures/ida-source-auth');
  const listed = execFileSync('git', ['ls-tree', '-r', '--name-only', head], { cwd: ROOT, encoding: 'utf8' });
  const tracked = new Set(listed.trim().split('\n'));
  const hashes = {};
  for (const path of paths.sort()) {
    require(tracked.has(path), `UNCOMMITTED_IMPLEMENTATION:${path}`);
    const current = await readFile(join(ROOT, path));
    const committed = execFileSync('git', ['show', `${head}:${path}`], { cwd: ROOT, maxBuffer: 8 * 1024 * 1024 });
    require(current.equals(committed), `IMPLEMENTATION_BYTES_CHANGED:${path}`);
    hashes[path] = sha256(current);
  }
  require(revision() === head, 'REVISION_CHANGED');
  return { head, hashes };
}

function exactKeys(value, keys, required = keys) {
  require(value !== null && typeof value === 'object' && !Array.isArray(value), 'EXPECTED_OBJECT');
  require(Object.keys(value).every(key => keys.includes(key))
    && required.every(key => Object.hasOwn(value, key)), 'UNEXPECTED_FIELDS');
}

export function selection(params) {
  exactKeys(params, ['mask', 'population', 'authorityMode']);
  for (const [field, upper] of [['mask', 16], ['population', 4], ['authorityMode', 6]]) {
    require(Number.isSafeInteger(params[field]) && params[field] >= 0 && params[field] < upper,
      `INVALID_SCENARIO_${field}`);
  }
  return { mask: params.mask, population: params.population, authorityMode: params.authorityMode };
}

/** Validate the request before running any verifier or reading evidence. */
export function validateRequest(request) {
  exactKeys(request, ['schema', 'method', 'params']);
  require(request.schema === REQUEST_SCHEMA, 'REQUEST_SCHEMA');
  require(METHODS.includes(request.method), 'METHOD_NOT_SUPPORTED');
  if (request.method === 'claim.explain') {
    exactKeys(request.params, ['claimId']);
    require(typeof request.params.claimId === 'string' && request.params.claimId.length <= 100,
      'INVALID_CLAIM_ID');
  } else if (request.method === 'scenario.explore') {
    selection(request.params);
  } else if (request.method === 'questions.next' && Object.keys(request.params ?? {}).length > 0) {
    selection(request.params);
  } else exactKeys(request.params, []);
  return request;
}

function leanExport(head) {
  const cwd = join(ROOT, 'formal/lean');
  execFileSync('lake', ['build', 'UsulTest.IDACaseWorkbench'], { cwd, stdio: ['ignore', 'pipe', 'pipe'] });
  const bytes = execFileSync('lake', ['env', 'lean', '--run',
    'scripts/ExportIDACaseWorkbench.lean', head], { cwd, encoding: 'utf8', maxBuffer: 8 * 1024 * 1024 });
  const output = JSON.parse(bytes);
  require(output.schema === 'ida-case-workbench-lean-v1' && output.revision === head,
    'LEAN_EXPORT_SCOPE');
  require(output.scenarios?.length === 384, 'LEAN_EXPORT_COVERAGE');
  const keys = new Set(output.scenarios.map(row => {
    selection(rowSelection(row));
    return `${row.mask}/${row.population}/${row.authorityMode}`;
  }));
  require(keys.size === 384, 'LEAN_EXPORT_DUPLICATES');
  return output;
}

function rowSelection(row) {
  return { mask: row.mask, population: row.population, authorityMode: row.authorityMode };
}

/** Separate, project-owned fixture trust. These private keys are PUBLIC TEST DATA. */
export async function fixtureInputs(head) {
  const read = name => readFile(join(FIXTURE_ROOT, name));
  const pins = JSON.parse(await read('test-only-trust.json'));
  require(pins.syntheticFixtures === true, 'NOT_SYNTHETIC_FIXTURE');
  const signer = await read('test-only-untrusted-private.pem');
  const trust = {
    active: true, issuer: 'synthetic-premise-authority', publicKey: createPublicKey(signer),
    source: {
      sourceRoot: FIXTURE_ROOT, trustedIssuerId: pins.trustedIssuerId,
      expectedManifestSha256: pins.expectedManifestSha256,
      trustedPublicKeyPem: (await read('test-only-issuer-public.pem')).toString(),
    },
  };
  const attestationBytes = canonicalJsonBytes(attestation(head, pins.expectedManifestSha256,
    trust.issuer, [1, 2, 3, 4]));
  return {
    trust,
    candidate: {
      catalogBytes: await read('catalog.json'), catalogSignature: await read('catalog.sig'),
      attestationBytes, attestationSignature: sign(null, attestationBytes, signer),
    },
  };
}

function display(value) {
  if (value === undefined || value === null) return 'Not exported';
  if (value && typeof value === 'object') {
    if (value.reference && value.role) return `${value.role}: ${display(value.reference)}`;
    if (value.space && value.name) return `${value.space}:${value.name}`;
    if (value.kind && value.symbol) return `${value.kind} · ${display(value.symbol)}`;
    if (value.symbol && value.version !== undefined) return `${display(value.symbol)}@${value.version}`;
    if (Array.isArray(value) && value.length === 32 && value.every(n => Number.isInteger(n) && n >= 0 && n <= 255)) {
      return Buffer.from(value).toString('hex');
    }
  }
  return typeof value === 'string' ? value : JSON.stringify(value);
}

function items(object, fields) {
  return fields.map(([key, label]) => ({ label, value: display(object[key]) }));
}

const AUTHORITY_LABELS = [
  'Exact fixture authority', 'Missing destination certificates', 'Substituted destination formula',
  'Missing destination evidence', 'Stale destination snapshot', 'Missing application grant',
];
const POPULATION_LABELS = [
  'No supplied histories', 'Only incompatible history', 'One compatible history', 'All 16 declared histories',
];
const RESULT_DETAILS = {
  accepted: 'The modeled guard and admission pass, with a nonempty compatible history population. The conclusion remains conditional on the modeled premises.',
  destinationPremiseListMismatch: 'The exact destination premise certificate list is missing or changed.',
  destinationEvidenceMissing: 'Required destination evidence is unavailable to the admission environment.',
  destinationSnapshotStale: 'The current context catalog does not resolve the exact destination snapshot.',
  destinationGrantMissing: 'Independent authority has not granted this exact application.',
  guardRejected: 'The report guard requires positive support, explicit negative exception, and no opposing reports.',
  noCandidateHistories: 'An empty supplied history population provides no nonvacuous semantic assessment.',
  incompatibleHistories: 'None of the supplied histories satisfies the destination premises.',
};

export function nextQuestions(row) {
  const questions = [];
  const add = (id, question, reason, nextAction) => questions.push({ id, question, reason, nextAction });
  if (row && !row.support?.positive) add('support',
    'What evidence supports the condition for the accountable party?',
    'A positive support report is missing from this scenario.',
    'Identify a source and submit a scoped premise to the independent admission authority.');
  if (row?.support?.negative || row?.exception?.positive) add('opposition',
    'How should the opposing report be assessed?',
    'The current guard is blocked by contrary support or a reported exception.',
    'Inspect each report and its source; retain the disagreement for human review.');
  if (row && !row.exception?.negative) add('exception',
    'What explicitly supports exclusion of the exception?',
    'Missing exception evidence is not an explicit negative report.',
    'Request scoped evidence for the negative premise; do not infer it from silence.');
  if (row && row.authorityMode !== 0) add('admission',
    'Which exact destination certificates, context, and application grant are current?',
    AUTHORITY_LABELS[row.authorityMode],
    'Resolve the independent admission failure and request a fresh replay.');
  if (row && row.population < 2) add('histories',
    'Which declared histories are compatible with the premises?',
    POPULATION_LABELS[row.population],
    'State the scenario assumptions and history coverage explicitly before reassessment.');
  add('real-evidence', 'What real evidence would justify each proposed premise?',
    'The running example contains published test keys and synthetic source bytes.',
    'A general case requires a reviewed evidence-admission profile and a general typed adapter.');
  add('interpretation', 'Which qualified interpretation and authority should govern this inquiry?',
    'The example pins one synthetic interpretation and cannot select a juristic position.',
    'Have the adjudicator or mufti identify the applicable profile, jurisdiction, and inquiry.');
  return questions;
}

function proofCards(head) {
  const path = 'formal/lean/Usul/Typing/IDACaseWorkbench.lean';
  const scope = 'Formal statement over the declared typed model; empirical truth and juristic authority are separate.';
  const entries = [
    ['scope', 'Exact context retained', 'View.exact_snapshot', 'The presented snapshot is the exact destination snapshot in the admitted receipt.'],
    ['nonvacuous', 'Compatible history exists', 'View.nonvacuous', 'A receipt entails a nonempty compatible subset of the supplied histories.'],
    ['conditional', 'Conditional conclusion', 'View.conditional_sound', 'For a history satisfying the destination premises, the exact admitted conclusion holds.'],
    ['guard', 'All guard signs retained', 'View.explicit_report_states', 'The checked view retains exact scope, supported report state for support, and negative-only report state for the exception.'],
    ['occurrences', 'All certificate occurrences retained', 'View.all_source_occurrences', 'The presented certificate list retains both source and destination certificate lists in order.'],
    ['premises', 'Exact destination certificate formulas', 'View.exact_certificates', 'The destination certificate formulas equal the exact presented grounded premises.'],
  ];
  return entries.map(([id, label, name, statement]) => ({
    id, label, symbol: `Usul.IDA.CaseWorkbench.${name}`, path,
    url: `${REPOSITORY}/blob/${head}/${path}`, statement, scope, status: 'compiled',
  }));
}

/** Recompute admission from original inputs. A submitted receipt is never sufficient. */
export async function replayDossier(receipt, candidate, trust) {
  const implementation = await implementationRevision();
  const { head } = implementation;
  require(await verifyReceipt(receipt, candidate, trust), 'RECEIPT_REPLAY_MISMATCH');
  require(receipt.statement.fixture === FIXTURE && receipt.statement.revision === head,
    'RECEIPT_SCOPE');
  const exported = leanExport(head);
  const baseline = exported.baseline;
  require(baseline.guard === true && baseline.assessment === 'robust' && baseline.result === 'accepted'
    && baseline.authorityRevision === head,
    'BASELINE_NOT_ACCEPTED');
  const catalog = JSON.parse(Buffer.from(candidate.catalogBytes).toString());
  const sources = [];
  for (const entry of catalog.sources) {
    // Recheck the exact bytes being displayed, after the independent authentication.
    const bytes = await readFile(join(trust.source.sourceRoot, entry.path));
    const excerpt = bytes.subarray(entry.passageStart, entry.passageEnd);
    require(bytes.length === entry.sourceBytes && sha256(bytes) === entry.sourceHash
      && sha256(excerpt) === entry.passageHash, 'DISPLAYED_SOURCE_CHANGED');
    sources.push({
      id: `source-${entry.sourceId}`, label: `Synthetic source ${entry.sourceId}`,
      excerpt: excerpt.toString('utf8'), locator: `${entry.path}, UTF-8 byte range [${entry.passageStart}, ${entry.passageEnd})`,
      sourceSha256: entry.sourceHash, passageSha256: entry.passageHash,
      issuer: trust.source.trustedIssuerId, keyFingerprint: receipt.sourceIssuerKey,
      status: 'authenticated test bytes',
      notes: ['Published fixture key. These bytes are not testimony, a legal source, or evidence of a real event.'],
    });
  }
  const inquiry = baseline.inquiry;
  require(inquiry && baseline.snapshot && Array.isArray(baseline.certificates)
    && baseline.certificates.length === 4, 'BASELINE_EXPORT_INCOMPLETE');
  const receiptSha256 = sha256(canonicalJsonBytes(receipt));
  const snapshotSha256 = sha256(canonicalJsonBytes(baseline.snapshot));
  const proofIds = ['scope', 'guard', 'nonvacuous', 'conditional'];
  const claims = baseline.certificates.map(cert => ({
    id: `premise-${cert.token}`, label: `${cert.side === 'source' ? 'Source' : 'Destination'} premise ${cert.token}`,
    statement: cert.formula, kind: 'premise', status: 'admitted in synthetic fixture',
    scope: cert.side === 'source' ? 'Exact source application' : 'Exact destination application',
    dependencies: [], sourceIds: [`source-${cert.sourceId}`],
    proofIds: cert.side === 'source' ? ['occurrences'] : ['occurrences', 'premises'],
    binding: { side: cert.side, certificateToken: cert.token, snapshotRepresentation: cert.scope,
      formulaSyntax: cert.formulaSyntax, applicationPremises: cert.applicationPremises,
      applicationConclusion: cert.applicationConclusion, sourceRepresentation: cert.sourceRepresentation },
    notes: ['Authenticated certificate membership and contextual applicability were rechecked.',
      'Admission is distinct from truth in the actual world.',
      cert.side === 'source' ? 'This premise belongs to the source context; the inquiry header shows the destination.' : 'This premise belongs to the displayed destination context.'],
  }));
  claims.push(...['support', 'exception'].map(id => ({
    id: `report-${id}`, label: id === 'support' ? 'Support for accountable party' : 'Exception for performer',
    statement: `${id === 'support' ? 'Support' : 'Exception'} query: positive=${baseline[id].positive}, negative=${baseline[id].negative}`,
    kind: 'report', status: baseline[id].status, scope: 'Exact destination report list',
    dependencies: [], sourceIds: [], proofIds: ['guard'],
    notes: ['Report signs are a separate modeled input; neither sign certifies an event occurred.',
      'Both signs are retained. Absence is not negation.'],
  })));
  claims.push({ id: 'conditional-conclusion', label: 'Checked conditional conclusion',
    statement: baseline.conclusion, kind: 'derivation', status: 'conditional',
    scope: 'Exact destination context and pinned synthetic interpretation',
    dependencies: ['premise-3', 'premise-4', 'report-support', 'report-exception'],
    sourceIds: ['source-1', 'source-2'], proofIds,
    binding: { side: 'destination', formulaSyntax: baseline.conclusionSyntax,
      snapshotRepresentation: baseline.snapshot.representation },
    notes: ['No deontic ruling or real-world factual finding is issued.'],
  });
  const rows = exported.scenarios.map(row => ({
    selection: rowSelection(row), label: `Reports ${row.mask} · ${POPULATION_LABELS[row.population]} · ${AUTHORITY_LABELS[row.authorityMode]}`,
    guard: row.guard, reportStatus: row.reportStatus, assessment: row.assessment, result: row.result,
    support: row.support, exception: row.exception,
    explanation: RESULT_DETAILS[row.result] ?? `Typed pilot outcome: ${row.result}.`,
    questions: nextQuestions(row), hypothetical: true,
  }));
  const baselineRow = exported.scenarios.find(row => row.mask === 9 && row.population === 2 && row.authorityMode === 0);
  const dossier = {
    schema: DOSSIER_SCHEMA, title: 'IDA case workbench', caseMode: 'synthetic-scenario', audience: 'review',
    fixture: { id: FIXTURE, label: 'Guarded repayment inquiry', synthetic: true, testKeys: true,
      scope: 'One bounded synthetic ACT-08 example. General case intake is not implemented.' },
    verification: {
      status: 'replayed-at-generation', revision: head, receiptSha256, snapshotSha256,
      checks: [
        { id: 'source', label: 'Source bytes and catalog signature', status: 'passed', detail: 'Exact source and passage hashes, independently pinned published fixture issuer and manifest.' },
        { id: 'premise', label: 'Premise attestation and membership', status: 'passed', detail: 'All four exact certificates, signed in a separate domain for this fixture and implementation revision.' },
        { id: 'admission', label: 'Context and application admission', status: 'passed', detail: 'Existing Lean admission checks independently validate context, scope, interpretations and grants.' },
        { id: 'replay', label: 'Complete receipt replay', status: 'passed', detail: 'Recomputed from original signed inputs and project-owned fixture trust.' },
        { id: 'truth', label: 'Actual-world truth / juristic authority', status: 'unverified', detail: 'No real case evidence or qualified human decision is supplied.' },
      ],
      limits: [
        'Replayed at generation. This static artifact does not monitor authority changes or revocation.',
        'The displayed digest checks identity; the dossier itself is not an independently signed credential.',
        'Robustness concerns the supplied finite histories. It does not establish coverage of all real possibilities.',
        'The fixture sources and premise keys are public test material.',
      ],
    },
    inquiry: {
      id: display(inquiry.questionId), question: display(inquiry.question), label: 'Exact contextual inquiry',
      target: `${inquiry.targetForm === 'omission' ? 'Omission inquiry' : 'Performance inquiry'}: ${display(inquiry.act)}(${inquiry.operands.map(display).join(', ')})`,
      parties: [{ role: 'Accountable party · المحكوم عليه', label: display(inquiry.accountable), reference: display(inquiry.accountable) },
        { role: 'Performer', label: display(inquiry.performer), reference: display(inquiry.performer) }],
      context: [...items(inquiry, [['contextId', 'Context'], ['subjectId', 'Subject'], ['snapshotKey', 'Snapshot']]),
        { label: 'Occurrence / opportunity', value: inquiry.opportunityDetails
          ? `${display(inquiry.opportunityDetails.occurrence)} · [${inquiry.opportunityDetails.opensAt}, ${inquiry.opportunityDetails.closesAt}) on ${display(inquiry.opportunityDetails.clock)}` : 'No omission opportunity' }],
      time: items(inquiry, [['effectiveAt', 'Effective time'], ['recordedAt', 'Recorded time'], ['cutoff', 'Evidence cutoff'], ['clockVersion', 'Clock version'], ['perspective', 'Perspective']]),
      pins: items(inquiry, [['profile', 'Profile'], ['profileVersion', 'Profile version'], ['interpretationId', 'Interpretation'], ['interpretationVersion', 'Interpretation version'], ['definition', 'Definition'], ['definitionDigest', 'Definition digest'], ['registrySnapshot', 'Registry snapshot'], ['vocabulary', 'Vocabulary'], ['policy', 'Admission policy']]),
    },
    claims, sources, proofs: proofCards(head),
    conclusion: {
      title: 'Conditional derivation for human review', statement: baseline.conclusion, status: 'conditional',
      conditions: baseline.premises, premiseIds: ['premise-3', 'premise-4'],
      limits: ['The premises must hold in the history being considered.',
        'The synthetic report guard and separate application grants pass for this exact snapshot.',
        'The mufti or adjudicator still determines evidence acceptance, applicability, and any ruling.'],
    },
    questions: nextQuestions(baselineRow),
    scenarios: {
      description: 'Hypothetical cells are computed by Lean from the declared fixture. The baseline attestation does not authenticate a changed scenario.',
      dimensions: [
        { id: 'mask', label: 'Support and exception reports', options: Array.from({ length: 16 }, (_, value) => ({ value,
          label: `Support ${value & 1 ? '+' : '·'}${value & 2 ? '−' : '·'} / exception ${value & 4 ? '+' : '·'}${value & 8 ? '−' : '·'}` })) },
        { id: 'population', label: 'Declared history population', options: POPULATION_LABELS.map((label, value) => ({ value, label })) },
        { id: 'authorityMode', label: 'Admission inputs', options: AUTHORITY_LABELS.map((label, value) => ({ value, label })) },
      ], baseline: { mask: 9, population: 2, authorityMode: 0 }, cells: rows,
    },
    protocol: { id: REQUEST_SCHEMA, commands: [
      { name: 'dossier.read', description: 'Recompute and read the bounded dossier.' },
      { name: 'dossier.reverify', description: 'Reauthenticate signed fixture inputs and replay the receipt.' },
      { name: 'claim.explain', description: 'Inspect a claim, exact dependencies, sources and formal proof references.' },
      { name: 'scenario.explore', description: 'Read a hypothetical Lean cell without changing the admitted baseline.' },
      { name: 'questions.next', description: 'List explicit unmet evidence and interpretation questions.' },
    ] },
    binding: { receipt, leanExportSha256: sha256(canonicalJsonBytes(exported)), snapshot: baseline.snapshot,
      implementationSha256: sha256(canonicalJsonBytes(implementation.hashes)), sourceSha256: implementation.hashes },
  };
  const after = await implementationRevision();
  require(after.head === head && canonicalJsonBytes(after.hashes).equals(canonicalJsonBytes(implementation.hashes)),
    'IMPLEMENTATION_CHANGED_DURING_REPLAY');
  return dossier;
}

/** Every invocation reconstructs a disposable synthetic fixture admission. */
export async function generateDossier() {
  const { head } = await implementationRevision();
  const { candidate, trust } = await fixtureInputs(head);
  const work = await mkdtemp(join(tmpdir(), 'ida-case-workbench-'));
  try {
    const receipt = await admit(join(work, 'fixture.sqlite'), candidate, trust);
    return await replayDossier(receipt, candidate, trust);
  } finally { await rm(work, { recursive: true, force: true }); }
}

export function answerRequest(request, dossier) {
  validateRequest(request);
  const scope = { fixture: dossier.fixture.id, revision: dossier.verification.revision,
    receiptSha256: dossier.verification.receiptSha256, caseMode: dossier.caseMode };
  let result;
  if (request.method === 'dossier.read') result = dossier;
  if (request.method === 'dossier.reverify') result = dossier.verification;
  if (request.method === 'claim.explain') {
    const claim = dossier.claims.find(c => c.id === request.params.claimId);
    require(claim, 'CLAIM_NOT_FOUND');
    result = { claim, dependencies: dossier.claims.filter(c => claim.dependencies.includes(c.id)),
      sources: dossier.sources.filter(source => claim.sourceIds.includes(source.id)),
      proofs: dossier.proofs.filter(proof => claim.proofIds.includes(proof.id)) };
  }
  if (request.method === 'scenario.explore' || (request.method === 'questions.next' && Object.keys(request.params).length)) {
    const requested = selection(request.params);
    const cell = dossier.scenarios.cells.find(row => Object.entries(requested)
      .every(([key, value]) => row.selection[key] === value));
    require(cell, 'SCENARIO_NOT_FOUND');
    result = request.method === 'scenario.explore'
      ? { ...cell, baselineAdmissionApplies: false, notice: dossier.scenarios.description }
      : cell.questions;
  } else if (request.method === 'questions.next') result = dossier.questions;
  return { schema: 'ida-case-workbench-response-v1', method: request.method, scope, result };
}

export async function handleRequest(request) {
  validateRequest(request);
  return answerRequest(request, await generateDossier());
}

export async function build(output) {
  const destination = resolve(output);
  // Remove only our success marker before replay; an old package must not appear fresh on failure.
  await rm(join(destination, 'verification.json'), { force: true });
  const dossier = await generateDossier();
  const parent = dirname(destination);
  await mkdir(parent, { recursive: true });
  const stage = await mkdtemp(join(parent, '.ida-workbench-'));
  try {
    for (const file of ['index.html', 'app.js', 'style.css']) {
      const bytes = execFileSync('git', ['show', `${dossier.verification.revision}:web/ida-case-workbench/${file}`], { cwd: ROOT });
      await writeFile(join(stage, file), bytes);
    }
    const serialized = JSON.stringify(dossier, null, 2) + '\n';
    await writeFile(join(stage, 'dossier.json'), serialized);
    const manifest = { schema: 'ida-case-workbench-build-v1', revision: dossier.verification.revision,
      receiptSha256: dossier.verification.receiptSha256, dossierSha256: sha256(Buffer.from(serialized)),
      scenarioCells: dossier.scenarios.cells.length, synthetic: true };
    await mkdir(destination, { recursive: true });
    for (const file of ['index.html', 'app.js', 'style.css', 'dossier.json']) {
      await rename(join(stage, file), join(destination, file));
    }
    const final = await implementationRevision();
    require(final.head === dossier.verification.revision
      && sha256(canonicalJsonBytes(final.hashes)) === dossier.binding.implementationSha256,
    'IMPLEMENTATION_CHANGED_DURING_PUBLICATION');
    await writeFile(join(destination, 'verification.json'), JSON.stringify(manifest, null, 2) + '\n');
    return manifest;
  } finally { await rm(stage, { recursive: true, force: true }); }
}

async function main(args) {
  if (args[0] === 'build' && args.length <= 2) {
    const output = args[1] ?? join(ROOT, '.cache/ida-case-workbench');
    process.stdout.write(JSON.stringify(await build(output)) + '\n');
  } else if (args.length === 1 && args[0] === 'request') {
    let input = '';
    for await (const chunk of process.stdin) {
      input += chunk;
      require(Buffer.byteLength(input) <= 16384, 'REQUEST_TOO_LARGE');
    }
    process.stdout.write(JSON.stringify(await handleRequest(JSON.parse(input))) + '\n');
  } else throw new Error('Usage: node formal/ida-case-workbench.mjs build [output-directory] | request < request.json');
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main(process.argv.slice(2)).catch(error => {
    process.stderr.write(`${error.code ?? 'CASE_WORKBENCH_FAILED'}: ${error.message}\n`);
    process.exitCode = 1;
  });
}
