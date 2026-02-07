const fs = require('fs');
const path = require('path');

const enDir = 'c:/Users/shuba/Desktop/Med_buddy/backend/src/data/questions/';
const huDir = 'c:/Users/shuba/Desktop/Med_buddy/backend/src/data/questions/hungarian/';
const outputFile = 'c:/Users/shuba/Desktop/Med_buddy/backend/src/data/questions/haematology_questions.json';

const mergeQuestions = () => {
    try {
        const enFiles = fs.readdirSync(enDir).filter(f => f.startsWith('high_density_batch_') && f.endsWith('.json'));
        const huFiles = fs.readdirSync(huDir).filter(f => f.startsWith('hu_high_density_batch_') && f.endsWith('.json'));

        console.log(`Found ${enFiles.length} English batches and ${huFiles.length} Hungarian batches.`);

        const enQuestions = [];
        enFiles.forEach(f => {
            const filePath = path.join(enDir, f);
            try {
                const content = JSON.parse(fs.readFileSync(filePath, 'utf8'));
                enQuestions.push(...content);
            } catch (e) {
                console.error(`❌ Failed to parse English: ${f}`, e.message);
            }
        });

        const huQuestionsMap = {};
        huFiles.forEach(f => {
            const filePath = path.join(huDir, f);
            try {
                const content = JSON.parse(fs.readFileSync(filePath, 'utf8'));
                content.forEach(q => {
                    huQuestionsMap[q.id] = q;
                });
            } catch (e) {
                console.error(`❌ Failed to parse Hungarian: ${f}`, e.message);
            }
        });

        console.log(`Loaded ${enQuestions.length} English questions and ${Object.keys(huQuestionsMap).length} Hungarian translations.`);

        const merged = enQuestions.map(enQ => {
            const huQ = huQuestionsMap[enQ.id];
            if (!huQ) {
                return null;
            }

            return {
                id: enQ.id,
                type: enQ.type,
                bloom_level: enQ.bloom_level,
                question_text_en: enQ.question_text,
                question_text_hu: huQ.question_text,
                options: {
                    en: enQ.options,
                    hu: huQ.options
                },
                correct_answer_en: enQ.correct_answer,
                correct_answer_hu: huQ.correct_answer,
                explanation_en: enQ.explanation,
                explanation_hu: huQ.explanation
            };
        }).filter(q => q !== null);

        fs.writeFileSync(outputFile, JSON.stringify(merged, null, 4));
        console.log(`🚀 Successfully merged ${merged.length} questions into ${outputFile}`);

    } catch (err) {
        console.error('❌ Merge failed:', err);
    }
};

mergeQuestions();
