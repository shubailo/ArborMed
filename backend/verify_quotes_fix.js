const db = require('./src/config/db');

async function verify() {
    try {
        const r = await db.query('SELECT count(*) FROM quotes');
        console.log('✅ Found', r.rows[0].count, 'quotes in database.');

        // Check if table structure is correct
        const cols = await db.query("SELECT column_name FROM information_schema.columns WHERE table_name = 'quotes'");
        console.log('✅ Columns found:', cols.rows.map(c => c.column_name).join(', '));

        process.exit(0);
    } catch (err) {
        console.error('❌ Verification failed:', err);
        process.exit(1);
    }
}

verify();
