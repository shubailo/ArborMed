const db = require('./src/config/db');

async function showTopicHierarchy() {
    try {
        const result = await db.query('SELECT id, name, parent_id FROM topics ORDER BY parent_id NULLS FIRST, id');
        console.log('\n=== TOPIC HIERARCHY ===\n');

        // Group by parent
        const parents = result.rows.filter(t => !t.parent_id);
        const children = result.rows.filter(t => t.parent_id);

        console.log('ROOT TOPICS (Subjects):');
        parents.forEach(p => {
            console.log(`  ${p.id}. ${p.name}`);
            const kids = children.filter(c => c.parent_id === p.id);
            if (kids.length > 0) {
                kids.forEach(k => console.log(`    └─ ${k.id}. ${k.name}`));
            } else {
                console.log(`    └─ (no sections)`);
            }
        });

    } catch (err) {
        console.error(err);
    } finally {
        process.exit(0);
    }
}

showTopicHierarchy();
