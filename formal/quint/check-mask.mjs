#!/usr/bin/env node
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";
import { mkdirSync, mkdtempSync, readFileSync, renameSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, "../..");
const lean = join(root, "formal/lean");
const cli = join(here, "node_modules/@informalsystems/quint/dist/src/cli.js");
const out = join(root, ".cache/agency-mask");
const rowsPerConfig = 256 * 13;
const sha256 = bytes => createHash("sha256").update(bytes).digest("hex");
const read = path => JSON.parse(readFileSync(path, "utf8"));
const command = (cwd, file, args) => execFileSync(file, args, {
  cwd, encoding: "utf8", timeout: 120000, maxBuffer: 16 * 1024 * 1024,
  stdio: ["ignore", "pipe", "pipe"],
});
const quint = (...args) => command(here, process.execPath, [cli, ...args]);
const lake = (...args) => command(lean, "lake", args);
const fingerprint = () => [
  "formal/lean/lean-toolchain",
  "formal/lean/Usul/Agency.lean",
  "formal/lean/Usul/AgencyMask.lean",
  "formal/lean/UsulTest/AgencyMask.lean",
  "formal/lean/scripts/ExportAgency.lean",
  "formal/lean/scripts/ExportAgencyMask.lean",
  "formal/quint/agency.qnt",
  "formal/quint/agencyMask.qnt",
  "formal/quint/maskTable.qnt",
  "formal/quint/check-mask.mjs",
  "formal/quint/package-lock.json",
  "formal/check-agency-sources.mjs",
  "docs/research/agency-source-profile.md",
  "docs/research/agency-asymmetric-candidate.md",
  "corpus/registry.json",
  "corpus/lock.json",
].map(path => ({ path, sha256: sha256(readFileSync(join(root, path))) }));

function readLeanTable(csv, configs) {
  const lines = csv.trim().split(/\r?\n/);
  assert.equal(lines.shift(), "config,state,event,next");
  assert.equal(lines.length, configs * rowsPerConfig);
  return lines.map((line, offset) => {
    assert.match(line, /^\d+,\d+,\d+,-?\d+$/);
    const [config, state, event, next] = line.split(",").map(Number);
    assert.equal(config, Math.floor(offset / rowsPerConfig));
    assert.equal(state, Math.floor(offset / 13) % 256);
    assert.equal(event, offset % 13);
    assert.ok(Number.isInteger(next) && next >= -1 && next < 256);
    return next;
  });
}

mkdirSync(out, { recursive: true });
const receipt = join(out, "report.json");
rmSync(receipt, { force: true });
const work = mkdtempSync(join(tmpdir(), "usul-agency-mask-"));
try {
  const revision = command(root, "git", ["rev-parse", "HEAD"]).trim();
  const sources = fingerprint();
  process.stdout.write(command(root, process.execPath, ["formal/check-agency-sources.mjs"]));
  const quintVersion = quint("--version").trim();
  assert.equal(quintVersion, "0.33.1");
  const leanVersion = lake("env", "lean", "--version").trim();
  const pin = readFileSync(join(lean, "lean-toolchain"), "utf8").trim();
  const version = /^leanprover\/lean4:v([^\s]+)$/.exec(pin)?.[1];
  assert.ok(version && leanVersion.startsWith(`Lean (version ${version},`));

  lake("build", "UsulTest.AgencyMask");
  quint("typecheck", "agencyMask.qnt");
  quint("typecheck", "maskTable.qnt");
  const testsPath = join(work, "tests.json");
  quint("test", "agencyMask.qnt", "--backend", "typescript", "--max-samples", "1", "--out", testsPath);
  const tests = read(testsPath);
  assert.equal(tests.stage, "testing");
  assert.deepEqual(tests.failed, []);
  for (const name of ["singletonGrantsTest", "withdrawalTest", "knowledgeTest"]) {
    assert.ok(tests.passed.includes(name), `Missing mask scenario test ${name}`);
  }
  const maskSource = readFileSync(join(here, "agencyMask.qnt"), "utf8");
  const selector = "| ExecuteB => mask / 2 == 1";
  assert.equal(maskSource.split(selector).length, 2, "Expected one B solo selector");
  writeFileSync(join(work, "agency.qnt"), readFileSync(join(here, "agency.qnt")));
  writeFileSync(join(work, "agencyMask.qnt"), maskSource.replace(selector, "| ExecuteB => mask % 2 == 1"));
  const mutant = (...args) => command(work, process.execPath, [cli, ...args]);
  mutant("typecheck", "agencyMask.qnt");
  assert.throws(() => mutant("test", "agencyMask.qnt", "--backend", "typescript",
    "--max-samples", "1", "--match", "^singletonGrantsTest$", "--verbosity", "2"), error =>
    error.status === 1 && error.stdout.includes("singletonGrantsTest failed after 1 test(s)")
      && error.stdout.includes("Error [QNT508]: Assertion failed"));

  const tracePath = join(work, "table.itf.json");
  quint("run", "maskTable.qnt", "--backend", "typescript", "--max-samples", "1",
    "--max-steps", "0", "--verbosity", "0", "--out-itf", tracePath);
  const trace = read(tracePath);
  assert.deepEqual(trace.vars, ["transitions"]);
  assert.equal(trace.states.length, 1);
  const quintTable = trace.states[0].transitions;
  const csv = lake("env", "lean", "--run", "scripts/ExportAgencyMask.lean");
  const leanTable = readLeanTable(csv, 8);
  assert.equal(quintTable.length, leanTable.length);
  leanTable.forEach((next, i) => assert.deepEqual(quintTable[i], { "#bigint": String(next) },
    `Parity mismatch at offset ${i}`));

  const original = readLeanTable(lake("env", "lean", "--run", "scripts/ExportAgency.lean"), 4);
  const symmetricCodes = [0, 3, 4, 7];
  original.forEach((next, i) => {
    const config = symmetricCodes[Math.floor(i / rowsPerConfig)];
    assert.equal(leanTable[config * rowsPerConfig + i % rowsPerConfig], next,
      `Symmetric projection mismatch at offset ${i}`);
  });
  assert.equal(command(root, "git", ["rev-parse", "HEAD"]).trim(), revision);
  assert.deepEqual(fingerprint(), sources, "Inputs changed during mask replay");
  const vector = JSON.stringify({ vars: trace.vars, states: trace.states }) + "\n";
  const outputs = { "lean-transitions.csv": csv, "quint-transitions.json": vector };
  for (const [name, content] of Object.entries(outputs)) writeFileSync(join(out, name), content);
  const staged = join(out, `report.${process.pid}.json`);
  writeFileSync(staged, JSON.stringify({
    schema: "usul.agency.mask.v1", interpretation: "candidate", revision, sources,
    toolchain: { lean: leanVersion, quint: quintVersion },
    comparedRows: leanTable.length, symmetricProjectionRows: original.length,
    passedQuintTests: tests.passed,
    negativeControl: "B reading A's grant bit rejected by singletonGrantsTest",
    outputs: Object.fromEntries(Object.entries(outputs).map(([name, content]) => [name, sha256(content)])),
  }, null, 2) + "\n");
  renameSync(staged, receipt);
  console.log(`Agency mask: ${leanTable.length} parity rows and ${original.length} symmetric projection rows passed. Grant-bit mutant rejected.`);
} finally {
  rmSync(work, { recursive: true, force: true });
}
