const fs = require('fs');
const path = require('path');
const db = require('../config/db');

const migrate = async () => {
  try {
    const file = '011_ecg_module.sql';
    const schemaPath = path.join(__dirname, '../models', file);

    console.log(`🚀 Running single migration: ${file}`);

    const schemaSql = fs.readFileSync(schemaPath, 'utf8');
    await db.query(schemaSql);

    console.log('✅ Migration successful!');
    process.exit(0);
  } catch (err) {
    console.error('❌ Migration failed:', err);
    process.exit(1);
  }
};

migrate();
