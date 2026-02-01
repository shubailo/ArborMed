const db = require('../config/db');

async function checkDb() {
    try {
        console.log('🔍 Checking Database Topics...');

        const subjects = await db.query("SELECT id, name_en, slug FROM topics WHERE parent_id IS NULL");
        console.log('\nRoot Subjects:');
        for (const s of subjects.rows) {
            const children = await db.query("SELECT name_en, slug FROM topics WHERE parent_id = $1", [s.id]);
            console.log(`- ${s.name_en} (${s.slug}) [ID: ${s.id}]`);
            if (children.rows.length === 0) {
                console.log('  ⚠️ NO CHILDREN FOUND');
            } else {
                children.rows.forEach(c => console.log(`  -> ${c.name_en} (${c.slug})`));
            }
        }

        process.exit(0);
    } catch (err) {
        console.error('Check failed:', err);
        process.exit(1);
    }
}

checkDb();
