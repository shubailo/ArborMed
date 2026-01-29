const db = require('../config/db');

async function checkSchema() {
    const res = await db.query("SELECT column_name FROM information_schema.columns WHERE table_name = 'items'");
    console.log(res.rows);
    process.exit();
}
checkSchema();
