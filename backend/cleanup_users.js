const db = require('./src/config/db');

async function cleanData() {
    try {
        console.log("Starting cleanup...");
        const targetEmail = 'shubailobeid@gmail.com';

        // 1. Find the test user IDs
        const usersRes = await db.query("SELECT id FROM users WHERE email != $1", [targetEmail]);
        const testIds = usersRes.rows.map(r => r.id);

        if (testIds.length === 0) {
            console.log("No test users found.");
            return;
        }

        console.log(`Found ${testIds.length} test users. Cleaning up data...`);

        // 2. Cascade delete responses
        await db.query("DELETE FROM responses WHERE session_id IN (SELECT id FROM quiz_sessions WHERE user_id = ANY($1))", [testIds]);

        // 3. Delete sessions
        await db.query("DELETE FROM quiz_sessions WHERE user_id = ANY($1)", [testIds]);

        // 4. Delete progress
        await db.query("DELETE FROM user_topic_progress WHERE user_id = ANY($1)", [testIds]);

        // 5. Delete users
        const finalRes = await db.query("DELETE FROM users WHERE id = ANY($1)", [testIds]);

        console.log(`Successfully deleted ${finalRes.rowCount} users and their history.`);
    } catch (err) {
        console.error("Cleanup failed:", err);
    } finally {
        process.exit(0);
    }
}

cleanData();
