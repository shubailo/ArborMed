const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
});

async function checkQuestions() {
    try {
        console.log('=== QUESTIONS TABLE COLUMNS ===');
        const cols = await pool.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'questions' 
      ORDER BY ordinal_position
    `);
        console.log('Columns:');
        cols.rows.forEach(c => console.log(`  ${c.column_name} (${c.data_type})`));

        console.log('\n=== SAMPLE QUESTIONS ===');
        const questions = await pool.query('SELECT * FROM questions LIMIT 3');
        console.log(JSON.stringify(questions.rows, null, 2));

        process.exit(0);
    } catch (error) {
        console.error('Error:', error.message);
        process.exit(1);
    }
}

checkQuestions();
