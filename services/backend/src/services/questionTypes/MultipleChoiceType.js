const QuestionType = require('./QuestionType');
const { choiceOptions, gradeChoices } = require('./choiceOptions');

/**
 * Multiple Choice Question Type (Multi-select)
 * Users can choose one or more correct answers
 */
class MultipleChoiceType extends QuestionType {
    constructor() {
        super('multiple_choice', 'Multiple Choice', 'Choose one or more correct answers from multiple options');
    }

    validate(questionData) {
        const errors = [];

        if (!questionData.content) {
            errors.push('content is required');
            return { valid: false, errors };
        }

        const { options } = questionData.content;

        if (!options || !options.en || !Array.isArray(options.en) || options.en.length < 2) {
            errors.push('At least 2 English options are required in content.options.en');
        }

        if (questionData.correct_answer === undefined || questionData.correct_answer === null) {
            errors.push('correct_answer is required');
        } else {
            // correct_answer should be a JSON array of strings (the correct options)
            try {
                const correctArr = typeof questionData.correct_answer === 'string'
                    ? JSON.parse(questionData.correct_answer)
                    : questionData.correct_answer;

                if (!Array.isArray(correctArr) || correctArr.length === 0) {
                    errors.push('correct_answer must be a non-empty array of strings');
                } else if (options?.en) {
                    const invalid = correctArr.filter(ans => !options.en.includes(ans));
                    if (invalid.length > 0) {
                        errors.push(`Some correct answers are not in the options list: ${invalid.join(', ')}`);
                    }
                }
            } catch {
                errors.push('correct_answer must be a valid JSON array');
            }
        }

        return {
            valid: errors.length === 0,
            errors
        };
    }

    checkAnswer(question, userAnswer) {
        return gradeChoices(question, userAnswer, true);
    }

    getSchema() {
        return {
            type: 'object',
            properties: {
                content: {
                    type: 'object',
                    properties: {
                        options: {
                            type: 'object',
                            properties: {
                                en: { type: 'array', items: { type: 'string' }, minItems: 2 },
                                hu: { type: 'array', items: { type: 'string' } }
                            },
                            required: ['en']
                        }
                    },
                    required: ['options']
                },
                correct_answer: { type: 'array', items: { type: 'string' } },
                explanation: { type: 'string' }
            },
            required: ['content', 'correct_answer']
        };
    }

    prepareForClient(question) {
        const clientQuestion = super.prepareForClient(question);
        clientQuestion.choice_options = choiceOptions(question);
        clientQuestion.is_multiple = true;
        return clientQuestion;
    }
}

module.exports = MultipleChoiceType;
