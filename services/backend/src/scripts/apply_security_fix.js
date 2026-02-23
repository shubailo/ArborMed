const db = require('../config/db');
const fs = require('fs');
const path = require('path');

async function migrate() {
  try {
    console.log('🚀 Running 017_security_and_performance_fix.sql migration...');
    const sqlPath = path.join(
      __dirname,
      '../models/017_security_and_performance_fix.sql'
    );
    const sql = fs.readFileSync(sqlPath, 'utf8');

    // Split by semi-colon to handle multiple statements if needed,
    // though pg.query can handle multi-statement strings.
    await db.query(sql);
    console.log(
      '✅ Security Hardening and Performance Fixes applied successfully!'
    );
  } catch (e) {
    console.error('❌ Migration failed:', e.message);
    if (e.message.includes('already exists')) {
      console.log('💡 Some elements already exist, which is likely fine.');
    }
  } finally {
    process.exit();
  }
}

migrate();
