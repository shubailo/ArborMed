const db = require('../config/db');

const diagnoses = [
    { code: 'NSR', name_en: 'Normal Sinus Rhythm', name_hu: 'Normál Szinusz Ritmus', severity: 'normal', desc_en: 'Regular rhythm, rate 60-100, P per QRS.' },
    { code: 'SINUS_TACHY', name_en: 'Sinus Tachycardia', name_hu: 'Szinusz Tachikardia', severity: 'warning', desc_en: 'Regular rhythm, rate > 100.' },
    { code: 'SINUS_BRADY', name_en: 'Sinus Bradycardia', name_hu: 'Szinusz Bradikardia', severity: 'warning', desc_en: 'Regular rhythm, rate < 60.' },
    { code: 'AFIB', name_en: 'Atrial Fibrillation', name_hu: 'Pitvarfibrilláció', severity: 'warning', desc_en: 'Irregularly irregular, no P waves.' },
    { code: 'AFLUT', name_en: 'Atrial Flutter', name_hu: 'Pitvarlebegés', severity: 'warning', desc_en: 'Sawtooth P waves (F waves).' },
    { code: 'VT', name_en: 'Ventricular Tachycardia', name_hu: 'Kamrai Tachikardia', severity: 'critical', desc_en: 'Wide QRS regular tachycardia.' },
    { code: 'VF', name_en: 'Ventricular Fibrillation', name_hu: 'Kamrai Fibrilláció', severity: 'critical', desc_en: 'Chaotic electrical activity.' },
    { code: 'STEMI_INF', name_en: 'Inferior STEMI', name_hu: 'Alsó fali STEMI', severity: 'critical', desc_en: 'ST elevation in II, III, aVF.' },
    { code: 'STEMI_ANT', name_en: 'Anterior STEMI', name_hu: 'Elülső fali STEMI', severity: 'critical', desc_en: 'ST elevation in V1-V4.' },
];

const seed = async () => {
    try {
        console.log('🌱 Seeding ECG Diagnoses...');

        for (const d of diagnoses) {
            await db.query(`
                INSERT INTO ecg_diagnoses (code, name_en, name_hu, description_en, severity_level)
                VALUES ($1, $2, $3, $4, $5)
                ON CONFLICT (code) DO NOTHING
            `, [d.code, d.name_en, d.name_hu, d.desc_en, d.severity]);
        }

        console.log('✅ ECG Diagnoses seeded!');
        process.exit(0);
    } catch (err) {
        console.error('❌ Seeding failed:', err);
        process.exit(1);
    }
};

seed();
