const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

async function run() {
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
  });

  const client = await pool.connect();
  console.log('Connected to Supabase...');

  try {
    const sqlPath = path.join(__dirname, '../../migrations/046_seed_150_ecg_cases.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');

    console.log(`Executing 046_seed_150_ecg_cases.sql (${(sql.length / 1024).toFixed(1)} KB)...`);
    await client.query(sql);
    console.log('Successfully executed 046_seed_150_ecg_cases.sql!');

    const countRes = await client.query('SELECT count(*) FROM ecg_cases');
    const diagRes = await client.query('SELECT count(*) FROM ecg_diagnoses');
    console.log('Updated ecg_cases count in Supabase:', countRes.rows[0].count);
    console.log('Updated ecg_diagnoses count in Supabase:', diagRes.rows[0].count);

  } catch (err) {
    console.error('Error applying migration 046:', err);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

run();
