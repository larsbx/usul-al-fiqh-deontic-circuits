#!/usr/bin/env node
// Audit every named theorem in the two pilot modules using the pinned Lean toolchain.
// The parser requires one recognized result per theorem and rejects all other output.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const receiptPath = resolve(root, '.cache/agency/axioms-verification.json');
rmSync(receiptPath, { force: true });
const leanRoot = resolve(root, 'formal/lean');
const allowed = new Set(['propext', 'Classical.choice', 'Quot.sound']);
const modules = ['Usul.Agency', 'UsulTest.Agency'].map(name => {
  const path = `formal/lean/${name.replaceAll('.', '/')}.lean`;
  const source = readFileSync(resolve(root, path), 'utf8');
  // Unsupported names/modifiers cause the generated Lean commands or parser to fail;
  // declarations are never silently omitted because their name is inconvenient.
  const declarations = [...source.matchAll(
    /^[ \t]*(?:@\[[^\]]*\][ \t]*)*(?:(?:private|protected|noncomputable)[ \t]+)*(?:theorem|lemma)\s+([^\s(:]+)/gm,
  )];
  assert.ok(declarations.length > 0, `No theorem declarations found in ${path}`);
  const names = declarations.map(match => {
    assert.match(match[1], /^[A-Za-z_][A-Za-z0-9_']*$/, `Unsupported theorem name in ${path}`);
    return `${name}.${match[1]}`;
  });
  return { name, path, source_sha256: createHash('sha256').update(source).digest('hex'), names };
});
const names = modules.flatMap(module => module.names);
assert.equal(new Set(names).size, names.length, 'Duplicate theorem declarations');

function lake(args) {
  const result = spawnSync('lake', args, {
    cwd: leanRoot, encoding: 'utf8', timeout: 120000, maxBuffer: 8 * 1024 * 1024,
  });
  if (result.error) throw result.error;
  assert.equal(result.status, 0,
    `lake ${args.join(' ')} failed:\n${result.stdout}\n${result.stderr}`);
  return result;
}

function parseAudit(output, expectedNames) {
  const expected = new Set(expectedNames);
  const found = new Map();
  for (const line of output.split(/\r?\n/).filter(line => line.trim() !== '')) {
    const empty = /^'([^']+)' does not depend on any axioms$/.exec(line);
    const dependent = /^'([^']+)' depends on axioms: \[([^\]]*)\]$/.exec(line);
    assert.ok(empty || dependent, `Unrecognized Lean axioms output: ${line}`);
    const name = (empty || dependent)[1];
    assert.ok(expected.has(name), `Unexpected theorem in axioms output: ${name}`);
    assert.ok(!found.has(name), `Duplicate theorem in axioms output: ${name}`);
    const axioms = empty ? [] : dependent[2].split(',').map(axiom => axiom.trim());
    for (const axiom of axioms) {
      assert.ok(allowed.has(axiom), `Unexpected axiom for ${name}: ${axiom}`);
    }
    assert.equal(new Set(axioms).size, axioms.length, `Duplicate axioms for ${name}`);
    found.set(name, axioms);
  }
  const missing = expectedNames.filter(name => !found.has(name));
  assert.deepEqual(missing, [], `Missing theorem results: ${missing.join(', ')}`);
  return expectedNames.map(name => ({ name, axioms: found.get(name) }));
}

// These controls make a weakened or permissive output parser fail the gate itself.
const probe = ['Usul.Agency.auditProbe'];
assert.throws(() => parseAudit(`'${probe[0]}' depends on axioms: [sorryAx]\n`, probe),
  /Unexpected axiom/);
assert.throws(() => parseAudit(`'${probe[0]}' depends on axioms: [Agency.customAxiom]\n`, probe),
  /Unexpected axiom/);
assert.throws(() => parseAudit('', probe), /Missing theorem/);
assert.throws(() => parseAudit('warning: unknown output\n', probe), /Unrecognized Lean/);
assert.throws(() => parseAudit(
  `'${probe[0]}' does not depend on any axioms\n'${probe[0]}' does not depend on any axioms\n`,
  probe), /Duplicate theorem/);

const toolchain = readFileSync(resolve(leanRoot, 'lean-toolchain'), 'utf8').trim();
const pinnedVersion = /^leanprover\/lean4:v([^\s]+)$/.exec(toolchain)?.[1];
assert.ok(pinnedVersion, `Unsupported Lean toolchain pin: ${toolchain}`);
const versionResult = lake(['env', 'lean', '--version']);
assert.equal(versionResult.stderr.trim(), '', 'Unexpected Lean version stderr');
const version = versionResult.stdout.trim();
assert.ok(version.startsWith(`Lean (version ${pinnedVersion},`),
  `Lean version does not match ${toolchain}: ${version}`);

// Build from the current sources before importing their declarations for the audit.
lake(['build', ...modules.map(module => module.name)]);
const outputDir = resolve(root, '.cache/agency');
mkdirSync(outputDir, { recursive: true });
const auditPath = resolve(outputDir, 'PrintAgencyAxioms.lean');
writeFileSync(auditPath, [
  ...modules.map(module => `import ${module.name}`),
  ...names.map(name => `#print axioms ${name}`),
  '',
].join('\n'));
const audit = lake(['env', 'lean', auditPath]);
assert.equal(audit.stderr.trim(), '', `Unexpected axioms audit stderr: ${audit.stderr}`);
const theorems = parseAudit(audit.stdout, names);
const observed = [...new Set(theorems.flatMap(theorem => theorem.axioms))].sort();
const receipt = {
  schema: 'usul.agency.axioms-check.v1',
  status: 'all_named_theorems_audited',
  toolchain, lean_version: version,
  allowed_axioms: [...allowed].sort(), observed_axioms: observed,
  theorem_count: theorems.length,
  modules: modules.map(({ name, path, source_sha256, names }) =>
    ({ name, path, source_sha256, theorem_count: names.length })),
  negative_controls: ['sorryAx', 'custom_axiom', 'missing_result', 'unknown_output', 'duplicate_result'],
  theorems,
};
writeFileSync(receiptPath, JSON.stringify(receipt, null, 2) + '\n');
console.log(`Agency axioms audit: ${theorems.length} theorems ` +
  `(${modules.map(module => `${module.names.length} ${module.name}`).join(', ')}); ` +
  `observed axioms: ${observed.join(', ') || 'none'}.`);
