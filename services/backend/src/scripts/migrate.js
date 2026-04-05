const fsPromises = require('fs').promises;
const path = require('path');
const db = require('../config/db');

const migrate = async () => {
    try {
        const migrationsDir = path.join(__dirname, '../../migrations');
        const allFiles = await fsPromises.readdir(migrationsDir);
        
        const migrationFiles = allFiles
            .filter(f => f.endsWith('.sql'))
            .sort((a, b) => {
                if (a === 'schema.sql') return -1;
                if (b === 'schema.sql') return 1;
                const aNum = parseInt(a.split('_')[0], 10);
                const bNum = parseInt(b.split('_')[0], 10);
                if (!isNaN(aNum) && !isNaN(bNum)) return aNum - bNum;
                if (!isNaN(aNum)) return -1;
                if (!isNaN(bNum)) return 1;
                return a.localeCompare(b);
            });

        console.log('🚀 Running sequential migrations...');

        const schemas = [];
        for (const file of migrationFiles) {
            const schemaPath = path.join(migrationsDir, file);
            try {
                const schemaSql = await fsPromises.readFile(schemaPath, 'utf8');
                schemas.push({ file, schemaSql });
            } catch (err) {
                console.warn(`⚠️ Warning: Migration file ${file} not found. Skipping.`);
            }
        }

        let progressLog = '';
        const client = await db.pool.connect();
        
        try {
            for (const { file, schemaSql } of schemas) {
                progressLog += `Starting: ${file}\n`;
                console.log(`📡 [MIGRATION] Starting: ${file}`);

                try {
                    // Try executing the whole file first for speed and handling complex blocks (like DO $$ blocks)
                    await client.query(schemaSql);
                    console.log(`✅ [MIGRATION] Completed: ${file}`);
                } catch (err) {
                    // If it failed because of 'CREATE INDEX CONCURRENTLY' inside a transaction block (Code: 25001)
                    // OR if it just needs to be run statement-by-statement due to implicit transaction issues
                    if (err.code === '25001') {
                        console.log(`🔄 [MIGRATION] Retrying ${file} sequentially (CONCURRENTLY detected)`);
                        const statements = [];
                        let currentStatement = '';
                        let insideDollarBlock = false;
                        
                        // Split carefully by semicolon, ignoring those inside $$ blocks
                        const lines = schemaSql.split('\n');
                        for (const line of lines) {
                            if (line.includes('$$')) {
                                insideDollarBlock = !insideDollarBlock;
                            }
                            
                            if (!insideDollarBlock && line.includes(';')) {
                                const parts = line.split(';');
                                for (let i = 0; i < parts.length - 1; i++) {
                                    currentStatement += parts[i] + ';';
                                    statements.push(currentStatement.trim());
                                    currentStatement = '';
                                }
                                currentStatement += parts[parts.length - 1];
                            } else {
                                currentStatement += line + '\n';
                            }
                        }
                        if (currentStatement.trim()) {
                            statements.push(currentStatement.trim());
                        }

                        for (const statement of statements) {
                            try {
                                if (statement.length > 5) {
                                    await client.query(statement);
                                }
                            } catch (statementErr) {
                                const skipCodes = ['42P07', '42701', '42710', '42703', '42P01'];
                                if (skipCodes.includes(statementErr.code)) {
                                    // console.log(`ℹ️ [MIGRATION] Skipped statement in ${file} (Code: ${statementErr.code})`);
                                } else {
                                    console.error(`❌ [MIGRATION] Error in ${file} (Code: ${statementErr.code}):`, statementErr.message);
                                    throw statementErr;
                                }
                            }
                        }
                        console.log(`✅ [MIGRATION] Completed: ${file} (Sequentially)`);
                    } else {
                        // Standard error handling for non-concurrent errors
                        const skipCodes = ['42P07', '42701', '42710', '42703', '42P01'];
                        if (skipCodes.includes(err.code)) {
                            console.log(`ℹ️  [MIGRATION] Skipped ${file} (already applied: ${err.code})`);
                        } else {
                            console.error(`❌ [MIGRATION] Error in ${file} (Code: ${err.code}):`, err.message);
                            throw err;
                        }
                    }
                }
            }
        } finally {
            client.release();
        }

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
