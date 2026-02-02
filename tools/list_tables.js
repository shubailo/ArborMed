const db = require('./backend/src/config/db');

async function listTables() {
    try {
        const result = await db.query("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'");
        console.log('--- DATABASE TABLES ---');
        console.table(result.rows);
        process.exit();
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

listTables();
