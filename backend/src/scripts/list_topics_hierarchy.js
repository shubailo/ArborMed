const db = require('../config/db');

async function main() {
    const res = await db.query(`
        SELECT t1.id, t1.name, t1.slug, t2.name as parent_name 
        FROM topics t1 
        LEFT JOIN topics t2 ON t1.parent_id = t2.id
        ORDER BY t1.parent_id NULLS FIRST, t1.id
    `);
    console.table(res.rows);
    process.exit();
}
main();
