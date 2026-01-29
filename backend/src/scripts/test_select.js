const db = require('../config/db');

async function testSelect() {
    try {
        await db.query("SELECT bloom_level FROM questions LIMIT 1");
        console.log("✅ SELECT bloom_level success.");
        process.exit();
    } catch (err) {
        console.error("❌ SELECT bloom_level failed:", err.message);
        process.exit(1);
    }
}
testSelect();
