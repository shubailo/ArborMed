const path = require('path');
const db = require(path.join(__dirname, 'src/config/db'));

async function checkSpecificSlug() {
    try {
        const slug = 'renal-system';
        const topicRes = await db.query("SELECT id, name_en, slug, parent_id FROM topics WHERE slug = $1", [slug]);
        console.log(`Topic info for slug [${slug}]:`, JSON.stringify(topicRes.rows, null, 2));

        if (topicRes.rows.length > 0) {
            const topicId = topicRes.rows[0].id;
            const directCount = await db.query("SELECT COUNT(*) FROM questions WHERE topic_id = $1", [topicId]);
            console.log(`Direct questions for ${slug}: ${directCount.rows[0].count}`);

            const recursiveCount = await db.query(`
        WITH RECURSIVE subtopics AS (
            SELECT id FROM topics WHERE id = $1
            UNION ALL
            SELECT t.id FROM topics t JOIN subtopics st ON t.parent_id = st.id
        )
        SELECT COUNT(*) FROM questions WHERE topic_id IN (SELECT id FROM subtopics)
      `, [topicId]);
            console.log(`Recursive questions for ${slug} (DIRECT + CHILDREN [recursive SQL result]): ${recursiveCount.rows[0].count}`);

            // Check non-recursive (2-level) count for comparison
            const twoLevelCount = await db.query(`
                WITH subtopics AS (
                    SELECT id FROM topics WHERE id = $1
                    UNION ALL
                    SELECT id FROM topics WHERE parent_id = $1
                )
                SELECT COUNT(*) FROM questions WHERE topic_id IN (SELECT id FROM subtopics)
            `, [topicId]);
            console.log(`2-Level questions for ${slug} (DIRECT + CHILDREN [flat SQL result]): ${twoLevelCount.rows[0].count}`);
        } else {
            console.log(`Slug [${slug}] NOT FOUND in topics table.`);
        }
    } catch (err) {
        console.error(err);
    } finally {
        process.exit();
    }
}

checkSpecificSlug();
