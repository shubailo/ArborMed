const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

// Debug tool: logging connection user (Safe)
if (process.env.DATABASE_URL) {
  const url = new URL(process.env.DATABASE_URL);
  console.log(`[DB] Connecting to host: ${url.host}, database: ${url.pathname}, user: ${url.username}`);
} else {
  console.warn("[DB] DATABASE_URL is missing!");
}

pool.on('error', (err) => {
  console.error('Unexpected error on idle client', err);
  process.exit(-1);
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool,
};
