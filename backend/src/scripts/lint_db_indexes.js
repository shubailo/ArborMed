const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

async function lintDatabase() {
    console.log('🔍 Starting Database Performance Lint...\n');
    let issuesFound = 0;

    try {
        // 1. Detect Unindexed Foreign Keys
        // This query finds foreign keys that don't have a corresponding index starting with the FK columns
        const unindexedFkQuery = `
      WITH fk_columns AS (
        SELECT
          ns.nspname AS schema_name,
          t.relname AS table_name,
          con.conname AS fk_name,
          con.conkey AS key_columns,
          t.oid AS table_oid
        FROM pg_constraint con
        JOIN pg_class t ON t.oid = con.conrelid
        JOIN pg_namespace ns ON ns.oid = t.relnamespace
        WHERE con.contype = 'f'
      ),
      indexed_columns AS (
        SELECT
          indrelid AS table_oid,
          indkey AS key_columns
        FROM pg_index
      )
      SELECT
        schema_name,
        table_name,
        fk_name,
        (
          SELECT string_agg(attname, ', ')
          FROM pg_attribute
          WHERE attrelid = table_oid AND attnum = ANY(key_columns)
        ) AS column_names
      FROM fk_columns f
      WHERE NOT EXISTS (
        SELECT 1
        FROM indexed_columns i
        WHERE i.table_oid = f.table_oid
          AND (i.key_columns::int2[])[0:cardinality(f.key_columns)-1] = f.key_columns::int2[]
      )
      AND schema_name = 'public'
      ORDER BY table_name;
    `;

        const fkRes = await pool.query(unindexedFkQuery);
        if (fkRes.rows.length > 0) {
            console.log('❌ UNINDEXED FOREIGN KEYS FOUND:');
            fkRes.rows.forEach(r => {
                console.log(`   - [${r.table_name}] ${r.fk_name} (Columns: ${r.column_names})`);
                issuesFound++;
            });
        } else {
            console.log('✅ All foreign keys are indexed.');
        }

        // 2. Detect Unused Indexes
        const unusedIndexQuery = `
      SELECT
        schemaname AS schema_name,
        relname AS table_name,
        indexrelname AS index_name,
        idx_scan AS scan_count
      FROM pg_stat_user_indexes
      WHERE idx_scan = 0
        AND schemaname = 'public'
        AND indexrelname NOT IN (
          SELECT conname FROM pg_constraint WHERE contype IN ('p', 'u')
        )
      ORDER BY table_name, index_name;
    `;

        const unusedRes = await pool.query(unusedIndexQuery);
        if (unusedRes.rows.length > 0) {
            console.log('\n⚠️  UNUSED INDEXES FOUND (Candidate for removal):');
            unusedRes.rows.forEach(r => {
                console.log(`   - [${r.table_name}] ${r.index_name} (Scans: ${r.scan_count})`);
                issuesFound++;
            });
        } else {
            console.log('\n✅ No unused user indexes found.');
        }

        console.log('\n-------------------------------------------');
        if (issuesFound > 0) {
            console.log(`🏁 Finished. Total issues found: ${issuesFound}`);
        } else {
            console.log('✨ Database is fully optimized!');
        }

        process.exit(0);
    } catch (err) {
        console.error('💥 Error running database lint:', err);
        process.exit(1);
    }
}

lintDatabase();
