const db = require('../config/db');
const fs = require('fs');
const path = require('path');

async function migrate() {
    try {
        console.log('🚀 Running 005_iso_coords.sql migration...');
        const sqlPath = path.join(__dirname, '../models/005_iso_coords.sql');
        const sql = fs.readFileSync(sqlPath, 'utf8');

        await db.query(sql);
        console.log('✅ Migration successful! Columns added.');
    } catch (e) {
        console.error('❌ Migration failed (might already exist):', e.message);
    } finally {
        process.exit();
    }
}

migrate();
