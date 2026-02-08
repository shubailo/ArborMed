
const fs = require('fs');
const https = require('https');
const path = require('path');

const FILE = path.join(__dirname, '../../../backend/src/data/questions/tk7_combined_bilingual.json');

// Re-use translation function with better error handling
function translateText(text) {
    return new Promise((resolve, reject) => {
        if (!text || text.trim().length === 0) return resolve(text);

        const url = `https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=hu&dt=t&q=${encodeURIComponent(text)}`;

        setTimeout(() => { // Add inherent delay
            https.get(url, (res) => {
                if (res.statusCode !== 200) {
                    console.error(`API Error ${res.statusCode}`);
                    res.resume();
                    return resolve(text); // Fail
                }
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
        }, 500); // 500ms delay before request
    });
}

async function fixTranslations() {
    console.log(`Reading from ${FILE}...`);
    if (!fs.existsSync(FILE)) {
        console.error("File not found.");
        process.exit(1);
    }

    let questions = JSON.parse(fs.readFileSync(FILE, 'utf8'));
    let fixedCount = 0;

    // Identify candidates
    // A primitive check: if en == hu and length > 5 (to avoid short words that are same like "OK")
    const candidates = questions.filter(q =>
        (q.question_text_en && q.question_text_hu === q.question_text_en && q.question_text_en.length > 5) ||
        (q.explanation_en && q.explanation_hu === q.explanation_en && q.explanation_en.length > 5)
    );

    console.log(`Found ${candidates.length} questions potentially missing translations.`);

    // Process candidates with higher delay
    const BATCH_SIZE = 2; // Very small batch
    const DELAY_MS = 2000; // 2 seconds delay

    for (let i = 0; i < candidates.length; i += BATCH_SIZE) {
        const batch = candidates.slice(i, i + BATCH_SIZE);
        console.log(`Fixing batch ${(i / BATCH_SIZE) + 1}/${Math.ceil(candidates.length / BATCH_SIZE)}...`);

        await Promise.all(batch.map(async (q) => {
            // Re-translate items
            if (q.question_text_en === q.question_text_hu) {
                const newText = await translateText(q.question_text_en);
                if (newText !== q.question_text_hu) {
                    q.question_text_hu = newText;
                    fixedCount++;
                }
            }
            if (q.explanation_en === q.explanation_hu) {
                const newText = await translateText(q.explanation_en);
                if (newText !== q.explanation_hu) {
                    q.explanation_hu = newText;
                    fixedCount++;
                }
            }
            // Options - harder to check deeply, skipping for now to save time
        }));

        if (i + BATCH_SIZE < candidates.length) {
            await new Promise(r => setTimeout(r, DELAY_MS));
        }
    }

    console.log(`Fixed ${fixedCount} fields. Saving...`);
    fs.writeFileSync(FILE, JSON.stringify(questions, null, 2));
    console.log("Done.");
}

fixTranslations();
