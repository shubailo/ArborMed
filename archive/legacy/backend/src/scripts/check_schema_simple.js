const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

async function checkSchema() {
    try {
        console.log('--- CHECKING SCHEMA ---');

        // 1. Get Questions Table Columns
        const cols = await pool.query("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'questions' ORDER BY ordinal_position");
        console.log('Questions Table Columns:', cols.rows.map(c => `${c.column_name} (${c.data_type})`));

        // 2. Get All Topics
        const topics = await pool.query("SELECT id, name_en, slug, parent_id FROM topics ORDER BY id");
        console.log('All Topics:', JSON.stringify(topics.rows, null, 2));

        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

checkSchema();
