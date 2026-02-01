const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
});

async function checkData() {
    try {
        console.log('=== CHECKING TOPICS ===');
        const topics = await pool.query('SELECT id, name_en, name_hu FROM topics ORDER BY id LIMIT 20');
        console.log(`Found ${topics.rows.length} topics:`);
        topics.rows.forEach(t => {
            console.log(`  ID: ${t.id}, EN: ${t.name_en}, HU: ${t.name_hu}`);
        });

        console.log('\n=== CHECKING QUESTIONS ===');
        const questions = await pool.query('SELECT COUNT(*) as count FROM questions');
        console.log(`Total questions: ${questions.rows[0].count}`);

        const sampleQ = await pool.query('SELECT id, topic_id, text_en FROM questions ORDER BY id LIMIT 5');
        console.log('Sample questions:');
        sampleQ.rows.forEach(q => {
            console.log(`  ID: ${q.id}, Topic: ${q.topic_id}, Text: ${q.text_en?.substring(0, 50)}...`);
        });

        process.exit(0);
    } catch (error) {
        console.error('Error:', error.message);
        process.exit(1);
    }
}

checkData();
