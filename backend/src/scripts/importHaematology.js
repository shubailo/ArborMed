const fs = require('fs');
const path = require('path');
const db = require('../config/db');

const FILE_PATH = path.join(__dirname, '../data/questions/haematology_questions.json');
const TARGET_TOPIC_ID = 85; // Haematology

const importHaematology = async () => {
    try {
        if (!fs.existsSync(FILE_PATH)) {
            console.error(`❌ Error: ${FILE_PATH} not found.`);
            process.exit(1);
        }

        const questions = JSON.parse(fs.readFileSync(FILE_PATH, 'utf8'));
        console.log(`📥 Starting import of ${questions.length} bilingual questions...`);
        console.log(`ℹ️  Note: Using 'metadata->external_id' for idempotency (bypassing schema lock).`);

        let count = 0;
        let updated = 0;
        let inserted = 0;

        for (const q of questions) {
            // Check if exists by external_id in metadata
            const checkRes = await db.query(
                "SELECT id FROM questions WHERE metadata->>'external_id' = $1",
                [q.id]
            );

            const metadata = {
                external_id: q.id,
                source: 'hd_merge_v1',
                imported_at: new Date().toISOString()
            };

            const optionsJson = JSON.stringify(q.options);

            if (checkRes.rows.length > 0) {
                // UPDATE
                const updateQuery = `
                    UPDATE questions SET
                        topic_id = $1,
                        type = $2,
                        bloom_level = $3,
                        difficulty = $4,
                        question_text_en = $5,
                        question_text_hu = $6,
                        options = $7,
                        correct_answer = $8,
                        explanation_en = $9,
                        explanation_hu = $10,
                        metadata = $11,
                        updated_at = CURRENT_TIMESTAMP
                    WHERE id = $12
                `;
                const updateValues = [
                    TARGET_TOPIC_ID,
                    q.type,
                    q.bloom_level || 1,
                    q.difficulty || 1,
                    q.question_text_en,
                    q.question_text_hu,
                    optionsJson,
                    q.correct_answer_en,
                    q.explanation_en,
                    q.explanation_hu,
                    JSON.stringify(metadata),
                    checkRes.rows[0].id
                ];
                await db.query(updateQuery, updateValues);
                updated++;
            } else {
                // INSERT
                const insertQuery = `
                    INSERT INTO questions (
                        topic_id,
                        type,
                        bloom_level,
                        difficulty,
                        question_text_en,
                        question_text_hu,
                        options,
                        correct_answer,
                        explanation_en,
                        explanation_hu,
                        metadata,
                        active
                    )
                    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, true)
                `;
                const insertValues = [
                    TARGET_TOPIC_ID,
                    q.type,
                    q.bloom_level || 1,
                    q.difficulty || 1,
                    q.question_text_en,
                    q.question_text_hu,
                    optionsJson,
                    q.correct_answer_en,
                    q.explanation_en,
                    q.explanation_hu,
                    JSON.stringify(metadata)
                ];
                await db.query(insertQuery, insertValues);
                inserted++;
            }

            count++;
            if (count % 50 === 0) {
                console.log(`✅ Progress: ${count}/${questions.length} (Ins: ${inserted}, Upd: ${updated})`);
            }
        }

        console.log(`\n🚀 Import Complete!`);
        console.log(`- Total Processed: ${count}`);
        console.log(`- New Questions: ${inserted}`);
        console.log(`- Updated: ${updated}`);

        process.exit();
    } catch (err) {
        console.error('❌ Import failed:', err);
        process.exit(1);
    }
};

importHaematology();
