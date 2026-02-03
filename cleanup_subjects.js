const db = require('./backend/src/config/db');

async function cleanupSubjects() {
  try {
    console.log('🧹 Starting cleanup of extra subjects...\n');
    
    // Subjects to delete (keep ECG as a special subject for ECG cases)
    const subjectsToDelete = [
      { id: 82, name: 'Endocrine System' },
      { id: 83, name: 'Neurology' },
      { id: 81, name: 'Renal System' }
    ];
    
    for (const subject of subjectsToDelete) {
      console.log(`Deleting subject: ${subject.name} (ID: ${subject.id})`);
      
      // First, find all child topics (sections) of this subject
      const topicsResult = await db.query(
        'SELECT id FROM topics WHERE parent_id = $1',
        [subject.id]
      );
      
      const topicIds = topicsResult.rows.map(r => r.id);
      console.log(`  Found ${topicIds.length} sections`);
      
      if (topicIds.length > 0) {
        // Delete responses for questions in these topics
        await db.query(
          `DELETE FROM responses WHERE question_id IN (
            SELECT id FROM questions WHERE topic_id = ANY($1)
          )`,
          [topicIds]
        );
        console.log(`  ✓ Deleted responses`);
        
        // Delete questions in these topics
        await db.query(
          'DELETE FROM questions WHERE topic_id = ANY($1)',
          [topicIds]
        );
        console.log(`  ✓ Deleted questions`);
        
        // Delete the topics (sections)
        await db.query(
          'DELETE FROM topics WHERE parent_id = $1',
          [subject.id]
        );
        console.log(`  ✓ Deleted sections`);
      }
      
      // Delete the subject itself
      await db.query(
        'DELETE FROM topics WHERE id = $1',
        [subject.id]
      );
      console.log(`  ✓ Deleted subject\n`);
    }
    
    console.log('✅ Cleanup completed!');
    console.log('\nRemaining subjects:');
    const remaining = await db.query(
      'SELECT id, name_en, slug FROM topics WHERE parent_id IS NULL ORDER BY name_en ASC'
    );
    remaining.rows.forEach(row => {
      console.log(`  - ${row.name_en} (${row.slug})`);
    });
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

cleanupSubjects();
