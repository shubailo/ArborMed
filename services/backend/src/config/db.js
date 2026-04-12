const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const isDevelopment = process.env.NODE_ENV === 'development';
const caCert = process.env.DB_CA_CERT;
const hasValidCert = caCert && caCert !== 'your_ca_certificate_if_applicable';

// 🛡️ SSL: Resilient configuration for Supabase / Render
// We explicitly allow self-signed certificates in production if no CA cert is provided.
// This prevents "self-signed certificate" or "connection timeout" errors common in PaaS environments.
const sslConfig = process.env.DATABASE_URL?.includes('supabase') || !isDevelopment
  ? {
      rejectUnauthorized: hasValidCert ? true : false,
      ca: hasValidCert ? caCert : undefined,
    }
  : false;

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: sslConfig,
  // ⏱️ Optimization: Fail fast if connection cannot be established
  connectionTimeoutMillis: 10000,
  idleTimeoutMillis: 30000,
  max: 20,
});

// Debug tool: logging connection user (Safe)
if (process.env.DATABASE_URL) {
  try {
    const url = new URL(process.env.DATABASE_URL);
    console.log(`[DB] Attempting connection to ${url.host} (SSL: ${!!sslConfig})`);
  } catch (e) {
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
