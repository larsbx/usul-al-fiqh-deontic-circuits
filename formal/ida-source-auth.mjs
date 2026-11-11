#!/usr/bin/env node
/**
 * Authenticate a caller-pinned source catalog and the exact bytes it names.
 *
 * This module assigns no evidence grade, interpretation version, registry
 * status, or normative judgment. Its only model-facing output is SourceRef[].
 * The caller must supply the intended current manifest hash and issuer key
 * independently of the candidate catalog. See docs/research/ida-source-auth.md.
 */
import { createHash, createPublicKey, verify } from 'node:crypto';
import { constants } from 'node:fs';
import { lstat, open, readFile, realpath } from 'node:fs/promises';
import { isAbsolute, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const CATALOG_SCHEMA = 'ida-source-catalog-v1';
const MAX_CATALOG_BYTES = 1024 * 1024;
const MAX_REFERENCES = 4096;
const HEX_SHA256 = /^[0-9a-f]{64}$/;

export class SourceAuthenticationError extends Error {
  constructor(code, message) {
    super(message);
    this.name = 'SourceAuthenticationError';
    this.code = code;
  }
}

function requireCondition(condition, code, message) {
  if (!condition) throw new SourceAuthenticationError(code, message);
}

export function sha256(bytes) {
  return createHash('sha256').update(bytes).digest('hex');
}

/**
 * Restricted canonical JSON: sorted object keys, preserved array order,
 * JSON string escaping, safe integer numbers, UTF-8, no trailing whitespace.
 * It is a versioned local encoding, not a claim of RFC 8785 conformance.
 */
export function canonicalJsonBytes(value) {
  function encode(item) {
    if (item === null || typeof item === 'boolean' || typeof item === 'string') {
      return JSON.stringify(item);
    }
    if (typeof item === 'number') {
      requireCondition(Number.isSafeInteger(item) && !Object.is(item, -0),
        'UNSAFE_JSON_NUMBER', 'Catalog numbers must be safe integers, excluding negative zero');
      return String(item);
    }
    if (Array.isArray(item)) {
      requireCondition(Object.keys(item).length === item.length,
        'INVALID_JSON_VALUE', 'Sparse arrays and additional array properties are not allowed');
      return `[${item.map(encode).join(',')}]`;
    }
    requireCondition(item !== null && typeof item === 'object'
      && (Object.getPrototypeOf(item) === Object.prototype || Object.getPrototypeOf(item) === null),
    'INVALID_JSON_VALUE', 'Catalog values must be plain JSON values');
    return `{${Object.keys(item).sort().map(key => `${JSON.stringify(key)}:${encode(item[key])}`).join(',')}}`;
  }
  return Buffer.from(encode(value), 'utf8');
}

function exactKeys(value, keys, description) {
  requireCondition(value !== null && typeof value === 'object' && !Array.isArray(value)
    && Object.getPrototypeOf(value) === Object.prototype,
  'BAD_SCHEMA', `${description} must be a JSON object`);
  const actual = Object.keys(value).sort();
  const expected = [...keys].sort();
  requireCondition(actual.length === expected.length
    && actual.every((key, index) => key === expected[index]),
  'BAD_SCHEMA', `${description} has missing or unsupported fields`);
}

function natural(value, name) {
  requireCondition(Number.isSafeInteger(value) && value >= 0 && !Object.is(value, -0),
    'BAD_NATURAL', `${name} must be a safe nonnegative integer`);
}

function safeRelativePath(value) {
  requireCondition(typeof value === 'string' && value.length > 0 && value.length <= 1024,
    'UNSAFE_SOURCE_PATH', 'Source paths must be nonempty relative paths of at most 1024 characters');
  const parts = value.split('/');
  requireCondition(parts.every(part => /^[A-Za-z0-9](?:[A-Za-z0-9._-]*[A-Za-z0-9_-])?$/.test(part)),
    'UNSAFE_SOURCE_PATH', 'Source paths must use simple ASCII relative components without dot segments');
  return parts;
}

function parseCatalog(bytes) {
  requireCondition(bytes.length > 0 && bytes.length <= MAX_CATALOG_BYTES,
    'BAD_CATALOG_SIZE', 'Catalog must contain between 1 and 1048576 bytes');
  let text;
  try {
    text = new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(bytes);
  } catch {
    throw new SourceAuthenticationError('BAD_CATALOG_UTF8', 'Catalog is not valid UTF-8');
  }
  let catalog;
  try {
    catalog = JSON.parse(text);
  } catch {
    throw new SourceAuthenticationError('BAD_CATALOG_JSON', 'Catalog is not valid JSON');
  }
  requireCondition(canonicalJsonBytes(catalog).equals(bytes),
    'NONCANONICAL_CATALOG', 'Catalog must use its canonical encoding without duplicate keys or whitespace');
  exactKeys(catalog, ['schema', 'issuerId', 'catalogVersion', 'sources'], 'Catalog');
  requireCondition(catalog.schema === CATALOG_SCHEMA,
    'BAD_SCHEMA', `Catalog schema must be ${CATALOG_SCHEMA}`);
  requireCondition(typeof catalog.issuerId === 'string'
    && /^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$/.test(catalog.issuerId),
  'BAD_SCHEMA', 'Catalog issuer ID is invalid');
  natural(catalog.catalogVersion, 'catalogVersion');
  requireCondition(Array.isArray(catalog.sources) && catalog.sources.length > 0
    && catalog.sources.length <= MAX_REFERENCES,
  'BAD_SCHEMA', 'Catalog must have between 1 and 4096 source references');

  const origins = new Map();
  const references = new Set();
  for (const source of catalog.sources) {
    exactKeys(source, ['sourceId', 'path', 'sourceHash', 'sourceBytes',
      'passageStart', 'passageEnd', 'passageHash'], 'Source reference');
    for (const name of ['sourceId', 'sourceBytes', 'passageStart', 'passageEnd']) {
      natural(source[name], name);
    }
    requireCondition(typeof source.sourceHash === 'string' && HEX_SHA256.test(source.sourceHash)
      && typeof source.passageHash === 'string' && HEX_SHA256.test(source.passageHash),
    'BAD_DIGEST', 'Source and passage digests must be lowercase SHA256 hex');
    requireCondition(source.passageStart < source.passageEnd
      && source.passageEnd <= source.sourceBytes,
    'BAD_PASSAGE_RANGE', 'Passage must be a nonempty half-open byte range within the source');
    safeRelativePath(source.path);
    const origin = JSON.stringify([source.path, source.sourceHash, source.sourceBytes]);
    requireCondition(!origins.has(source.sourceId) || origins.get(source.sourceId) === origin,
      'SOURCE_ID_CONFLICT', 'One source ID cannot name different source files or contents');
    origins.set(source.sourceId, origin);
    const reference = `${source.sourceId}:${source.passageStart}:${source.passageEnd}`;
    requireCondition(!references.has(reference),
      'DUPLICATE_SOURCE_REFERENCE', 'A source passage may appear only once in the catalog');
    references.add(reference);
  }
  return catalog;
}

function publicKeyFromPin(pem) {
  requireCondition(typeof pem === 'string' && pem.trim().startsWith('-----BEGIN PUBLIC KEY-----')
    && pem.trim().endsWith('-----END PUBLIC KEY-----'),
  'BAD_TRUSTED_KEY', 'A separately configured public SPKI PEM key is required');
  let key;
  try {
    key = createPublicKey(pem);
  } catch {
    throw new SourceAuthenticationError('BAD_TRUSTED_KEY', 'Configured public key cannot be parsed');
  }
  requireCondition(key.type === 'public' && key.asymmetricKeyType === 'ed25519',
    'BAD_TRUSTED_KEY', 'Configured issuer key must be an Ed25519 public key');
  return key;
}

async function checkedSourcePath(root, sourcePath) {
  const parts = safeRelativePath(sourcePath);
  let current = root;
  for (let index = 0; index < parts.length; index++) {
    current = resolve(current, parts[index]);
    const info = await lstat(current);
    requireCondition(!info.isSymbolicLink(),
      'UNSAFE_SOURCE_PATH', 'Symbolic links are not allowed in source paths');
    if (index < parts.length - 1) {
      requireCondition(info.isDirectory(), 'UNSAFE_SOURCE_PATH', 'Source parent must be a directory');
    } else {
      requireCondition(info.isFile(), 'SOURCE_NOT_REGULAR', 'Source must be a regular file');
    }
  }
  const physical = await realpath(current);
  const inside = relative(root, physical);
  requireCondition(inside.length > 0 && inside !== '..'
    && !inside.startsWith(`..${sep}`) && !isAbsolute(inside) && physical === current,
  'UNSAFE_SOURCE_PATH', 'Source must resolve inside its configured root');
  return physical;
}

async function authenticateSource(root, source) {
  let handle;
  try {
    const path = await checkedSourcePath(root, source.path);
    // O_NOFOLLOW closes the final-component symlink race where supported.
    // This is not an atomic filesystem snapshot or an openat-based sandbox.
    handle = await open(path, constants.O_RDONLY
      | (constants.O_NOFOLLOW ?? 0) | (constants.O_NONBLOCK ?? 0));
    const info = await handle.stat();
    requireCondition(info.isFile(), 'SOURCE_NOT_REGULAR', 'Source must be a regular file');
    requireCondition(Number.isSafeInteger(info.size) && info.size === source.sourceBytes,
      'SOURCE_BYTE_COUNT_MISMATCH', 'Source byte count differs from the authenticated catalog');
    const fullHash = createHash('sha256');
    const passageHash = createHash('sha256');
    const buffer = Buffer.allocUnsafe(65536);
    let offset = 0;
    while (true) {
      const { bytesRead } = await handle.read(buffer, 0, buffer.length, null);
      if (bytesRead === 0) break;
      requireCondition(offset + bytesRead <= source.sourceBytes,
        'SOURCE_BYTE_COUNT_MISMATCH', 'Source grew beyond its authenticated byte count');
      fullHash.update(buffer.subarray(0, bytesRead));
      const start = Math.max(0, source.passageStart - offset);
      const end = Math.min(bytesRead, source.passageEnd - offset);
      if (start < end) passageHash.update(buffer.subarray(start, end));
      offset += bytesRead;
    }
    requireCondition(offset === source.sourceBytes,
      'SOURCE_BYTE_COUNT_MISMATCH', 'Source ended before its authenticated byte count');
    requireCondition(fullHash.digest('hex') === source.sourceHash,
      'SOURCE_HASH_MISMATCH', 'Source bytes differ from the authenticated SHA256 digest');
    requireCondition(passageHash.digest('hex') === source.passageHash,
      'PASSAGE_HASH_MISMATCH', 'Passage bytes differ from the authenticated SHA256 digest');
    return Object.freeze({
      sourceId: source.sourceId,
      sourceHash: Object.freeze([...Buffer.from(source.sourceHash, 'hex')]),
      sourceBytes: source.sourceBytes,
      passageStart: source.passageStart,
      passageEnd: source.passageEnd,
      passageHash: Object.freeze([...Buffer.from(source.passageHash, 'hex')]),
    });
  } catch (error) {
    if (error instanceof SourceAuthenticationError) throw error;
    throw new SourceAuthenticationError('SOURCE_READ_FAILED',
      `Could not read an authenticated source file (${error.code ?? error.name})`);
  } finally {
    if (handle) await handle.close();
  }
}

/**
 * All trust inputs are caller supplied. No key, current hash, status, evidence,
 * or interpretation authority is obtained from a submitted source catalog.
 * Authentication is all-or-nothing; no partial catalog is returned on error.
 */
export async function authenticateSourceCatalog({
  catalogBytes, signatureBytes, expectedManifestSha256, trustedIssuerId,
  trustedPublicKeyPem, sourceRoot,
}) {
  requireCondition(catalogBytes instanceof Uint8Array && signatureBytes instanceof Uint8Array,
    'BAD_AUTH_INPUT', 'Catalog and signature inputs must be byte arrays');
  const bytes = Buffer.from(catalogBytes);
  const signature = Buffer.from(signatureBytes);
  requireCondition(typeof expectedManifestSha256 === 'string' && HEX_SHA256.test(expectedManifestSha256),
    'BAD_TRUST_PIN', 'An exact current lowercase manifest SHA256 pin is required');
  requireCondition(typeof trustedIssuerId === 'string'
    && /^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$/.test(trustedIssuerId),
  'BAD_TRUSTED_ISSUER', 'A separately configured issuer ID is required');
  const manifestHash = sha256(bytes);
  requireCondition(manifestHash === expectedManifestSha256,
    'MANIFEST_PIN_MISMATCH', 'Catalog does not match the separately configured current manifest hash');
  const catalog = parseCatalog(bytes);
  requireCondition(catalog.issuerId === trustedIssuerId,
    'UNTRUSTED_ISSUER', 'Catalog issuer does not match the separately configured issuer');
  const publicKey = publicKeyFromPin(trustedPublicKeyPem);
  requireCondition(signature.length === 64,
    'BAD_SIGNATURE_LENGTH', 'An Ed25519 signature must contain exactly 64 bytes');
  requireCondition(verify(null, bytes, publicKey, signature),
    'SIGNATURE_INVALID', 'Catalog signature does not verify under the configured issuer key');
  requireCondition(typeof sourceRoot === 'string' && sourceRoot.length > 0,
    'BAD_SOURCE_ROOT', 'A separately configured source root is required');
  let root;
  try {
    root = await realpath(sourceRoot);
    requireCondition((await lstat(root)).isDirectory(), 'BAD_SOURCE_ROOT', 'Source root must be a directory');
  } catch (error) {
    if (error instanceof SourceAuthenticationError) throw error;
    throw new SourceAuthenticationError('BAD_SOURCE_ROOT', 'Configured source root is unavailable');
  }
  const sources = [];
  for (const source of catalog.sources) sources.push(await authenticateSource(root, source));
  return Object.freeze({
    schema: 'ida-authenticated-sources-v1',
    issuer_id: catalog.issuerId,
    catalog_version: catalog.catalogVersion,
    manifest_sha256: manifestHash,
    issuer_public_key_sha256: sha256(publicKey.export({ format: 'der', type: 'spki' })),
    signature_algorithm: 'Ed25519',
    source_ref_schema: 'Usul.IDA.Judgment.SourceRef/v1',
    authenticated_sources: Object.freeze(sources),
  });
}

async function main(args) {
  const names = ['manifest', 'signature', 'trusted-key', 'trusted-issuer',
    'expected-manifest-sha256', 'source-root'];
  const options = new Map();
  requireCondition(args.length === 2 * names.length, 'BAD_ARGUMENTS',
    `Required arguments: ${names.map(name => `--${name} VALUE`).join(' ')}`);
  for (let index = 0; index < args.length; index += 2) {
    const name = args[index].slice(2);
    requireCondition(args[index].startsWith('--') && names.includes(name)
      && !options.has(name) && args[index + 1].length > 0,
    'BAD_ARGUMENTS', 'Unknown, duplicate, or empty command-line argument');
    options.set(name, args[index + 1]);
  }
  const result = await authenticateSourceCatalog({
    catalogBytes: await readFile(options.get('manifest')),
    signatureBytes: await readFile(options.get('signature')),
    trustedPublicKeyPem: await readFile(options.get('trusted-key'), 'utf8'),
    trustedIssuerId: options.get('trusted-issuer'),
    expectedManifestSha256: options.get('expected-manifest-sha256'),
    sourceRoot: options.get('source-root'),
  });
  process.stdout.write(`${JSON.stringify(result)}\n`);
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main(process.argv.slice(2)).catch(error => {
    process.stderr.write(`${error.code ?? 'SOURCE_AUTH_FAILED'}: ${error.message}\n`);
    process.exitCode = 1;
  });
}
