const fs = require('fs');
const https = require('https');
const path = require('path');

// Configuration
const FILE = path.join(__dirname, '../../../backend/src/data/questions/tk7_combined_bilingual.json');
const BATCH_SIZE = 2;
const DELAY_MS = 2000;
const REQUEST_DELAY_MS = 500;

/**
 * Translate text from English to Hungarian using Google Translate API.
 * Returns original text on failure to avoid breaking the data.
 */
function translateText(text) {
    if (!text || text.trim().length === 0) {
        return Promise.resolve(text);
    }

    const url = `https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=hu&dt=t&q=${encodeURIComponent(text)}`;

    return new Promise(function (resolve) {
        setTimeout(function () {
            https.get(url, function (res) {
                if (res.statusCode !== 200) {
                    console.error(`API Error ${res.statusCode}`);
                    res.resume();
                    return resolve(text);
                }

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
                    } catch (_e) {
                        resolve(text);
                    }
                });
            }).on('error', function () {
                resolve(text);
            });
        }, REQUEST_DELAY_MS);
    });
}

/**
 * Check if a field needs re-translation (en === hu and length > 5).
 */
function needsTranslation(enValue, huValue) {
    return enValue && huValue === enValue && enValue.length > 5;
}

/**
 * Process a single question and fix missing translations.
 */
async function processQuestion(question) {
    let fixedCount = 0;

    if (needsTranslation(question.question_text_en, question.question_text_hu)) {
        const newText = await translateText(question.question_text_en);
        if (newText !== question.question_text_hu) {
            question.question_text_hu = newText;
            fixedCount++;
        }
    }

    if (needsTranslation(question.explanation_en, question.explanation_hu)) {
        const newText = await translateText(question.explanation_en);
        if (newText !== question.explanation_hu) {
            question.explanation_hu = newText;
            fixedCount++;
        }
    }

    return fixedCount;
}

/**
 * Main function to fix missing translations in the question file.
 */
async function fixTranslations() {
    console.log(`Reading from ${FILE}...`);

    if (!fs.existsSync(FILE)) {
        console.error("File not found.");
        process.exit(1);
    }

    const questions = JSON.parse(fs.readFileSync(FILE, 'utf8'));
    let fixedCount = 0;

    // Find questions where en === hu (likely missing translation)
    const candidates = questions.filter(function (q) {
        return needsTranslation(q.question_text_en, q.question_text_hu) ||
            needsTranslation(q.explanation_en, q.explanation_hu);
    });

    console.log(`Found ${candidates.length} questions potentially missing translations.`);

    const totalBatches = Math.ceil(candidates.length / BATCH_SIZE);

    for (let i = 0; i < candidates.length; i += BATCH_SIZE) {
        const batch = candidates.slice(i, i + BATCH_SIZE);
        const batchNum = Math.floor(i / BATCH_SIZE) + 1;
        console.log(`Fixing batch ${batchNum}/${totalBatches}...`);

        const results = await Promise.all(batch.map(processQuestion));
        fixedCount += results.reduce(function (sum, count) { return sum + count; }, 0);

        if (i + BATCH_SIZE < candidates.length) {
            await new Promise(function (r) { setTimeout(r, DELAY_MS); });
        }
    }

    console.log(`Fixed ${fixedCount} fields. Saving...`);
    fs.writeFileSync(FILE, JSON.stringify(questions, null, 2));
    console.log("Done.");
}

fixTranslations();
