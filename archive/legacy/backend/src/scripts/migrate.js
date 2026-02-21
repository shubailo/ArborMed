const fs = require('fs');
const path = require('path');
const db = require('../config/db');

const migrate = async () => {
    try {
        // Only pending migrations — already-applied ones are removed
        const migrationFiles = [
            '032_rename_wall_ac_to_desk_decor.sql',
            '033_social_like_protection.sql',
            '034_security_audit_logs.sql'
        ];

        console.log('🚀 Running sequential migrations...');

        for (const file of migrationFiles) {
            const schemaPath = path.join(__dirname, '../models', file);
            if (!fs.existsSync(schemaPath)) {
                console.warn(`⚠️ Warning: Migration file ${file} not found. Skipping.`);
                continue;
            }
            const schemaSql = fs.readFileSync(schemaPath, 'utf8');
            fs.appendFileSync('migration_progress.log', `Starting: ${file}\n`);
            console.log(`📡 Starting: ${file}`);
            try {
                await db.query(schemaSql);
            } catch (err) {
                // 42P07: duplicate_table
                // 42701: duplicate_column
                if (err.code === '42P07' || err.code === '42701') {
                    console.log(`ℹ️  Skipped ${file} (already applied)`);
                } else {
                    console.error(`❌ Error in ${file} (Code: ${err.code}):`, err.message);
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
