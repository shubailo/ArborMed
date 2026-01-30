const fs = require('fs');
const path = require('path');
const db = require('../config/db');

const migrate = async () => {
    try {
        const migrationFiles = [
            'schema.sql',
            '002_gamification.sql',
            '003_gamification_logic.sql',
            '004_smart_shop.sql',
            '005_iso_coords.sql'
        ];

        console.log('🚀 Running sequential migrations...');

        for (const file of migrationFiles) {
            const schemaPath = path.join(__dirname, '../models', file);
            if (!fs.existsSync(schemaPath)) {
                console.warn(`⚠️ Warning: Migration file ${file} not found. Skipping.`);
                continue;
            }
            const schemaSql = fs.readFileSync(schemaPath, 'utf8');
            console.log(`📡 Running: ${file}`);

            try {
                await db.query(schemaSql);
            } catch (err) {
                // 42P07: duplicate_table
                // 42701: duplicate_column
                if (err.code === '42P07' || err.code === '42701') {
                    console.log(`ℹ️  Skipped ${file} (already applied)`);
                } else {
                    throw err;
                }
            }
        }

        console.log('✅ Migration successful!');
        process.exit(0);
    } catch (err) {
        console.error('❌ Migration failed:', err);
        process.exit(1);
    }
};

migrate();
