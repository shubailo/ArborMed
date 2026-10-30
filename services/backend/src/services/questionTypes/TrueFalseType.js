const QuestionType = require('./QuestionType');

/**
 * Normalizes any boolean-like or bilingual value into boolean (true/false)
 * Handles: true, false, 'true', 'false', 'igaz', 'hamis', 1, 0
 */
function toBoolean(val) {
    if (val === true || val === 1) return true;
    if (val === false || val === 0) return false;
    if (val === null || val === undefined) return null;
    const s = String(val).trim().toLowerCase();
    if (s === 'true' || s === 'igaz' || s === '1') return true;
    if (s === 'false' || s === 'hamis' || s === '0') return false;
    return null;
}

/**
 * True/False Question Type
 * Simple binary choice question
 */
class TrueFalseType extends QuestionType {
    constructor() {
        super('true_false', 'True/False', 'Determine if a medical statement is true or false');
    }

    get shouldShuffleOptions() {
        return false;
    }

    validate(questionData) {
        const errors = [];

        if (!questionData.content) {
            errors.push('content is required');
            return { valid: false, errors };
        }

        const { statement } = questionData.content;

        if (!statement?.en || statement.en.trim() === '') {
            errors.push('statement.en is required in content');
        }

        if (questionData.correct_answer === undefined || questionData.correct_answer === null) {
            errors.push('correct_answer is required');
        } else if (toBoolean(questionData.correct_answer) === null) {
            errors.push('correct_answer must be true/false or Igaz/Hamis');
        }

        return {
            valid: errors.length === 0,
            errors
        };
    }

    checkAnswer(question, userAnswer) {
        const userBool = toBoolean(userAnswer);
        const correctBool = toBoolean(question.correct_answer);
        const correct = userBool !== null && correctBool !== null && userBool === correctBool;

        const isCorrectHu = correctBool ? 'Igaz' : 'Hamis';

        return {
            correct,
            score: correct ? 1 : 0,
            correctAnswer: isCorrectHu,
            feedback: correct
                ? 'Helyes!'
                : `Helytelen. A helyes válasz: ${isCorrectHu}`
        };
    }

    getSchema() {
        return {
            type: 'object',
            properties: {
                content: {
                    type: 'object',
                    properties: {
                        statement: {
                            type: 'object',
                            properties: { en: { type: 'string' }, hu: { type: 'string' } },
                            required: ['en']
                        }
                    },
                    required: ['statement']
                },
                correct_answer: {
                    type: 'string',
                    enum: ['true', 'false']
                },
                explanation: { type: 'string' }
            },
            required: ['content', 'correct_answer']
        };
    }

    prepareForClient(question) {
        const clientQuestion = super.prepareForClient(question);
        clientQuestion.options = [
            { value: 'true', label: 'Igaz' },
            { value: 'false', label: 'Hamis' }
        ];
        return clientQuestion;
    }

    prepareForAdmin(question) {
        const adminQuestion = super.prepareForAdmin(question);
        adminQuestion.options = [
            { value: 'true', label: 'Igaz' },
            { value: 'false', label: 'Hamis' }
        ];
        return adminQuestion;
    }
}

module.exports = TrueFalseType;
