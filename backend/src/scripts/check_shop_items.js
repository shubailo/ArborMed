const db = require('../config/db');

async function checkItems() {
    const res = await db.query('SELECT name, slot_type, asset_path FROM items');
    console.log(`Total Items: ${res.rows.length}`);
    res.rows.forEach(r => console.log(`- ${r.name} (${r.slot_type}) -> [${r.asset_path}]`));
    process.exit();
}
checkItems();
