const db = require('../config/db');

async function seedPathology() {
    try {
        console.log('🧬 Seeding Pathology Sections...');

        // 1. Create/Get Pathology Subject
        let pathologyRes = await db.query("SELECT id FROM topics WHERE slug = 'pathology'");
        let pathologyId;

        if (pathologyRes.rows.length === 0) {
            console.log('Creating parent topic: Pathology');
            const inserted = await db.query(
                "INSERT INTO topics (name_en, name_hu, slug) VALUES ('Pathology', 'Pathology', 'pathology') RETURNING id"
            );
            pathologyId = inserted.rows[0].id;
        } else {
            pathologyId = pathologyRes.rows[0].id;
        }

        const sections = [
            { name: 'Cardiovascular Pathology', slug: 'cardiovascular-pathology' },
            { name: 'Respiratory System Pathology', slug: 'respiratory-pathology' },
            { name: 'Gastrointestinal Pathology', slug: 'gastrointestinal-pathology' },
            { name: 'Liver, Biliary Tract, and Pancreatic Pathology', slug: 'liver-biliary-pancreatic-pathology' },
            { name: 'Nephropathology and Uropathology', slug: 'nephro-uropathology' },
            { name: 'Hematopathology', slug: 'hematopathology' },
            { name: 'Neuropathology', slug: 'neuropathology-specific' },
            { name: 'Endocrine and Soft Tissue Pathology', slug: 'endocrine-soft-tissue-pathology' },
            { name: 'Male Genital Pathology', slug: 'male-genital-pathology' },
            { name: 'Female Genital Pathology', slug: 'female-genital-pathology' },
            { name: 'Dermatopathology', slug: 'dermatopathology' },
            { name: 'Bone Pathology', slug: 'bone-pathology' }
        ];

        for (const section of sections) {
            // Check if exists
            const exists = await db.query("SELECT id FROM topics WHERE slug = $1", [section.slug]);
            if (exists.rows.length === 0) {
                console.log(`Adding section: ${section.name}`);
                await db.query(
                    "INSERT INTO topics (name_en, name_hu, slug, parent_id) VALUES ($1, $2, $3, $4)",
                    [section.name, section.name, section.slug, pathologyId]
                );
            } else {
                console.log(`Section already exists: ${section.name}`);
                // Update parent_id just in case
                await db.query("UPDATE topics SET parent_id = $1 WHERE slug = $2", [pathologyId, section.slug]);
            }
        }

        console.log('✅ Pathology sections seeded successfully.');
        process.exit();
    } catch (err) {
        console.error('Failed to seed pathology:', err);
        process.exit(1);
    }
}

seedPathology();
