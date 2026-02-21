const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

async function checkTopics() {
    try {
        console.log('[DRY RUN] Checking topics and questions...');
        const topicsRes = await pool.query("SELECT id, name_en, slug, parent_id FROM topics WHERE slug = 'pathophysiology' OR parent_id IN (SELECT id FROM topics WHERE slug = 'pathophysiology')");
        console.log('Topics found:', JSON.stringify(topicsRes.rows, null, 2));

        // Also check questions table columns and defaults
        const cols = await pool.query("SELECT column_name, column_default FROM information_schema.columns WHERE table_name = 'questions'");
        console.log('Question columns and defaults:', JSON.stringify(cols.rows, null, 2));

        // Check is_active status for new questions
        const qStatus = await pool.query("SELECT id, topic_id, is_active FROM questions ORDER BY created_at DESC LIMIT 10");
        console.log('Latest questions status:', JSON.stringify(qStatus.rows, null, 2));

        // Also check questions count per topic
        const qCount = await pool.query(`
      SELECT t.name_en, t.id as topic_id, COUNT(q.id) as question_count 
      FROM topics t
      LEFT JOIN questions q ON q.topic_id = t.id
      WHERE t.slug = 'pathophysiology' OR t.parent_id IN (SELECT id FROM topics WHERE slug = 'pathophysiology')
      GROUP BY t.id, t.name_en
    `);
        console.log('Question counts by topic:', JSON.stringify(qCount.rows, null, 2));

        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

checkTopics();
