
const fs = require('fs');
const path = require('path');

const QUESTIONS_DIR = path.join(__dirname, '../backend/src/data/questions');
const OUTPUT_FILE = path.join(__dirname, '../backend/src/data/questions/tk7_combined_en.json');

// Helper to validate a single question
function validateQuestion(q, fileName) {
    const issues = [];
    if (!q.question_text || q.question_text.length < 5) issues.push('Question text missing or too short');
    if (!q.correct_answer) issues.push('Correct answer missing');
    if (!q.options || !Array.isArray(q.options) || q.options.length < 2) issues.push('Options missing or insufficient');

    if (q.options && q.correct_answer) {
        // Handle multiple correct answers (semicolon separated)
        const correctAnswers = q.correct_answer.split(';').map(a => a.trim());
        const optionsNormalized = q.options.map(o => o.trim().toLowerCase());

        const missingAnswers = correctAnswers.filter(ans => {
            const ansNorm = ans.toLowerCase();
            // Check formatted matching pair or direct content
            return !optionsNormalized.some(opt => opt === ansNorm || opt.includes(ansNorm) || ansNorm.includes(opt));
        });

        if (missingAnswers.length > 0) {
            // If strict match fails, try fuzzy or lenient check for 'matching' types
            // For matching, the option might be "A -> B" and correct answer "A -> B"
            // The above logic should cover it.
            // If it fails, log it but maybe allow it if it's a known structure?
            // Actually, let's just be permissive if >0 matches found vs 0 matches.
            // But strictness is good. Let's see.
            // If we have 4 options and correct_answer is "A; B; C", we expect A, B, C to be in options.
            // For matching, options are "A->1", "B->2". correct is "A->1; B->2".

            // Relaxation: If at least ONE part matches, we assume it's okay-ish, or just double check logic.
            // Check if specific failures in log were exact matches.
            // Log: "Vitamin B12 -> Glossitis" not found in ["Vitamin B12 -> Glossitis"...]
            // Wait, the log showed they ARE identical strings. 
            // "Vitamin B12 -> Glossitis" vs "Vitamin B12 -> Glossitis"
            // Why did it fail?
            // Ah, the code was: !q.options.includes(q.correct_answer)
            // q.correct_answer was the LONG string "A; B; C".
            // q.options has "A", "B", "C".
            // "A; B; C" is NOT in ["A", "B", "C"].
            // So splitting by semicolon IS the fix.

            issues.push(`Correct answers [${missingAnswers.join('; ')}] not found in options`);
        }
    }

    return issues;
}

// Main processing function
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
