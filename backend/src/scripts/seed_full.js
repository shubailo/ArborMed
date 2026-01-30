const fs = require('fs');
const path = require('path');
const db = require('../config/db');

// Map JSON filename (slug) to Topic Name
const TOPIC_MAP = {
    'cardiovascular': { name: 'Cardiovascular System', id: null },
    'respiratory': { name: 'Respiratory System', id: null },
    'haematology': { name: 'Haematology', id: null },
    'gastrointestinal': { name: 'Gastrointestinal System', id: null },
    'renal': { name: 'Renal System', id: null },
    'endocrine': { name: 'Endocrine System', id: null },
    'neurology': { name: 'Neurology', id: null }
};

const JSON_DIR = path.join(__dirname, '../data/questions/pathophysiology');

const seedFull = async () => {
    try {
        console.log('🌱 Starting Full Seed...');

        // 1. Ensure Topics Exist & Get IDs
        console.log('📋 Syncing Topics...');
        for (const slug of Object.keys(TOPIC_MAP)) {
            const topicName = TOPIC_MAP[slug].name;

            // Insert or Ignore
            await db.query(`
                INSERT INTO topics (name, slug) 
                VALUES ($1, $2) 
                ON CONFLICT (slug) DO NOTHING
            `, [topicName, slug]);

            // Get ID
            const res = await db.query(`SELECT id FROM topics WHERE slug = $1`, [slug]);
            if (res.rows.length > 0) {
                TOPIC_MAP[slug].id = res.rows[0].id;
                console.log(`   ✅ ${topicName} (ID: ${res.rows[0].id})`);
            }
        }

        // 2. Process JSON Files
        const files = fs.readdirSync(JSON_DIR).filter(f => f.endsWith('.json'));

        for (const file of files) {
            const slug = file.replace('.json', '');
            const topicInfo = TOPIC_MAP[slug];

            if (!topicInfo || !topicInfo.id) {
                console.warn(`   ⚠️ Skipping ${file} (Topic not found in map)`);
                continue;
            }

            console.log(`📂 Processing ${file}...`);
            const content = fs.readFileSync(path.join(JSON_DIR, file), 'utf8');
            const questions = JSON.parse(content);

            let insertedCount = 0;
            for (const q of questions) {
                // Convert correct_index to string answer
                const correctOption = q.options[q.correct_index];

                // Sanitize options to string
                const optionsString = JSON.stringify(q.options);

                await db.query(`
                    INSERT INTO questions 
                    (topic_id, text, type, options, correct_answer, bloom_level, difficulty, explanation)
                    VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
                `, [
                    topicInfo.id,
                    q.text,
                    'single_choice',
                    optionsString,
                    correctOption,
                    q.bloom_level || 1, // Default to Bloom 1 if missing
                    1, // Default difficulty
                    q.explanation || 'No explanation provided.'
                ]);
                insertedCount++;
            }
            console.log(`   ✨ Inserted ${insertedCount} questions for ${topicInfo.name}`);
        }

        console.log('✅ Seeding Complete!');
        process.exit(0);
    } catch (err) {
        console.error('❌ Seed Failed:', err);
        process.exit(1);
    }
};

seedFull();
