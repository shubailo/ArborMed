
const fs = require('fs');
const path = require('path');
const db = require('../src/config/db');

const INPUT_FILE = path.join(__dirname, '../src/data/questions/tk7_combined_bilingual.json');

async function uploadQuestions() {
    try {
        console.log('Starting upload process...');

        // 1. Ensure Topic Hierarchy
        let pathophysiologyId;

        // Find Pathophysiology
        let res = await db.query("SELECT id FROM topics WHERE slug = 'pathophysiology'");
        if (res.rows.length === 0) {
            console.log("Creating Pathophysiology topic...");
            res = await db.query("INSERT INTO topics (name_en, slug) VALUES ('Pathophysiology', 'pathophysiology') RETURNING id");
        }
        pathophysiologyId = res.rows[0].id;

        // Find GIT System under Pathophysiology
        // We look for a topic with parent_id = pathophysiologyId AND slug associated with GIT
        // Users said "GIT system". Let's name it "Gastrointestinal System" (standard) or "GIT System"
        // Let's search for existing "Gastrointestinal System" first

        let gitTopicId;
        res = await db.query("SELECT id FROM topics WHERE slug = 'gastrointestinal-pathophysiology' OR (slug = 'gastrointestinal' AND parent_id = $1)", [pathophysiologyId]);

        if (res.rows.length > 0) {
            gitTopicId = res.rows[0].id;
            console.log(`Found existing GIT topic (ID: ${gitTopicId})`);
        } else {
            // Create it
            console.log("Creating 'Gastrointestinal System' under Pathophysiology...");
            const slug = 'gastrointestinal-pathophysiology';
            res = await db.query(
                "INSERT INTO topics (name_en, name_hu, slug, parent_id) VALUES ($1, $2, $3, $4) RETURNING id",
                ['Gastrointestinal System', 'Emésztőrendszer', slug, pathophysiologyId]
            );
            gitTopicId = res.rows[0].id;
        }

        // 1b. Clear existing questions for this topic to avoid duplicates
        console.log(`Clearing existing questions for Topic ID ${gitTopicId}...`);
        await db.query("DELETE FROM questions WHERE topic_id = $1", [gitTopicId]);

        // 2. Read Questions
        if (!fs.existsSync(INPUT_FILE)) {
            console.error(`Input file not found: ${INPUT_FILE}`);
            process.exit(1);
        }

        const questions = JSON.parse(fs.readFileSync(INPUT_FILE, 'utf8'));
        console.log(`Uploading ${questions.length} questions to Topic ID ${gitTopicId}...`);

        let successCount = 0;
        let errorCount = 0;

        for (const q of questions) {
            try {
                // Prepare options JSONB
                const optionsJson = JSON.stringify({
                    en: q.options.en || q.options, // Fallback if structure varies
                    hu: q.options.hu || []
                });

                // Insert
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
                    gitTopicId,
                    q.question_text_en, q.question_text_hu || '',
                    q.explanation_en, q.explanation_hu || '',
                    optionsJson,
                    q.correct_answer,
                    q.bloom_level || 1, // Difficulty
                    q.bloom_level || 1, // Bloom
                    q.type || 'single_choice', // Legacy type
                    q.type || 'single_choice', // New type
                    null // System created (or admin ID if available, using null for now or 1)
                ]);
                successCount++;
                if (successCount % 50 === 0) process.stdout.write('.');
            } catch (err) {
                console.error(`\nFailed to upload question: ${q.question_text_en?.substring(0, 30)}... Error: ${err.message}`);
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
