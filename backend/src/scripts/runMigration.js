const fs = require('fs');
const path = require('path');
const db = require('../config/db');

async function runMigration() {
    try {
        const sqlPath = path.join(__dirname, '../models/036_question_reports_simple.sql');
        const sql = fs.readFileSync(sqlPath, 'utf8');

        console.log('Running simplified migration...');
        await db.query(sql);
        console.log('simplified Migration completed successfully.');
        process.exit(0);
    } catch (err) {
        console.error('Migration failed:', err);
        process.exit(1);
    }
}

runMigration();
