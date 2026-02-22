const path = require('path');
const db = require(path.join(__dirname, 'src/config/db'));

async function generateReport() {
    try {
        const pathoId = 8;

        // 1. Get all child topics
        const topicsRes = await db.query("SELECT id, name_en, slug FROM topics WHERE parent_id = $1 ORDER BY name_en", [pathoId]);
        const topics = topicsRes.rows;

        console.log(`\n=== Pathophysiology (Subject) Hierarchy & Question Counts ===\n`);
        console.log(`| Topic Name | Total Qs | Bloom 1 | Bloom 2 | Bloom 3 | Bloom 4 | Bloom 5 |`);
        console.log(`|------------|----------|---------|---------|---------|---------|---------|`);

        for (const topic of topics) {
            // Get counts by bloom level for this topic
            const countsRes = await db.query(`
        SELECT bloom_level, COUNT(*) as count 
        FROM questions 
        WHERE topic_id = $1 
        GROUP BY bloom_level 
        ORDER BY bloom_level
      `, [topic.id]);

            const counts = {};
            let total = 0;
            countsRes.rows.forEach(r => {
                counts[r.bloom_level] = parseInt(r.count);
                total += parseInt(r.count);
            });

            const b1 = counts[1] || 0;
            const b2 = counts[2] || 0;
            const b3 = counts[3] || 0;
            const b4 = counts[4] || 0;
            const b5 = counts[5] || 0;

            console.log(`| ${topic.name_en.padEnd(10)} | ${total.toString().padEnd(8)} | ${b1.toString().padEnd(7)} | ${b2.toString().padEnd(7)} | ${b3.toString().padEnd(7)} | ${b4.toString().padEnd(7)} | ${b5.toString().padEnd(7)} |`);
        }

        // 2. Summary for the whole Subject
        const totalRes = await db.query(`
      SELECT COUNT(*) as total FROM questions 
      WHERE topic_id IN (SELECT id FROM topics WHERE parent_id = $1)
    `, [pathoId]);

        console.log(`\nGrand Total for Pathophysiology: ${totalRes.rows[0].total} questions across ${topics.length} topics.`);

    } catch (err) {
        console.error(err);
    } finally {
        process.exit();
    }
}

generateReport();
