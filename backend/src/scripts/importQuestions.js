const fs = require('fs');
const path = require('path');
const db = require('../config/db');

/**
 * Bulk Import Questions from a JSON file.
 */
const importQuestions = async () => {
    try {
        const filePath = path.join(__dirname, '../../../my_questions.json');

        if (!fs.existsSync(filePath)) {
            console.error('❌ Error: my_questions.json not found in the project root.');
            process.exit(1);
        }

        const data = fs.readFileSync(filePath, 'utf8');
        const questions = JSON.parse(data);

        console.log(`📥 Starting import of ${questions.length} questions...`);

        for (const q of questions) {
            // Support both underscored and non-underscored keys
            const topicSlug = q.topic_slug || q.topicslug;
            const topicName = q.topic || "General";
            const bloomLevel = q.bloom_level || q.bloomlevel || 1;
            const correctIndex = (q.correct_index !== undefined) ? q.correct_index : q.correctindex;
            const text = q.text;
            const options = q.options;

            if (!topicSlug || !text || !options || correctIndex === undefined) {
                console.warn(`⚠️ Skipping invalid question: ${text?.substring(0, 20)}`);
                continue;
            }

            // 1. Ensure Topic exists
            const topicRes = await db.query(
                "SELECT id FROM topics WHERE slug = $1",
                [topicSlug]
            );

            let topicId;
            if (topicRes.rows.length === 0) {
                console.log(`🔍 Creating new topic: ${topicName} (${topicSlug})`);
                const inserted = await db.query(
                    "INSERT INTO topics (name, slug, parent_id) VALUES ($1, $2, 1) RETURNING id",
                    [topicName, topicSlug]
                );
                topicId = inserted.rows[0].id;
            } else {
                topicId = topicRes.rows[0].id;
            }

            // 2. Insert Question
            await db.query(
                `INSERT INTO questions (topic_id, text, options, correct_answer, bloom_level, type, difficulty)
                 VALUES ($1, $2, $3, $4, $5, $6, $7)`,
                [
                    topicId,
                    text,
                    JSON.stringify(options),
                    correctIndex,
                    bloomLevel,
                    'multiple_choice',
                    1
                ]
            );

            console.log(`✅ Added: "${text.substring(0, 30)}..."`);
        }

        console.log('🚀 Bulk import complete!');
        process.exit();
    } catch (err) {
        console.error('❌ Import failed:', err);
        process.exit(1);
    }
};

importQuestions();
