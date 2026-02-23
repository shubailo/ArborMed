const fs = require('fs');
const path = require('path');
const { validateQuestion } = require('./question_validator');

const QUESTIONS_DIR = path.join(__dirname, '../../../backend/src/data/questions');
const OUTPUT_FILE = path.join(__dirname, '../../../backend/src/data/questions/tk7_combined_en.json');

/**
 * Combines and validates batch question files into a single output.
 */
function processFiles() {
    const files = fs.readdirSync(QUESTIONS_DIR).filter(f => f.startsWith('tk7_batch_') && f.endsWith('.json'));
    console.log(`Found ${files.length} batch files.`);

    let allQuestions = [];
    let validationErrors = 0;

    files.forEach(file => {
        const content = fs.readFileSync(path.join(QUESTIONS_DIR, file), 'utf8');
        try {
            const questions = JSON.parse(content);
            questions.forEach((q, idx) => {
                const issues = validateQuestion(q, file);
                if (issues.length > 0) {
                    // console.error(`[${file}:Q${idx}] Validation Failed: ${issues.join('; ')}`);
                    fs.appendFileSync('validation_errors.log', `[${file} Q${idx + 1}] ${issues.join('; ')}\n`);
                    validationErrors++;
                } else {
                    // Normalize structure for combined file
                    allQuestions.push({
                        id: `${file.replace('.json', '')}_${q.id}`, // Force unique ID
                        original_id: q.id,
                        source_file: file,
                        type: q.type,
                        bloom_level: q.bloom_level,
                        question_text: q.question_text,
                        options: q.options,
                        correct_answer: q.correct_answer,
                        explanation: q.explanation
                    });
                }
            });
        } catch (err) {
            console.error(`Error parsing ${file}: ${err.message}`);
        }
    });

    console.log(`\nProcessed ${allQuestions.length} valid questions.`);
    console.log(`Validation errors encountered: ${validationErrors}`);

    fs.writeFileSync(OUTPUT_FILE, JSON.stringify(allQuestions, null, 2));
    console.log(`Saved combined file to ${OUTPUT_FILE}`);
}

processFiles();
