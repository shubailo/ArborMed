const db = require('../config/db');
const fs = require('fs');
const path = require('path');

async function seedQuestionBank() {
    try {
        console.log('🚀 Starting Modular Question Bank Seeding...');

        const subjects = ['pathophysiology', 'pathology'];
        const baseDir = path.join(__dirname, '../data/questions');

        for (const subject of subjects) {
            console.log(`\n📂 Processing Subject: ${subject.toUpperCase()}`);

            // Get parent topic ID
            const parentRes = await db.query("SELECT id FROM topics WHERE slug = $1", [subject]);
            if (parentRes.rows.length === 0) {
                console.warn(`⚠️ Parent topic '${subject}' not found. Skipping...`);
                continue;
            }
            const parentId = parentRes.rows[0].id;

            const subjectDir = path.join(baseDir, subject);
            if (!fs.existsSync(subjectDir)) {
                console.warn(`⚠️ Directory ${subjectDir} does not exist. Skipping...`);
                continue;
            }

            const files = fs.readdirSync(subjectDir).filter(f => f.endsWith('.json'));

            for (const file of files) {
                const topicSlug = file.replace('.json', '');
                // Special mapping for slugs that differ from filenames if needed
                let actualSlug = topicSlug;
                if (subject === 'pathophysiology' && topicSlug === 'haematology') actualSlug = 'haematology-system';
                if (subject === 'pathophysiology' && topicSlug === 'nervous-system') actualSlug = 'nervous-system-patho';

                console.log(`  📄 Seeding Topic: ${actualSlug}`);

                // 1. Ensure topic exists under parent
                let topicRes = await db.query("SELECT id, name FROM topics WHERE slug = $1", [actualSlug]);
                let topicId;

                // Cleaner name generation: handle hyphens and CamelCase
                const cleanName = actualSlug
                    .replace(/([A-Z])/g, ' $1') // Handle camelCase
                    .split(/[- ]/)              // Split by hyphen or space
                    .filter(w => w.length > 0)
                    .map(w => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase())
                    .join(' ');

                if (topicRes.rows.length === 0) {
                    const inserted = await db.query(
                        "INSERT INTO topics (name, slug, parent_id) VALUES ($1, $2, $3) RETURNING id",
                        [cleanName, actualSlug, parentId]
                    );
                    topicId = inserted.rows[0].id;
                } else {
                    topicId = topicRes.rows[0].id;
                    // Proactively fix name and parent logic for existing topics
                    await db.query(
                        "UPDATE topics SET name = $1, parent_id = $2 WHERE id = $3",
                        [cleanName, parentId, topicId]
                    );
                }

                // 2. Read questions
                const questionsData = JSON.parse(fs.readFileSync(path.join(subjectDir, file), 'utf8'));

                // 3. Clear existing for this topic to avoid duplicates
                await db.query(`DELETE FROM responses WHERE question_id IN (SELECT id FROM questions WHERE topic_id = $1)`, [topicId]);
                await db.query("DELETE FROM questions WHERE topic_id = $1", [topicId]);

                // 4. Insert New Questions
                for (const q of questionsData) {
                    await db.query(
                        `INSERT INTO questions (topic_id, text, options, correct_answer, bloom_level, type, difficulty)
                         VALUES ($1, $2, $3, $4, $5, 'multiple_choice', 1)`,
                        [topicId, q.text, JSON.stringify(q.options), q.correct_index, q.bloom_level]
                    );
                }
                console.log(`    ✅ Seeded ${questionsData.length} questions.`);
            }
        }

        console.log('\n✨ Question Bank Seeding Complete!');
        process.exit(0);
    } catch (err) {
        console.error('❌ Seeding failed:', err);
        process.exit(1);
    }
}

seedQuestionBank();
