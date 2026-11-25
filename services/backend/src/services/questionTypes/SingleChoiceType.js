const QuestionType = require('./QuestionType');
const { choiceOptions, gradeChoices } = require('./choiceOptions');

/**
 * Single Choice Question Type
 * Traditional multiple choice with one correct answer
 */
class SingleChoiceType extends QuestionType {
    constructor() {
        super('single_choice', 'Single Choice', 'Choose one correct answer from multiple options');
    }

    validate(questionData) {
        const errors = [];

        if (!questionData.content) {
            errors.push('content is required');
            return { valid: false, errors };
        }

        const { question_text, options } = questionData.content;

        if (!question_text || question_text.trim() === '') {
            errors.push('question_text is required in content');
        }

        if (!Array.isArray(options) || options.length < 2) {
            errors.push('At least 2 options are required');
        }

        if (!questionData.correct_answer) {
            errors.push('correct_answer is required');
        } else if (!options || !options.includes(questionData.correct_answer)) {
            errors.push('correct_answer must be one of the options');
        }

        return {
            valid: errors.length === 0,
            errors
        };
    }

    checkAnswer(question, userAnswer) {
        return gradeChoices(question, userAnswer);
    }

    prepareForClient(question) {
        return { ...super.prepareForClient(question), choice_options: choiceOptions(question) };
    }

    getSchema() {
        return {
            type: 'object',
            properties: {
                content: {
                    type: 'object',
                    properties: {
                        question_text: { type: 'string', minLength: 1 },
                        options: {
                            type: 'array',
                            items: { type: 'string' },
                            minItems: 2
                        }
                    },
                    required: ['question_text', 'options']
                },
                correct_answer: { type: 'string' },
                explanation: { type: 'string' }
            },
            required: ['content', 'correct_answer']
        };
    }
}

module.exports = SingleChoiceType;
