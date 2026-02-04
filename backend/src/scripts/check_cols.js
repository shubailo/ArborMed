const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

async function checkColumns() {
    const tables = [
        'cohort_members', 'cohorts', 'consultation_notes', 'ecg_cases',
        'notifications', 'password_resets', 'quiz_sessions', 'topics',
        'user_items', 'users', 'admin_audit_log'
    ];
    try {
        const res = await pool.query(`
      SELECT table_name, column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = ANY($1)
      ORDER BY table_name, ordinal_position
    `, [tables]);
        console.log(JSON.stringify(res.rows, null, 2));
        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

checkColumns();
