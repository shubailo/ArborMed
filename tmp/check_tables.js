const db = require('../services/backend/src/config/db');

async function checkTables() {
  try {
    const result = await db.query("SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = 'public'");
    console.log('--- TABLES ---');
    result.rows.forEach(r => console.log(r.tablename));
    process.exit(0);
  } catch (err) {
    console.error('Error fetching tables:', err);
    process.exit(1);
  }
}

checkTables();
