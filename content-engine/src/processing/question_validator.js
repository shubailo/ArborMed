/**
 * Validates a question has required fields and correct answer exists in options.
 * @param {Object} q The question object.
 * @param {string} fileName The name of the file being processed.
 * @returns {string[]} An array of validation issues.
 */
function validateQuestion(q, fileName) {
    const issues = [];

    if (!q.question_text || q.question_text.length < 5) {
        issues.push('Question text missing or too short');
    }
    if (!q.correct_answer) {
        issues.push('Correct answer missing');
    }
    if (!q.options || !Array.isArray(q.options) || q.options.length < 2) {
        issues.push('Options missing or insufficient');
    }

    if (q.options && Array.isArray(q.options) && q.correct_answer) {
        const correctAnswers = q.correct_answer.split(';').map(a => a.trim());
        const optionsNormalized = q.options.map(o => o.trim().toLowerCase());

        const missingAnswers = correctAnswers.filter(ans => {
            const ansNorm = ans.toLowerCase();
            return !optionsNormalized.some(opt =>
                opt === ansNorm || opt.includes(ansNorm) || ansNorm.includes(opt)
            );
        });

        if (missingAnswers.length > 0) {
            issues.push(`Correct answers [${missingAnswers.join('; ')}] not found in options`);
        }
    }

    return issues;
}

module.exports = { validateQuestion };
