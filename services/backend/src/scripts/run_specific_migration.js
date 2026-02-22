const fs = require('fs');
const db = require('../config/db');

async function runMigration() {
    try {
        const sql = fs.readFileSync('src/models/035_ensure_adaptive_learning.sql', 'utf8');
        console.log("Running migration...");
        await db.query(sql);
        console.log("Migration successful!");
    } catch (err) {
        console.error("Migration failed:", err);
    } finally {
        process.exit();
    }
}

runMigration();
