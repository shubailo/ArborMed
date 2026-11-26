const QuestionType = require('./QuestionType');
const matchingDefinition = require('./matchingDefinition');
const { decodeStoredAnswer } = require('./storedAnswer');
const { secureShuffleArray } = require('../../utils/cryptoUtils');

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
        const {errors} = matchingDefinition(questionData);
        return { valid: errors.length === 0, errors };
    }

    checkAnswer(question, userAnswer) {
        const {answer: correctPairs} = matchingDefinition(question);
        const submitted = decodeStoredAnswer(userAnswer);
        const entries = correctPairs ? Object.entries(correctPairs) : [];
        const isCorrect = entries.length > 0 && submitted !== null && typeof submitted === 'object'
            && !Array.isArray(submitted) && Object.keys(submitted).length === entries.length
            && entries.every(([left, right]) => Object.hasOwn(submitted, left)
                && typeof submitted[left] === 'string' && submitted[left].trim() === right.trim());

        return {
            correct: isCorrect,
            correctAnswer: correctPairs,
            score: isCorrect ? 1 : 0,
            feedback: isCorrect ? 'Zseniális! Minden párosítás helyes.' : 'Sajnos nem minden párosítás volt korrekt.'
        };
    }

    getSchema() {
        const text = {type:'string', pattern:'\\S'};
        const term = {type:'object', required:['en'], properties:{en:text, hu:{type:'string'}}};
        return {
            type: 'object',
            required: ['content'],
            properties: {
                content: {
                    type: 'object', required: ['pairs'], properties: {
                        pairs: {
                            type: 'array', minItems: 2,
                            items: {type:'object', required:['left','right'], properties:{left:term, right:term}},
                        },
                    },
                },
                correct_answer: {type:'object', additionalProperties:text},
                explanation: {type:'string'},
            },
        };
    }

    prepareForClient(question) {
        const clientQuestion = super.prepareForClient(question);

        const {pairs, answer} = matchingDefinition(question);
        if (pairs) {
            clientQuestion.correct_answer = answer;
            clientQuestion.matching_data = {
                left: secureShuffleArray(pairs.map(pair => pair.left)),
                right: secureShuffleArray(pairs.map(pair => pair.right)),
            };
        } else {
            delete clientQuestion.matching_data;
        }
        return clientQuestion;
    }

}

module.exports = MatchingType;
