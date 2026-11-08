"""Inventory sources loaded by the pinned Quint compiler for IDA receipts.

The compiler sourceCode Map records recursively loaded source paths. Verification
requires exact declared closures and rejects unlisted or symlinked project files.
The caller fingerprints this helper and every approved source in its receipt.
"""
import json
import os
from pathlib import Path
import subprocess


INVENTORY_JS = r'''
const path = require("node:path");
const compilerPath = process.argv[1];
const entries = JSON.parse(process.argv[2]);
const cli = require(compilerPath);
const pkg = require(path.resolve(path.dirname(compilerPath), "../../package.json"));
function requireThat(ok, message) { if (!ok) throw Error(message); }
function stageOrThrow(result, phase) {
  requireThat(result && typeof result.isLeft === "function", "Unexpected Quint Either API");
  if (result.isLeft()) throw Error(`Quint ${phase} failed: ${result.value.msg}`);
  return result.value;
}
(async () => {
  requireThat(pkg.version === "0.33.1", "Unexpected Quint compiler version");
  requireThat(Array.isArray(entries) && entries.length > 0, "Missing Quint entrypoints");
  const inventories = [];
  for (const entry of entries) {
    requireThat(typeof entry === "string" && path.isAbsolute(entry), "Entrypoint must be absolute");
    const loaded = stageOrThrow(await cli.load({ input: entry }), "load");
    const parsed = stageOrThrow(await cli.parse(loaded), "parse");
    requireThat(parsed.stage === "parsing", "Unexpected Quint parse stage");
    for (const field of ["errors", "warnings"]) {
      requireThat(Array.isArray(parsed[field]) && parsed[field].length === 0,
                  `Quint parser reported ${field}`);
    }
    requireThat(parsed.sourceCode instanceof Map && parsed.sourceCode.size > 0,
                "Quint compiler did not return a source inventory");
    requireThat(parsed.sourceCode.has(entry), "Quint inventory omits its entrypoint");
    for (const [source, contents] of parsed.sourceCode) {
      requireThat(typeof source === "string" && path.isAbsolute(source)
                  && typeof contents === "string", "Malformed Quint source inventory");
    }
    inventories.push({entry, sources: [...parsed.sourceCode.keys()].sort()});
  }
  process.stdout.write(JSON.stringify({schema: "quint.sources.v1", version: pkg.version, inventories}));
})().catch(error => { process.stderr.write(`${error.message}\n`); process.exitCode = 1; });
'''


class ClosureError(ValueError):
    pass


def _require(ok, message):
    if not ok:
        raise ClosureError(message)


def _absolute(path):
    # Lexical normalization keeps an unlisted symlink alias distinguishable.
    return Path(os.path.abspath(path))


def compiler_source_inventory(compiler, entrypoints):
    entries = [_absolute(p) for p in entrypoints]
    result = subprocess.run(
        ['node', '-e', INVENTORY_JS, str(_absolute(compiler)), json.dumps(list(map(str, entries)))],
        text=True, capture_output=True, timeout=60,
    )
    _require(result.returncode == 0, f'Quint inventory failed: {result.stderr.strip()}')
    _require(not result.stderr.strip(), f'Unexpected Quint inventory diagnostics: {result.stderr}')
    payload = json.loads(result.stdout)
    _require(isinstance(payload, dict) and set(payload) == {'schema', 'version', 'inventories'}
             and payload['schema'] == 'quint.sources.v1' and payload['version'] == '0.33.1',
             'Unexpected Quint inventory schema')
    inventories = payload['inventories']
    _require(isinstance(inventories, list) and len(inventories) == len(entries),
             'Incomplete Quint entrypoint inventory')
    for item, entry in zip(inventories, entries):
        _require(isinstance(item, dict) and set(item) == {'entry', 'sources'}
                 and item['entry'] == str(entry), 'Unexpected Quint entrypoint')
        sources = item['sources']
        _require(isinstance(sources, list) and sources
                 and all(isinstance(p, str) for p in sources)
                 and sources == sorted(set(sources)) and str(entry) in sources,
                 'Malformed Quint dependency inventory')
    return inventories


def verify_quint_closure(compiler, entrypoints, allowed_sources):
    """Require every compiler-resolved source to be an approved, hash-covered file.

    The caller should construct allowed_sources from its receipt INPUTS and
    include this helper in INPUTS if it is installed as a separate source file.
    Extra approved inputs are permitted; executed inputs outside the set fail.
    """
    approved = {_absolute(p) for p in allowed_sources}
    entries = [_absolute(p) for p in entrypoints]
    _require(set(entries) <= approved, 'Unapproved Quint entrypoint')
    inventories = compiler_source_inventory(compiler, entries)
    for inventory in inventories:
        for name in inventory['sources']:
            candidate = Path(name)
            _require(candidate.is_absolute() and candidate == _absolute(candidate),
                     f'Noncanonical Quint source: {name}')
            _require(candidate in approved, f'Unexpected Quint source: {name}')
            _require(candidate.resolve(strict=True) == candidate,
                     f'Symlinked Quint source: {name}')
    return inventories


def verify_exact_quint_closure(compiler, expected_closures, hashed_sources):
    """Exact per-entrypoint closure, additionally constrained to hashed sources."""
    expected = {_absolute(entry): {_absolute(p) for p in paths}
                for entry, paths in expected_closures.items()}
    inventories = verify_quint_closure(compiler, expected, hashed_sources)
    for item in inventories:
        required = expected[Path(item['entry'])]
        observed = {Path(p) for p in item['sources']}
        _require(observed == required,
                 f'Quint closure differs for {item["entry"]}: '
                 f'missing={sorted(map(str, required - observed))}, '
                 f'unexpected={sorted(map(str, observed - required))}')
    return inventories
