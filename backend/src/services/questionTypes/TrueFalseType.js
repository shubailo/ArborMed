const QuestionType = require('./QuestionType');

/**
 * True/False Question Type
 * Simple binary choice question
 */
class TrueFalseType extends QuestionType {
    constructor() {
        super('true_false', 'True/False', 'Determine if a medical statement is true or false');
    }

    validate(questionData) {
        const errors = [];

        if (!questionData.content) {
            errors.push('content is required');
            return { valid: false, errors };
        }

        const { statement } = questionData.content;

        if (!statement || statement.trim() === '') {
            errors.push('statement is required in content');
        }

        const validAnswers = ['true', 'false'];

        if (!questionData.correct_answer) {
            errors.push('correct_answer is required');
        } else if (!validAnswers.includes(String(questionData.correct_answer).toLowerCase())) {
            errors.push('correct_answer must be "true" or "false"');
        }

        return {
            valid: errors.length === 0,
            errors
        };
    }

    checkAnswer(question, userAnswer) {
        const normalizedUserAnswer = String(userAnswer).toLowerCase();
        const correct = normalizedUserAnswer === String(question.correct_answer).toLowerCase();

        const answerLabels = {
            'true': 'Igaz',
            'false': 'Hamis'
        };

        return {
            correct,
            score: correct ? 1 : 0,
            feedback: correct
                ? 'Helyes!'
                : `Helytelen. A helyes válasz: ${answerLabels[String(question.correct_answer).toLowerCase()]}`
        };
    }

    getSchema() {
        return {
            type: 'object',
            properties: {
                content: {
                    type: 'object',
                    properties: {
                        statement: { type: 'string', minLength: 1 }
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
