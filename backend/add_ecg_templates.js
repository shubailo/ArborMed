const db = require('./src/config/db');

async function migrateDiagnoses() {
    try {
        console.log("Adding standard_findings_json column...");
        await db.query(`
      ALTER TABLE ecg_diagnoses 
      ADD COLUMN IF NOT EXISTS standard_findings_json JSONB;
    `);
        console.log("Column added.");

        console.log("Seeding templates...");

        // Seed Normal Sinus Rhythm
        const sinusFindings = {
            rhythm: { regularity: 'Regular', sinus: true, p_qrs_relation: '1:1' },
            rate: { min: 60, max: 100 },
            conduction: { pr_interval: 160, qrs_duration: 80, qt_interval: 400, av_block: 'None' },
            axis: { quadrant: 'Normal' },
            p_wave: { morphology: 'Normal', atrial_enlargement: 'None' },
            qrs_morph: { hypertrophy: 'None', bbb: 'None', q_waves: 'None' },
            st_t: { ischemia: 'None', t_wave: 'Normal' }
        };

        await db.query(`
        UPDATE ecg_diagnoses 
        SET standard_findings_json = $1 
        WHERE code = 'NSR' OR name_en ILIKE '%Sinus Rhythm%'
    `, [JSON.stringify(sinusFindings)]);

        // Seed Atrial Fibrillation
        const afibFindings = {
            rhythm: { regularity: 'Irregularly Irregular', sinus: false, p_qrs_relation: 'Dissociated' }, // Variable/Dissociated
            rate: { min: 60, max: 150 }, // Variable
            conduction: { pr_interval: null, qrs_duration: 80, qt_interval: 380, av_block: 'None' }, // No PR
            axis: { quadrant: 'Normal' },
            p_wave: { morphology: 'Absent', atrial_enlargement: 'None' }, // Fibrillatory waves
            qrs_morph: { hypertrophy: 'None', bbb: 'None', q_waves: 'None' },
            st_t: { ischemia: 'None', t_wave: 'Normal' }
        };

        await db.query(`
        UPDATE ecg_diagnoses 
        SET standard_findings_json = $1 
        WHERE code = 'AFIB' OR name_en ILIKE '%Atrial Fibrillation%'
    `, [JSON.stringify(afibFindings)]);

        console.log("Seeding complete.");

    } catch (err) {
        console.error("Migration failed:", err.message);
    } finally {
        process.exit();
    }
}

migrateDiagnoses();
