const db = require('../src/config/db');

async function checkSchema() {
    try {
        console.log('--- TOPICS SCHEMA ---');
        const cols = await db.query("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'topics'");
        console.log(cols.rows);

        console.log('\n--- TOPICS DATA ---');
        const data = await db.query("SELECT * FROM topics LIMIT 10");
        console.log(data.rows);

        console.log('\n--- UQP SCHEMA ---');
        const uqpCols = await db.query("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'user_question_progress'");
        console.log(uqpCols.rows);

        console.log('\n--- UTP SCHEMA ---');
        const utpCols = await db.query("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'user_topic_progress'");
        console.log(utpCols.rows);

        console.log('\n--- RESPONSES SCHEMA ---');
        const respCols = await db.query("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'responses'");
        console.log(respCols.rows);

    } catch (e) {
        console.error(e);
    } finally {
        process.exit();
    }
}

checkSchema();
