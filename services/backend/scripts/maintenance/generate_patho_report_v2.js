const path = require('path');
const db = require(path.join(__dirname, 'src/config/db'));
const fs = require('fs');

async function generateReport() {
    try {
        const pathoId = 8;
        const topicsRes = await db.query("SELECT id, name_en, slug FROM topics WHERE parent_id = $1 ORDER BY name_en", [pathoId]);
        const topics = topicsRes.rows;

        let output = "=== Pathophysiology Hierarchy & Question Counts ===\n\n";
        output += "| Topic Name | Total Qs | B1 | B2 | B3 | B4 | B5 |\n";
        output += "|------------|----------|----|----|----|----|----|\n";

        for (const topic of topics) {
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

            output += `| ${topic.name_en} | ${total} | ${b1} | ${b2} | ${b3} | ${b4} | ${b5} |\n`;
        }

        const totalRes = await db.query(`
      SELECT COUNT(*) as total FROM questions 
      WHERE topic_id IN (SELECT id FROM topics WHERE parent_id = $1)
    `, [pathoId]);

        output += `\nGrand Total: ${totalRes.rows[0].total} questions across ${topics.length} topics.\n`;

        fs.writeFileSync('patho_report.md', output);
        console.log("Report generated in patho_report.md");

    } catch (err) {
        console.error(err);
    } finally {
        process.exit();
    }
}

generateReport();
