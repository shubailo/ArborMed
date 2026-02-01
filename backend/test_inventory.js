const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
});

async function testInventoryQuery() {
    try {
        const query = `
      SELECT 
        p.id as subject_id,
        p.name_en as subject_name,
        c.id as section_id,
        c.name_en as section_name,
        q.bloom_level,
        COUNT(q.id)::int as count
      FROM topics p
      JOIN topics c ON c.parent_id = p.id
      LEFT JOIN questions q ON q.topic_id = c.id
      WHERE p.parent_id IS NULL
      GROUP BY p.id, p.name_en, c.id, c.name_en, q.bloom_level
      ORDER BY p.name_en, c.name_en, q.bloom_level;
    `;

        const result = await pool.query(query);
        console.log(`✅ Query succeeded! Got ${result.rows.length} rows`);
        console.log('Sample:', JSON.stringify(result.rows.slice(0, 3), null, 2));
        process.exit(0);
    } catch (error) {
        console.error('❌ Query failed:', error.message);
        console.error('Stack:', error.stack);
        process.exit(1);
    }
}

testInventoryQuery();
