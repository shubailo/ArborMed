const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

async function checkDuplicates() {
    try {
        const res = await pool.query(`
      SELECT name_en, COUNT(*) 
      FROM topics 
      GROUP BY name_en 
      HAVING COUNT(*) > 1
    `);
        console.log('Duplicate Topic Names:', JSON.stringify(res.rows, null, 2));

        // Also check for slug duplicates (should be impossible due to constraint, but let's check name-slug mismatch)
        const mismatch = await pool.query(`
      SELECT name_en, slug, parent_id FROM topics 
      WHERE name_en IN (SELECT name_en FROM topics GROUP BY name_en HAVING COUNT(*) > 1)
      ORDER BY name_en
    `);
        console.log('Duplicate detail:', JSON.stringify(mismatch.rows, null, 2));

        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

checkDuplicates();
