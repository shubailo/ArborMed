const db = require('./src/config/db');

async function showTopics() {
    try {
        const result = await db.query('SELECT id, name, parent_id FROM topics ORDER BY id');
        console.log('\n=== TOPICS STRUCTURE ===\n');
        result.rows.forEach(t => {
            console.log(`ID: ${t.id}, Name: ${t.name}, Parent: ${t.parent_id || 'NULL'}`);
        });
    } catch (err) {
        console.error(err);
    } finally {
        process.exit(0);
    }
}

showTopics();
