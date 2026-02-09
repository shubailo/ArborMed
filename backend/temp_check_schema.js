const pg = require('pg');
require('dotenv').config();

async function checkSchema() {
    const client = new pg.Client(process.env.DATABASE_URL);
    try {
        await client.connect();
        const res = await client.query(`
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = 'user_topic_progress'
            ORDER BY column_name;
        `);
        console.log('Columns in user_topic_progress table:');
        res.rows.forEach(row => {
            console.log(`${row.column_name}: ${row.data_type}`);
        });

    } catch (err) {
        console.error(err);
    } finally {
        await client.end();
    }
}

checkSchema();
