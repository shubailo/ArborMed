
const db = require('../src/config/db');

async function listTopics() {
    try {
        const res = await db.query('SELECT id, name_en, slug, parent_id FROM topics ORDER BY parent_id, name_en');
        console.log('Topics:', JSON.stringify(res.rows, null, 2));
        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

listTopics();
