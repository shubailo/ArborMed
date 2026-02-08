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
            if (!pair.left?.en || pair.left.en.trim() === '') {
                errors.push(`Pair ${index + 1} is missing English "left" value`);
            }
            if (!pair.right?.en || pair.right.en.trim() === '') {
                errors.push(`Pair ${index + 1} is missing English "right" value`);
            }
        });

        if (!questionData.correct_answer) {
            errors.push('correct_answer is required');
        }

        return {
            valid: errors.length === 0,
            errors
        };
    }

    checkAnswer(question, userAnswer) {
        // userAnswer is expected to be an object/map of { leftEn: rightEn }
        const correctPairs = question.correct_answer;
        let isCorrect = true;

        try {
            const userPairs = typeof userAnswer === 'string' ? JSON.parse(userAnswer) : userAnswer;

            const leftKeys = Object.keys(correctPairs);
            if (Object.keys(userPairs).length !== leftKeys.length) {
                isCorrect = false;
            } else {
                for (const leftEn of leftKeys) {
                    if (String(userPairs[leftEn]).trim() !== String(correctPairs[leftEn]).trim()) {
                        isCorrect = false;
                        break;
                    }
                }
            }
        } catch {
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
                                    left: {
                                        type: 'object',
                                        properties: { en: { type: 'string' }, hu: { type: 'string' } },
                                        required: ['en']
                                    },
                                    right: {
                                        type: 'object',
                                        properties: { en: { type: 'string' }, hu: { type: 'string' } },
                                        required: ['en']
                                    }
                                },
                                required: ['left', 'right']
                            },
                            minItems: 2
                        }
                    },
                    required: ['pairs']
                },
                correct_answer: { type: 'object' }, // { "Term A (EN)": "Definition A (EN)", ... }
                explanation: { type: 'string' }
            },
            required: ['content', 'correct_answer']
        };
    }

    prepareForClient(question) {
        const clientQuestion = super.prepareForClient(question);

        if (question.content && Array.isArray(question.content.pairs)) {
            // We'll provide localized items based on the request (requested in question_renderer_registry or similar)
            // But here we return BOTH for the client to handle based on current language
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
        return super.prepareForAdmin(question);
    }
}

module.exports = MatchingType;
