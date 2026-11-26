const choiceSchema = require('./choiceSchema');
const QuestionType = require('./QuestionType');
const { choiceOptions, distinctChoices, gradeChoices, resolveChoice } = require('./choiceOptions');

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

        if (!questionData?.content || typeof questionData.content !== 'object' || Array.isArray(questionData.content)) {
            errors.push('content is required');
            return { valid: false, errors };
        }

        const choices = choiceOptions(questionData);
        if (choices.length < 2) errors.push('At least 2 options are required');
        else if (!distinctChoices(choices)) errors.push('Each option needs a distinct identity');

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
                } else {
                    const ids = new Set();
                    for (const value of correctArr) {
                        const choice = typeof value === 'string' && value.trim() && resolveChoice(choices, value);
                        if (!choice) errors.push('Correct answer not in the options list: ' + String(value));
                        else if (ids.has(choice.id)) errors.push('Each correct option may appear only once');
                        else ids.add(choice.id);
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
                        options: choiceSchema.options
                    },
                    required: ['options']
                },
                correct_answer: { type: 'array', minItems: 1, uniqueItems: true, items: { type: 'string' } },
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
