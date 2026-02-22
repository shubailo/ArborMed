const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

async function checkQuestionDistribution() {
    try {
        const res = await pool.query(`
      SELECT q.topic_id, t.name_en, t.slug, t.parent_id, COUNT(*) 
      FROM questions q
      JOIN topics t ON q.topic_id = t.id
      GROUP BY q.topic_id, t.name_en, t.slug, t.parent_id
      ORDER BY count DESC
    `);
        console.log('Question Distribution:', JSON.stringify(res.rows, null, 2));
        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

checkQuestionDistribution();
