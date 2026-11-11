/** Authenticate one complete omission observation batch before typed review. */
import {
  authenticateSourceCatalog, canonicalJsonBytes, sha256, SourceAuthenticationError,
} from './ida-source-auth.mjs';

const MAX_BATCH_BYTES = 1024 * 1024;

function requireObservation(condition, code, message) {
  if (!condition) throw new SourceAuthenticationError(code, message);
}

/**
 * The caller supplies the current catalog pin, issuer, designated source ID
 * and trusted evaluator. The evaluator owns current registry/snapshot inputs.
 * The signed observation file attests what the issuer supplied for its scope.
 */
export async function reviewAuthenticatedOmission({
  observationBytes, catalog, trustedObservationSourceId, evaluateVerified,
}) {
  requireObservation(observationBytes instanceof Uint8Array && observationBytes.length > 0
    && observationBytes.length <= MAX_BATCH_BYTES, 'BAD_OBSERVATION_BYTES',
  'Expected a nonempty observation batch no larger than 1 MiB');
  requireObservation(Number.isSafeInteger(trustedObservationSourceId)
    && trustedObservationSourceId >= 0 && typeof evaluateVerified === 'function',
  'BAD_OBSERVATION_TRUST', 'Expected a configured source ID and trusted evaluator');

  // Freeze the submitted byte value before the first asynchronous operation.
  const bytes = Buffer.from(observationBytes);
  const auth = await authenticateSourceCatalog(catalog);
  const whole = auth.authenticated_sources.filter(ref => ref.sourceId === trustedObservationSourceId
    && ref.passageStart === 0 && ref.passageEnd === ref.sourceBytes);
  requireObservation(whole.length === 1, 'OBSERVATION_SOURCE_MISSING',
    'The pinned catalog must authenticate exactly one whole-file reference for the configured ID');
  const [source] = whole;
  const digest = sha256(bytes);
  requireObservation(source.sourceBytes === bytes.length
    && Buffer.from(source.sourceHash).toString('hex') === digest
    && Buffer.from(source.passageHash).toString('hex') === digest, 'OBSERVATION_BYTES_MISMATCH',
  'Submitted bytes differ from the exact authenticated observation batch');

  let text;
  let canonical;
  try {
    text = new TextDecoder('utf-8', { fatal: true }).decode(bytes);
    canonical = canonicalJsonBytes(JSON.parse(text));
  } catch {
    throw new SourceAuthenticationError('BAD_OBSERVATION_JSON', 'Expected restricted UTF-8 JSON');
  }
  requireObservation(canonical.equals(bytes), 'NONCANONICAL_OBSERVATION_JSON',
    'Observation JSON must use the canonical encoding');

  return Object.freeze({
    issuer_id: auth.issuer_id,
    issuer_public_key_sha256: auth.issuer_public_key_sha256,
    catalog_version: auth.catalog_version,
    manifest_sha256: auth.manifest_sha256,
    source,
    assessment: await evaluateVerified(text),
  });
}
