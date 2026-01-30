const db = require('./backend/src/config/db');

async function listItems() {
    try {
        const result = await db.query('SELECT id, name, slot_type, price FROM items');
        console.log('--- DATABASE ITEMS ---');
        console.table(result.rows);
        process.exit();
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

listItems();
