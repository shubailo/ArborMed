const { Client } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

async function runMigration() {
  const client = new Client({
    connectionString: process.env.DATABASE_URL,
  });

  try {
    await client.connect();
    console.log(
      '🚀 Connected to database. Starting performance migration...\n'
    );

    const sqlPath = path.join(
      __dirname,
      '../models/023_supabase_performance_optimizations.sql'
    );
    const sql = fs.readFileSync(sqlPath, 'utf8');

    // Split SQL by semicolon, but be careful with multi-line statements if any
    // This script assumes simple semicolon separation for our specific migration
    const commands = sql
      .split(';')
      .map((cmd) => cmd.trim())
      .filter((cmd) => cmd.length > 0 && !cmd.startsWith('--'));

    for (const command of commands) {
      console.log(`执行: ${command.split('\n')[0]}...`);
      try {
        await client.query(command);
        console.log('✅ Success\n');
      } catch (err) {
        if (err.message.includes('already exists')) {
          console.warn(`⚠️  Warning: ${err.message}\n`);
        } else {
          console.error(`❌ Error executing command: ${err.message}\n`);
        }
      }
    }

    console.log('✨ All migration steps completed.');
    process.exit(0);
  } catch (err) {
    console.error('💥 Migration failed:', err);
    process.exit(1);
  } finally {
    await client.end();
  }
}

runMigration();
