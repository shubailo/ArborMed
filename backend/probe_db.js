const db = require('./src/config/db');

async function probe() {
    try {
        console.log('📡 Probing database...');

        // 1. Check current tables
        const tables = await db.query(`
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public'
        `);
        console.log('Existing tables:', tables.rows.map(r => r.table_name).join(', '));

        // 2. Try very simple creation in a different name
        console.log('📡 Attempting simple table creation...');
        await db.query('CREATE TABLE IF NOT EXISTS test_antigravity (id SERIAL PRIMARY KEY)');
        console.log('✅ Created test table!');

        // 3. Cleanup
        await db.query('DROP TABLE test_antigravity');
        console.log('✅ Dropped test table!');

    } catch (err) {
        console.error('❌ Probe failed:', err);
    } finally {
        process.exit(0);
    }
}

probe();
