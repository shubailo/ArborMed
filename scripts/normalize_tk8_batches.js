
const fs = require('fs');
const path = require('path');

const QUESTIONS_DIR = path.join(__dirname, '../backend/src/data/questions');

function normalize() {
    const files = fs.readdirSync(QUESTIONS_DIR).filter(f => f.startsWith('tk8_questions_batch') && f.endsWith('.json'));
    console.log(`Found ${files.length} TK8 files to normalize.`);

    files.forEach(file => {
        const oldPath = path.join(QUESTIONS_DIR, file);
        const batchNum = file.match(/batch(\d+)/)[1];
        const newFileName = `tk8_batch_${batchNum}.json`;
        const newPath = path.join(QUESTIONS_DIR, newFileName);

        console.log(`Normalizing ${file} -> ${newFileName}...`);

        let content = fs.readFileSync(oldPath, 'utf8');
        // Fix the type naming issue
        content = content.replace(/"type": "relational_analysis"/g, '"type": "relation_analysis"');

        fs.writeFileSync(newPath, content);

        // Remove old file if it was different
        if (oldPath !== newPath) {
            fs.unlinkSync(oldPath);
        }
    });

    console.log('Normalization complete.');
}

normalize();
