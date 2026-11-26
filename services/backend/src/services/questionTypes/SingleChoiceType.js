const QuestionType = require('./QuestionType');
const { choiceOptions, distinctChoices, gradeChoices, resolveChoice } = require('./choiceOptions');

const { scalarAnswer } = require('./storedAnswer');

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

        if (!questionData?.content || typeof questionData.content !== 'object' || Array.isArray(questionData.content)) {
            return { valid: false, errors: ['content is required'] };
        }

        const prompt = questionData.content.question_text;
        if (![prompt, prompt?.en, prompt?.hu, questionData.question_text_en,
            questionData.question_text_hu, questionData.text].some(value => typeof value === 'string' && value.trim())) {
            errors.push('question_text is required in content');
        }

        const choices = choiceOptions(questionData);
        if (choices.length < 2) errors.push('At least 2 options are required');
        else if (!distinctChoices(choices)) errors.push('Each option needs a distinct identity');

        const key = scalarAnswer(questionData.correct_answer);
        if (key == null || String(key).trim() === '') errors.push('correct_answer is required');
        else if (!['string', 'number'].includes(typeof key) || !resolveChoice(choices, key)) {
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
        const text = { type: 'string', minLength: 1 };
        const localized = { type: 'object', properties: { en: text, hu: text },
            anyOf: [{ required: ['en'] }, { required: ['hu'] }] };
        const option = { type: 'object', properties: { en: text, hu: text, label: text, text, value: text },
            anyOf: ['en', 'hu', 'label', 'text', 'value'].map(field => ({ required: [field] })) };
        const list = { type: 'array', items: { anyOf: [text, option] }, minItems: 2 };
        return {
            type: 'object',
            properties: {
                content: {
                    type: 'object',
                    properties: {
                        question_text: { anyOf: [text, localized] },
                        options: { anyOf: [list, { type: 'object', properties: { en: list, hu: list },
                            anyOf: [{ required: ['en'] }, { required: ['hu'] }] }] }
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
