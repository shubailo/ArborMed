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
  const code = typeof err?.code === 'string' && /^[A-Z][A-Z0-9_]{4,19}$|^[0-9][A-Z0-9]{4}$/.test(err.code)
    ? err.code : 'unclassified';
  console.error('[DB] Unexpected error on idle client:', code);
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool,
};
