const fs = require('fs');
const path = require('path');
const db = require('../config/db');

const migrate = async () => {
    try {
        const schemaPath = path.join(__dirname, '../models/schema.sql');
        const schemaSql = fs.readFileSync(schemaPath, 'utf8');

        console.log('Running migration...');
        // Split by statement if possible or just run the whole thing
        // A simple way is to wrap in a try-catch for specific errors or use DO blocks in SQL
        // For this MVP fix, we'll just run it. If it fails due to existing table, we might need a better script.
        // Let's improve schema.sql to be idempotent instead.
        await db.query(schemaSql);
        console.log('Migration successful!');
        process.exit(0);
    } catch (err) {
        console.error('Migration failed:', err);
        process.exit(1);
    }
};

migrate();
