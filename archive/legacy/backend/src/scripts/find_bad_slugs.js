const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

async function findBadSlugs() {
    console.log('🔍 Checking for problematic topic slugs...\n');
    try {
        const res = await pool.query(`
      SELECT id, name_en, slug 
      FROM topics 
      WHERE slug IS NULL 
         OR slug ~ '^\\s*$' 
         OR slug != lower(slug) 
         OR slug ~ '[^a-z0-9-]'
    `);

        if (res.rows.length === 0) {
            console.log('✅ No problematic slugs found.');
        } else {
            console.log(`❌ Found ${res.rows.length} problematic slugs:`);
            res.rows.forEach(r => {
                console.log(`ID: ${r.id}, Name: ${r.name_en}, Slug: '${r.slug}'`);
            });
        }

        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

findBadSlugs();
