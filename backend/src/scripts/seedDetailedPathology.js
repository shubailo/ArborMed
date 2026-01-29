const db = require('../config/db');

async function seedPathologyDetailed() {
    try {
        console.log('🧬 Seeding Detailed Pathology Topics & Questions...');

        // 1. Get Pathology Parent
        const pathParent = await db.query("SELECT id FROM topics WHERE slug = 'pathology'");
        if (pathParent.rows.length === 0) {
            console.error('Pathology parent topic not found! Please run seedPathologyTopics.js first.');
            process.exit(1);
        }
        const parentId = pathParent.rows[0].id;

        const pathologySections = [
            {
                name: 'Cardiovascular Pathology',
                slug: 'cardiovascular-pathology',
                questions: [
                    { bloom: 1, q: "What is the most common cause of Left-Sided Heart Failure?", o: ["Smoking", "Hypertension", "Diabetes", "Obesity"], c: 1 },
                    { bloom: 2, q: "Aschoff bodies are pathognomonic for which condition?", o: ["Myocarditis", "Rheumatic Heart Disease", "Endocarditis", "Pericarditis"], c: 1 },
                    { bloom: 3, q: "A 65yo patient presents with sudden tearing chest pain radiating to the back. Most likely diagnosis?", o: ["MI", "Aortic Dissection", "Angina", "Pneumothorax"], c: 1 }
                ]
            },
            {
                name: 'Respiratory System Pathology',
                slug: 'respiratory-pathology',
                questions: [
                    { bloom: 1, q: "Which type of lung cancer is most strongly associated with non-smokers?", o: ["Small cell", "Adenocarcinoma", "Squamous cell", "Large cell"], c: 1 },
                    { bloom: 2, q: "What is the characteristic histological finding in Sarcoidosis?", o: ["Caseating granuloma", "Non-caseating granuloma", "Abscess", "Fibrosis"], c: 1 },
                    { bloom: 3, q: "Patient with heavy asbestos exposure presents with pleural thickening. Which cancer are they at risk for?", o: ["Adenocarcinoma", "Mesothelioma", "Leukemia", "Lymphoma"], c: 1 }
                ]
            },
            {
                name: 'Gastrointestinal Pathology',
                slug: 'gastrointestinal-pathology',
                questions: [
                    { bloom: 1, q: "Which part of the GI tract is most commonly affected by Crohn's disease?", o: ["Esophagus", "Terminal Ileum", "Rectum", "Stomach"], c: 1 },
                    { bloom: 2, q: "Barrett's esophagus is a metaplasia of which cell type?", o: ["Squamous to Columnar", "Columnar to Squamous", "Cuboidal to Squamous", "None"], c: 0 },
                    { bloom: 3, q: "Skip lesions and transmural inflammation are characteristic of:", o: ["Ulcerative Colitis", "Crohn's Disease", "Celiac Disease", "IBS"], c: 1 }
                ]
            },
            {
                name: 'Liver, Biliary Tract, and Pancreatic Pathology',
                slug: 'liver-biliary-pancreatic-pathology',
                questions: [
                    { bloom: 1, q: "What is the primary risk factor for Pancreatic Adenocarcinoma?", o: ["Alcohol", "Smoking", "Sugar", "Salt"], c: 1 },
                    { bloom: 2, q: "Mallory-Denk bodies are commonly seen in:", o: ["Wilson's disease", "Alcoholic Steatohepatitis", "Viral Hepatitis", "Hemochromatosis"], c: 1 },
                    { bloom: 3, q: "A patient with long-term Hepatitis C is at high risk for which primary liver cancer?", o: ["Angiosarcoma", "Hepatocellular Carcinoma", "Cholangiocarcinoma", "Hepatoblastoma"], c: 1 }
                ]
            },
            {
                name: 'Nephropathology and Uropathology',
                slug: 'nephro-uropathology',
                questions: [
                    { bloom: 1, q: "What is the hallmark finding in Minimal Change Disease on Electron Microscopy?", o: ["Splitting GBM", "Podocyte effacement", "Spikes", "Tram-tracks"], c: 1 },
                    { bloom: 2, q: "Which kidney stone is associated with Proteus infections?", o: ["Calcium Oxalate", "Struvite", "Uric Acid", "Cystine"], c: 1 },
                    { bloom: 3, q: "A child presents with hematuria and hypertension 2 weeks after a sore throat. Diagnostic suspect?", o: ["IgA Nephropathy", "PSGN", "Goodpasture", "Alport"], c: 1 }
                ]
            },
            {
                name: 'Hematopathology',
                slug: 'hematopathology',
                questions: [
                    { bloom: 1, q: "Reed-Sternberg cells are characteristic of:", o: ["Burkitt Lymphoma", "Hodgkin Lymphoma", "CLL", "Multiple Myeloma"], c: 1 },
                    { bloom: 2, q: "The Philadelphia Chromosome t(9;22) is the hallmark of:", o: ["AML", "CML", "ALL", "CLL"], c: 1 },
                    { bloom: 3, q: "A patient's bone marrow shows 'Starry sky' appearance. Diagnosis?", o: ["Follicular Lymphoma", "Burkitt Lymphoma", "DLBCL", "Marginal Zone"], c: 1 }
                ]
            },
            {
                name: 'Neuropathology',
                slug: 'neuropathology-specific',
                questions: [
                    { bloom: 1, q: "Which protein accumulates in Alzheimer's neurofibrillary tangles?", o: ["Amyloid-beta", "Tau", "Alpha-synuclein", "Prion"], c: 1 },
                    { bloom: 2, q: "Negri bodies are diagnostic for which viral infection?", o: ["HSV", "Rabies", "CMV", "HIV"], c: 1 },
                    { bloom: 3, q: "Sudden headache described as 'worst of my life' suggests:", o: ["Migraine", "Subarachnoid Hemorrhage", "Stroke", "Tumor"], c: 1 }
                ]
            },
            {
                name: 'Endocrine and Soft Tissue Pathology',
                slug: 'endocrine-soft-tissue-pathology',
                questions: [
                    { bloom: 1, q: "What is the most common thyroid malignancy?", o: ["Medullary", "Papillary", "Follicular", "Anaplastic"], c: 1 },
                    { bloom: 2, q: "Hashimoto's thyroiditis is a risk factor for which cancer?", o: ["Papillary carcinoma", "B-cell Lymphoma", "Medullary carcinoma", "Sarcoma"], c: 1 },
                    { bloom: 3, q: "Patient with hypertension, sweating, and palpitations likely has a tumor in:", o: ["Thyroid", "Adrenal Medulla (Pheochromocytoma)", "Pituitary", "Pancreas"], c: 1 }
                ]
            },
            {
                name: 'Male Genital Pathology',
                slug: 'male-genital-pathology',
                questions: [
                    { bloom: 1, q: "Where does prostate adenocarcinoma most commonly arise?", o: ["Transition zone", "Peripheral zone", "Central zone", "Periurethral"], c: 1 },
                    { bloom: 2, q: "The most common germ cell tumor in young men is:", o: ["Teratoma", "Seminoma", "Yolk sac tumor", "Choriocarcinoma"], c: 1 },
                    { bloom: 3, q: "Elevated AFP in a testicular tumor suggests:", o: ["Seminoma", "Yolk Sac Tumor", "Leydig cell tumor", "Sertoli cell tumor"], c: 1 }
                ]
            },
            {
                name: 'Female Genital Pathology',
                slug: 'female-genital-pathology',
                questions: [
                    { bloom: 1, q: "Which HPV strains are higher risk for cervical cancer?", o: ["6 & 11", "16 & 18", "1 & 2", "5 & 8"], c: 1 },
                    { bloom: 2, q: "Chocolate cysts are associated with:", o: ["PCOS", "Endometriosis", "Ovarian Cancer", "Teratoma"], c: 1 },
                    { bloom: 3, q: "The most common benign tumor of the female reproductive tract is:", o: ["Fibroadenoma", "Leiomyoma (Fibroid)", "Teratoma", "Endometrial polyp"], c: 1 }
                ]
            },
            {
                name: 'Dermatopathology',
                slug: 'dermatopathology',
                questions: [
                    { bloom: 1, q: "What is the most aggressive primary skin cancer?", o: ["BCC", "Melanoma", "SCC", "Targetoid hemangioma"], c: 1 },
                    { bloom: 2, q: "A 'pearly papule with telangiectasia' is characteristic of:", o: ["SCC", "BCC", "Melanoma", "Seborrheic keratosis"], c: 1 },
                    { bloom: 3, q: "The 'ABCDE' rule is used to evaluate:", o: ["Psoriasis", "Melanoma", "Eczema", "Basal cell carcinoma"], c: 1 }
                ]
            },
            {
                name: 'Bone Pathology',
                slug: 'bone-pathology',
                questions: [
                    { bloom: 1, q: "What is the most common primary malignant bone tumor in children?", o: ["Osteosarcoma", "Ewing Sarcoma", "Chondrosarcoma", "Osteoma"], c: 0 },
                    { bloom: 2, q: "'Onion skin' periosteal reaction is seen in:", o: ["Osteosarcoma", "Ewing Sarcoma", "Osteoid Osteoma", "Enchondroma"], c: 1 },
                    { bloom: 3, q: "Osteosarcoma most commonly occurs in which part of the bone?", o: ["Epiphysis", "Metaphysis", "Diaphysis", "Cortex"], c: 1 }
                ]
            }
        ];

        for (const section of pathologySections) {
            console.log(`Processing: ${section.name}`);

            // 2. Ensure topic exists
            let topicRes = await db.query("SELECT id FROM topics WHERE slug = $1", [section.slug]);
            let topicId;
            if (topicRes.rows.length === 0) {
                const inserted = await db.query(
                    "INSERT INTO topics (name, slug, parent_id) VALUES ($1, $2, $3) RETURNING id",
                    [section.name, section.slug, parentId]
                );
                topicId = inserted.rows[0].id;
            } else {
                topicId = topicRes.rows[0].id;
            }

            // 3. Insert Questions (Simple cleanup first)
            await db.query(`DELETE FROM responses WHERE question_id IN (SELECT id FROM questions WHERE topic_id = $1)`, [topicId]);
            await db.query("DELETE FROM questions WHERE topic_id = $1", [topicId]);

            for (const q of section.questions) {
                await db.query(
                    `INSERT INTO questions (topic_id, text, options, correct_answer, bloom_level, type, difficulty)
                     VALUES ($1, $2, $3, $4, $5, 'multiple_choice', 1)`,
                    [topicId, q.q, JSON.stringify(q.o), q.c, q.bloom]
                );
            }
        }

        console.log('✅ All Pathology sections and questions seeded!');
        process.exit();
    } catch (err) {
        console.error('Seeding failed:', err);
        process.exit(1);
    }
}

seedPathologyDetailed();
