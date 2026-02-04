const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

async function checkFunctions() {
    const functions = ['validate_and_reset_password', 'check_password_reset_rate_limit'];
    try {
        for (const fn of functions) {
            console.log(`\n--- Function: ${fn} ---`);
            const res = await pool.query(`
        SELECT proconfig 
        FROM pg_proc 
        WHERE proname = $1
      `, [fn]);
            console.log('Config:', JSON.stringify(res.rows[0]?.proconfig, null, 2));
        }
        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

checkFunctions();
