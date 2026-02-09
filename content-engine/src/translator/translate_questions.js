const fs = require('fs');
const https = require('https');
const path = require('path');

// Configuration
const INPUT_FILE = path.join(__dirname, '../../../backend/src/data/questions/tk7_combined_en.json');
const OUTPUT_FILE = path.join(__dirname, '../../../backend/src/data/questions/tk7_combined_bilingual.json');
const BATCH_SIZE = 5;
const DELAY_MS = 1000;

/**
 * Translates text from English to Hungarian using Google Translate GTX endpoint.
 * Returns original text on failure.
 */
function translateText(text) {
    if (!text || text.trim().length === 0) {
        return Promise.resolve(text);
    }

    const url = `https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=hu&dt=t&q=${encodeURIComponent(text)}`;

    return new Promise(function (resolve) {
        https.get(url, function (res) {
            let data = '';
            res.on('data', function (chunk) { data += chunk; });
            res.on('end', function () {
                try {
                    const result = JSON.parse(data);
                    if (result && result[0]) {
                        resolve(result[0].map(function (item) { return item[0]; }).join(''));
                    } else {
                        resolve(text);
                    }
                } catch (e) {
                    console.error(`Error parsing translation for "${text.substring(0, 20)}...":`, e.message);
                    resolve(text);
                }
            });
        }).on('error', function (err) {
            console.error(`Error translating "${text.substring(0, 20)}...":`, err.message);
            resolve(text);
        });
    });
}

/**
 * Translates a single question object to bilingual format.
 */
async function translateQuestion(q) {
    const newQ = { ...q };

    newQ.question_text_en = q.question_text;
    newQ.question_text_hu = await translateText(q.question_text);

    newQ.explanation_en = q.explanation;
    newQ.explanation_hu = await translateText(q.explanation);

    newQ.options = {
        en: q.options,
        hu: Array.isArray(q.options)
            ? await Promise.all(q.options.map(function (opt) { return translateText(opt); }))
            : []
    };

    delete newQ.question_text;
    delete newQ.explanation;

    return newQ;
}

/**
 * Processes all questions, translating each field to Hungarian.
 */
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
    const totalBatches = Math.ceil(questions.length / BATCH_SIZE);

    for (let i = 0; i < questions.length; i += BATCH_SIZE) {
        const batch = questions.slice(i, i + BATCH_SIZE);
        const batchNum = Math.floor(i / BATCH_SIZE) + 1;
        console.log(`Processing batch ${batchNum}/${totalBatches}...`);

        const translations = await Promise.all(batch.map(translateQuestion));
        translatedQuestions.push(...translations);

        if (i + BATCH_SIZE < questions.length) {
            await new Promise(function (r) { setTimeout(r, DELAY_MS); });
        }

        // Save progress every 10 batches
        if (batchNum % 10 === 0) {
            fs.writeFileSync(OUTPUT_FILE, JSON.stringify(translatedQuestions, null, 2));
            console.log(`Saved progress (${translatedQuestions.length} questions).`);
        }
    }

    fs.writeFileSync(OUTPUT_FILE, JSON.stringify(translatedQuestions, null, 2));
    console.log('Translation complete. Saved to', OUTPUT_FILE);
}

processQuestions();
