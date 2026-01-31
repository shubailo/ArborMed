const QuestionType = require('./QuestionType');

/**
 * Matching Question Type
 * Connect pairs of related medical terms or concepts
 */
class MatchingType extends QuestionType {
    constructor() {
        super('matching', 'Matching', 'Match related pairs of medical concepts');
    }

    get shouldShuffleOptions() {
        // We handle internal shuffling in prepareForClient
        return false;
    }

    validate(questionData) {
        const errors = [];

        if (!questionData.content) {
            errors.push('content is required');
            return { valid: false, errors };
        }

        const { pairs } = questionData.content;

        if (!Array.isArray(pairs) || pairs.length < 2) {
            errors.push('pairs must be an array with at least 2 items');
            return { valid: false, errors };
        }

        pairs.forEach((pair, index) => {
            if (!pair.left || pair.left.trim() === '') {
                errors.push(`Pair ${index + 1} is missing "left" value`);
            }
            if (!pair.right || pair.right.trim() === '') {
                errors.push(`Pair ${index + 1} is missing "right" value`);
            }
        });

        // correct_answer should be the mapping of left to right
        if (!questionData.correct_answer) {
            errors.push('correct_answer is required');
        }

        return {
            valid: errors.length === 0,
            errors
        };
    }

    checkAnswer(question, userAnswer) {
        // userAnswer is expected to be an object/map of { leftValue: rightValue }
        const correctPairs = question.correct_answer;

        // Match Duolingo style: users must match ALL correctly for full points (as per user request)
        let isCorrect = true;

        try {
            const userPairs = typeof userAnswer === 'string' ? JSON.parse(userAnswer) : userAnswer;

            const leftKeys = Object.keys(correctPairs);
            if (Object.keys(userPairs).length !== leftKeys.length) {
                isCorrect = false;
            } else {
                for (const left of leftKeys) {
                    if (userPairs[left] !== correctPairs[left]) {
                        isCorrect = false;
                        break;
                    }
                }
            }
        } catch (e) {
            isCorrect = false;
        }

        return {
            correct: isCorrect,
            score: isCorrect ? 1 : 0,
            feedback: isCorrect ? 'Zseniális! Minden párosítás helyes.' : 'Sajnos nem minden párosítás volt korrekt.'
        };
    }

    getSchema() {
        return {
            type: 'object',
            properties: {
                content: {
                    type: 'object',
                    properties: {
                        pairs: {
                            type: 'array',
                            items: {
                                type: 'object',
                                properties: {
                                    left: { type: 'string' },
                                    right: { type: 'string' }
                                },
                                required: ['left', 'right']
                            },
                            minItems: 2
                        }
                    },
                    required: ['pairs']
                },
                correct_answer: { type: 'object' }, // { "Term A": "Definition A", ... }
                explanation: { type: 'string' }
            },
            required: ['content', 'correct_answer']
        };
    }

    prepareForClient(question) {
        const clientQuestion = super.prepareForClient(question);

        if (question.content && Array.isArray(question.content.pairs)) {
            const leftItems = question.content.pairs.map(p => p.left).sort(() => Math.random() - 0.5);
            const rightItems = question.content.pairs.map(p => p.right).sort(() => Math.random() - 0.5);

            clientQuestion.matching_data = {
                left: leftItems,
                right: rightItems
            };
        }

        return clientQuestion;
    }

    prepareForAdmin(question) {
        const adminQuestion = super.prepareForAdmin(question);
        return adminQuestion;
    }
}

module.exports = MatchingType;
