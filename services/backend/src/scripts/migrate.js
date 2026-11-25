const { createHash } = require('node:crypto');
const fs = require('node:fs/promises');
const path = require('node:path');

const directory = path.join(__dirname, '../../migrations');
const baseline = '050_verified_legacy_schema';
const lockId = 185872925;

async function transaction(client, work) {
  await client.query('BEGIN');
  try {
    await work();
    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  }
}

async function migrate(client, { baselineOnly = false, dir = directory } = {}) {
  // One session owns the lock until all pending files are applied.
  await client.query('SELECT pg_advisory_lock($1)', [lockId]);
  try {
    await client.query(`CREATE TABLE IF NOT EXISTS arbormed_schema_migrations (
      filename text PRIMARY KEY, checksum text NOT NULL, applied_at timestamptz NOT NULL DEFAULT now()
    )`);
    await client.query(`ALTER TABLE arbormed_schema_migrations ENABLE ROW LEVEL SECURITY;
      REVOKE ALL ON arbormed_schema_migrations FROM PUBLIC;
      DO $permissions$ BEGIN
        IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'anon') THEN REVOKE ALL ON arbormed_schema_migrations FROM anon; END IF;
        IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticated') THEN REVOKE ALL ON arbormed_schema_migrations FROM authenticated; END IF;
      END $permissions$`);
    const applied = new Map((await client.query('SELECT filename, checksum FROM arbormed_schema_migrations'))
      .rows.map(row => [row.filename, row.checksum]));
    if (!applied.has(baseline)) {
      if (!baselineOnly) throw new Error('Restore or verify the legacy schema, then run npm run migrate -- --baseline.');
      // Detect an empty or obviously incompatible database before recording the operator-reviewed baseline.
      await client.query(`SELECT u.id, u.coins, u.password_hash, u.is_email_verified, t.revoked,
          q.metadata, r.user_id, p.user_id, s.user_id
        FROM users u, refresh_tokens t, questions q, responses r, user_topic_progress p, quiz_sessions s LIMIT 0`);
      await client.query('INSERT INTO arbormed_schema_migrations(filename, checksum) VALUES ($1,$2)',
        [baseline, 'operator-verified']);
    }
    if (baselineOnly) return;
    const files = (await fs.readdir(dir)).filter(name => /^\d{3}_.*\.sql$/.test(name) && Number(name.slice(0, 3)) > 50).sort();
    const versions = new Set();
    for (const file of files) {
      const version = file.slice(0, 3);
      if (versions.has(version)) throw new Error('Duplicate migration version ' + version);
      versions.add(version);
    }
    const pending = [];
    for (const historical of applied.keys()) {
      if (historical !== baseline && !files.includes(historical)) throw new Error('Applied migration is missing: ' + historical);
    }
    const latest = Math.max(50, ...[...applied.keys()].map(name => Number(name.slice(0, 3))));
    for (const file of files) {
      const sql = (await fs.readFile(path.join(dir, file), 'utf8')).replace(/\r\n/g, '\n');
      const checksum = createHash('sha256').update(sql).digest('hex');
      if (applied.has(file)) {
        if (applied.get(file) !== checksum) throw new Error('Applied migration changed: ' + file);
      } else {
        if (Number(file.slice(0, 3)) <= latest) throw new Error('Out-of-order migration: ' + file);
        pending.push({ file, sql, checksum });
      }
    }
    for (const { file, sql, checksum } of pending) {
      try {
        await transaction(client, async () => {
          await client.query(sql);
          await client.query('INSERT INTO arbormed_schema_migrations(filename, checksum) VALUES ($1,$2)', [file, checksum]);
        });
      } catch (cause) {
        throw new Error('Migration failed in ' + file, { cause });
      }
      console.log('Applied', file);
    }
  } finally {
    await client.query('SELECT pg_advisory_unlock($1)', [lockId]);
  }
}

if (require.main === module) {
  require('dotenv').config({ path: path.join(__dirname, '../../.env') });
  const { Pool } = require('pg');
  const { databaseOptions } = require('../config/databaseOptions');
  const pool = new Pool(databaseOptions({ ...process.env, DATABASE_URL: process.env.MIGRATION_DATABASE_URL || process.env.DATABASE_URL }));
  (async () => {
    const args = process.argv.slice(2);
    if (args.length && (args.length !== 1 || args[0] !== '--baseline')) throw new Error('Usage: npm run migrate [-- --baseline]');
    const client = await pool.connect();
    try { await migrate(client, { baselineOnly: args.length === 1 }); }
    finally { client.release(); }
  })().catch(error => {
    console.error(error.message, error.cause?.message || '');
    process.exitCode = 1;
  }).finally(() => pool.end());
}

module.exports = { migrate };
