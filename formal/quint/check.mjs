#!/usr/bin/env node
// The transition implementations live in Lean and Quint. This harness only
// decodes their exports, compares them, and checks separately declared cases
// and safety requirements; it does not implement a third transition function.
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { copyFileSync, mkdirSync, mkdtempSync, readFileSync, renameSync, rmSync, writeFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "../..");
const leanDir = path.resolve(here, "../lean");
const cli = path.join(here, "node_modules/@informalsystems/quint/dist/src/cli.js");
const configs = 4;
const states = 256;
const events = [
  "appoint", "revoke", "notifyA", "notifyB", "withdrawA", "withdrawB",
  "executeA", "executeB", "executeJoint", "stutter",
  "executeAOutsideScope", "executeBOutsideScope", "executeJointOutsideScope",
];
const rowCount = configs * states * events.length;
const seed = "20261106";
const temporary = mkdtempSync(path.join(here, ".check-"));
const receipts = path.join(here, ".out");

function digest(bytes) {
  return createHash("sha256").update(bytes).digest("hex");
}

function fingerprintInputs() {
  // Relative paths and content hashes make the receipt independent of checkout
  // location. Rechecking before publication detects edits during a running gate.
  return [
    "formal/lean/Usul/Agency.lean",
    "formal/lean/scripts/ExportAgency.lean",
    "formal/lean/lean-toolchain",
    "formal/quint/agency.qnt",
    "formal/quint/table.qnt",
    "formal/quint/check.mjs",
    "formal/quint/scenarios.json",
    "formal/quint/package.json",
    "formal/quint/package-lock.json",
    "docs/research/agency-source-profile.md",
    "corpus/registry.json",
    "corpus/lock.json",
  ].map(filename => {
    const bytes = readFileSync(path.join(root, filename));
    return { path: filename, bytes: bytes.length, sha256: digest(bytes) };
  });
}

function command(program, args, { cwd = temporary, allowFailure = false } = {}) {
  const result = spawnSync(program, args, {
    cwd, encoding: "utf8", maxBuffer: 16 * 1024 * 1024,
    timeout: 120000,
    env: { ...process.env, NO_COLOR: "1" },
  });
  if (result.error) throw result.error;
  if (result.signal) throw new Error(`${program} terminated by ${result.signal}`);
  if (result.status !== 0 && !allowFailure) {
    throw new Error(`${program} ${args.join(" ")} failed (${result.status})\n${result.stdout}\n${result.stderr}`);
  }
  return result;
}

function quint(args, options) {
  return command(process.execPath, [cli, ...args], options);
}

function log(message) {
  console.log(`[agency] ${message}`);
}

function readJSON(filename) {
  return JSON.parse(readFileSync(filename, "utf8"));
}

function test(file, names, cwd = temporary, match) {
  const output = path.join(cwd, `${path.basename(file, ".qnt")}-tests.json`);
  const args = ["test", file, "--backend", "typescript", "--max-samples", "1",
    "--seed", seed];
  if (match) args.push("--match", match, "--verbosity", "2");
  else args.push("--out", output);
  const result = quint(args, { cwd, allowFailure: Boolean(match) });
  if (match) {
    assert.notEqual(result.status, 0, `Mutant unexpectedly passed ${match}`);
    // Quint 0.33.1's --out JSON drops individual test errors. Inspect the
    // pinned CLI diagnostic so a runtime error cannot count as mutation kill.
    const diagnostics = [...result.stdout.matchAll(/Error \[(QNT\d+)\]: ([^\n]*)/g)];
    assert.equal(diagnostics.length, 1, `Expected one assertion failure: ${result.stdout}\n${result.stderr}`);
    assert.equal(diagnostics[0][1], "QNT508");
    assert.equal(diagnostics[0][2].trim(), "Assertion failed");
    assert.ok(result.stdout.includes(`1) ${names[0]} failed after 1 test(s)`));
    return;
  }
  const report = readJSON(output);
  assert.equal(report.stage, "testing", "A parser/runtime startup failure is not a test result");
  assert.deepEqual(report.failed, []);
  assert.deepEqual(new Set(report.passed), new Set(names), "No required test may be omitted");
  return report;
}

function validateFixtures(fixture) {
  assert.equal(fixture.schema, "agency-scenarios-v1");
  assert.ok(fixture.scenarios.length > 0);
  const names = new Set();
  for (const scenario of fixture.scenarios) {
    assert.match(scenario.name, /^[A-Za-z][A-Za-z0-9]*$/);
    assert.ok(!names.has(scenario.name), `Duplicate scenario ${scenario.name}`);
    names.add(scenario.name);
    assert.ok(Number.isInteger(scenario.config) && scenario.config >= 0 && scenario.config < configs);
    assert.ok(scenario.claim.length > 0);
    assert.ok(scenario.events.length > 0);
    assert.equal(scenario.events.length, scenario.expected.length);
    scenario.events.forEach(event => assert.ok(events.includes(event), `Unknown event ${event}`));
    scenario.expected.forEach(value => assert.ok(Number.isInteger(value) && value >= -1 && value < states));
  }
}

function fixtureModule(scenarios) {
  const tests = scenarios.map(scenario => {
    const eventCodes = scenario.events.map(event => events.indexOf(event));
    return `  run ${scenario.name}Test = assert(outcomes(${scenario.config}, List(${eventCodes.join(", ")})) == List(${scenario.expected.join(", ")}))`;
  });
  return `// Generated only from the manually declared scenarios.json.\nmodule scenarios {\n  import agency.outcomes from "./agency"\n\n${tests.join("\n")}\n}\n`;
}

function index(config, state, event) {
  return (config * states + state) * events.length + event;
}

function readLeanTable(csv) {
  const lines = csv.trim().split(/\r?\n/);
  assert.equal(lines.shift(), "config,state,event,next", "Lean exporter header changed");
  assert.equal(lines.length, rowCount, "Lean export must cover the complete declared domain");
  return lines.map((line, offset) => {
    assert.match(line, /^\d+,\d+,\d+,-?\d+$/);
    const [config, state, event, next] = line.split(",").map(Number);
    assert.equal(config, Math.floor(offset / (states * events.length)));
    assert.equal(state, Math.floor(offset / events.length) % states);
    assert.equal(event, offset % events.length);
    assert.ok(next >= -1 && next < states);
    return next;
  });
}

function readQuintTable(filename) {
  const trace = readJSON(filename);
  assert.deepEqual(trace.vars, ["transitions"]);
  assert.equal(trace.states.length, 1, "Export must be exactly one deterministic initial state");
  const table = trace.states[0].transitions;
  assert.equal(table.length, rowCount, "Quint export must evaluate every declared input");
  return table.map(value => {
    assert.deepEqual(Object.keys(value), ["#bigint"]);
    assert.match(value["#bigint"], /^-?\d+$/);
    const number = Number(value["#bigint"]);
    assert.ok(Number.isSafeInteger(number) && number >= -1 && number < states);
    return number;
  });
}

function compareTables(lean, quintTable) {
  for (let offset = 0; offset < rowCount; offset++) {
    const config = Math.floor(offset / (states * events.length));
    const state = Math.floor(offset / events.length) % states;
    const event = offset % events.length;
    assert.equal(quintTable[offset], lean[offset],
      `Parity mismatch: config=${config}, state=${state}, event=${events[event]}`);
  }
}

function checkScenarios(table, scenarios, implementation) {
  for (const scenario of scenarios) {
    let state = 0;
    scenario.events.forEach((event, position) => {
      const next = table[index(scenario.config, state, events.indexOf(event))];
      assert.equal(next, scenario.expected[position],
        `${implementation} scenario ${scenario.name}, attempt ${position + 1}: ${event}`);
      if (next !== -1) state = next;
    });
  }
}

function decode(code) {
  return {
    appointed: Boolean(code & 1), revoked: Boolean(code & 2),
    knownA: Boolean(code & 4), knownB: Boolean(code & 8),
    withdrawnA: Boolean(code & 16), withdrawnB: Boolean(code & 32),
    accepted: Math.floor(code / 64),
  };
}

// These requirements check every reachable edge of the exported graph. They
// deliberately do not encode the transition cases or compute an expected next
// state. In particular, historical acceptance is checked against the PRE-state.
function checkReachableGraph(table) {
  const counts = [];
  for (let config = 0; config < configs; config++) {
    const visited = new Set([0]);
    const queue = [0];
    let enabled = 0;
    for (let position = 0; position < queue.length; position++) {
      const state = queue[position];
      const before = decode(state);
      assert.ok(!before.revoked || before.appointed);
      assert.ok(!before.knownA || before.revoked);
      assert.ok(!before.knownB || before.revoked);
      assert.ok(!before.withdrawnA || before.appointed);
      assert.ok(!before.withdrawnB || before.appointed);
      assert.ok(before.accepted === 0 || before.appointed);
      for (let event = 0; event < events.length; event++) {
        const next = table[index(config, state, event)];
        if (next === -1) continue;
        enabled++;
        assert.ok(event < 10, "No out-of-scope execution may be enabled");
        const after = decode(next);
        assert.equal((state & 63) & (next & 63), state & 63, "Lifecycle flags are monotone");
        if (before.accepted !== 0) {
          assert.ok(event < 6 || event > 8,
            "No execution event may be enabled after acceptance, even if it preserves the same receipt");
          assert.equal(after.accepted, before.accepted, "Later events must preserve execution history");
        }
        if (after.accepted !== before.accepted) {
          assert.equal(before.accepted, 0, "At most one modeled execution");
          assert.ok(event >= 6 && event <= 8, "Only scoped execution may create acceptance");
          assert.equal(after.accepted, event - 5, "Acceptance must name its actual participants");
          assert.ok(before.appointed, "Acceptance requires appointment");
          assert.ok(after.accepted === 3 || config % 2 === 1, "A solo execution requires independent permission");
          if (after.accepted === 1 || after.accepted === 3) {
            assert.ok(!before.withdrawnA, "A withdrawn agent A cannot execute");
            assert.ok(config < 2 ? !before.revoked : !before.knownA,
              "Agent A must retain authority at the moment of execution");
          }
          if (after.accepted === 2 || after.accepted === 3) {
            assert.ok(!before.withdrawnB, "A withdrawn agent B cannot execute");
            assert.ok(config < 2 ? !before.revoked : !before.knownB,
              "Agent B must retain authority at the moment of execution");
          }
        }
        if (!visited.has(next)) {
          visited.add(next);
          queue.push(next);
        }
      }
    }
    counts.push({ config, states: visited.size, enabledEdges: enabled });
  }
  return counts;
}

function replaceOnce(source, needle, replacement) {
  const position = source.indexOf(needle);
  assert.ok(position >= 0 && source.indexOf(needle, position + needle.length) === -1,
    `Mutation site must occur exactly once: ${needle}`);
  return source.slice(0, position) + replacement + source.slice(position + needle.length);
}

function checkMutants(source, scenarioText) {
  const mutants = [
    {
      name: "drop-joint-requirement",
      needle: "cfg.independent and canAct(cfg, s, agent)",
      replacement: "canAct(cfg, s, agent)",
      test: "jointSoloARejectedTest",
    },
    {
      name: "revocation-confused-with-knowledge",
      needle: "| Immediate => not(s.revoked)",
      replacement: "| Immediate => not(known)",
      test: "immediateRevocationBeforeNoticeTest",
    },
    {
      name: "knowledge-confused-with-revocation",
      needle: "| OnKnowledge => not(known)",
      replacement: "| OnKnowledge => not(s.revoked)",
      test: "knowledgeJointBeforeNoticeTest",
    },
  ];
  for (const mutant of mutants) {
    const directory = path.join(temporary, mutant.name);
    mkdirSync(directory);
    writeFileSync(path.join(directory, "agency.qnt"), replaceOnce(source, mutant.needle, mutant.replacement));
    writeFileSync(path.join(directory, "scenarios.qnt"), scenarioText);
    // A parse/type failure cannot masquerade as detecting the intended bug.
    quint(["typecheck", "agency.qnt"], { cwd: directory });
    test("scenarios.qnt", [mutant.test], directory, `^${mutant.test}$`);
    log(`negative control rejected: ${mutant.name} (${mutant.test})`);
  }
  return mutants.map(mutant => ({
    name: mutant.name,
    test: mutant.test,
    replacedClause: mutant.needle,
    faultyClause: mutant.replacement,
    typecheckPassed: true,
    rejectedWith: "QNT508: Assertion failed",
  }));
}

function asCSV(table) {
  return "config,state,event,next\n" + table.map((next, offset) => {
    const config = Math.floor(offset / (states * events.length));
    const state = Math.floor(offset / events.length) % states;
    const event = offset % events.length;
    return `${config},${state},${event},${next}\n`;
  }).join("");
}

function writeReceipts({ inputs, leanVersion, fixture, unitReport, scenarioReport,
  leanCSV, quintOutput, quintTable, counts, mutants }) {
  assert.deepEqual(fingerprintInputs(), inputs, "An input changed during the check; rerun before publishing a receipt");
  const staged = path.join(temporary, "receipts");
  mkdirSync(staged);
  const trace = readJSON(quintOutput);
  // Retain the actual evaluated state, while dropping only volatile tool
  // timestamps/description. This keeps artifact hashes reproducible.
  const normalizedTrace = {
    "#meta": {
      format: "ITF",
      "format-description": "https://apalache-mc.org/docs/adr/015adr-trace.html",
      source: "table.qnt",
      status: "ok",
      description: "Complete deterministic transition vector; volatile CLI timestamps omitted",
    },
    vars: trace.vars,
    states: trace.states,
  };
  const contents = [
    ["lean-transitions.csv", leanCSV],
    ["quint-transitions.csv", asCSV(quintTable)],
    ["quint-transitions.itf.json", JSON.stringify(normalizedTrace, null, 2) + "\n"],
  ];
  const artifacts = contents.map(([filename, content]) => {
    const bytes = Buffer.from(content, "utf8");
    writeFileSync(path.join(staged, filename), bytes);
    return { path: filename, bytes: bytes.length, sha256: digest(bytes) };
  });
  const report = {
    schema: "usul.agency.quint-check.v1",
    status: "passed",
    interpretationStatus: "candidate",
    tools: { node: process.version, quint: "0.33.1", quintBackend: "typescript", lean: leanVersion },
    inputs,
    checks: {
      typecheck: { passed: true, files: ["agency.qnt", "table.qnt"] },
      deterministicUnitTests: { passed: unitReport.passed, count: unitReport.passed.length },
      declaredScenarios: {
        count: scenarioReport.passed.length,
        attempts: fixture.scenarios.reduce((total, scenario) => total + scenario.events.length, 0),
        passed: scenarioReport.passed,
        implementations: ["Lean", "Quint"],
        rejectedAttemptConvention: "record -1 and retain last accepted state for the next attempted event",
      },
      exhaustiveOneStepParity: {
        comparedInputs: rowCount,
        configs,
        rawStates: states,
        events: events.map((name, code) => ({ code, name })),
        disabledResult: -1,
        ordering: ["config", "state", "event"],
        allEqual: true,
        leanBuild: "lake build Usul.Agency",
        leanExport: "lake env lean --run scripts/ExportAgency.lean",
        quintExport: "quint run table.qnt --backend typescript --max-samples 1 --max-steps 0 --out-itf table.itf.json",
      },
      exhaustiveReachableGraph: {
        configurations: counts,
        statePairs: counts.reduce((total, count) => total + count.states, 0),
        enabledEdges: counts.reduce((total, count) => total + count.enabledEdges, 0),
        includesStutteringEdges: true,
        requirements: ["lifecycle coherence", "monotone lifecycle flags", "receipt persistence",
          "no execution after acceptance", "scope preservation", "joint requirement",
          "participant identity", "authority in the execution pre-state"],
      },
      negativeControls: mutants,
      sampledActionWrapper: {
        passed: true, runs: 100, maxStepsPerRun: 20, seed,
        invariant: "safety", exhaustive: false,
      },
    },
    artifacts,
    artifactNormalization: "ITF states are unchanged; volatile top-level CLI timestamp and description are replaced",
    separateRequiredGates: {
      command: "make agency",
      sourceVerification: ".cache/agency/source-verification.json",
      leanAxiomAudit: "See the separate Lean axiom-audit receipt from make agency",
      interpretationReview: "Source interpretation and scholarly acceptance are not established by executable agreement",
    },
  };
  writeFileSync(path.join(staged, "report.json"), JSON.stringify(report, null, 2) + "\n");
  // Nothing appears under .out until every required model check has succeeded.
  renameSync(staged, receipts);
}

try {
  // A failed fresh run must not leave a previous successful receipt in place.
  rmSync(receipts, { recursive: true, force: true });
  const inputs = fingerprintInputs();
  const manifest = readJSON(path.join(here, "package.json"));
  assert.equal(manifest.devDependencies["@informalsystems/quint"], "0.33.1");
  assert.equal(quint(["--version"]).stdout.trim(), "0.33.1");
  const source = readFileSync(path.join(here, "agency.qnt"), "utf8");
  copyFileSync(path.join(here, "agency.qnt"), path.join(temporary, "agency.qnt"));
  copyFileSync(path.join(here, "table.qnt"), path.join(temporary, "table.qnt"));
  const fixture = readJSON(path.join(here, "scenarios.json"));
  validateFixtures(fixture);
  const scenarioText = fixtureModule(fixture.scenarios);
  writeFileSync(path.join(temporary, "scenarios.qnt"), scenarioText);

  quint(["typecheck", "agency.qnt"]);
  quint(["typecheck", "table.qnt"]);
  const unitReport = test("agency.qnt", ["codecRoundtripTest", "jointExecutionTest", "jointSoloRejectedTest",
    "immediateRevocationTest", "knowledgeBeforeNoticeTest", "asymmetricNoticeTest",
    "withdrawalBlocksJointTest", "acceptedHistoryTest", "scopeRejectedTest"]);
  const scenarioReport = test("scenarios.qnt", fixture.scenarios.map(scenario => `${scenario.name}Test`));
  log(`Quint 0.33.1 typecheck, 9 deterministic unit tests, and ${fixture.scenarios.length} declared scenarios passed`);

  const quintOutput = path.join(temporary, "table.itf.json");
  quint(["run", "table.qnt", "--backend", "typescript", "--max-samples", "1",
    "--max-steps", "0", "--out-itf", quintOutput, "--verbosity", "0"]);
  const quintTable = readQuintTable(quintOutput);

  // Fail closed: Lean is required. No cached CSV, JavaScript fallback, or
  // "skip because Lean is unavailable" path is accepted by this gate.
  command("lake", ["build", "Usul.Agency"], { cwd: leanDir });
  const leanVersion = command("lake", ["env", "lean", "--version"], { cwd: leanDir }).stdout.trim();
  const leanCSV = command("lake", ["env", "lean", "--run", "scripts/ExportAgency.lean"], { cwd: leanDir }).stdout;
  const leanTable = readLeanTable(leanCSV);
  compareTables(leanTable, quintTable);
  checkScenarios(leanTable, fixture.scenarios, "Lean");
  checkScenarios(quintTable, fixture.scenarios, "Quint");
  log(`exhaustive one-step parity: ${rowCount} inputs (${configs} configs × ${states} raw states × ${events.length} events), including disabled transitions`);
  const counts = checkReachableGraph(quintTable);
  for (const count of counts) log(`complete reachable graph: config ${count.config}, ${count.states} states, ${count.enabledEdges} enabled edges`);

  const mutants = checkMutants(source, scenarioText);

  // This run exercises the stateful action wrapper. It is explicitly sampled;
  // the complete table/graph checks above do not rely on its trace coverage.
  quint(["run", "agency.qnt", "--backend", "typescript", "--max-samples", "100",
    "--max-steps", "20", "--seed", seed, "--invariant", "safety", "--verbosity", "0"]);
  log(`sampled action-wrapper smoke check: 100 runs, at most 20 steps, seed ${seed}`);
  writeReceipts({ inputs, leanVersion, fixture, unitReport, scenarioReport,
    leanCSV, quintOutput, quintTable, counts, mutants });
  log("deterministic report, independent exports, and content hashes written to formal/quint/.out");
  log("PASS: all required checks completed; source interpretation remains a separate review obligation");
} finally {
  if (process.env.AGENCY_KEEP_CHECK === "1") {
    log(`temporary diagnostics retained at ${temporary}`);
  } else {
    rmSync(temporary, { recursive: true, force: true });
  }
}
