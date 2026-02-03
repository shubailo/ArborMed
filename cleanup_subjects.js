const db = require('./backend/src/config/db');
const readline = require('readline');

async function resolveSubjectId(nameOrId) {
  try {
    // Try to lookup by name first (primary key)
    let result = await db.query(
      'SELECT id, name_en FROM topics WHERE parent_id IS NULL AND name_en = $1',
      [nameOrId]
    );

    if (result.rows.length > 0) {
      return { id: result.rows[0].id, name: result.rows[0].name_en, found: true };
    }

    // If name not found, try by ID and validate it's a parent topic
    if (typeof nameOrId === 'number') {
      result = await db.query(
        'SELECT id, name_en FROM topics WHERE id = $1 AND parent_id IS NULL',
        [nameOrId]
      );

      if (result.rows.length > 0) {
        return { id: result.rows[0].id, name: result.rows[0].name_en, found: true };
      }
    }

    return { found: false };
  } catch (error) {
    console.error(`  ❌ Error resolving subject: ${error.message}`);
    return { found: false };
  }
}

async function cleanupSubjects(isDryRun = false) {
  try {
    const modeLabel = isDryRun ? '🏜️  DRY RUN MODE (no deletions)' : '🧹 LIVE MODE (deletions will occur)';
    console.log(`${modeLabel}\nStarting cleanup of extra subjects...\n`);
    
    // Subjects to delete (keep ECG as a special subject for ECG cases)
    const subjectsToDelete = [
      { name: 'Endocrine System', id: 82 },
      { name: 'Neurology', id: 83 },
      { name: 'Renal System', id: 81 }
    ];
    
    for (const subject of subjectsToDelete) {
      console.log(`Processing: ${subject.name}...`);
      
      // Resolve subject by name (authoritative) or validate ID
      const resolved = await resolveSubjectId(subject.name);
      
      if (!resolved.found) {
        console.log(`  ⚠️  Subject not found by name "${subject.name}". Attempting ID lookup...`);
        const byId = await resolveSubjectId(subject.id);
        
        if (!byId.found) {
          console.log(`  ❌ SKIPPED: Cannot find subject by name or ID. It may already be deleted.\n`);
          continue;
        }
        
        if (byId.name !== subject.name) {
          console.log(`  ❌ SKIPPED: ID/name mismatch. ID ${subject.id} maps to "${byId.name}", not "${subject.name}". Aborting deletion!\n`);
          continue;
        }
        
        console.log(`  ✓ Verified ID ${subject.id} matches name "${byId.name}"`);
      } else if (resolved.id !== subject.id) {
        console.log(`  ⚠️  Name found but ID mismatch: Expected ${subject.id}, found ${resolved.id}`);
        console.log(`  ✓ Using authoritative ID ${resolved.id} from database`);
      }
      
      const subjectId = resolved.id || subject.id;
      console.log(`  Deleting subject: ${resolved.name || subject.name} (ID: ${subjectId})`);
      
      // Wrap deletion operations in a transaction for atomicity
      let client;
      try {
        client = await db.pool.connect();
        await client.query('BEGIN');
        
        // First, find all child topics (sections) of this subject
        const topicsResult = await client.query(
          'SELECT id FROM topics WHERE parent_id = $1',
          [subjectId]
        );
        
        const topicIds = topicsResult.rows.map(r => r.id);
        console.log(`    Found ${topicIds.length} sections`);
        
        if (topicIds.length > 0) {
          // In dry-run mode, skip actual deletions
          if (isDryRun) {
            console.log(`    [DRY RUN] Would delete responses`);
            console.log(`    [DRY RUN] Would delete questions`);
            console.log(`    [DRY RUN] Would delete sections`);
          } else {
            // Delete responses for questions in these topics
            await client.query(
              `DELETE FROM responses WHERE question_id IN (
                SELECT id FROM questions WHERE topic_id = ANY($1)
              )`,
              [topicIds]
            );
            console.log(`    ✓ Deleted responses`);
            
            // Delete questions in these topics
            await client.query(
              'DELETE FROM questions WHERE topic_id = ANY($1)',
              [topicIds]
            );
            console.log(`    ✓ Deleted questions`);
            
            // Delete the topics (sections)
            await client.query(
              'DELETE FROM topics WHERE parent_id = $1',
              [subjectId]
            );
            console.log(`    ✓ Deleted sections`);
          }
        }
        
        // Delete the subject itself
        if (isDryRun) {
          console.log(`    [DRY RUN] Would delete subject`);
        } else {
          await client.query(
            'DELETE FROM topics WHERE id = $1',
            [subjectId]
          );
          console.log(`    ✓ Deleted subject`);
        }
        
        // Commit or rollback based on mode
        if (isDryRun) {
          await client.query('ROLLBACK');
          console.log(`  ✅ Dry-run simulation completed for subject ID ${subjectId}\n`);
        } else {
          await client.query('COMMIT');
          console.log(`  ✅ Transaction committed for subject ID ${subjectId}\n`);
        }
        
      } catch (error) {
        // Rollback on error
        if (client) {
          try {
            await client.query('ROLLBACK');
            console.log(`  ⚠️  Transaction rolled back for subject ID ${subjectId}`);
          } catch (rollbackError) {
            console.error(`  ❌ Rollback failed: ${rollbackError.message}`);
          }
        }
        console.error(`  ❌ Error deleting subject ID ${subjectId}: ${error.message}`);
        console.log(`  SKIPPED: Subject deletion aborted due to error\n`);
        // Continue to next subject instead of crashing
        continue;
        
      } finally {
        // Release client back to pool
        if (client) {
          client.release();
        }
      }
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

async function confirmExecution() {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  return new Promise((resolve) => {
    console.log('\n⚠️  WARNING: This will DELETE subjects and their associated data!\n');
    console.log('Subjects to be deleted:');
    console.log('  - Endocrine System');
    console.log('  - Neurology');
    console.log('  - Renal System\n');
    
    rl.question('Type "YES" to confirm, or press Enter to abort: ', (answer) => {
      rl.close();
      resolve(answer.trim().toUpperCase() === 'YES');
    });
  });
}

async function main() {
  // Check for command-line flags
  const isDryRun = process.argv.includes('--dry-run');
  
  if (isDryRun) {
    console.log('\n📋 Running in DRY-RUN mode. No changes will be made.\n');
    await cleanupSubjects(true);
  } else {
    // Interactive confirmation for live mode
    const confirmed = await confirmExecution();
    
    if (confirmed) {
      console.log('\n✅ Confirmed. Starting cleanup...\n');
      await cleanupSubjects(false);
    } else {
      console.log('\n❌ Aborted. No changes were made.');
      process.exit(0);
    }
  }
}

main();
