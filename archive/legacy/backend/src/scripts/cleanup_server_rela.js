const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

async function cleanupRelational() {
    console.log('--- STARTING SERVER CLEANUP: RELATIONAL ANALYSIS (ALL VARIANTS) ---');
    try {
        const targetTypes = ['relational_analysis', 'relation_analysis'];

        // 1. Get counts before deletion
        const beforeRes = await pool.query("SELECT type, COUNT(*) FROM questions WHERE type = ANY($1) GROUP BY type", [targetTypes]);
        console.log('Current counts in database:');
        beforeRes.rows.forEach(r => console.log(`  ${r.type}: ${r.count}`));

        // 2. Delete dependencies first
        console.log('Cleaning up dependencies...');
        const qIdsRes = await pool.query("SELECT id FROM questions WHERE type = ANY($1)", [targetTypes]);
        const qIds = qIdsRes.rows.map(r => r.id);

        if (qIds.length > 0) {
            await pool.query('DELETE FROM responses WHERE question_id = ANY($1)', [qIds]);
            await pool.query('DELETE FROM question_performance WHERE question_id = ANY($1)', [qIds]);
            console.log(`Cleaned up dependencies for ${qIds.length} questions.`);
        }

        // 3. Delete the questions
        const delRes = await pool.query("DELETE FROM questions WHERE type = ANY($1)", [targetTypes]);
        console.log(`Successfully deleted ${delRes.rowCount} questions from 'questions' table.`);

        // 4. Verify count
        const afterRes = await pool.query("SELECT COUNT(*) FROM questions WHERE type = ANY($1)", [targetTypes]);
        console.log(`Final Database Count for target types: ${afterRes.rows[0].count}`);

        process.exit(0);
    } catch (err) {
        console.error('--- CLEANUP FAILED ---');
        console.error(err);
        process.exit(1);
    }
}

cleanupRelational();
