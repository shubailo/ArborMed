const db = require('../config/db');

async function inspect() {
    try {
        console.log('--- TABLES ---');
        const tables = await db.query(`
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            ORDER BY table_name
        `);
        tables.rows.forEach(r => console.log(r.table_name));

        console.log('\n--- user_topic_progress COLUMNS ---');
        const columns = await db.query(`
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = 'user_topic_progress'
        `);
        if (columns.rows.length === 0) {
            console.log('(Table not found)');
        } else {
            columns.rows.forEach(r => console.log(`${r.column_name} (${r.data_type})`));
        }

        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

inspect();
