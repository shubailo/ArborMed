const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, 'backend/.env') });

const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

async function checkTopics() {
    try {
        const res = await pool.query("SELECT id, name_en, slug, parent_id FROM topics WHERE slug = 'pathophysiology' OR parent_id IN (SELECT id FROM topics WHERE slug = 'pathophysiology')");
        console.log(JSON.stringify(res.rows, null, 2));

        // Also check questions count per topic
        const qCount = await pool.query("SELECT topic_id, COUNT(*) as count FROM questions GROUP BY topic_id");
        console.log('Question counts:', JSON.stringify(qCount.rows, null, 2));

        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

checkTopics();
