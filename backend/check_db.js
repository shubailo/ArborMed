const db = require('./src/config/db');

async function check() {
    try {
        console.log('Checking tables...');
        const tables = await db.query(`
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public'
        `);
        console.log('Tables:', tables.rows.map(r => r.table_name).join(', '));

        for (const table of tables.rows.map(r => r.table_name)) {
            const columns = await db.query(`
                SELECT column_name 
                FROM information_schema.columns 
                WHERE table_name = $1
            `, [table]);
            console.log(`- ${table} columns:`, columns.rows.map(r => r.column_name).join(', '));
        }

        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

check();
