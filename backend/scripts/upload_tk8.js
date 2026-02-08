
const fs = require('fs');
const path = require('path');
const db = require('../src/config/db');

const INPUT_FILE = path.join(__dirname, '../src/data/questions/tk8_combined_bilingual.json');

async function uploadQuestions() {
    try {
        console.log('Starting TK8 upload process...');

        // 1. Ensure Topic Hierarchy
        let pathophysiologyId;
        let res = await db.query("SELECT id FROM topics WHERE slug = 'pathophysiology'");
        if (res.rows.length === 0) {
            console.log("Creating Pathophysiology topic...");
            res = await db.query("INSERT INTO topics (name_en, slug) VALUES ('Pathophysiology', 'pathophysiology') RETURNING id");
        }
        pathophysiologyId = res.rows[0].id;

        // 2. Ensure TK8 Topic: Metabolism and Thermoregulation
        let tk8TopicId;
        const topicSlug = 'metabolism-and-thermoregulation';
        res = await db.query("SELECT id FROM topics WHERE slug = $1 AND parent_id = $2", [topicSlug, pathophysiologyId]);

        if (res.rows.length > 0) {
            tk8TopicId = res.rows[0].id;
            console.log(`Found existing topic: Metabolism and Thermoregulation (ID: ${tk8TopicId})`);
        } else {
            console.log("Creating 'Metabolism and Thermoregulation' under Pathophysiology...");
            res = await db.query(
                "INSERT INTO topics (name_en, name_hu, slug, parent_id) VALUES ($1, $2, $3, $4) RETURNING id",
                ['Metabolism and Thermoregulation', 'Anyagcsere és Hőszabályozás', topicSlug, pathophysiologyId]
            );
            tk8TopicId = res.rows[0].id;
        }

        // Optional: Clear existing questions if re-running
        // console.log(`Clearing existing questions for Topic ID ${tk8TopicId}...`);
        // await db.query("DELETE FROM questions WHERE topic_id = $1 AND question_text_en LIKE 'tk8_%'", [tk8TopicId]);

        // 3. Read Questions
        if (!fs.existsSync(INPUT_FILE)) {
            console.error(`Input file not found: ${INPUT_FILE}`);
            process.exit(1);
        }

        const questions = JSON.parse(fs.readFileSync(INPUT_FILE, 'utf8'));
        console.log(`Uploading ${questions.length} questions to Topic ID ${tk8TopicId}...`);

        let successCount = 0;
        let errorCount = 0;

        for (const q of questions) {
            try {
                const optionsJson = JSON.stringify({
                    en: q.options_en || [],
                    hu: q.options_hu || []
                });

                // Use 'relation_analysis' as the canonical type ID
                const typeId = q.type === 'relational_analysis' ? 'relation_analysis' : (q.type || 'single_choice');

                await db.query(`
                    INSERT INTO questions (
                        topic_id, 
                        question_text_en, question_text_hu,
                        explanation_en, explanation_hu,
                        options, 
                        correct_answer, 
                        difficulty, bloom_level,
                        type, question_type,
                        created_by
                    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
                `, [
                    tk8TopicId,
                    q.question_text_en, q.question_text_hu || '',
                    q.explanation_en, q.explanation_hu || '',
                    optionsJson,
                    q.correct_answer,
                    q.bloom_level || 1,
                    q.bloom_level || 1,
                    typeId, // legacy type
                    typeId, // new type
                    null
                ]);
                successCount++;
                if (successCount % 50 === 0) process.stdout.write('.');
            } catch (err) {
                console.error(`\nFailed to upload question: ${q.id}. Error: ${err.message}`);
                errorCount++;
            }
        }

        console.log(`\nUpload complete. Success: ${successCount}, Errors: ${errorCount}`);
        process.exit(0);

    } catch (error) {
        console.error('Fatal error during upload:', error);
        process.exit(1);
    }
}

uploadQuestions();
