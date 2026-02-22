const fs = require('fs');
const path = require('path');
const db = require('../config/db');

async function runMigration() {
    try {
        const sqlPath = path.join(__dirname, '../models/005_iso_coords.sql');
        const sql = fs.readFileSync(sqlPath, 'utf8');

        console.log('Running migration 005...');
        await db.query(sql);
        console.log('Migration 005 completed successfully.');
    } catch (err) {
        console.error('Migration failed:', err);
    } finally {
        await db.pool.end();
    }
}

runMigration();
