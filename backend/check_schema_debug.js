const pg = require('pg');
require('dotenv').config();

async function checkSchema() {
    const client = new pg.Client(process.env.DATABASE_URL);
    try {
        await client.connect();
        const res = await client.query(`
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = 'questions'
            ORDER BY column_name;
        `);
        console.log('Columns in questions table:');
        res.rows.forEach(row => {
            console.log(`${row.column_name}: ${row.data_type}`);
        });

        const resStats = await client.query(`
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = 'topics'
            ORDER BY column_name;
        `);
        console.log('\nColumns in topics table:');
        resStats.rows.forEach(row => {
            console.log(`${row.column_name}: ${row.data_type}`);
        });

    } catch (err) {
        console.error(err);
    } finally {
        await client.end();
    }
}

checkSchema();
