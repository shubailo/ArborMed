const fs = require('fs');
const path = require('path');
const db = require('../config/db');

const migrate = async () => {
    try {
        const schemaPath = path.join(__dirname, '../models/schema.sql');
        const schemaSql = fs.readFileSync(schemaPath, 'utf8');

        console.log('Running migration...');
        await db.query(schemaSql);
        console.log('Migration successful!');
        process.exit(0);
    } catch (err) {
        console.error('Migration failed:', err);
        process.exit(1);
    }
};

migrate();
