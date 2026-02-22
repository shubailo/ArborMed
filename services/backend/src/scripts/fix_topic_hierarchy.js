const db = require('../config/db');

/**
 * fix_topic_hierarchy.js
 * Restructures the topics table to ensure major subjects have children sections.
 * Handles localized column names (name_en, name_hu).
 */
async function fixHierarchy() {
    try {
        console.log('🏗️ Starting Topic Hierarchy Repair...');

        const subjectMapping = {
            'pathophysiology': {
                name: 'Pathophysiology',
                children: [
                    'cardiovascular', 'respiratory', 'gastrointestinal', 'renal',
                    'endocrine', 'neurology', 'haematology', 'hepatobiliary-system',
                    'gastrointestinal-system', 'haematology-system', 'endocrinology-system',
                    'metabolism-nutrition', 'renal-system', 'fluid-electrolyte-homeostasis',
                    'nervous-system-patho', 'thermoregulation-system'
                ]
            },
            'pathology': {
                name: 'Pathology',
                children: [
                    'cardiovascular-pathology', 'respiratory-pathology', 'gastrointestinal-pathology',
                    'liver-biliary-pancreatic-pathology', 'nephro-uropathology', 'hematopathology',
                    'neuropathology-specific', 'endocrine-soft-tissue-pathology', 'male-genital-pathology',
                    'female-genital-pathology', 'dermatopathology', 'bone-pathology'
                ]
            },
            'microbiology': {
                name: 'Microbiology',
                children: []
            },
            'pharmacology': {
                name: 'Pharmacology',
                children: []
            },
            'ecg': {
                name: 'ECG',
                children: []
            }
        };

        for (const [parentSlug, data] of Object.entries(subjectMapping)) {
            console.log(`\n📁 Processing Subject: ${data.name} (${parentSlug})`);

            // 1. Ensure parent exists
            let parentRes = await db.query("SELECT id FROM topics WHERE slug = $1", [parentSlug]);
            let parentId;

            if (parentRes.rows.length === 0) {
                console.log(`   ➕ Creating parent: ${data.name}`);
                const inserted = await db.query(
                    "INSERT INTO topics (name_en, name_hu, slug) VALUES ($1, $2, $3) RETURNING id",
                    [data.name, data.name, parentSlug]
                );
                parentId = inserted.rows[0].id;
            } else {
                parentId = parentRes.rows[0].id;
                console.log(`   ✅ Parent exists (ID: ${parentId})`);
            }

            // 2. Link children
            for (const childSlug of data.children) {
                let childRes = await db.query("SELECT id FROM topics WHERE slug = $1", [childSlug]);
                if (childRes.rows.length > 0) {
                    const childId = childRes.rows[0].id;
                    await db.query("UPDATE topics SET parent_id = $1 WHERE id = $2", [parentId, childId]);
                    console.log(`   🔗 Linked child: ${childSlug}`);
                } else {
                    console.log(`   ⚠️ Child not found: ${childSlug} (Skipping linkage)`);
                }
            }
        }

        console.log('\n✅ Topic Hierarchy Repair Complete!');
        process.exit(0);
    } catch (err) {
        console.error('\n❌ Repair Failed:', err);
        process.exit(1);
    }
}

fixHierarchy();
