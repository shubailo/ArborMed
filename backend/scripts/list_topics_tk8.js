
const db = require('../src/config/db');

async function listTopics() {
    try {
        const res = await db.query(`
            SELECT t.id, t.name_en, t.slug, p.name_en as parent_name
            FROM topics t
            LEFT JOIN topics p ON t.parent_id = p.id
            WHERE t.slug = 'pathophysiology' OR p.slug = 'pathophysiology'
            ORDER BY p.name_en NULLS FIRST, t.name_en;
        `);

        console.log('--- Pathophysiology Topics ---');
        res.rows.forEach(row => {
            console.log(`[ID: ${row.id}] ${row.name_en} (${row.slug}) ${row.parent_name ? '< ' + row.parent_name : ''}`);
        });

        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

listTopics();
