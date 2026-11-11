/** Read-only view of a generated, bounded IDA dossier. No verification occurs here. */
const $ = (id) => document.getElementById(id);
const list = (value) => Array.isArray(value) ? value : [];
const text = (value, fallback = 'Not supplied') => value === undefined || value === null || value === '' ? fallback : String(value);
const state = { dossier: null, claim: null, filter: 'all', query: '', evidenceTab: 'sources', source: null, proof: null, selection: {}, view: 'dossier' };

function element(tag, content, className) {
  const node = document.createElement(tag);
  if (content !== undefined) node.textContent = text(content, '');
  if (className) node.className = className;
  return node;
}

function tone(status) {
  const value = String(status).toLowerCase();
  if (['passed', 'admitted', 'robust', 'replayed-at-generation', 'source-authenticated', 'synthetic-contextual-admission', 'verified-at-generation'].includes(value)) return 'tone-passed';
  if (['blocked', 'rejected', 'conflicting', 'contested', 'incompatible', 'counterexample'].includes(value)) return 'tone-blocked';
  if (['unknown', 'missing', 'unverified', 'conditional', 'hypothetical', 'unsupported', 'pending', 'candidate'].includes(value)) return 'tone-warning';
  return '';
}

function statusBadge(value) {
  return element('span', text(value), `status-badge ${tone(value)}`.trim());
}

function setBadge(id, value) {
  const node = $(id);
  node.textContent = text(value);
  node.className = `status-badge ${tone(value)}`.trim();
}

function fillList(container, values) {
  container.replaceChildren(...list(values).map(value => element('li', value)));
}

function addParagraph(container, value, className) {
  if (value !== undefined && value !== null && value !== '') container.append(element('p', value, className));
}

function addField(container, label, value, code = false) {
  if (value === undefined || value === null || value === '') return;
  const field = element('div', undefined, 'hash-field');
  field.append(element('span', label, 'field-label'), element(code ? 'code' : 'span', value, code ? undefined : 'source-note'));
  container.append(field);
}

function renderKeyValues(container, values) {
  container.replaceChildren();
  for (const value of list(values)) container.append(element('dt', value.label), element('dd', text(value.value)));
}

function switchView(view) {
  state.view = view;
  for (const id of ['dossier', 'scenario']) {
    const active = view === id;
    $(`${id}-view`).hidden = !active;
    $(`${id}-view-button`).classList.toggle('active', active);
    $(`${id}-view-button`).setAttribute('aria-pressed', String(active));
  }
}

function selectClaim(id) {
  const claim = list(state.dossier.claims).find(item => item.id === id);
  if (!claim) return;
  state.claim = claim;
  if (list(claim.sourceIds).length) state.source = claim.sourceIds[0];
  if (list(claim.proofIds).length) state.proof = claim.proofIds[0];
  renderClaims();
  renderClaimDetail();
  renderEvidence();
}

function renderClaims() {
  const items = list(state.dossier.claims).filter(claim => (state.filter === 'all' || claim.kind === state.filter)
    && [claim.label, claim.statement, claim.id, claim.status].some(value => text(value, '').toLowerCase().includes(state.query)));
  const container = $('claims-list');
  container.replaceChildren();
  for (const claim of items) {
    const button = element('button', undefined, `claim-card${state.claim?.id === claim.id ? ' selected' : ''}`);
    button.type = 'button';
    button.setAttribute('aria-pressed', String(state.claim?.id === claim.id));
    const heading = element('span', undefined, 'claim-card-heading');
    heading.append(element('span', claim.kind, 'claim-kind'), element('span', claim.id, 'claim-id'));
    button.append(heading, element('span', claim.label, 'claim-card-title'), element('span', claim.status, 'claim-card-status'));
    button.addEventListener('click', () => selectClaim(claim.id));
    container.append(button);
  }
  if (!items.length) container.append(element('p', 'No statements match this view.', 'empty-state'));
}

function referenceButtons(container, title, ids, collection, action) {
  const references = list(ids).map(id => list(collection).find(item => item.id === id)).filter(Boolean);
  if (!references.length) return;
  container.append(element('h3', title));
  const links = element('div', undefined, 'dependency-links');
  for (const item of references) {
    const button = element('button', `${item.id} · ${text(item.label)}`, 'reference-button');
    button.type = 'button';
    button.addEventListener('click', () => action(item.id));
    links.append(button);
  }
  container.append(links);
}

function renderClaimDetail() {
  const claim = state.claim;
  const container = $('claim-detail');
  container.replaceChildren();
  if (!claim) {
    $('claim-detail-title').textContent = 'No statement selected';
    setBadge('claim-detail-status', 'unknown');
    return;
  }
  $('claim-detail-title').textContent = text(claim.label);
  setBadge('claim-detail-status', claim.status);
  if (claim.binding?.side) container.append(element('p', `${text(claim.binding.side)} application`, 'binding-side'));
  addParagraph(container, claim.statement, 'claim-statement');
  addParagraph(container, claim.scope, 'detail-scope');
  if (claim.binding && typeof claim.binding === 'object') {
    const details = element('details');
    details.append(element('summary', 'Exact typed binding and application scope'));
    for (const [key, label] of [['side', 'Application side'], ['certificateToken', 'Certificate token'],
      ['snapshotRepresentation', 'Complete snapshot'], ['formulaSyntax', 'Typed formula'],
      ['applicationPremises', 'Exact application premises'], ['applicationConclusion', 'Application conclusion'],
      ['sourceRepresentation', 'Source reference']]) {
      const value = claim.binding[key];
      if (value === undefined || value === null) continue;
      const rendered = typeof value === 'object' ? JSON.stringify(value, null, 2) : String(value);
      details.append(element('h3', label), element('pre', rendered, 'typed-binding'));
    }
    container.append(details);
  }
  referenceButtons(container, 'Depends on', claim.dependencies, state.dossier.claims, selectClaim);
  referenceButtons(container, 'Source occurrences', claim.sourceIds, state.dossier.sources, (id) => { state.evidenceTab = 'sources'; state.source = id; renderEvidence(); });
  referenceButtons(container, 'Proof obligations', claim.proofIds, state.dossier.proofs, (id) => { state.evidenceTab = 'proofs'; state.proof = id; renderEvidence(); });
  if (list(claim.notes).length) {
    const notes = element('ul', undefined, 'plain-list subtle');
    fillList(notes, claim.notes);
    container.append(notes);
  }
}

function safeProofLink(url) {
  try {
    const parsed = new URL(url);
    if (parsed.protocol !== 'https:' || parsed.hostname !== 'github.com' || parsed.username || parsed.password) return null;
    if (!parsed.pathname.startsWith('/larsbx/usul-al-fiqh-deontic-circuits/')) return null;
    return parsed.href;
  } catch { return null; }
}

function renderEvidence() {
  const sources = state.evidenceTab === 'sources';
  const items = list(sources ? state.dossier.sources : state.dossier.proofs);
  let selected = sources ? state.source : state.proof;
  if (!items.some(item => item.id === selected)) selected = items[0]?.id;
  if (sources) state.source = selected; else state.proof = selected;
  $('sources-tab').classList.toggle('active', sources);
  $('proofs-tab').classList.toggle('active', !sources);
  $('sources-tab').setAttribute('aria-pressed', String(sources));
  $('proofs-tab').setAttribute('aria-pressed', String(!sources));
  $('evidence-select-label').textContent = sources ? 'Source record' : 'Proof declaration';
  const select = $('evidence-select');
  select.replaceChildren(...items.map(item => { const option = element('option', `${item.id} · ${text(item.label)}`); option.value = item.id; return option; }));
  select.disabled = !items.length;
  if (selected) select.value = selected;
  const container = $('evidence-detail');
  container.replaceChildren();
  const item = items.find(record => record.id === selected);
  if (!item) { container.append(element('p', 'No evidence record supplied for this category.', 'empty-state')); return; }
  container.append(element('p', item.label, 'evidence-detail-title'), statusBadge(item.status));
  if (sources) {
    if (item.excerpt) container.append(element('blockquote', item.excerpt, 'source-excerpt'));
    addField(container, 'Exact locator', item.locator);
    addField(container, 'Source SHA-256', item.sourceSha256, true);
    addField(container, 'Passage SHA-256', item.passageSha256, true);
    addField(container, 'Source issuer', item.issuer);
    addField(container, 'Key fingerprint', item.keyFingerprint, true);
    addParagraph(container, 'Source authentication checks the supplied bytes and issuer. It does not establish the truth of the asserted event.', 'source-note');
  } else {
    if (item.symbol) container.append(element('code', item.symbol, 'proof-symbol'));
    addParagraph(container, item.statement, 'source-note');
    addField(container, 'Supported scope', item.scope);
    addField(container, 'Declaration path', item.path, true);
    const href = safeProofLink(item.url);
    if (href) { const link = element('a', 'Inspect declaration on GitHub'); link.href = href; link.target = '_blank'; link.rel = 'noopener noreferrer'; link.className = 'source-note'; container.append(link); }
  }
  for (const note of list(item.notes)) addParagraph(container, note, 'source-note');
}

function renderInquiry() {
  const inquiry = state.dossier.inquiry || {};
  $('inquiry-summary').replaceChildren();
  addParagraph($('inquiry-summary'), inquiry.label || inquiry.question, 'inquiry-question');
  addParagraph($('inquiry-summary'), inquiry.target, 'inquiry-target');
  const parties = $('party-list');
  parties.replaceChildren();
  for (const party of list(inquiry.parties)) {
    const card = element('div', undefined, 'party-card');
    card.append(element('span', party.role, 'field-label'), element('strong', party.label), element('code', party.reference));
    parties.append(card);
  }
  renderKeyValues($('context-list'), [...list(inquiry.context), ...list(inquiry.time)]);
  renderKeyValues($('pin-list'), inquiry.pins);
}

function renderQuestions() {
  const container = $('questions-list');
  container.replaceChildren();
  for (const question of list(state.dossier.questions)) {
    const section = element('section', undefined, 'question');
    section.append(element('h3', question.question));
    addParagraph(section, question.reason);
    addParagraph(section, question.nextAction, 'question-next');
    container.append(section);
  }
  if (!container.childElementCount) container.append(element('p', 'No review questions were supplied. This does not establish that the case is complete.', 'empty-state'));
}

function findScenario(selection) {
  const scenario = state.dossier.scenarios || {};
  return list(scenario.cells).find(cell => list(scenario.dimensions).every(dimension => cell.selection?.[dimension.id] === selection[dimension.id]));
}

function renderScenarioResult() {
  const scenario = state.dossier.scenarios || {};
  const baseline = findScenario(scenario.baseline || {});
  const selected = findScenario(state.selection);
  const container = $('scenario-result');
  container.replaceChildren();
  if (!selected || !baseline) {
    container.append(element('p', 'No precomputed cell matches this selection. No outcome can be displayed.', 'empty-state'));
    return;
  }
  const intro = element('p', selected.label || 'Selected hypothetical fixture cell', 'scenario-explanation');
  container.append(intro);
  const table = element('table', undefined, 'comparison-table');
  const caption = element('caption', 'Precomputed baseline and selected hypothetical scenario outcomes', 'sr-only');
  const head = element('thead');
  const heading = element('tr');
  for (const label of ['Observation', 'Baseline fixture', 'Selected · hypothetical']) { const cell = element('th', label); cell.scope = 'col'; heading.append(cell); }
  head.append(heading);
  const body = element('tbody');
  const reportText = (value) => value && typeof value === 'object'
    ? `${text(value.status)} · positive ${value.positive === true ? 'present' : 'absent'} · negative ${value.negative === true ? 'present' : 'absent'}`
    : text(value);
  for (const [key, label] of [['support', 'Support reports'], ['exception', 'Exception reports'], ['guard', 'Report guard'], ['reportStatus', 'Evaluator outcome'], ['assessment', 'Finite histories'], ['result', 'Staged result']]) {
    const row = element('tr');
    const title = element('th', label); title.scope = 'row';
    const format = key === 'support' || key === 'exception' ? reportText : text;
    const baselineText = format(baseline[key]);
    const selectedText = format(selected[key]);
    const a = element('td', baselineText);
    const b = element('td', selectedText);
    if (baselineText !== selectedText) b.className = 'changed-cell';
    row.append(title, a, b); body.append(row);
  }
  table.append(caption, head, body);
  container.append(table);
  addParagraph(container, selected.explanation, 'scenario-explanation');
  if (list(selected.questions).length) {
    container.append(element('h3', 'Questions raised by this scenario'));
    const questions = element('div', undefined, 'scenario-questions');
    for (const question of selected.questions) {
      const section = element('section', undefined, 'question');
      section.append(element('h3', question.question));
      addParagraph(section, question.reason);
      addParagraph(section, question.nextAction, 'question-next');
      questions.append(section);
    }
    container.append(questions);
  }
  const coordinates = list(scenario.dimensions).map(dimension => `${dimension.id}=${state.selection[dimension.id]}`).join(' · ');
  container.append(element('p', coordinates, 'selection-code'));
  container.append(element('p', 'A robust result concerns only the declared finite history population. Unknown, incompatible, and conflicting outcomes remain visible; no selected cell becomes a signed case fact.', 'panel-footnote'));
}

function renderScenarios() {
  const scenario = state.dossier.scenarios || {};
  $('scenario-description').textContent = text(scenario.description, 'No scenario population was supplied.');
  const container = $('scenario-selects');
  container.replaceChildren();
  for (const dimension of list(scenario.dimensions)) {
    const group = element('div', undefined, 'scenario-select');
    const label = element('label', dimension.label); label.htmlFor = `scenario-${dimension.id}`;
    const select = element('select'); select.id = label.htmlFor;
    for (const option of list(dimension.options)) { const node = element('option', option.label); node.value = String(option.value); select.append(node); }
    select.value = String(state.selection[dimension.id]);
    select.addEventListener('change', () => {
      const option = list(dimension.options).find(item => String(item.value) === select.value);
      if (!option) return;
      state.selection[dimension.id] = option.value;
      $('copy-status').textContent = '';
      renderScenarioResult();
    });
    group.append(label, select); container.append(group);
  }
  renderScenarioResult();
}

function renderVerification() {
  const verification = state.dossier.verification || {};
  $('verification-label').textContent = verification.status === 'replayed-at-generation' ? 'Replay passed at generation' : text(verification.status, 'No replay status supplied');
  for (const [id, value] of [['revision', verification.revision], ['receipt-hash', verification.receiptSha256]]) { $(id).textContent = text(value); $(id).title = text(value); }
  const container = $('verification-checks');
  container.replaceChildren();
  for (const check of list(verification.checks)) {
    const row = element('div', undefined, 'verification-check');
    const detail = element('div'); detail.append(element('strong', check.label)); addParagraph(detail, check.detail);
    row.append(detail, statusBadge(check.status)); container.append(row);
  }
  fillList($('verification-limits'), verification.limits);
  const protocol = state.dossier.protocol;
  if (protocol && list(protocol.commands).length) {
    $('protocol-details').hidden = false;
    const commands = $('protocol-commands');
    commands.replaceChildren();
    for (const command of protocol.commands) { const row = element('div', undefined, 'protocol-command'); row.append(element('code', command.name)); addParagraph(row, command.description); commands.append(row); }
  }
}

function renderConclusion() {
  const conclusion = state.dossier.conclusion || {};
  $('conclusion-title').textContent = text(conclusion.title, 'Conditional conclusion');
  $('conclusion-statement').textContent = text(conclusion.statement);
  setBadge('conclusion-status', conclusion.status);
  fillList($('conclusion-conditions'), conclusion.conditions);
  $('conclusion-limits').replaceChildren();
  for (const limit of list(conclusion.limits)) addParagraph($('conclusion-limits'), limit);
  $('conclusion-limits').hidden = !list(conclusion.limits).length;
}

async function copyDraftNotes() {
  const dossier = state.dossier;
  const draft = {
    schema: 'ida-review-draft-notes-v1',
    status: 'unsigned-unsubmitted-draft',
    caseMode: dossier.caseMode,
    audience: dossier.audience,
    reviewPerspective: $('perspective').value,
    fixture: dossier.fixture.id,
    implementationRevision: dossier.verification.revision,
    admissionReceiptSha256: dossier.verification.receiptSha256,
    displayedView: state.view,
    hypotheticalScenarioSelection: { ...state.selection },
    baselineSelection: { ...dossier.scenarios?.baseline },
    notes: $('review-notes').value,
  };
  const output = JSON.stringify(draft, null, 2);
  try {
    if (!navigator.clipboard?.writeText) throw new Error('Clipboard unavailable');
    await navigator.clipboard.writeText(output);
    $('copy-status').textContent = 'Bound draft copied. No decision issued.';
  } catch {
    // The fallback exposes the complete draft for manual copying, without
    // persisting it or issuing any decision to an external service.
    $('manual-copy').hidden = false;
    const area = $('draft-output');
    area.value = output;
    area.focus(); area.select();
    $('copy-status').textContent = 'Clipboard unavailable. The complete draft is selected for manual copy.';
  }
}

function bindEvents() {
  $('dossier-view-button').addEventListener('click', () => switchView('dossier'));
  $('scenario-view-button').addEventListener('click', () => switchView('scenario'));
  $('claim-search').addEventListener('input', (event) => { state.query = event.target.value.toLowerCase(); renderClaims(); });
  for (const button of document.querySelectorAll('[data-claim-filter]')) button.addEventListener('click', () => {
    state.filter = button.dataset.claimFilter;
    for (const peer of document.querySelectorAll('[data-claim-filter]')) { const active = peer === button; peer.classList.toggle('active', active); peer.setAttribute('aria-pressed', String(active)); }
    renderClaims();
  });
  for (const tab of ['sources', 'proofs']) $(`${tab}-tab`).addEventListener('click', () => { state.evidenceTab = tab; renderEvidence(); });
  $('evidence-select').addEventListener('change', (event) => { if (state.evidenceTab === 'sources') state.source = event.target.value; else state.proof = event.target.value; renderEvidence(); });
  $('reset-scenario').addEventListener('click', () => { state.selection = { ...state.dossier.scenarios?.baseline }; renderScenarios(); $('copy-status').textContent = ''; });
  $('perspective').addEventListener('change', () => { $('notes-title').textContent = $('perspective').value === 'mufti' ? 'Draft advisory notes' : 'Draft adjudication notes'; $('copy-status').textContent = ''; });
  $('copy-notes').addEventListener('click', copyDraftNotes);
  $('clear-notes').addEventListener('click', () => { $('review-notes').value = ''; $('draft-output').value = ''; $('manual-copy').hidden = true; $('copy-status').textContent = ''; $('review-notes').focus(); });
}

function validateDisplayContract(dossier) {
  if (!dossier || dossier.schema !== 'ida-case-dossier-v1') throw new Error('The dossier uses an unsupported display schema.');
  if (dossier.caseMode !== 'synthetic-scenario' || dossier.audience !== 'review'
      || dossier.fixture?.synthetic !== true || dossier.fixture?.testKeys !== true) {
    throw new Error('This bounded workbench only displays the declared synthetic test-key scenario.');
  }
  if (!dossier.verification?.revision || !dossier.verification?.receiptSha256) throw new Error('The dossier is missing its implementation or receipt binding.');
  if (!Array.isArray(dossier.claims)) throw new Error('The dossier does not contain a statement list.');
  const cardinalities = { mask: 16, population: 4, authorityMode: 6 };
  const dimensions = list(dossier.scenarios?.dimensions);
  const ids = dimensions.map(dimension => dimension.id);
  if (ids.length !== 3 || new Set(ids).size !== 3 || ids.some(id => !Object.hasOwn(cardinalities, id))) {
    throw new Error('The scenario dimensions do not match the supported bounded fixture.');
  }
  for (const dimension of dimensions) {
    const values = list(dimension.options).map(option => option.value);
    if (values.length !== cardinalities[dimension.id] || new Set(values).size !== values.length
        || values.some(value => !Number.isInteger(value) || value < 0 || value >= cardinalities[dimension.id])) {
      throw new Error('A scenario dimension contains missing, duplicate, or unsupported options.');
    }
  }
  const cells = list(dossier.scenarios?.cells);
  const keys = new Set();
  for (const cell of cells) {
    if (Object.entries(cardinalities).some(([id, size]) => !Number.isInteger(cell.selection?.[id]) || cell.selection[id] < 0 || cell.selection[id] >= size)) {
      throw new Error('A scenario cell uses an unsupported selection.');
    }
    const key = ['mask', 'population', 'authorityMode'].map(id => cell.selection[id]).join(':');
    if (keys.has(key)) throw new Error('Scenario cells contain a duplicate selection.');
    keys.add(key);
  }
  if (keys.size !== 384 || dossier.scenarios?.baseline?.mask !== 9
      || dossier.scenarios?.baseline?.population !== 2 || dossier.scenarios?.baseline?.authorityMode !== 0) {
    throw new Error('The complete scenario population or exact baseline is missing.');
  }
  // These are display-contract checks, not cryptographic or Lean verification.
}

async function initialize() {
  try {
    const options = { cache: 'no-store', credentials: 'same-origin' };
    const [response, manifestResponse] = await Promise.all([
      fetch('./dossier.json', options), fetch('./verification.json', options),
    ]);
    if (!response.ok) throw new Error(`The generated dossier could not be loaded (HTTP ${response.status}).`);
    if (!manifestResponse.ok) throw new Error(`The generation marker could not be loaded (HTTP ${manifestResponse.status}). Rebuild the package before reviewing it.`);
    const raw = await response.arrayBuffer();
    const dossier = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(raw));
    const manifest = await manifestResponse.json();
    validateDisplayContract(dossier);
    if (manifest.schema !== 'ida-case-workbench-build-v1' || manifest.synthetic !== true
        || manifest.revision !== dossier.verification.revision
        || manifest.receiptSha256 !== dossier.verification.receiptSha256
        || manifest.scenarioCells !== 384 || manifest.scenarioCells !== list(dossier.scenarios?.cells).length) {
      throw new Error('The generation marker does not match the displayed dossier. Rebuild the complete package.');
    }
    if (!globalThis.crypto?.subtle) throw new Error('Package consistency checks require a secure localhost browser context.');
    const digest = new Uint8Array(await crypto.subtle.digest('SHA-256', raw));
    const hash = Array.from(digest, byte => byte.toString(16).padStart(2, '0')).join('');
    if (hash !== manifest.dossierSha256) throw new Error('The dossier bytes differ from the generation marker. Rebuild the complete package.');
    // The unsigned marker checks package consistency. It supplies neither
    // external authenticity nor a new source/premise verification decision.
    state.dossier = dossier;
    state.claim = list(dossier.claims).find(claim => claim.kind === 'premise') || dossier.claims[0] || null;
    state.source = list(state.claim?.sourceIds)[0];
    state.proof = list(state.claim?.proofIds)[0];
    state.selection = { ...dossier.scenarios?.baseline };
    document.title = `${text(dossier.title, 'Case review')} · IDA`;
    $('case-title').textContent = text(dossier.title, 'A case, with its assumptions attached');
    $('fixture-scope').textContent = text(dossier.fixture.scope, 'Bounded synthetic replay for human review.');
    $('footer-fixture').textContent = text(dossier.fixture.id);
    $('claim-count').textContent = dossier.claims.length;
    renderVerification(); renderConclusion(); renderClaims(); renderClaimDetail(); renderEvidence(); renderInquiry(); renderQuestions(); renderScenarios(); bindEvents();
    $('loading').hidden = true;
    $('workbench').hidden = false;
  } catch (error) {
    $('loading').hidden = true;
    $('workbench').hidden = true;
    $('load-error-detail').textContent = error instanceof Error ? error.message : 'The dossier could not be read.';
    $('load-error').hidden = false;
  }
}

initialize();
