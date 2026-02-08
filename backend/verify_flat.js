const path = require('path');
const db = require(path.join(__dirname, 'src/config/db'));

async function verify() {
    try {
        const pathoId = 8; // Based on previous logs
        const res = await db.query("SELECT id, name_en, slug, parent_id FROM topics WHERE parent_id = $1 ORDER BY name_en", [pathoId]);

        console.log(`Total topics under Pathophysiology (ID ${pathoId}): ${res.rows.length}`);
        res.rows.forEach(t => {
            console.log(`- ${t.name_en} (${t.slug})`);
        });

        // Check if any of these children still have children
        const childIds = res.rows.map(r => r.id);
        const subRes = await db.query("SELECT COUNT(*) FROM topics WHERE parent_id = ANY($1)", [childIds]);
        console.log(`\nSub-topics remaining under these children: ${subRes.rows[0].count}`);

    } catch (err) {
        console.error(err);
    } finally {
        process.exit();
    }
}

verify();
