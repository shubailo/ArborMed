const { pool } = require('../src/config/db');
const fs = require('fs');
const path = require('path');

async function runMigration() {
    console.log('--- Running Migration: room_likes ---');
    const sqlPath = path.join(__dirname, '../src/models/033_social_like_protection.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');

    try {
        await pool.query(sql);
        console.log('✅ Migration successful!');
    } catch (err) {
        console.error('❌ Migration failed:', err.message);
    } finally {
        await pool.end();
    }
}

runMigration();
