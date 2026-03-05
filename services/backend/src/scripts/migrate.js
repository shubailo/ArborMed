const fsPromises = require('fs').promises;
const path = require('path');
const db = require('../config/db');

const migrate = async () => {
    try {
        // Only pending migrations — already-applied ones are removed
        const migrationFiles = [
            '032_rename_wall_ac_to_desk_decor.sql',
            '033_social_like_protection.sql',
            '034_security_audit_logs.sql',
            '039_pedagogical_engine_upgrade.sql',
            'economy_v1_setup.sql'
        ];

        console.log('🚀 Running sequential migrations...');

        // Parallelize reading files from disk
        const schemaPromises = migrationFiles.map(async file => {
            const schemaPath = path.join(__dirname, '../../migrations', file);
            try {
                const schemaSql = await fsPromises.readFile(schemaPath, 'utf8');
                return { file, schemaSql };
            } catch {
                return { file, error: 'not_found' };
            }
        });

        const schemas = await Promise.all(schemaPromises);

        let progressLog = '';

        // Request a single database connection from the pool to reduce overhead
        const client = await db.pool.connect();
        try {
            for (const { file, schemaSql, error } of schemas) {
                if (error === 'not_found') {
                    console.warn(`⚠️ Warning: Migration file ${file} not found. Skipping.`);
                    continue;
                }

                progressLog += `Starting: ${file}\n`;
                console.log(`📡 Starting: ${file}`);

                try {
                    await client.query(schemaSql);
                } catch (err) {
                    // 42P07: duplicate_table
                    // 42701: duplicate_column
                    // 42710: duplicate_object
                    if (err.code === '42P07' || err.code === '42701' || err.code === '42710') {
                        console.log(`ℹ️  Skipped ${file} (already applied)`);
                    } else {
                        console.error(`❌ Error in ${file} (Code: ${err.code}):`, err.message);
                        throw err;
                    }
                }
            }
        } finally {
            client.release();
        }

        // Write migration log asynchronously at the end
        if (progressLog) {
            await fsPromises.appendFile('migration_progress.log', progressLog);
        }

        console.log('✅ Migration successful!');
        process.exit(0);
    } catch (err) {
        console.error('❌ Migration failed:', err);
        process.exit(1);
    }
};

migrate();
