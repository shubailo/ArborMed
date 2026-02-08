const fs = require('fs');
const path = require('path');

const questionsDir = path.join(__dirname, '../src/data/questions');
const outputFile = path.join(questionsDir, 'tka6_full_merged.json');

let allQuestions = [];
let totalBatches = 0;

// Loop through batches 1 to 20
for (let i = 1; i <= 20; i++) {
    const filename = `tka6_high_density_batch_${i}.json`;
    const filePath = path.join(questionsDir, filename);

    if (fs.existsSync(filePath)) {
        try {
            const content = fs.readFileSync(filePath, 'utf8');
            const batchQuestions = JSON.parse(content);
            console.log(`Loaded ${filename}: ${batchQuestions.length} questions`);
            allQuestions = allQuestions.concat(batchQuestions);
            totalBatches++;
        } catch (error) {
            console.error(`Error reading/parsing ${filename}:`, error.message);
        }
    } else {
        console.warn(`Warning: ${filename} not found.`);
    }
}

// Validation
console.log(`\nTotal questions loaded: ${allQuestions.length}`);

// Check for duplicate IDs
const idMap = new Map();
const duplicates = [];

allQuestions.forEach(q => {
    if (idMap.has(q.id)) {
        duplicates.push(q.id);
    }
    idMap.set(q.id, true);
});

if (duplicates.length > 0) {
    console.error(`Found ${duplicates.length} duplicate IDs:`, duplicates);
} else {
    console.log('No duplicate IDs found.');
}

// Write merged file
try {
    fs.writeFileSync(outputFile, JSON.stringify(allQuestions, null, 2));
    console.log(`\nSuccessfully merged ${totalBatches} batches into ${outputFile}`);
} catch (error) {
    console.error('Error writing merged file:', error);
}
