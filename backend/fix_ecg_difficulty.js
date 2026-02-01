const db = require('./src/config/db');

async function fixDifficultyColumn() {
    try {
        console.log("Altering difficulty column to VARCHAR...");
        await db.query(`
      ALTER TABLE ecg_cases 
      ALTER COLUMN difficulty TYPE VARCHAR(50);
    `);
        console.log("Success: difficulty is now VARCHAR.");
    } catch (err) {
        console.error("Error altering column:", err.message);
    } finally {
        process.exit();
    }
}

fixDifficultyColumn();
