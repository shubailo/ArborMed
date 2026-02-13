const db = require('./src/config/db');
const fs = require('fs');
const path = require('path');

async function applyMigration() {
    try {
        const sqlPath = path.join(__dirname, 'src/models/036_question_reports.sql');
        const sql = fs.readFileSync(sqlPath, 'utf8');

        console.log('Applying migration: 036_question_reports.sql...');
        await db.query(sql);
        console.log('Migration applied successfully.');

    } catch (err) {
        console.error('Failed to apply migration:', err);
    } finally {
        process.exit();
    }
}

applyMigration();
