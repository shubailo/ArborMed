const db = require('../config/db');

async function main() {
    const res = await db.query('SELECT * FROM topics');
    console.log(JSON.stringify(res.rows, null, 2));
    process.exit();
}
main();
