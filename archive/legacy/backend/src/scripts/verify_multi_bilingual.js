const db = require('../config/db');

async function test() {
    try {
        // Sample multi-choice question from common dataset (requires checking a real ID)
        // Let's assume an ID or find one.
        const res = await db.query("SELECT id, correct_answer, options FROM questions WHERE question_type = 'multiple_choice' LIMIT 1");
        if (res.rows.length === 0) {
            console.log("No multiple_choice questions found to test.");
            process.exit();
        }

        const question = res.rows[0];
        const options = (typeof question.options === 'string') ? JSON.parse(question.options) : question.options;
        const dbCorrect = question.correct_answer;

        console.log(`--- Testing Multi-Choice Bilingual Validation ---`);
        console.log(`Question ID: ${question.id}`);
        console.log(`DB Correct (Raw): ${dbCorrect}`);

        // Logic from quizController.js
        let dbCorrectArr = [];
        try {
            dbCorrectArr = (typeof dbCorrect === 'string' && dbCorrect.startsWith('['))
                ? JSON.parse(dbCorrect)
                : [dbCorrect];
        } catch {
            dbCorrectArr = [dbCorrect];
        }

        const cNorms = dbCorrectArr.map(c => String(c).trim().toLowerCase());
        const enOptsLower = options.en.map(o => String(o).trim().toLowerCase());
        const huOptsLower = options.hu ? options.hu.map(o => String(o).trim().toLowerCase()) : [];

        const correctIndices = cNorms.map(c => enOptsLower.indexOf(c)).filter(idx => idx !== -1);

        // Simulate User Answer in Hungarian
        if (options.hu && options.hu.length > 0) {
            const huUserAnswers = correctIndices.map(idx => options.hu[idx]);
            console.log(`Simulated User Answers (HU): ${JSON.stringify(huUserAnswers)}`);

            const uNorms = huUserAnswers.map(u => String(u).trim().toLowerCase());

            const userIndices = uNorms.map(u => {
                let idx = enOptsLower.indexOf(u);
                if (idx === -1) idx = huOptsLower.indexOf(u);
                return idx;
            }).filter(idx => idx !== -1);

            const isCorrect = (correctIndices.length > 0 &&
                correctIndices.length === userIndices.length &&
                correctIndices.every(idx => userIndices.includes(idx)));

            console.log(`Validation Match: ${isCorrect}`);

            if (isCorrect) {
                console.log('✅ TEST PASSED for Multi-Choice HU');
            } else {
                console.error('❌ TEST FAILED for Multi-Choice HU');
            }
        } else {
            console.log("No Hungarian options found for this question, skipping HU test.");
        }

    } catch (e) {
        console.error('Test Error:', e);
    } finally {
        process.exit();
    }
}

test();
