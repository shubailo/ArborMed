const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

async function checkCounts() {
    console.log('🔍 Question Counts per Topic Slug...\n');
    try {
        const res = await pool.query(`
      SELECT 
        t.slug, 
        COUNT(q.id) as total_questions,
        COUNT(q.id) FILTER (WHERE q.active = TRUE) as active_questions
      FROM topics t
      LEFT JOIN questions q ON q.topic_id = t.id
      GROUP BY t.slug
      HAVING COUNT(q.id) > 0
      ORDER BY active_questions DESC
    `);

        res.rows.forEach(r => {
            console.log(`${r.slug.padEnd(60)}: Total=${r.total_questions}, Active=${r.active_questions}`);
        });

        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

checkCounts();
