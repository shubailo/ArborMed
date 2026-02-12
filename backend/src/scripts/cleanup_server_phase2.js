const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

async function cleanupPhase2() {
    console.log('--- STARTING SERVER CLEANUP PHASE 2 ---');
    try {
        // --- 1. REMOVE CASE STUDIES ---
        console.log('\n--- 1. Removing Case Studies ---');
        const caseStudyIdsRes = await pool.query("SELECT id FROM questions WHERE type = 'case_study'");
        const caseStudyIds = caseStudyIdsRes.rows.map(r => r.id);

        if (caseStudyIds.length > 0) {
            await pool.query('DELETE FROM responses WHERE question_id = ANY($1)', [caseStudyIds]);
            await pool.query('DELETE FROM question_performance WHERE question_id = ANY($1)', [caseStudyIds]);
            const delCaseRes = await pool.query("DELETE FROM questions WHERE id = ANY($1)", [caseStudyIds]);
            console.log(`Successfully deleted ${delCaseRes.rowCount} 'case_study' questions.`);
        } else {
            console.log("No 'case_study' questions found.");
        }

        // --- 2. MERGE MATCH TYPE INTO MATCHING ---
        console.log('\n--- 2. Merging Match Type ---');
        const updateMatchRes = await pool.query("UPDATE questions SET type = 'matching' WHERE type = 'match'");
        console.log(`Successfully updated ${updateMatchRes.rowCount} questions from 'match' to 'matching'.`);

        // --- 3. REDUCE TRUE/FALSE BY 50% ---
        console.log('\n--- 3. Reducing True/False Questions by 50% ---');
        const tfRes = await pool.query("SELECT id FROM questions WHERE type = 'true_false'");
        const tfIds = tfRes.rows.map(r => r.id);

        if (tfIds.length > 0) {
            const countToDelete = Math.floor(tfIds.length / 2);
            // Select half of IDs (first half for simplicity, or randomized)
            const idsToDelete = tfIds.slice(0, countToDelete);

            console.log(`Total True/False: ${tfIds.length}. Deleting ${countToDelete}...`);
            await pool.query('DELETE FROM responses WHERE question_id = ANY($1)', [idsToDelete]);
            await pool.query('DELETE FROM question_performance WHERE question_id = ANY($1)', [idsToDelete]);
            const delTFRes = await pool.query("DELETE FROM questions WHERE id = ANY($1)", [idsToDelete]);
            console.log(`Successfully deleted ${delTFRes.rowCount} 'true_false' questions.`);
        } else {
            console.log("No 'true_false' questions found.");
        }

        process.exit(0);
    } catch (err) {
        console.error('\n❌ Phase 2 Cleanup Failed:', err);
        process.exit(1);
    }
}

cleanupPhase2();
