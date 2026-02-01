const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
});

async function simpleCheck() {
    try {
        // Check topics count
        const topicsCount = await pool.query('SELECT COUNT(*) FROM topics');
        console.log(`Total topics: ${topicsCount.rows[0].count}`);

        // Check questions count
        const questionsCount = await pool.query('SELECT COUNT(*) FROM questions');
        console.log(`Total questions: ${questionsCount.rows[0].count}`);

        // Check if questions table has the right columns
        const hasTextEn = await pool.query(`
      SELECT column_name FROM information_schema.columns 
      WHERE table_name = 'questions' AND column_name = 'text_en'
    `);
        console.log(`Has text_en column: ${hasTextEn.rows.length > 0}`);

        // List actual text columns
        const textCols = await pool.query(`
      SELECT column_name FROM information_schema.columns 
      WHERE table_name = 'questions' AND column_name LIKE '%text%'
    `);
        console.log('Text columns:', textCols.rows.map(r => r.column_name).join(', '));

        process.exit(0);
    } catch (error) {
        console.error('Error:', error.message);
        process.exit(1);
    }
}

simpleCheck();
