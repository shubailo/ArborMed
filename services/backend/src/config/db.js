const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const { databaseOptions } = require('./databaseOptions');
const options = databaseOptions(process.env);

const pool = new Pool({
  ...options,
  // ⏱️ Optimization: Fail fast if connection cannot be established
  connectionTimeoutMillis: 10000,
  idleTimeoutMillis: 30000,
  max: 20,
});

// Debug tool: logging connection user (Safe)
if (process.env.DATABASE_URL) {
  try {
    const url = new URL(process.env.DATABASE_URL);
    console.log(`[DB] Attempting connection to ${url.host} (SSL: ${!!options.ssl})`);
  } catch {
    console.warn("[DB] Error parsing DATABASE_URL for logging");
  }
} else {
  console.error("[DB] CRITICAL: DATABASE_URL is missing!");
}

pool.on('error', (err) => {
  console.error('[DB] Unexpected error on idle client:', err.message);
  // Do not process.exit in a pooled environment unless critical, 
  // letting express/pm2 handle service health.
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool,
};
