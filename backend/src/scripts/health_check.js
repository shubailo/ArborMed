const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

async function runHealthCheck() {
    console.log('🚀 Starting MedBuddy Quiz Health Check...\n');
    let hasErrors = false;

    try {
        // 1. Check Schema Consistency
        const colRes = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'questions' AND (column_name = 'active' OR column_name = 'is_active')
    `);
        if (colRes.rows.length === 0) {
            console.error('❌ CRITICAL: questions table is missing an active status column.');
            hasErrors = true;
        } else {
            const colName = colRes.rows[0].column_name;
            console.log(`✅ Schema: "${colName}" column found in questions table.`);
        }

        // 2. Check Major Subjects
        const subjects = ['pathophysiology', 'pathology', 'microbiology', 'pharmacology', 'ecg'];
        const subRes = await pool.query(`
      SELECT slug FROM topics WHERE parent_id IS NULL AND slug = ANY($1)
    `, [subjects]);
        const foundSlugs = subRes.rows.map(r => r.slug);
        const missing = subjects.filter(s => !foundSlugs.includes(s));

        if (missing.length > 0) {
            console.error(`❌ CRITICAL: Missing major subjects: ${missing.join(', ')}`);
            hasErrors = true;
        } else {
            console.log('✅ Hierarchy: All major subjects found.');
        }

        // 3. Check for Orphan Topics
        const orphanRes = await pool.query(`
      SELECT name_en, slug FROM topics 
      WHERE parent_id IS NULL AND slug NOT IN ('pathophysiology', 'pathology', 'microbiology', 'pharmacology', 'ecg', 'cases', 'general', 'other')
    `);
        if (orphanRes.rows.length > 0) {
            console.warn(`⚠️  WARNING: Found ${orphanRes.rows.length} potentially orphaned root topics:`);
            orphanRes.rows.forEach(r => console.warn(`   - ${r.name_en} (${r.slug})`));
        }

        // 4. Check Question Availability per Subject
        const qCountRes = await pool.query(`
      SELECT t_parent.name_en as subject, COUNT(q.id) as q_count
      FROM topics t_parent
      LEFT JOIN topics t_child ON t_child.parent_id = t_parent.id
      LEFT JOIN questions q ON q.topic_id = t_child.id AND q.active = TRUE
      WHERE t_parent.parent_id IS NULL
      GROUP BY t_parent.id, t_parent.name_en
      ORDER BY q_count ASC
    `);
        console.log('\n📊 Question Counts per Subject:');
        qCountRes.rows.forEach(r => {
            const status = parseInt(r.q_count) === 0 ? '❌ EMPTY' : '✅ OK';
            console.log(`   ${r.subject.padEnd(20)}: ${r.q_count.toString().padEnd(5)} [${status}]`);
            if (parseInt(r.q_count) === 0 && subjects.includes(r.subject.toLowerCase())) {
                hasErrors = true;
            }
        });

        // 5. Check for Empty Sections (Children)
        const emptySecRes = await pool.query(`
      SELECT t.name_en, t.slug, p.name_en as parent
      FROM topics t
      JOIN topics p ON t.parent_id = p.id
      LEFT JOIN questions q ON q.topic_id = t.id AND q.active = TRUE
      GROUP BY t.id, t.name_en, t.slug, p.name_en
      HAVING COUNT(q.id) = 0
    `);
        if (emptySecRes.rows.length > 0) {
            console.log(`\n📂 Found ${emptySecRes.rows.length} sections with zero active questions (Coming Soon state):`);
            emptySecRes.rows.forEach(r => console.log(`   - [${r.parent}] ${r.name_en} (${r.slug})`));
        }

        console.log('\n-------------------------------------------');
        if (hasErrors) {
            console.log('❌ Health Check FAILED. Please address the critical issues above.');
            process.exit(1);
        } else {
            console.log('✨ Health Check PASSED. System is stable.');
            process.exit(0);
        }

    } catch (err) {
        console.error('💥 FATAL ERROR during health check:', err);
        process.exit(1);
    }
}

runHealthCheck();
