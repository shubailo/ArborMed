const db = require('./backend/src/config/db');

async function checkItems() {
    try {
        const furniture = await db.query("SELECT id, name, slot_type, price FROM items WHERE slot_type = 'furniture' ORDER BY id");
        console.log('\n=== FURNITURE ITEMS ===');
        console.table(furniture.rows);

        const examTable = await db.query("SELECT id, name, slot_type, price FROM items WHERE slot_type = 'exam_table' ORDER BY id");
        console.log('\n=== EXAM TABLE ITEMS ===');
        console.table(examTable.rows);

        process.exit();
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

checkItems();
