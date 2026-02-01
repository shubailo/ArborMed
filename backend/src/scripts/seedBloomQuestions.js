const db = require('../config/db');

// BLOOM TAXONOMY:
// 1: Remember (Recall facts)
// 2: Understand (Explain concepts)
// 3: Apply (Use info in new situations)
// 4: Analyze (Draw connections)

const topicsData = [
    {
        name: 'Cardiovascular System',
        slug: 'cardiovascular',
        questions: [
            { bloom_level: 1, text: "Which chamber of the heart pumps blood to the lungs?", options: ["Left Ventricle", "Right Ventricle", "Left Atrium", "Right Atrium"], correct_index: 1 },
            { bloom_level: 1, text: "What is the primary natural pacemaker of the heart?", options: ["AV Node", "Bundle of His", "SA Node", "Purkinje Fibers"], correct_index: 2 },
            { bloom_level: 1, text: "Which valve is located between the left atrium and left ventricle?", options: ["Tricuspid", "Mitral", "Pulmonary", "Aortic"], correct_index: 1 },
            { bloom_level: 1, text: "What is the normal resting heart rate range for adults?", options: ["40-60 bpm", "60-100 bpm", "100-120 bpm", "120-140 bpm"], correct_index: 1 },
            { bloom_level: 1, text: "Deoxygenated blood enters the heart through which vessel?", options: ["Aorta", "Pulmonary Vein", "Vena Cava", "Pulmonary Artery"], correct_index: 2 },
            { bloom_level: 2, text: "Why does the left ventricle have a thicker wall than the right?", options: ["It holds more blood", "It pumps against higher systemic resistance", "It protects the heart from trauma", "It contains more valves"], correct_index: 1 },
            { bloom_level: 2, text: "What happens during atrial systole?", options: ["Ventricles relax and fill actively", "Ventricles contract", "Atria relax", "Blood leaves the aorta"], correct_index: 0 },
            { bloom_level: 2, text: "How does the parasympathetic nervous system affect heart rate?", options: ["Increases it via Norepinephrine", "Decreases it via Acetylcholine", "Increases it via Acetylcholine", "No effect"], correct_index: 1 },
            { bloom_level: 2, text: "What does the P-wave on an ECG represent?", options: ["Ventricular Repolarization", "Ventricular Depolarization", "Atrial Depolarization", "Atrial Repolarization"], correct_index: 2 },
            { bloom_level: 2, text: "Why are heart valves important?", options: ["To pump blood", "To prevent backflow", "To oxygenate blood", "To generate electrical impulses"], correct_index: 1 },
            { bloom_level: 3, text: "A patient has a heart rate of 40 bpm and dizziness. Which structure is likely failing?", options: ["Mitral Valve", "SA Node", "Aorta", "Pericardium"], correct_index: 1 },
            { bloom_level: 3, text: "You hear a 'swishing' sound after S1. What is the most likely cause?", options: ["Normal flow", "Systolic Murmur", "Diastolic Murmur", "Pericardial Rub"], correct_index: 1 },
            { bloom_level: 3, text: "In Right Sided Heart Failure, where would you expect fluid to accumulate?", options: ["Lungs (Pulmonary Edema)", "Legs and Abdomen (Peripheral Edema)", "Brain", "Left arm"], correct_index: 1 },
            { bloom_level: 3, text: "A patient takes a beta-blocker. What effect do you expect on the cardiac cycle?", options: ["Shortened Diastole", "Lengthened Diastole (Slower HR)", "Increased Contractility", "Increased SA Node firing"], correct_index: 1 },
            { bloom_level: 3, text: "ECG shows 'sawtooth' patterns. What is the rhythm?", options: ["Atrial Fibrillation", "Ventricular Tachycardia", "Atrial Flutter", "Sinus Rhythm"], correct_index: 2 }
        ]
    },
    {
        name: 'Respiratory System',
        slug: 'respiratory',
        questions: [
            { bloom_level: 1, text: "Where does gas exchange primarily occur in the lungs?", options: ["Bronchi", "Trachea", "Alveoli", "Pharynx"], correct_index: 2 },
            { bloom_level: 1, text: "Which muscle is primarily responsible for inspiration?", options: ["Abdominals", "Diaphragm", "Pectorals", "Trapezius"], correct_index: 1 },
            { bloom_level: 1, text: "What is the medical term for a 'collapsed lung'?", options: ["Pneumonia", "Asthma", "Pneumothorax", "Bronchitis"], correct_index: 2 },
            { bloom_level: 2, text: "What is the primary driver of the respiratory rate in a healthy person?", options: ["Low Oxygen", "High Carbon Dioxide", "High Oxygen", "Low Blood Pressure"], correct_index: 1 },
            { bloom_level: 2, text: "What happens during exhalation?", options: ["Diaphragm contracts", "Thoracic volume increases", "Intrapulmonary pressure increases", "Air flows into the lungs"], correct_index: 2 },
            { bloom_level: 3, text: "A patient has a 'barrel chest' and chronic cough. What is the likely diagnosis?", options: ["Acute Bronchitis", "COPD/Emphysema", "Pulmonary Embolism", "Cystic Fibrosis"], correct_index: 1 }
        ]
    }
];

const seedBloom = async () => {
    try {
        console.log('🌱 Seeding Bloom Questions...');

        for (const topicData of topicsData) {
            console.log(`Processing Topic: ${topicData.name}`);

            const topicRes = await db.query("SELECT id FROM topics WHERE slug = $1", [topicData.slug]);
            let topicId;

            if (topicRes.rows.length === 0) {
                const inserted = await db.query("INSERT INTO topics (name_en, name_hu, slug, parent_id) VALUES ($1, $2, $3, 1) RETURNING id", [topicData.name, topicData.name, topicData.slug]);
                topicId = inserted.rows[0].id;
            } else {
                topicId = topicRes.rows[0].id;
            }

            // Clear old questions for this topic
            await db.query(`DELETE FROM responses WHERE question_id IN (SELECT id FROM questions WHERE topic_id = $1)`, [topicId]);
            await db.query("DELETE FROM questions WHERE topic_id = $1", [topicId]);

            // Insert New Questions
            for (const q of topicData.questions) {
                await db.query(
                    `INSERT INTO questions (
                        topic_id, 
                        question_text_en, 
                        question_text_hu,
                        options_en, 
                        options_hu,
                        correct_answer, 
                        bloom_level, 
                        question_type, 
                        difficulty,
                        explanation_en,
                        explanation_hu
                    )
                     VALUES ($1, $2, $3, $4, $5, $6, $7, 'single_choice', 1, $8, $9)`,
                    [
                        topicId,
                        q.text,
                        '',
                        JSON.stringify(q.options),
                        JSON.stringify([]),
                        q.options[q.correct_index],
                        q.bloom_level,
                        '',
                        ''
                    ]
                );
            }
            console.log(`✅ Seeded ${topicData.questions.length} questions for ${topicData.name}.`);
        }

        console.log('🚀 All topics seeded successfully.');
        process.exit();
    } catch (err) {
        console.error('Seeding failed:', err);
        process.exit(1);
    }
};

seedBloom();
