const { Pool } = require('pg');
require('dotenv').config({ path: './backend/.env' });

const pool = new Pool({
    connectionString: process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/med_buddy_app'
});

async function checkTopics() {
    try {
        const res = await pool.query("SELECT id, name_en, name_hu FROM topics WHERE name_en ILIKE '%respir%' OR name_hu ILIKE '%légz%'");
        console.log('--- Matching Topics in DB ---');
        console.log(JSON.stringify(res.rows, null, 2));
        await pool.end();
    } catch (err) {
        console.error('Error querying DB:', err);
        process.exit(1);
    }
}

checkTopics();
