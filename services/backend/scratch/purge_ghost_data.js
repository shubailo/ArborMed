require('dotenv').config({ path: './services/backend/.env' });
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function purgeGhostData() {
  console.log("🚀 Starting Sanitization of Session #1 ghost data...");
  
  try {
    // 1. Get initial count
    const initRes = await pool.query('SELECT count(*) FROM responses WHERE session_id = 1');
    const initCount = parseInt(initRes.rows[0].count);
    console.log(`📊 Initial count for Session #1: ${initCount}`);

    if (initCount === 0) {
      console.log("✅ No ghost data found in Session #1. Skipping.");
      return;
    }

    // 2. Perform deletion
    console.log("🧹 Deleting responses for Session #1...");
    const delRes = await pool.query('DELETE FROM responses WHERE session_id = 1');
    console.log(`✅ Successfully deleted ${delRes.rowCount} responses.`);

    // 3. Final verification
    const finalRes = await pool.query('SELECT count(*) FROM responses WHERE session_id = 1');
    const finalCount = finalRes.rows[0].count;
    console.log(`📊 Final count for Session #1: ${finalCount}`);

  } catch (err) {
    console.error("❌ Error purging data:", err);
  } finally {
    await pool.end();
  }
}

purgeGhostData();
