const assert = require('node:assert/strict');
const { execFileSync, spawnSync } = require('node:child_process');
const { createHash } = require('node:crypto');
const { cpSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, symlinkSync, writeFileSync } = require('node:fs');
const { createServer } = require('node:http');
const { tmpdir } = require('node:os');
const { join } = require('node:path');
const { chromium } = require('playwright');

const packageDir = '.cache/ida-case-workbench';
const evidenceDir = '.cache/ida-case-workbench-browser';
const read = (name) => readFileSync(join(packageDir, name));
const sha256 = (bytes) => createHash('sha256').update(bytes).digest('hex');
const dossierBytes = read('dossier.json');
const dossier = JSON.parse(dossierBytes);
const marker = JSON.parse(read('verification.json'));
const revision = execFileSync('git', ['rev-parse', 'HEAD'], { encoding: 'utf8' }).trim();
const checks = [];
const errors = [];

async function run() {
  mkdirSync(evidenceDir, { recursive: true });
  const report = {
    revision, receiptSha256: marker.receiptSha256, dossierSha256: marker.dossierSha256,
    playwright: require('playwright/package.json').version, node: process.version,
    runner: process.env.RUNNER_OS || process.platform, workflowRun: process.env.GITHUB_RUN_ID || null,
    workflowAttempt: process.env.GITHUB_RUN_ATTEMPT || null,
    status: 'failed', checks, errors,
  };
  const work = mkdtempSync(join(tmpdir(), 'ida-browser-'));
  let browser;
  let server;
  try {
    assert.equal(revision, process.env.EXPECTED_REVISION || revision);
    assert.equal(marker.revision, revision);
    assert.equal(dossier.verification.revision, revision);
    assert.equal(marker.receiptSha256, dossier.verification.receiptSha256);
    assert.equal(marker.dossierSha256, sha256(dossierBytes));
    for (const name of ['index.html', 'app.js', 'style.css']) {
      assert.deepEqual(read(name), execFileSync('git', ['show', revision + ':web/ida-case-workbench/' + name]));
    }

    const failedDir = join(work, 'failed');
    cpSync(packageDir, failedDir, { recursive: true });
    const onlyGit = join(work, 'git-only');
    mkdirSync(onlyGit);
    symlinkSync(execFileSync('which', ['git'], { encoding: 'utf8' }).trim(), join(onlyGit, 'git'));
    const failed = spawnSync(process.execPath, ['formal/ida-case-workbench.mjs', 'build', failedDir],
      { env: { ...process.env, PATH: onlyGit }, encoding: 'utf8' });
    writeFileSync(join(evidenceDir, 'failed-replay.log'), failed.stderr);
    assert.ok(failed.status > 0);
    assert.ok(!existsSync(join(failedDir, 'verification.json')));
    assert.deepEqual(readFileSync(join(failedDir, 'dossier.json')), dossierBytes);

    const types = { 'index.html': 'text/html', 'app.js': 'text/javascript', 'style.css': 'text/css',
      'dossier.json': 'application/json', 'verification.json': 'application/json' };
    server = createServer((request, response) => {
      const [, variant, file = ''] = request.url.split('/');
      const name = file || 'index.html';
      if (request.method !== 'GET' || !Object.hasOwn(types, name)
          || !['baseline', 'stale', 'altered', 'failed'].includes(variant)) {
        response.writeHead(404).end();
        return;
      }
      if (variant === 'failed' && name === 'verification.json') {
        response.writeHead(404).end();
        return;
      }
      let bytes = variant === 'failed' ? readFileSync(join(failedDir, name)) : read(name);
      if (variant === 'stale' && name === 'verification.json') {
        bytes = JSON.stringify({ ...marker, revision: '0'.repeat(40) });
      }
      if (variant === 'altered' && name === 'dossier.json') bytes = Buffer.concat([bytes, Buffer.from('\n')]);
      response.writeHead(200, { 'Content-Type': types[name], 'Cache-Control': 'no-store' }).end(bytes);
    });
    await new Promise((resolve, reject) => server.once('error', reject).listen(0, '127.0.0.1', resolve));
    const origin = 'http://127.0.0.1:' + server.address().port;
    browser = await chromium.launch();
    report.chromium = browser.version();
    const desktop = await browser.newContext({ viewport: { width: 1440, height: 1000 },
      permissions: ['clipboard-read', 'clipboard-write'] });
    const page = await desktop.newPage();
    const watch = (page) => page.on('pageerror', (error) => errors.push(error.message));
    watch(page);
    const open = (page, variant = 'baseline') => page.goto(origin + '/' + variant + '/');
    const shot = (page, name) => page.screenshot({ path: join(evidenceDir, name + '.png'), fullPage: true });
    const value = (page, selector) => page.locator(selector).textContent();
    const claimButton = (page, id) => page.locator('.claim-card').filter({
      has: page.getByText(id, { exact: true }),
    });

    await open(page);
    await page.locator('#workbench').waitFor();
    assert.equal(await value(page, '#verification-label'), 'Replay passed at generation');
    assert.equal(await value(page, '#revision'), revision);
    assert.equal(await value(page, '#receipt-hash'), marker.receiptSha256);
    const authority = page.getByRole('region', { name: 'Dossier binding and verification' });
    const decision = authority.getByText('Human decision', { exact: true }).locator('..');
    assert.equal(await decision.locator('strong').textContent(), 'Not issued');
    const initialAuthority = await authority.innerText();
    const skip = page.getByRole('link', { name: 'Skip to case review' });
    await page.keyboard.press('Tab');
    assert.equal(await skip.evaluate((node) => node === document.activeElement), true);
    await page.keyboard.press('Enter');
    assert.equal(new URL(page.url()).hash, '#main');

    const premise = dossier.claims.find(({ id }) => id === 'premise-3');
    const button = claimButton(page, premise.id);
    await button.focus();
    await page.keyboard.press('Enter');
    assert.equal(await button.evaluate((node) => node === document.activeElement), true);
    assert.equal(await button.getAttribute('aria-pressed'), 'true');
    assert.equal(await value(page, '#claim-detail-title'), premise.label);
    assert.equal(await value(page, '#claim-detail .claim-statement'), premise.statement);
    assert.equal(await value(page, '#claim-detail-status'), premise.status);
    const source = dossier.sources.find(({ id }) => id === premise.sourceIds[0]);
    await page.locator('#claim-detail').getByRole('button', { name: source.id + ' · ' + source.label, exact: true }).click();
    assert.equal(await page.locator('#evidence-select').inputValue(), source.id);
    assert.equal(await value(page, '#evidence-detail blockquote'), source.excerpt);
    for (const field of ['locator', 'sourceSha256', 'passageSha256']) {
      assert.ok((await value(page, '#evidence-detail')).includes(source[field]));
    }
    checks.push('Keyboard skip and claim activation, exact premise and authenticated source references');

    const conclusion = dossier.conclusion;
    assert.equal(await value(page, '#conclusion-status'), conclusion.status);
    assert.equal(await value(page, '#conclusion-statement'), conclusion.statement);
    assert.deepEqual(await page.locator('#conclusion-conditions li').allTextContents(), conclusion.conditions);
    const derivation = dossier.claims.find(({ dependencies }) =>
      conclusion.premiseIds.every((id) => dependencies.includes(id)));
    await claimButton(page, derivation.id).click();
    for (const id of conclusion.premiseIds) {
      const required = dossier.claims.find((claim) => claim.id === id);
      await page.locator('#claim-detail').getByRole('button', { name: id + ' · ' + required.label, exact: true }).waitFor();
    }
    const proof = dossier.proofs.find(({ id }) => id === derivation.proofIds[0]);
    await page.locator('#claim-detail').getByRole('button', { name: proof.id + ' · ' + proof.label, exact: true }).click();
    assert.equal(await value(page, '#evidence-detail .proof-symbol'), proof.symbol);
    assert.equal(await page.locator('#evidence-detail a').getAttribute('href'), proof.url);
    await shot(page, 'desktop-dossier');
    const stableDossier = await page.locator('#dossier-view').innerText();

    const perspective = page.getByLabel('Review perspective');
    assert.equal(await value(page, '#notes-title'), 'Draft adjudication notes');
    await perspective.selectOption('mufti');
    assert.equal(await value(page, '#notes-title'), 'Draft advisory notes');
    assert.equal(await authority.innerText(), initialAuthority);
    assert.equal(await page.locator('#dossier-view').innerText(), stableDossier);
    checks.push('Conditional conclusion, both required premises, revision-bound proof link and presentation-only perspective');

    const selection = { ...dossier.scenarios.baseline, mask: 1 };
    const selected = dossier.scenarios.cells.find(({ selection: cell }) =>
      Object.keys(selection).every((key) => cell[key] === selection[key]));
    await page.locator('#scenario-view-button').click();
    const baselineCells = await page.locator('#scenario-result tbody td:nth-child(2)').allTextContents();
    await page.locator('#scenario-mask').selectOption('1');
    assert.equal(await page.locator('#dossier-view').isVisible(), false);
    assert.match(await value(page, '.hypothesis-banner'), /Hypothetical exploration · unsigned/);
    assert.equal(await value(page, '#scenario-result tbody tr:last-child td:last-child'), selected.result);
    assert.deepEqual(await page.locator('#scenario-result tbody td:nth-child(2)').allTextContents(), baselineCells);
    assert.ok(selected.questions.length > 0);
    assert.deepEqual(await page.locator('.scenario-questions h3').allTextContents(),
      selected.questions.map(({ question }) => question));
    assert.match(await value(page, '.scenario-questions'), /exception/i);
    await shot(page, 'desktop-missing-evidence');
    await page.locator('#scenario-population').selectOption('0');
    await page.locator('#scenario-authorityMode').selectOption('1');
    const alternate = dossier.scenarios.cells.find(({ selection }) =>
      selection.mask === 1 && selection.population === 0 && selection.authorityMode === 1);
    assert.equal(await value(page, '#scenario-result tbody tr:last-child td:last-child'), alternate.result);
    assert.deepEqual(await page.locator('.scenario-questions h3').allTextContents(),
      alternate.questions.map(({ question }) => question));
    await page.locator('#scenario-population').selectOption(String(selection.population));
    await page.locator('#scenario-authorityMode').selectOption(String(selection.authorityMode));

    const notes = 'Check the explicit exception report.\nSynthetic review only.';
    await page.locator('#review-notes').fill(notes);
    await page.locator('#copy-notes').click();
    await page.getByText('Bound draft copied. No decision issued.', { exact: true }).waitFor();
    const expectedDraft = {
      schema: 'ida-review-draft-notes-v1', status: 'unsigned-unsubmitted-draft',
      caseMode: dossier.caseMode, audience: dossier.audience, reviewPerspective: 'mufti',
      fixture: dossier.fixture.id, implementationRevision: revision, admissionReceiptSha256: marker.receiptSha256,
      displayedView: 'scenario', hypotheticalScenarioSelection: selection,
      baselineSelection: dossier.scenarios.baseline, notes,
    };
    assert.deepEqual(JSON.parse(await page.evaluate(() => navigator.clipboard.readText())), expectedDraft);
    const fallback = await browser.newContext();
    await fallback.addInitScript(() => {
      Object.defineProperty(navigator, 'clipboard', { value: undefined });
    });
    const fallbackPage = await fallback.newPage();
    watch(fallbackPage);
    await open(fallbackPage);
    await fallbackPage.locator('#review-notes').fill(notes);
    await fallbackPage.locator('#copy-notes').click();
    const output = fallbackPage.locator('#draft-output');
    await output.waitFor();
    assert.deepEqual(JSON.parse(await output.inputValue()), {
      ...expectedDraft, displayedView: 'dossier', reviewPerspective: 'adjudicator',
      hypotheticalScenarioSelection: dossier.scenarios.baseline,
    });
    assert.ok(await output.evaluate((node) => node === document.activeElement
      && node.selectionStart === 0 && node.selectionEnd === node.value.length));
    await fallbackPage.locator('#clear-notes').click();
    assert.equal(await output.isVisible(), false);
    assert.equal(await fallbackPage.locator('#review-notes').inputValue(), '');
    await fallback.close();
    await page.locator('#reset-scenario').click();
    assert.equal(await page.locator('#scenario-mask').inputValue(), String(dossier.scenarios.baseline.mask));
    await page.locator('#dossier-view-button').click();
    assert.equal(await page.locator('#dossier-view').innerText(), stableDossier);
    assert.equal(await authority.innerText(), initialAuthority);
    checks.push('Unsigned scenario switching, missing-evidence questions, immutable baseline and bound clipboard draft including manual fallback');

    for (const width of [390, 320]) {
      const mobile = await browser.newPage({ viewport: { width, height: 844 }, isMobile: true, hasTouch: true });
      watch(mobile);
      await open(mobile);
      await mobile.locator('#workbench').waitFor();
      for (const [view, controls] of [
        ['dossier', ['#claim-search', '#evidence-select', '#copy-notes']],
        ['scenario', ['#scenario-mask', '#scenario-population', '#scenario-authorityMode', '#reset-scenario']],
      ]) {
        await mobile.locator('#' + view + '-view-button').tap();
        if (view === 'scenario') await mobile.locator('#scenario-mask').selectOption('1');
        const dimensions = await mobile.evaluate(() => ({
          document: document.documentElement.scrollWidth, viewport: document.documentElement.clientWidth,
        }));
        assert.equal(dimensions.viewport, width);
        assert.ok(dimensions.document <= width, JSON.stringify({ view, width, ...dimensions }));
        for (const selector of controls) {
          const control = mobile.locator(selector);
          assert.equal(await control.isVisible(), true);
          const box = await control.boundingBox();
          assert.ok(box.x >= 0 && box.x + box.width <= width + 1, selector);
        }
        await shot(mobile, 'mobile-' + width + '-' + view);
      }
      await mobile.close();
    }
    checks.push('Dossier and scenario mobile layouts at 390px and 320px');

    for (const [variant, message] of [
      ['stale', /generation marker does not match/],
      ['altered', /dossier bytes differ/],
      ['failed', /generation marker could not be loaded \(HTTP 404\)/],
    ]) {
      await open(page, variant);
      await page.getByRole('alert').waitFor();
      assert.match(await value(page, '#load-error-detail'), message);
      assert.equal(await page.locator('#workbench').isVisible(), false);
      assert.equal(await page.locator('#copy-notes').isVisible(), false);
      await shot(page, 'blocked-' + variant);
      checks.push('Review blocked for ' + variant + ' package');
    }
    assert.deepEqual(errors, []);
    report.status = 'passed';
  } catch (error) {
    report.failure = error.stack;
    throw error;
  } finally {
    writeFileSync(join(evidenceDir, 'report.json'), JSON.stringify(report, null, 2) + '\n');
    if (browser) await browser.close();
    if (server) server.close();
    rmSync(work, { recursive: true, force: true });
  }
}

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
