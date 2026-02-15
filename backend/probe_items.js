const db = require('./src/config/db');

async function probe() {
    try {
        console.log('📡 Probing items table...');

        const res = await db.query('SELECT * FROM items');
        console.log(`✅ Found ${res.rowCount} items.`);
        if (res.rowCount > 0) {
            console.log('Sample item:', res.rows[0]);
        } else {
            console.log('⚠️ Items table is EMPTY.');
        }

    } catch (err) {
        console.error('❌ Probe failed:', err);
    } finally {
        process.exit(0);
    }
}

probe();
