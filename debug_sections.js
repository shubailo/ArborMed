const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, 'backend/.env') });

const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

async function debugTopics() {
    try {
        // 1. Check parent topic
        const parentRes = await pool.query("SELECT * FROM topics WHERE slug = 'pathophysiology'");
        console.log('Parent Topic:', JSON.stringify(parentRes.rows, null, 2));

        if (parentRes.rows.length === 0) {
            console.log('❌ Pathophysiology parent topic not found by slug!');
            const allParents = await pool.query("SELECT * FROM topics WHERE parent_id IS NULL");
            console.log('Available Top-level Subjects:', JSON.stringify(allParents.rows.map(r => ({ name: r.name_en, slug: r.slug })), null, 2));
        } else {
            const parentId = parentRes.rows[0].id;
            // 2. Check clinical sections
            const sectionsRes = await pool.query("SELECT * FROM topics WHERE parent_id = $1", [parentId]);
            console.log(`Sections for Pathophysiology (ID: ${parentId}):`, JSON.stringify(sectionsRes.rows, null, 2));

            // 3. Check if questions are linked to these sections
            if (sectionsRes.rows.length > 0) {
                const sectionIds = sectionsRes.rows.map(r => r.id);
                const qCounts = await pool.query("SELECT topic_id, COUNT(*) as count FROM questions WHERE topic_id = ANY($1) GROUP BY topic_id", [sectionIds]);
                console.log('Question counts by Section ID:', JSON.stringify(qCounts.rows, null, 2));
            }
        }

        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

debugTopics();
