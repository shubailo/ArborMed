const QuestionType = require('./QuestionType');

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
        // userAnswer is expected to be an array of strings
        let correctArr;
        try {
            correctArr = typeof question.correct_answer === 'string'
                ? JSON.parse(question.correct_answer)
                : question.correct_answer;
        } catch {
            correctArr = [];
        }

        let uArr;
        try {
            uArr = typeof userAnswer === 'string' ? JSON.parse(userAnswer) : userAnswer;
        } catch {
            uArr = [];
        }

        if (!Array.isArray(uArr)) uArr = [uArr];

        // Sort and compare
        const sortedCorrect = [...correctArr].sort();
        const sortedUser = [...uArr].sort();

        const isCorrect = JSON.stringify(sortedCorrect) === JSON.stringify(sortedUser);

        return {
            correct: isCorrect,
            score: isCorrect ? 1 : 0,
            feedback: isCorrect ? 'Helyes! Minden jó választ megtaláltál.' : `Sajnos nem találtad el az összeset. A helyes válaszok: ${correctArr.join(', ')}`
        };
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
        clientQuestion.is_multiple = true;
        return clientQuestion;
    }
}

module.exports = MultipleChoiceType;
