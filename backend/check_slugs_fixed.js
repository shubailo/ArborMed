const path = require('path');
const db = require(path.join(__dirname, 'src/config/db'));

async function checkAllSlugs() {
    try {
        const res = await db.query("SELECT id, slug, name_en, parent_id FROM topics");
        console.log("All Topics:", JSON.stringify(res.rows, null, 2));
    } catch (err) {
        console.error(err);
    } finally {
        process.exit();
    }
}

checkAllSlugs();
