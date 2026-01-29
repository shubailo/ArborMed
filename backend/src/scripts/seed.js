const fs = require('fs');
const path = require('path');
const db = require('../config/db');

const seed = async () => {
    try {
        const seedPath = path.join(__dirname, '../models/seed.sql');
        const seedSql = fs.readFileSync(seedPath, 'utf8');

        console.log('Running seed...');
        await db.query(seedSql);
        console.log('Seed successful!');
        process.exit(0);
    } catch (err) {
        console.error('Seed failed:', err);
        process.exit(1);
    }
};

seed();
