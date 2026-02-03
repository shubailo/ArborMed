const db = require('./backend/src/config/db');

async function checkSubjects() {
  try {
    // Get all topics where parent_id is NULL (these are the subjects)
    const result = await db.query('SELECT id, name_en, name_hu, slug, parent_id FROM topics WHERE parent_id IS NULL ORDER BY name_en ASC');
    console.log('Current subjects (parent_id = NULL):');
    result.rows.forEach(row => {
      console.log(`  ID: ${row.id}, Name: ${row.name_en}, Slug: ${row.slug}`);
    });
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

checkSubjects();
