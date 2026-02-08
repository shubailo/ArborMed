
const fs = require('fs');
const path = require('path');

const QUESTIONS_DIR = path.join(__dirname, '../backend/src/data/questions');
const OUTPUT_FILE = path.join(__dirname, '../backend/src/data/questions/tk8_combined_en.json');

// Helper to validate a single question
function validateQuestion(q, fileName) {
    const issues = [];
    if (!q.question_text || q.question_text.length < 5) issues.push('Question text missing or too short');
    if (!q.correct_answer) issues.push('Correct answer missing');
    if (q.type !== 'relation_analysis' && (!q.options || !Array.isArray(q.options) || q.options.length < 2)) {
        issues.push('Options missing or insufficient');
    }

    return issues;
}

// Main processing function
function processFiles() {
    // Filter for normalized tk8 batches
    const files = fs.readdirSync(QUESTIONS_DIR).filter(f => f.startsWith('tk8_batch_') && f.endsWith('.json'));
    console.log(`Found ${files.length} TK8 batch files.`);

    // Sort files numerically by batch number
    files.sort((a, b) => {
        const numA = parseInt(a.match(/batch_(\d+)/)[1]);
        const numB = parseInt(b.match(/batch_(\d+)/)[1]);
        return numA - numB;
    });

    let allQuestions = [];
    let validationErrors = 0;
    const errorLog = 'validation_errors_tk8.log';

    if (fs.existsSync(errorLog)) fs.unlinkSync(errorLog);

    files.forEach(file => {
        const content = fs.readFileSync(path.join(QUESTIONS_DIR, file), 'utf8');
        try {
            const questions = JSON.parse(content);
            questions.forEach((q, idx) => {
                const issues = validateQuestion(q, file);
                if (issues.length > 0) {
                    fs.appendFileSync(errorLog, `[${file} Q${idx + 1}] ${issues.join('; ')}\n`);
                    validationErrors++;
                } else {
                    // Normalize structure for combined file
                    allQuestions.push({
                        ...q,
                        source_file: file,
                        tk_source: 'tk8'
                    });
                }
            });
        } catch (err) {
            console.error(`Error parsing ${file}: ${err.message}`);
        }
    });

    console.log(`\nProcessed ${allQuestions.length} valid TK8 questions.`);
    console.log(`Validation errors encountered: ${validationErrors}`);
    if (validationErrors > 0) {
        console.log(`Check ${errorLog} for details.`);
    }

    fs.writeFileSync(OUTPUT_FILE, JSON.stringify(allQuestions, null, 2));
    console.log(`Saved combined file to ${OUTPUT_FILE}`);
}

processFiles();
