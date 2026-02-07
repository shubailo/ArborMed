const fs = require('fs');
const path = require('path');

const q1 = require('../src/data/questions/generated_questions.json');
const q2 = require('../src/data/questions/additional_questions.json');
const q3 = require('../src/data/questions/batch3_questions.json');
const q4 = require('../src/data/questions/batch4_questions.json');

const combined = [...q1, ...q2, ...q3, ...q4];

// Re-index IDs to be sequential
combined.forEach((q, idx) => {
    q.id = `gen_${String(idx + 1).padStart(3, '0')}`;
});

const outputPath = path.join(__dirname, '../src/data/questions/haematology_full.json');
fs.writeFileSync(outputPath, JSON.stringify(combined, null, 2));

console.log(`Successfully combined ${q1.length} + ${q2.length} + ${q3.length} + ${q4.length} = ${combined.length} questions into ${outputPath}`);
