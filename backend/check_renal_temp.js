const db = require('./src/config/db');

async function checkRenal() {
    try {
        const topicRes = await db.query("SELECT id, name_en, slug, parent_id FROM topics WHERE name_en ILIKE '%Renal%' OR slug ILIKE '%renal%'");
        console.log("Renal Topics:", JSON.stringify(topicRes.rows, null, 2));

        for (const t of topicRes.rows) {
            const directCount = await db.query("SELECT COUNT(*) FROM questions WHERE topic_id = $1", [t.id]);
            console.log(`Topic ${t.name_en} (${t.slug}) direct questions: ${directCount.rows[0].count}`);

            const recursiveCount = await db.query(`
        WITH RECURSIVE subtopics AS (
            SELECT id FROM topics WHERE id = $1
            UNION ALL
            SELECT t.id FROM topics t JOIN subtopics st ON t.parent_id = st.id
        )
        SELECT COUNT(*) FROM questions WHERE topic_id IN (SELECT id FROM subtopics)
      `, [t.id]);
            console.log(`Topic ${t.name_en} (${t.slug}) recursive questions: ${recursiveCount.rows[0].count}`);
        }
    } catch (err) {
        console.error(err);
    } finally {
        process.exit();
    }
}

checkRenal();
