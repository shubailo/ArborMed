const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

async function checkStats() {
    try {
        // 1. Group by Type
        const typeRes = await pool.query("SELECT type, COUNT(*) as count FROM questions GROUP BY type ORDER BY count DESC");
        console.log('--- BY TYPE ---');
        typeRes.rows.forEach(row => {
            console.log(`Type: ${row.type.padEnd(20)} | Count: ${row.count}`);
        });

        // 2. Group by Bloom Level
        const bloomRes = await pool.query("SELECT bloom_level, COUNT(*) as count FROM questions GROUP BY bloom_level ORDER BY bloom_level ASC");
        console.log('\n--- BY BLOOM LEVEL ---');
        bloomRes.rows.forEach(row => {
            console.log(`Bloom Level: ${row.bloom_level} | Count: ${row.count}`);
        });

        const totalRes = await pool.query("SELECT COUNT(*) FROM questions");
        console.log(`\nTOTAL QUESTIONS: ${totalRes.rows[0].count}`);

        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

checkStats();
