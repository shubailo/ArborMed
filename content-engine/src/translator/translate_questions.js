
const fs = require('fs');
const https = require('https');
const path = require('path');

const INPUT_FILE = path.join(__dirname, '../../../backend/src/data/questions/tk7_combined_en.json');
const OUTPUT_FILE = path.join(__dirname, '../../../backend/src/data/questions/tk7_combined_bilingual.json');

// Simple translation function using Google Translate GTX endpoint
function translateText(text) {
    return new Promise((resolve, reject) => {
        if (!text || text.trim().length === 0) return resolve(text);

        const url = `https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=hu&dt=t&q=${encodeURIComponent(text)}`;

        https.get(url, (res) => {
            let data = '';
            res.on('data', (chunk) => { data += chunk; });
            res.on('end', () => {
                try {
                    const result = JSON.parse(data);
                    // Result format: [[["translated", "original", null, null, 1]], ...]
                    if (result && result[0]) {
                        const translatedText = result[0].map(item => item[0]).join('');
                        resolve(translatedText);
                    } else {
                        resolve(text); // Fallback
                    }
                } catch (e) {
                    console.error(`Error parsing translation for "${text.substring(0, 20)}...":`, e.message);
                    resolve(text); // Fallback
                }
            });
        }).on('error', (err) => {
            console.error(`Error translating "${text.substring(0, 20)}...":`, err.message);
            resolve(text); // Fallback
        });
    });
}

// Processing function
async function processQuestions() {
    console.log(`Reading from ${INPUT_FILE}...`);
    let questions;
    try {
        questions = JSON.parse(fs.readFileSync(INPUT_FILE, 'utf8'));
    } catch (e) {
        console.error("Failed to read input file:", e);
        process.exit(1);
    }

    console.log(`Found ${questions.length} questions. Starting translation...`);
    const translatedQuestions = [];

    // Process in batches to be nice to the API
    const BATCH_SIZE = 5;
    const DELAY_MS = 1000; // 1 second delay between batches

    for (let i = 0; i < questions.length; i += BATCH_SIZE) {
        const batch = questions.slice(i, i + BATCH_SIZE);
        console.log(`Processing batch ${i / BATCH_SIZE + 1}/${Math.ceil(questions.length / BATCH_SIZE)}...`);

        const translations = await Promise.all(batch.map(async (q) => {
            // Clone question
            const newQ = { ...q };

            // Translate Text
            newQ.question_text_en = q.question_text;
            newQ.question_text_hu = await translateText(q.question_text);

            // Translate Explanation
            newQ.explanation_en = q.explanation;
            newQ.explanation_hu = await translateText(q.explanation);

            // Translate Options
            // We need to store options as object { en: [], hu: [] }
            // 'options' in input is array of strings
            newQ.options = {
                en: q.options,
                hu: []
            };

            if (Array.isArray(q.options)) {
                newQ.options.hu = await Promise.all(q.options.map(opt => translateText(opt)));
            }

            // Clean up old fields if desired, but schema uses 'content' jsonb often.
            // For now, keep the new structure clean.
            delete newQ.question_text; // replaced by _en
            delete newQ.explanation;   // replaced by _en
            // delete newQ.options array? The script/upload will handle it.
            // But let's keep the structure consistent with our plan.

            return newQ;
        }));

        translatedQuestions.push(...translations);

        // Delay
        if (i + BATCH_SIZE < questions.length) {
            await new Promise(r => setTimeout(r, DELAY_MS));
        }

        // Save progress every 10 batches (50 questions)
        if ((i / BATCH_SIZE) % 10 === 0) {
            fs.writeFileSync(OUTPUT_FILE, JSON.stringify(translatedQuestions, null, 2));
            console.log(`Saved progress (${translatedQuestions.length} questions).`);
        }
    }

    // Final save
    fs.writeFileSync(OUTPUT_FILE, JSON.stringify(translatedQuestions, null, 2));
    console.log('Translation complete. Saved to', OUTPUT_FILE);
}

processQuestions();
