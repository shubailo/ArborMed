
const fs = require('fs');
const https = require('https');
const path = require('path');

const INPUT_FILE = path.join(__dirname, '../backend/src/data/questions/tk8_combined_en.json');
const OUTPUT_FILE = path.join(__dirname, '../backend/src/data/questions/tk8_combined_bilingual.json');

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
                    if (result && result[0]) {
                        const translatedText = result[0].map(item => item[0]).join('');
                        resolve(translatedText);
                    } else {
                        resolve(text);
                    }
                } catch (e) {
                    resolve(text);
                }
            });
        }).on('error', (err) => {
            resolve(text);
        });
    });
}

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
    const BATCH_SIZE = 10;
    const DELAY_MS = 500;

    for (let i = 0; i < questions.length; i += BATCH_SIZE) {
        const batch = questions.slice(i, i + BATCH_SIZE);
        console.log(`Processing batch ${Math.floor(i / BATCH_SIZE) + 1}/${Math.ceil(questions.length / BATCH_SIZE)}...`);

        const translations = await Promise.all(batch.map(async (q) => {
            const newQ = { ...q };
            newQ.question_text_en = q.question_text;
            newQ.question_text_hu = await translateText(q.question_text);
            newQ.explanation_en = q.explanation;
            newQ.explanation_hu = await translateText(q.explanation);

            newQ.options_en = q.options;
            if (Array.isArray(q.options)) {
                newQ.options_hu = await Promise.all(q.options.map(opt => translateText(opt)));
            } else {
                newQ.options_hu = [];
            }

            // Clean up original fields
            delete newQ.question_text;
            delete newQ.explanation;
            delete newQ.options;

            return newQ;
        }));

        translatedQuestions.push(...translations);

        if (i + BATCH_SIZE < questions.length) {
            await new Promise(r => setTimeout(r, DELAY_MS));
        }

        if ((i / BATCH_SIZE) % 5 === 0) {
            fs.writeFileSync(OUTPUT_FILE, JSON.stringify(translatedQuestions, null, 2));
            console.log(`Saved progress (${translatedQuestions.length} questions).`);
        }
    }

    fs.writeFileSync(OUTPUT_FILE, JSON.stringify(translatedQuestions, null, 2));
    console.log('Translation complete. Saved to', OUTPUT_FILE);
}

processQuestions();
