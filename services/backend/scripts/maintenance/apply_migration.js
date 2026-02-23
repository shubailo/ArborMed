const db = require('./src/config/db');
const fs = require('fs');
const path = require('path');

async function runMigration() {
  console.log('--- 🚀 Running Migration: 028_email_verification.sql ---');
  try {
    const sqlPath = path.join(
      __dirname,
      'src/models/028_email_verification.sql'
    );
    const sql = fs.readFileSync(sqlPath, 'utf8');

    console.log('Executing SQL...');
    await db.query(sql);
    console.log('✅ Migration applied successfully!');
  } catch (error) {
    console.error('❌ Migration failed:');
    console.error(error.message);
  } finally {
    process.exit();
  }
}

runMigration();
