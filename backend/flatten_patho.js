const path = require('path');
const db = require(path.join(__dirname, 'src/config/db'));

async function flattenAllPatho() {
    try {
        // 1. Find Pathophysiology
        const pRes = await db.query("SELECT id, name_en FROM topics WHERE name_en ILIKE 'Pathophysiology' LIMIT 1");
        if (pRes.rows.length === 0) {
            console.log("Pathophysiology not found.");
            return;
        }
        const pathoId = pRes.rows[0].id;
        console.log(`Found Pathophysiology (Subject): ID ${pathoId}`);

        // 2. Find all descendants of Pathophysiology
        const dRes = await db.query(`
      WITH RECURSIVE descendants AS (
        SELECT id, parent_id, name_en FROM topics WHERE parent_id = $1
        UNION ALL
        SELECT t.id, t.parent_id, t.name_en FROM topics t JOIN descendants d ON t.parent_id = d.id
      )
      SELECT * FROM descendants;
    `, [pathoId]);

        console.log(`Found ${dRes.rows.length} descendants to potentially flatten.`);

        // 3. Move all descendants to be direct children of Pathophysiology
        for (const topic of dRes.rows) {
            if (topic.parent_id !== pathoId) {
                console.log(`Moving "${topic.name_en}" (ID ${topic.id}) from Parent ID ${topic.parent_id} to Pathophysiology (ID ${pathoId})`);
                await db.query("UPDATE topics SET parent_id = $1 WHERE id = $2", [pathoId, topic.id]);
            } else {
                console.log(`"${topic.name_en}" (ID ${topic.id}) is already a direct child.`);
            }
        }

        // 4. Final verification
        const vRes = await db.query("SELECT id, name_en, slug, parent_id FROM topics WHERE parent_id = $1 ORDER BY name_en", [pathoId]);
        console.log("\nFinal Flat Structure under Pathophysiology:");
        console.log(JSON.stringify(vRes.rows, null, 2));

    } catch (err) {
        console.error(err);
    } finally {
        process.exit();
    }
}

flattenAllPatho();
