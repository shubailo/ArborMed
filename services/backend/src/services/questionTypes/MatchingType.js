const QuestionType = require('./QuestionType');
const splitPair = require('./splitPair');
const { decodeStoredAnswer } = require('./storedAnswer');
const { secureShuffleArray } = require('../../utils/cryptoUtils');

/**
 * Matching Question Type
 * Connect pairs of related medical terms or concepts
 */
function legacyPairs(question) {
    const answers = decodeStoredAnswer(question.correct_answer);
    if (!answers || typeof answers !== 'object' || Array.isArray(answers)) return [];
    const options = decodeStoredAnswer(question.options);
    const labels = new Map();
    if (Array.isArray(options?.en) && Array.isArray(options?.hu)) {
        options.en.forEach((line, i) => {
            if (typeof line !== 'string' || typeof options.hu[i] !== 'string') return;
            const english = splitPair(line);
            const hungarian = splitPair(options.hu[i]);
            if (english && hungarian) {
                labels.set(english[0], hungarian[0]);
                labels.set(english[1], hungarian[1]);
            }
        });
    }
    return Object.entries(answers).filter(([, right]) => typeof right === 'string').map(([left, right]) => ({
        left: {en: left, hu: labels.get(left) || left},
        right: {en: right, hu: labels.get(right) || right},
    }));
}

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
        const correctPairs = decodeStoredAnswer(question.correct_answer);
        const userPairs = decodeStoredAnswer(userAnswer);
        const isMap = value => value !== null && typeof value === 'object' && !Array.isArray(value);
        const keys = isMap(correctPairs) ? Object.keys(correctPairs) : [];
        const isCorrect = keys.length > 0 && isMap(userPairs) && keys.length === Object.keys(userPairs).length
            && keys.every(key => Object.hasOwn(userPairs, key) && typeof userPairs[key] === 'string'
                && typeof correctPairs[key] === 'string' && userPairs[key].trim() === correctPairs[key].trim());

        return {
            correct: isCorrect,
            correctAnswer: correctPairs,
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

        const pairs = question.content?.pairs;
        const source = Array.isArray(pairs) && pairs.length ? pairs : legacyPairs(question);
        if (source.length) {
            clientQuestion.matching_data = {
                left: secureShuffleArray(source.map(p => p.left)),
                right: secureShuffleArray(source.map(p => p.right)),
            };
        }
        return clientQuestion;
    }

    prepareForAdmin(question) {
        return super.prepareForAdmin(question);
    }
}

module.exports = MatchingType;
