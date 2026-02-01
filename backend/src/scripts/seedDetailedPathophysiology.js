const db = require('../config/db');

async function seedPathophysiologyDetailed() {
    try {
        console.log('🧪 Seeding Detailed Pathophysiology Topics & Questions...');

        // 1. Create/Get Pathophysiology Parent
        let pathoRes = await db.query("SELECT id FROM topics WHERE slug = 'pathophysiology'");
        let parentId;

        if (pathoRes.rows.length === 0) {
            console.log('Creating parent topic: Pathophysiology');
            const inserted = await db.query(
                "INSERT INTO topics (name_en, name_hu, slug) VALUES ('Pathophysiology', 'Pathophysiology', 'pathophysiology') RETURNING id"
            );
            parentId = inserted.rows[0].id;
        } else {
            parentId = pathoRes.rows[0].id;
        }

        const sections = [
            {
                name: 'Gastrointestinal System',
                slug: 'gastrointestinal-system',
                questions: [
                    { bloom: 1, q: "What is the principal site of nutrient absorption in the GI tract?", o: ["Stomach", "Small Intestine", "Large Intestine", "Esophagus"], c: 1 },
                    { bloom: 2, q: "What is the primary role of Hydrochloric Acid (HCl) in the stomach?", o: ["Digest fat", "Activate pepsinogen to pepsin", "Absorb Vitamin B12", "Neutralize bile"], c: 1 },
                    { bloom: 3, q: "A patient with chronic pancreatitis presents with fatty, foul-smelling stools (steatorrhea). This is due to deficiency of:", o: ["Amylase", "Lipase", "Trypsin", "Pepsin"], c: 1 }
                ]
            },
            {
                name: 'Hepatobiliary System',
                slug: 'hepatobiliary-system',
                questions: [
                    { bloom: 1, q: "Which organ is the major site of bile production?", o: ["Gallbladder", "Pancreas", "Liver", "Spleen"], c: 2 },
                    { bloom: 2, q: "Jaundice (icterus) occurs primarily due to the accumulation of:", o: ["Urea", "Bilirubin", "Ammonia", "Cholesterol"], c: 1 },
                    { bloom: 3, q: "Ascites in patients with liver cirrhosis is primarily caused by:", o: ["Low blood sugar", "Portal hypertension and hypoalbuminemia", "Excess vitamin A", "Renal failure"], c: 1 }
                ]
            },
            {
                name: 'Haematology',
                slug: 'haematology-system',
                questions: [
                    { bloom: 1, q: "Which hormone, produced by the kidneys, stimulates red blood cell production?", o: ["Insulin", "Erythropoietin", "Renin", "Aldosterone"], c: 1 },
                    { bloom: 2, q: "What is the most common cause of microcytic, hypochromic anemia?", o: ["Vitamin B12 deficiency", "Iron deficiency", "Folate deficiency", "Aplastic anemia"], c: 1 },
                    { bloom: 3, q: "A patient with a normal platelet count but prolonged bleeding time and normal PT/aPTT may have a defect in:", o: ["Clotting Factor VIII", "Von Willebrand Factor (vWF)", "Factor IX", "Factor X"], c: 1 }
                ]
            },
            {
                name: 'Endocrinology',
                slug: 'endocrinology-system',
                questions: [
                    { bloom: 1, q: "Which of the following is produced by the posterior pituitary gland?", o: ["Growth Hormone", "Antidiuretic Hormone (ADH)", "TSH", "ACTH"], c: 1 },
                    { bloom: 2, q: "The primary pathophysiology of Type 2 Diabetes Mellitus involves:", o: ["Absolute insulin deficiency", "Insulin resistance", "Destruction of alpha cells", "Excessive glucagon"], c: 1 },
                    { bloom: 3, q: "Hypercalcemia accompanied by a low PTH level suggests which likely cause?", o: ["Primary Hyperparathyroidism", "Malignancy-associated hypercalcemia", "Vitamin D deficiency", "Hypoparathyroidism"], c: 1 }
                ]
            },
            {
                name: 'Metabolism & Nutrition',
                slug: 'metabolism-nutrition',
                questions: [
                    { bloom: 1, q: "Which vitamin is essential for the intestinal absorption of calcium?", o: ["Vitamin A", "Vitamin C", "Vitamin D", "Vitamin K"], c: 2 },
                    { bloom: 2, q: "What is the primary function of glycogen in the human body?", o: ["Build muscle", "Short-term storage of glucose", "Long-term energy in adipose tissue", "Structural support in bones"], c: 1 },
                    { bloom: 3, q: "The symptoms of Scurvy (bleeding gums, poor wound healing) are due to the disruption of:", o: ["Glucose metabolism", "Collagen hydroxylation", "Iron transport", "Lipid oxidation"], c: 1 }
                ]
            },
            {
                name: 'Renal System',
                slug: 'renal-system',
                questions: [
                    { bloom: 1, q: "What is the functional unit of the kidney?", o: ["Neuron", "Nephron", "Alveolus", "Hepatocyte"], c: 1 },
                    { bloom: 2, q: "How does the hormone Aldosterone affect renal sodium handling?", o: ["Increases sodium excretion", "Promotes sodium reabsorption", "Inhibits water reabsorption", "Increases potassium reabsorption"], c: 1 },
                    { bloom: 3, q: "A significant reduction in GFR in patients with congestive heart failure is primarily due to:", o: ["Direct toxic effect", "Reduced renal blood flow (prerenal)", "Urinary obstruction", "Glomerulonephritis"], c: 1 }
                ]
            },
            {
                name: 'Fluid–Electrolyte Homeostasis',
                slug: 'fluid-electrolyte-homeostasis',
                questions: [
                    { bloom: 1, q: "Which ion is the major intracellular cation?", o: ["Sodium", "Potassium", "Chloride", "Calcium"], c: 1 },
                    { bloom: 2, q: "Severe hyponatremia can lead to neurological symptoms primarily because of:", o: ["Cellular dehydration", "Cerebral edema (brain cell swelling)", "Increased action potentials", "Voltage-gated channel blockage"], c: 1 },
                    { bloom: 3, q: "What is the primary respiratory compensation for metabolic acidosis?", o: ["Hypoventilation (Retaining CO2)", "Hyperventilation (Blowing off CO2)", "Increased bicarbonate reabsorption", "Increased urea production"], c: 1 }
                ]
            },
            {
                name: 'Nervous System',
                slug: 'nervous-system-patho',
                questions: [
                    { bloom: 1, q: "Which neurotransmitter is primarily used at the Neuromuscular Junction?", o: ["Dopamine", "Serotonin", "Acetylcholine", "GABA"], c: 2 },
                    { bloom: 2, q: "The primary function of the myelin sheath in the nervous system is to:", o: ["Provide nutrients", "Increase the speed of nerve impulse conduction", "Store calcium", "Protect from infections"], c: 1 },
                    { bloom: 3, q: "Identify the sign characteristic of an Upper Motor Neuron (UMN) lesion:", o: ["Muscle atrophy", "Fasciculations", "Hyperreflexia and Spasticity", "Flaccid paralysis"], c: 2 }
                ]
            },
            {
                name: 'Thermoregulation',
                slug: 'thermoregulation-system',
                questions: [
                    { bloom: 1, q: "Which part of the brain acts as the body's thermostat?", o: ["Thalamus", "Hypothalamus", "Medulla", "Cerebellum"], c: 1 },
                    { bloom: 2, q: "How does shivering help regulate body temperature?", o: ["Increases evaporation", "Generates heat via involuntary muscle contraction", "Promotes vasodilation", "Decreases metabolic rate"], c: 1 },
                    { bloom: 3, q: "Malignant hyperthermia, a life-threatening response to certain anesthetics, is caused by a defect in:", o: ["Acetylcholine receptors", "Ryanodine receptors (excessive Ca2+ release)", "Sodium-Potassium pumps", "Chloride channels"], c: 1 }
                ]
            },
            // Group existing ones too
            { name: 'Cardiovascular System', slug: 'cardiovascular', questions: [] },
            { name: 'Respiratory System', slug: 'respiratory', questions: [] }
        ];

        for (const section of sections) {
            console.log(`Processing: ${section.name}`);

            // 2. Ensure topic exists under Pathophysiology
            let topicRes = await db.query("SELECT id FROM topics WHERE slug = $1", [section.slug]);
            let topicId;
            if (topicRes.rows.length === 0) {
                const inserted = await db.query(
                    "INSERT INTO topics (name_en, name_hu, slug, parent_id) VALUES ($1, $2, $3, $4) RETURNING id",
                    [section.name, section.name, section.slug, parentId]
                );
                topicId = inserted.rows[0].id;
            } else {
                topicId = topicRes.rows[0].id;
                // Ensure parent_id is correct
                await db.query("UPDATE topics SET parent_id = $1 WHERE id = $2", [parentId, topicId]);
            }

            // 3. Insert Questions (If any)
            if (section.questions.length > 0) {
                await db.query(`DELETE FROM responses WHERE question_id IN (SELECT id FROM questions WHERE topic_id = $1)`, [topicId]);
                await db.query("DELETE FROM questions WHERE topic_id = $1", [topicId]);

                for (const q of section.questions) {
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
                            q.q,
                            '',
                            JSON.stringify(q.o),
                            JSON.stringify([]),
                            q.o[q.c],
                            q.bloom,
                            '',
                            ''
                        ]
                    );
                }
            }
        }

        console.log('✅ Pathophysiology sections and questions seeded!');
        process.exit();
    } catch (err) {
        console.error('Seeding failed:', err);
        process.exit(1);
    }
}

seedPathophysiologyDetailed();
