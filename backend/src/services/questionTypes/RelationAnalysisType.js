const QuestionType = require('./QuestionType');

/**
 * Relation Analysis Question Type
 * Medical exam format: Two statements with relationship analysis
 */
class RelationAnalysisType extends QuestionType {
    constructor() {
        super('relation_analysis', 'Relation Analysis', 'Analyze the relationship between two medical statements');
    }

    get shouldShuffleOptions() {
        return false;
    }

    validate(questionData) {
        const errors = [];

        // Content is optional now if using main text
        // But if provided, check structure? 
        // For simplicity, just relaxed.

        // const { statement1, statement2, link_word } = questionData.content || {};

        const validAnswers = ['A', 'B', 'C', 'D', 'E'];

        if (!questionData.correct_answer) {
            errors.push('correct_answer is required');
        } else if (!validAnswers.includes(String(questionData.correct_answer).toUpperCase())) {
            errors.push(`correct_answer must be one of: ${validAnswers.join(', ')}`);
        }

        return {
            valid: errors.length === 0,
            errors
        };
    }

    checkAnswer(question, userAnswer) {
        const correct = String(userAnswer).toUpperCase() === String(question.correct_answer).toUpperCase();

        const answerLabels = {
            'A': 'Mindkét állítás igaz, és van köztük ok-okozati összefüggés',
            'B': 'Mindkét állítás igaz, de nincs köztük összefüggés',
            'C': 'Csak az 1. állítás igaz',
            'D': 'Csak a 2. állítás igaz',
            'E': 'Egyik állítás sem igaz'
        };

        return {
            correct,
            score: correct ? 1 : 0,
            feedback: correct
                ? 'Helyes!'
                : `Helytelen. A helyes válasz: ${question.correct_answer} (${answerLabels[question.correct_answer.toUpperCase()]})`
        };
    }

    getSchema() {
        return {
            type: 'object',
            properties: {
                content: {
                    type: 'object',
                    properties: {
                        statement1: {
                            type: 'object',
                            properties: {
                                en: { type: 'string', minLength: 1 },
                                hu: { type: 'string' }
                            },
                            required: ['en']
                        },
                        statement2: {
                            type: 'object',
                            properties: {
                                en: { type: 'string', minLength: 1 },
                                hu: { type: 'string' }
                            },
                            required: ['en']
                        },
                        link_word: {
                            type: 'object',
                            properties: {
                                en: { type: 'string' },
                                hu: { type: 'string' }
                            }
                        }
                    },
                    required: ['statement1', 'statement2']
                },
                correct_answer: {
                    type: 'string',
                    enum: ['A', 'B', 'C', 'D', 'E']
                },
                explanation: { type: 'string' }
            },
            required: ['content', 'correct_answer']
        };
    }

    prepareForClient(question) {
        const clientQuestion = super.prepareForClient(question);
        // Standard Hungarian medical exam options A-E
        clientQuestion.options = [
            { value: 'A', label: 'Mindkét állítás igaz, és van köztük ok-okozati összefüggés' },
            { value: 'B', label: 'Mindkét állítás igaz, de nincs köztük összefüggés' },
            { value: 'C', label: 'Csak az 1. állítás igaz' },
            { value: 'D', label: 'Csak a 2. állítás igaz' },
            { value: 'E', label: 'Egyik állítás sem igaz' }
        ];
        return clientQuestion;
    }

    prepareForAdmin(question) {
        const adminQuestion = super.prepareForAdmin(question);
        adminQuestion.options = [
            { value: 'A', label: 'A (Both True, Link True)' },
            { value: 'B', label: 'B (Both True, Link False)' },
            { value: 'C', label: 'C (Only 1st True)' },
            { value: 'D', label: 'D (Only 2nd True)' },
            { value: 'E', label: 'E (Neither True)' }
        ];
        return adminQuestion;
    }
}

module.exports = RelationAnalysisType;
