const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

const QUEST_FILE = path.join(__dirname, '../../data/questions/endocrinology_questions.json');
const TOPIC_ID = 71; // Endocrinology

async function syncEndo() {
    console.log('--- STARTING ENDOCRINOLOGY SYNC ---');
    try {
        // 1. Read JSON file
        if (!fs.existsSync(QUEST_FILE)) {
            throw new Error(`File not found: ${QUEST_FILE}`);
        }
        const data = fs.readFileSync(QUEST_FILE, 'utf8');
        const questions = JSON.parse(data);
        console.log(`Loaded ${questions.length} questions from JSON.`);

        // 2. Delete existing questions for this topic
        console.log(`Deleting existing questions for Topic ID ${TOPIC_ID}...`);

        // Get IDs first to delete dependencies
        const qIdsRes = await pool.query('SELECT id FROM questions WHERE topic_id = $1', [TOPIC_ID]);
        const qIds = qIdsRes.rows.map(r => r.id);

        if (qIds.length > 0) {
            console.log(`Found ${qIds.length} questions to remove. Cleaning up dependencies...`);
            await pool.query('DELETE FROM responses WHERE question_id = ANY($1)', [qIds]);
            await pool.query('DELETE FROM question_performance WHERE question_id = ANY($1)', [qIds]);
            // Removed user_progress deletion as table does not exist

            const delRes = await pool.query('DELETE FROM questions WHERE topic_id = $1', [TOPIC_ID]);
            console.log(`Deleted ${delRes.rowCount} old questions.`);
        } else {
            console.log('No existing questions found for this topic.');
        }

        // 3. Insert new questions
        console.log('Inserting new questions...');
        let insertedCount = 0;

        for (const q of questions) {
            // Construct options JSON
            // Handle structure where 'options' object has 'en'/'hu' arrays
            // For matching, handle 'items' as well

            const optionsJson = {};

            if (q.options) {
                if (q.options.en) optionsJson.en = q.options.en;
                if (q.options.hu) optionsJson.hu = q.options.hu;
                // Fallback for older format if any
                if (q.options_en && !q.options.en) optionsJson.en = q.options_en;
                if (q.options_hu && !q.options.hu) optionsJson.hu = q.options_hu;
            } else {
                optionsJson.en = q.options_en || [];
                optionsJson.hu = q.options_hu || [];
            }

            // Include items for Matching questions
            if (q.items) {
                optionsJson.items = {};
                if (q.items.en) optionsJson.items.en = q.items.en;
                if (q.items.hu) optionsJson.items.hu = q.items.hu;
            }

            const query = `
                INSERT INTO questions (
                    topic_id, 
                    type, 
                    question_type, 
                    bloom_level, 
                    difficulty,
                    question_text_en, 
                    question_text_hu, 
                    explanation_en, 
                    explanation_hu, 
                    correct_answer, 
                    options,
                    created_at,
                    updated_at,
                    active
                ) VALUES ($1, $2, $2, $3, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW(), true)
            `;
            // Note: we use 'type' value for both 'type' and 'question_type' columns to cover legacy/new schemas

            // Ensure bloom_level is integer
            const bloom = parseInt(q.bloom_level) || 1;

            const values = [
                TOPIC_ID,
                q.type,
                bloom,
                q.question_text_en,
                q.question_text_hu,
                q.explanation_en,
                q.explanation_hu,
                q.correct_answer,
                JSON.stringify(optionsJson)
            ];

            await pool.query(query, values);
            insertedCount++;
            if (insertedCount % 50 === 0) process.stdout.write('.');
        }
        console.log(`\n✅ Successfully inserted ${insertedCount} questions.`);

        // 4. Verify count
        const countRes = await pool.query('SELECT COUNT(*) FROM questions WHERE topic_id = $1', [TOPIC_ID]);
        console.log(`Final Database Count for Topic ${TOPIC_ID}: ${countRes.rows[0].count}`);

        process.exit(0);
    } catch (err) {
        console.error('\n❌ Sync Failed:', err);
        process.exit(1);
    }
}

syncEndo();
