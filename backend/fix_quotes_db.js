const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
});

async function fixQuotes() {
    try {
        console.log('Checking quotes table...');

        // First, check if new columns exist
        const checkCols = await pool.query(`
      SELECT column_name FROM information_schema.columns
      WHERE table_name = 'quotes' AND column_name IN ('title_en', 'title_hu', 'icon_name');
    `);

        console.log('Found columns:', checkCols.rows.map(r => r.column_name));

        // If columns don't exist, add them
        if (checkCols.rows.length === 0) {
            console.log('Adding missing columns...');
            await pool.query(`
        ALTER TABLE quotes 
        ADD COLUMN IF NOT EXISTS title_en VARCHAR(100) DEFAULT 'Study Break',
        ADD COLUMN IF NOT EXISTS title_hu VARCHAR(100) DEFAULT 'Tanul\u00e1s',
        ADD COLUMN IF NOT EXISTS icon_name VARCHAR(50) DEFAULT 'menu_book_rounded',
        ADD COLUMN IF NOT EXISTS custom_icon_url TEXT;
      `);
            console.log('Columns added!');
        }

        // Update null values
        console.log('Updating null values...');
        await pool.query(`
      UPDATE quotes 
      SET 
        title_en = COALESCE(title_en, 'Study Break'),
        title_hu = COALESCE(title_hu, 'Tanul\u00e1s'),
        icon_name = COALESCE(icon_name, 'menu_book_rounded')
      WHERE title_en IS NULL OR title_hu IS NULL OR icon_name IS NULL;
    `);

        // Check sample
        const sample = await pool.query('SELECT id, title_en, title_hu, icon_name FROM quotes LIMIT 2');
        console.log('Sample data:', JSON.stringify(sample.rows, null, 2));

        console.log('\n✅ Database fixed!');
        process.exit(0);
    } catch (error) {
        console.error('❌ Error:', error.message);
        process.exit(1);
    }
}

fixQuotes();
