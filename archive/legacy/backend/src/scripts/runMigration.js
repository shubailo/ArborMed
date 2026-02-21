const fs = require('fs');
const path = require('path');
const db = require('../config/db');

async function runMigration() {
    try {
        const migrationFile = process.argv[2];
        if (!migrationFile) {
            console.error('Please provide a migration file path.');
            process.exit(1);
        }

        const sqlPath = path.resolve(migrationFile);
        if (!fs.existsSync(sqlPath)) {
            console.error(`Migration file not found: ${sqlPath}`);
            process.exit(1);
        }

        const sql = fs.readFileSync(sqlPath, 'utf8');

        console.log(`Running migration: ${path.basename(sqlPath)}...`);
        await db.query(sql);
        console.log('Migration completed successfully.');
        process.exit(0);
    } catch (err) {
        console.error('Migration failed:', err);
        process.exit(1);
    }
}

runMigration();
