const fs = require('fs');
const path = require('path');
const db = require('./src/config/db');

const applyUpgrade = async () => {
    const migrationFile = '039_pedagogical_engine_upgrade.sql';
    const schemaPath = path.join(__dirname, 'src/models', migrationFile);

    console.log(`🚀 Applying upgrade: ${migrationFile}`);

    try {
        const schemaSql = fs.readFileSync(schemaPath, 'utf8');
        await db.query(schemaSql);
        console.log('✅ Upgrade applied successfully!');
        process.exit(0);
    } catch (err) {
        // 42701: duplicate_column
        if (err.code === '42701') {
            console.log(`ℹ️  Skipped (columns already exist)`);
            process.exit(0);
        } else {
            console.error('❌ Upgrade failed:', err);
            process.exit(1);
        }
    }
};

applyUpgrade();
