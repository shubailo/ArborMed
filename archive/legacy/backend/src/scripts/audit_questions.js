const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

async function auditQuestions() {
    console.log('🔍 Auditing Recently Added Questions...\n');
    try {
        const res = await pool.query(`
      SELECT 
        q.id, 
        q.question_text_en, 
        q.active, 
        q.bloom_level, 
        q.topic_id, 
        t.name_en as topic_name, 
        t.slug as topic_slug,
        p.name_en as parent_topic,
        q.created_at
      FROM questions q
      JOIN topics t ON q.topic_id = t.id
      LEFT JOIN topics p ON t.parent_id = p.id
      ORDER BY q.created_at DESC
      LIMIT 10
    `);

        if (res.rows.length === 0) {
            console.log('⚠️  No questions found in the database.');
        } else {
            res.rows.forEach(r => {
                console.log(`ID: ${r.id}`);
                console.log(`Text: ${r.question_text_en?.substring(0, 50)}...`);
                console.log(`Active: ${r.active}`);
                console.log(`Bloom: ${r.bloom_level}`);
                console.log(`Topic: ${r.topic_name} (${r.topic_slug})`);
                console.log(`Parent: ${r.parent_topic}`);
                console.log(`Created: ${r.created_at}`);
                console.log('---');
            });
        }

        // Also check for questions that might have NULL bloom_level or other issues
        const issuesRes = await pool.query(`
      SELECT COUNT(*) as count, 'Missing Bloom Level' as issue FROM questions WHERE bloom_level IS NULL
      UNION ALL
      SELECT COUNT(*) as count, 'Inactive' as issue FROM questions WHERE active = FALSE
      UNION ALL
      SELECT COUNT(*) as count, 'Missing Question Text' as issue FROM questions WHERE question_text_en IS NULL AND content IS NULL
    `);

        console.log('\nPotential Data Issues:');
        issuesRes.rows.forEach(i => console.log(` - ${i.issue}: ${i.count}`));

        process.exit(0);
    } catch (err) {
        console.error('💥 Audit failed:', err);
        process.exit(1);
    }
}

auditQuestions();
