/**
 * migrate_multiple_choice.js
 * Converts K-type multiple_choice questions (numbered statements in question_text,
 * combination options like "1,2,3") into proper multi-select format:
 * - Statements become individual options[]
 * - correct_answer becomes the array of matching statement texts
 */

const fs = require('fs');
const path = require('path');

const BASE = './services/backend/src/data/questions';
const BATCHES = [
  'nephrology_new_batch1.json',
  'nephrology_new_batch2_tubular.json',
  'nephrology_new_batch3_tubular.json',
  'nephrology_new_batch4_functions.json',
  'nephrology_new_batch5_clinical.json',
];

// Parse numbered statements from question_text string
// Returns { preamble: string, statements: string[] }
function parseStatements(text) {
  const lines = text.split('\n');
  const preamline = [];
  const statements = [];

  for (const line of lines) {
    // Match "1. Statement text" or "1 – Statement text"
    const m = line.match(/^\s*(\d+)[.\-–]\s+(.+)$/);
    if (m) {
      statements.push(m[2].trim());
    } else if (statements.length === 0) {
      preamline.push(line);
    }
  }

  return {
    preamble: preamline.join('\n').trim(),
    statements,
  };
}

// Parse the old "1, 2, 3" / "1,3" / "All (1,2,3,4)" / "4 only" correct_answer
// into a 1-based index array
function parseCorrectIndices(str) {
  const s = str.toLowerCase();
  if (s.includes('all')) {
    // Return all 4 (max statements we have)
    const nums = s.match(/\d+/g);
    return nums ? nums.map(Number) : [1, 2, 3, 4];
  }
  if (/\d+\s*only/.test(s)) {
    const m = s.match(/(\d+)\s*only/);
    return m ? [parseInt(m[1])] : [];
  }
  // Comma / space separated list of numbers
  const nums = s.match(/\d+/g);
  return nums ? nums.map(Number) : [];
}

let totalFixed = 0;

BATCHES.forEach(filename => {
  const filePath = path.join(BASE, filename);
  if (!fs.existsSync(filePath)) {
    console.warn(`SKIP (not found): ${filename}`);
    return;
  }

  const questions = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  let changed = 0;

  const updated = questions.map(q => {
    if (q.question_type !== 'multiple_choice') return q;

    const { preamble: pEN, statements: stEN } = parseStatements(q.question_text_en);
    const { preamble: pHU, statements: stHU } = parseStatements(q.question_text_hu);

    if (stEN.length === 0) {
      console.log(`  [SKIP] ${q.id}: no numbered statements found — already migrated?`);
      return q;
    }

    if (stEN.length !== stHU.length) {
      console.warn(`  [WARN] ${q.id}: EN/HU statement count mismatch (${stEN.length} vs ${stHU.length})`);
    }

    // Determine which indices are correct
    const rawCorrect = q.correct_answer[0] || '';
    const correctIdx = parseCorrectIndices(rawCorrect); // e.g. [1,2,3]
    const newCorrectAnswer = correctIdx
      .map(i => stEN[i - 1])
      .filter(Boolean);

    if (newCorrectAnswer.length === 0) {
      console.warn(`  [WARN] ${q.id}: could not parse correct indices from "${rawCorrect}"`);
      return q;
    }

    // Build clean preamble — append "Select ALL that apply." instruction
    const cleanEN = pEN.replace(/Select ALL that apply\.?\s*$/i, '').trim() + ' Select ALL that apply.';
    const cleanHU = pHU.replace(/Jelölje meg az ÖSSZES helyes választ\.?\s*$/i, '').trim() + ' Jelölje meg az ÖSSZES helyes választ.';

    console.log(`  [FIX] ${q.id}: ${stEN.length} statements → correct: ${newCorrectAnswer.length}`);
    changed++;

    return {
      ...q,
      question_text_en: cleanEN,
      question_text_hu: cleanHU,
      options: {
        en: stEN,
        hu: stHU,
      },
      correct_answer: newCorrectAnswer,
    };
  });

  fs.writeFileSync(filePath, JSON.stringify(updated, null, 2));
  console.log(`${filename}: ${changed} question(s) migrated.\n`);
  totalFixed += changed;
});

console.log(`\n==============================`);
console.log(`Total migrated: ${totalFixed} multiple_choice question(s)`);
