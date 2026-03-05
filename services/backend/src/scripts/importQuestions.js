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

        const data = await fs.promises.readFile(filePath, 'utf8');
        const questions = JSON.parse(data);

        console.log(`📥 Starting import of ${questions.length} questions...`);

        // Cache existing topics
        const topicsCache = new Map();
        const existingTopicsRes = await db.query('SELECT slug, id FROM topics');
        existingTopicsRes.rows.forEach(row => {
            topicsCache.set(row.slug, row.id);
        });

        const validQuestions = [];
        const newTopicsToInsert = new Map(); // slug -> name_en

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

            validQuestions.push({
                topicSlug,
                topicName,
                bloomLevel,
                text,
                options,
                correctIndex
            });

            if (!topicsCache.has(topicSlug) && !newTopicsToInsert.has(topicSlug)) {
                newTopicsToInsert.set(topicSlug, topicName);
            }
        }

        // Batch insert new topics
        if (newTopicsToInsert.size > 0) {
            console.log(`🔍 Batch inserting ${newTopicsToInsert.size} new topics...`);
            const topicEntries = Array.from(newTopicsToInsert.entries());
            // Insert topics in chunks of 500
            for (let i = 0; i < topicEntries.length; i += 500) {
                const chunk = topicEntries.slice(i, i + 500);
                const values = [];
                const placeholders = [];
                let paramIndex = 1;

                for (const [slug, name] of chunk) {
                    values.push(name, name, slug);
                    placeholders.push(`($${paramIndex++}, $${paramIndex++}, $${paramIndex++}, 1)`);
                }

                const insertedTopics = await db.query(
                    `INSERT INTO topics (name_en, name_hu, slug, parent_id) VALUES ${placeholders.join(', ')} RETURNING slug, id`,
                    values
                );

                insertedTopics.rows.forEach(row => {
                    topicsCache.set(row.slug, row.id);
                });
            }
        }

        // Batch insert questions
        if (validQuestions.length > 0) {
            console.log(`📥 Batch inserting ${validQuestions.length} valid questions...`);
            for (let i = 0; i < validQuestions.length; i += 500) {
                const chunk = validQuestions.slice(i, i + 500);
                const values = [];
                const placeholders = [];
                let paramIndex = 1;

                for (const q of chunk) {
                    const topicId = topicsCache.get(q.topicSlug);
                    const optionsJson = {
                        en: q.options,
                        hu: []
                    };
                    const correctAnswer = q.options[q.correctIndex];

                    values.push(
                        topicId,
                        q.text,
                        JSON.stringify(optionsJson),
                        correctAnswer,
                        q.bloomLevel,
                        'multiple_choice',
                        1
                    );

                    placeholders.push(`($${paramIndex++}, $${paramIndex++}, $${paramIndex++}, $${paramIndex++}, $${paramIndex++}, $${paramIndex++}, $${paramIndex++})`);
                }

                await db.query(
                    `INSERT INTO questions (topic_id, question_text_en, options, correct_answer, bloom_level, type, difficulty) VALUES ${placeholders.join(', ')}`,
                    values
                );
            }
        }

        console.log('🚀 Bulk import complete!');
        process.exit();
    } catch (err) {
        console.error('❌ Import failed:', err);
        process.exit(1);
    }
};

importQuestions();
