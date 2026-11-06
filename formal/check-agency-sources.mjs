#!/usr/bin/env node
// Verify the existing source locks and the passages used by the candidate pilot.
// This checks textual provenance, not interpretation or scholarly acceptance.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const output = resolve(root, '.cache/agency/source-verification.json');
rmSync(output, { force: true });
const lock = JSON.parse(readFileSync(resolve(root, 'corpus/lock.json'), 'utf8'));
const references = [
  {
    witness: 'openiti-buhuti-kashshaf-shamela21642',
    locus: 'Kitab al-wakala, printed 3:472–473',
    start: '# (وإذا وكل) شخص (اثنين)',
    end: '# (ولا يصح بيع وكيل)',
    anchors: [
      '~~معا (لم يجز لأحدهما الانفراد بالتصرف)',
      '~~بعينه أو يجعله لكل منهما فيكون له الانفراد به',
    ],
  },
  {
    witness: 'openiti-ibnqudama-mughni-shamela8463',
    locus: 'Kitab al-wakala, section 3747, printed 5:70',
    start: '### | [فصل وكل وكيلين في تصرف وجعل لكل واحد الانفراد بالتصرف]',
    end: '### | [مسألة ليس للوكيل أن يوكل فيما وكل فيه إلا أن يجعل ذلك إليه]',
    anchors: [
      '~~فله ذلك؛ لأنه مأذون له فيه. فإن لم يجعل له ذلك، فليس لأحدهما الانفراد',
      '~~وإن جحد الغائب الوكالة، أو عزل نفسه، لم يكن للآخر أن يتصرف.',
    ],
  },
  {
    witness: 'openiti-ibnqudama-mughni-shamela8463',
    locus: 'Kitab al-wakala, masala 3776, printed 5:88–89',
    start: '### | [مسألة فعل الوكيل بعد فسخ الموكل أو موته]',
    end: '### | [فصل خروج الموكل والوكيل عن كونهما من أهل التصرف]',
    anchors: [
      '~~قولان. وظاهر كلام الخرقي هذا أنه ينعزل، علم أو لم يعلم.',
      '~~أحمد، لا ينعزل قبل علمه بموت الموكل وعزله.',
    ],
  },
];

function verify(reference, bytes) {
  const pin = lock.witnesses[reference.witness];
  assert.ok(pin, `Missing existing lock: ${reference.witness}`);
  assert.equal(bytes.length, pin.bytes, `${reference.witness}: byte count mismatch`);
  assert.equal(createHash('sha256').update(bytes).digest('hex'), pin.sha256,
    `${reference.witness}: SHA-256 mismatch`);
  const text = bytes.toString('utf8');
  const start = text.indexOf(reference.start);
  assert.ok(start >= 0, `${reference.witness}: opening locator missing`);
  assert.equal(text.indexOf(reference.start, start + 1), -1,
    `${reference.witness}: opening locator is ambiguous`);
  const end = text.indexOf(reference.end, start + reference.start.length);
  assert.ok(end > start, `${reference.witness}: closing locator missing`);
  const passage = text.slice(start, end);
  for (const anchor of reference.anchors) {
    assert.ok(passage.includes(anchor), `${reference.witness}: passage anchor missing: ${anchor}`);
  }
  return {
    witness: reference.witness,
    locus: reference.locus,
    sha256: pin.sha256,
    bytes: bytes.length,
    passage_sha256: createHash('sha256').update(passage, 'utf8').digest('hex'),
  };
}

const results = [];
for (const reference of references) {
  const bytes = readFileSync(resolve(root, `corpus/texts/${reference.witness}.txt`));
  results.push(verify(reference, bytes));
  // A same-length byte mutation must fail against the original, unchanged lock.
  const corrupted = Buffer.from(bytes);
  corrupted[0] ^= 1;
  assert.throws(() => verify(reference, corrupted), /SHA-256 mismatch/);
  // Correct file bytes cannot compensate for an unsupported passage locator.
  assert.throws(() => verify({ ...reference, start: 'AGENCY-MISSING-SOURCE-LOCATOR' }, bytes),
    /opening locator missing/);
}

const receipt = {
  schema: 'usul.agency.source-check.v1',
  status: 'source_bytes_and_anchors_verified',
  interpretation_status: 'candidate',
  scholarly_acceptance: false,
  negative_controls: ['same_length_corruption', 'missing_locator'],
  passages: results,
};
mkdirSync(dirname(output), { recursive: true });
writeFileSync(output, JSON.stringify(receipt, null, 2) + '\n');
console.log(`Agency source check: ${new Set(results.map(r => r.witness)).size} locked witnesses, ${results.length} passages; corruption and locator controls rejected.`);
