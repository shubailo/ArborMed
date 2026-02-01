const db = require('../config/db');

async function migrate() {
    try {
        console.log('Starting migration: Adding secondary_diagnoses_ids to ecg_cases...');

        await db.query(`
            ALTER TABLE ecg_cases 
            ADD COLUMN IF NOT EXISTS secondary_diagnoses_ids INTEGER[] DEFAULT '{}';
        `);

        console.log('Migration successful: Column added.');
        process.exit(0);
    } catch (error) {
        console.error('Migration failed:', error);
        process.exit(1);
    }
}

migrate();
