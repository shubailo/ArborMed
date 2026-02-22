const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

async function checkSummary() {
    try {
        // const userId = 1;
        const query = `
            SELECT 
                t_parent.name_en as subject,
                t_parent.slug as slug
            FROM topics t_parent
            WHERE t_parent.parent_id IS NULL
            AND t_parent.slug IN ('pathophysiology', 'pathology', 'microbiology', 'pharmacology', 'ecg')
        `;
        const res = await pool.query(query);
        console.log('Summary Topics:', JSON.stringify(res.rows, null, 2));
        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

checkSummary();
