const db = require('../config/db');

async function inspect() {
    try {
        const res = await db.query(`
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = 'questions';
        `);
        const columns = res.rows.map(r => r.column_name);
        console.log(JSON.stringify(columns));
        process.exit();
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}
inspect();
