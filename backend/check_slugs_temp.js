const db = require('./src/config/db');

async function checkAllSlugs() {
    try {
        const res = await db.query("SELECT slug, name_en FROM topics");
        console.log("All Slugs:", JSON.stringify(res.rows, null, 2));
    } catch (err) {
        console.error(err);
    } finally {
        process.exit();
    }
}

checkAllSlugs();
