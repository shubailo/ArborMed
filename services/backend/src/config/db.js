const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const { databaseOptions } = require('./databaseOptions');
const options = databaseOptions(process.env);

const pool = new Pool({
  ...options,
  connectionTimeoutMillis: 10000,
  idleTimeoutMillis: 30000,
  max: 20,
});

pool.on('error', (err) => {
  console.error('[DB] Unexpected error on idle client:', err.message);
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool,
};
