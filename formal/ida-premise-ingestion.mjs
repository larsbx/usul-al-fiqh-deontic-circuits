/** Bounded ACT-08 fixture adapter. Trust and current policy come from the caller. */
import { execFileSync } from 'node:child_process';
import { createPublicKey, verify } from 'node:crypto';
import { DatabaseSync } from 'node:sqlite';
import { fileURLToPath } from 'node:url';
import { authenticateSourceCatalog, canonicalJsonBytes, sha256 } from './ida-source-auth.mjs';

const root = fileURLToPath(new URL('..', import.meta.url));
const leanRoot = fileURLToPath(new URL('./lean', import.meta.url));
const fixture = 'act08-synthetic-guarded-repayment-v1';
const schema = 'ida-premise-attestation-v1';
const tokens = [1, 2, 3, 4];

function require(condition, code) {
  if (!condition) throw new Error(code);
}

export function revision() {
  const git = (...args) => execFileSync('git', args, { cwd: root, encoding: 'utf8' }).trim();
  require(git('status', '--porcelain', '--untracked-files=no') === '', 'DIRTY_REVISION');
  return git('rev-parse', 'HEAD');
}

export function leanReplay(mode, input) {
  execFileSync('lake', ['build', 'UsulTest.IDAPremiseIngestion'], { cwd: leanRoot });
  return JSON.parse(execFileSync('lake', ['env', 'lean', '--run',
    'scripts/CheckIDAPremiseIngestion.lean', mode], {
    cwd: leanRoot, encoding: 'utf8', input,
  }));
}

export function attestation(revision, sourceManifest, issuer, certificateTokens) {
  return { schema, fixture, revision, sourceManifest, issuer, certificateTokens };
}

/**
 * The exact revision and fixed fixture resolve the four immutable typed
 * certificate selectors. No submitted identifier resolves arbitrary terms.
 * The fixture's ACT-05 grants remain independent of the signature.
 */
async function evaluate(candidate, trust) {
  const head = revision();
  require(trust.active === true, 'AUTHORITY_REVOKED');
  const { issuer, publicKey } = trust;
  const supplied = Buffer.from(candidate.attestationBytes);
  const signature = Buffer.from(candidate.attestationSignature);
  const catalogSignature = Buffer.from(candidate.catalogSignature);
  const authenticated = await authenticateSourceCatalog({
    ...trust.source, catalogBytes: candidate.catalogBytes, signatureBytes: catalogSignature,
  });
  const statement = attestation(head, authenticated.manifest_sha256, issuer, tokens);
  const expected = canonicalJsonBytes(statement);
  require(supplied.equals(expected), 'ATTESTATION_SCOPE');
  const key = publicKey?.type === 'public' ? publicKey : createPublicKey(publicKey);
  require(key.asymmetricKeyType === 'ed25519' && signature.length === 64
    && verify(null, expected, key, signature), 'ATTESTATION_SIGNATURE');
  const decision = leanReplay('check', JSON.stringify({
    revision: head, sources: authenticated.authenticated_sources, tokens: statement.certificateTokens,
  }));
  require(decision === 0, `LEAN_REJECTION_${decision}`);
  require(revision() === head, 'REVISION_CHANGED');
  return {
    schema: 'ida-premise-admission-receipt-v1',
    statement,
    sourceIssuerKey: authenticated.issuer_public_key_sha256,
    admissionIssuerKey: sha256(key.export({ format: 'der', type: 'spki' })),
    attestationSignature: signature.toString('hex'),
    catalogSignature: catalogSignature.toString('hex'),
    result: 'synthetic-contextual-admission',
  };
}

/** One durable insertion is the admission boundary. A competing insert loses
 * under SQLite's unique constraint, including across process restarts. */
export async function admit(database, candidate, trust) {
  const receipt = await evaluate(candidate, trust);
  const db = new DatabaseSync(database);
  try {
    db.exec('PRAGMA busy_timeout = 5000; PRAGMA synchronous = FULL');
    db.exec('CREATE TABLE IF NOT EXISTS admissions (revision TEXT, fixture TEXT, receipt TEXT NOT NULL, PRIMARY KEY (revision, fixture)) WITHOUT ROWID');
    const result = db.prepare('INSERT INTO admissions VALUES (?, ?, ?) ON CONFLICT DO NOTHING')
      .run(receipt.statement.revision, fixture, canonicalJsonBytes(receipt).toString());
    require(result.changes === 1, 'DUPLICATE_ADMISSION');
  } finally {
    db.close();
  }
  return receipt;
}

export function recover(database, revision) {
  const db = new DatabaseSync(database, { readOnly: true });
  try {
    const row = db.prepare('SELECT receipt FROM admissions WHERE revision = ? AND fixture = ?')
      .get(revision, fixture);
    return row === undefined ? undefined : JSON.parse(row.receipt);
  } finally {
    db.close();
  }
}

/** Replay from the original signed inputs and independently pinned trust. */
export async function verifyReceipt(receipt, candidate, trust) {
  const expected = await evaluate(candidate, trust);
  return canonicalJsonBytes(receipt).equals(canonicalJsonBytes(expected));
}
