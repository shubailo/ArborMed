const db = require('../config/db');
const adaptiveEngine = require('../services/adaptiveEngine');

async function runTest() {
    try {
        console.log("Fetching user...");
        const uRes = await db.query("SELECT id FROM users LIMIT 1");
        if (uRes.rows.length === 0) {
            console.log("No users found.");
            return;
        }
        const userId = uRes.rows[0].id;

        console.log("Fetching topic...");
        const tRes = await db.query("SELECT slug FROM topics LIMIT 1");
        if (tRes.rows.length === 0) {
            console.log("No topics found.");
            return;
        }
        const topicSlug = tRes.rows[0].slug;

        console.log(`Starting test for User ${userId}, Topic ${topicSlug}...`);

        // Simulate correct answer
        const result = await adaptiveEngine.processAnswerResult(userId, topicSlug, true, null, 1);
        console.log("Adaptive Engine Result:", result);

    } catch (err) {
        console.error("Manual test failed:", err);
    } finally {
        process.exit();
    }
}

runTest();
