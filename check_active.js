const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, 'backend/.env') });

const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

async function check() {
    try {
        const colInfo = await pool.query("SELECT column_name, column_default FROM information_schema.columns WHERE table_name = 'questions' AND column_name IN ('active', 'is_active')");
        console.log('Columns found:', JSON.stringify(colInfo.rows, null, 2));

        const count = await pool.query("SELECT is_active, COUNT(*) FROM questions GROUP BY is_active");
        console.log('Status counts:', JSON.stringify(count.rows, null, 2));

        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

check();
