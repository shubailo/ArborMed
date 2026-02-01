const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
});

async function checkQuotesTable() {
    try {
        // Check columns in quotes table
        const columnsResult = await pool.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_name = 'quotes'
      ORDER BY ordinal_position;
    `);

        console.log('\n=== QUOTES TABLE COLUMNS ===');
        console.table(columnsResult.rows);

        // Check sample data
        const dataResult = await pool.query('SELECT * FROM quotes LIMIT 3');
        console.log('\n=== SAMPLE QUOTES DATA ===');
        console.table(dataResult.rows);

        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

checkQuotesTable();
