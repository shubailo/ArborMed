const { Client } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

async function applyMigration() {
    const migrationFile = process.argv[2];
    if (!migrationFile) {
        console.error("Please provide a migration filename.");
        process.exit(1);
    }

    const migrationPath = path.join(__dirname, 'migrations', migrationFile);
    const sql = fs.readFileSync(migrationPath, 'utf8');

    const client = new Client({
        connectionString: process.env.DATABASE_URL,
    });

    try {
        await client.connect();
        console.log(`Applying migration: ${migrationFile}`);
        await client.query(sql);
        console.log("Migration applied successfully!");
    } catch (err) {
        console.error("Error applying migration:", err);
    } finally {
        await client.end();
    }
}

applyMigration();
