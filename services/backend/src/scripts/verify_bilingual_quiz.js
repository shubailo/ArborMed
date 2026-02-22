const db = require('../config/db');

async function test() {
    try {
        const questionId = 3314;
        const huAnswer = 'Igaz';

        console.log('--- Testing Bilingual Validation Logic ---');
        console.log(`Question ID: ${questionId}`);
        console.log(`User Answer (HU): ${huAnswer}`);

        const qResult = await db.query('SELECT correct_answer, options FROM questions WHERE id = $1', [questionId]);
        const question = qResult.rows[0];

        const options = (typeof question.options === 'string') ? JSON.parse(question.options) : question.options;
        const uNorm = huAnswer.trim().toLowerCase();
        const cNorm = question.correct_answer.trim().toLowerCase();

        let isCorrect = false;
        let correctAnswerToReturn = question.correct_answer;

        if (uNorm === cNorm) {
            isCorrect = true;
        } else if (options && options.en && options.hu) {
            const enOptions = options.en.map(o => String(o).trim().toLowerCase());
            const huOptions = options.hu.map(o => String(o).trim().toLowerCase());
            const correctIdx = enOptions.indexOf(cNorm);

            if (correctIdx !== -1) {
                if (huOptions[correctIdx] === uNorm) {
                    isCorrect = true;
                }
                const isUserHu = huOptions.includes(uNorm);
                if (isUserHu) {
                    correctAnswerToReturn = options.hu[correctIdx] || question.correct_answer;
                }
            }
        }

        console.log('Validation Results:');
        console.log(`- Match Found: ${isCorrect}`);
        console.log(`- Correct Answer Returned: ${correctAnswerToReturn}`);

        if (isCorrect && correctAnswerToReturn === 'Igaz') {
            console.log('✅ TEST PASSED');
        } else {
            console.error('❌ TEST FAILED');
        }

    } catch (e) {
        console.error('Test Error:', e);
    } finally {
        process.exit();
    }
}

test();
