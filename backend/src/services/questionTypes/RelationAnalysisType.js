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

        if (!questionData.content) {
            errors.push('content is required');
            return { valid: false, errors };
        }

        const { statement_1, statement_2 } = questionData.content;

        if (!statement_1 || statement_1.trim() === '') {
            errors.push('statement_1 is required in content');
        }

        if (!statement_2 || statement_2.trim() === '') {
            errors.push('statement_2 is required in content');
        }

        const validAnswers = [
            'both_true_related',
            'both_true_unrelated',
            'only_first_true',
            'only_second_true',
            'neither_true'
        ];

        if (!questionData.correct_answer) {
            errors.push('correct_answer is required');
        } else if (!validAnswers.includes(questionData.correct_answer)) {
            errors.push(`correct_answer must be one of: ${validAnswers.join(', ')}`);
        }

        return {
            valid: errors.length === 0,
            errors
        };
    }

    checkAnswer(question, userAnswer) {
        const correct = userAnswer === question.correct_answer;

        const answerLabels = {
            'both_true_related': 'Both statements are true and there is a causal relationship',
            'both_true_unrelated': 'Both statements are true but there is no relationship',
            'only_first_true': 'Only the first statement is true',
            'only_second_true': 'Only the second statement is true',
            'neither_true': 'Neither statement is true'
        };

        return {
            correct,
            score: correct ? 1 : 0,
            feedback: correct
                ? 'Correct!'
                : `Incorrect. The correct answer is: ${answerLabels[question.correct_answer]}`
        };
    }

    getSchema() {
        return {
            type: 'object',
            properties: {
                content: {
                    type: 'object',
                    properties: {
                        statement_1: { type: 'string', minLength: 1 },
                        statement_2: { type: 'string', minLength: 1 }
                    },
                    required: ['statement_1', 'statement_2']
                },
                correct_answer: {
                    type: 'string',
                    enum: [
                        'both_true_related',
                        'both_true_unrelated',
                        'only_first_true',
                        'only_second_true',
                        'neither_true'
                    ]
                },
                explanation: { type: 'string' }
            },
            required: ['content', 'correct_answer']
        };
    }

    prepareForClient(question) {
        // Add standard options for relation analysis
        const clientQuestion = super.prepareForClient(question);
        clientQuestion.options = [
            { value: 'both_true_related', label: 'Mindkét állítás igaz, és van köztük ok-okozati összefüggés' },
            { value: 'both_true_unrelated', label: 'Mindkét állítás igaz, de nincs köztük összefüggés' },
            { value: 'only_first_true', label: 'Csak az 1. állítás igaz' },
            { value: 'only_second_true', label: 'Csak a 2. állítás igaz' },
            { value: 'neither_true', label: 'Egyik állítás sem igaz' }
        ];
        return clientQuestion;
    }

    prepareForAdmin(question) {
        const adminQuestion = super.prepareForAdmin(question);
        adminQuestion.options = [
            { value: 'both_true_related', label: 'Mindkét állítás igaz, és van köztük ok-okozati összefüggés' },
            { value: 'both_true_unrelated', label: 'Mindkét állítás igaz, de nincs köztük összefüggés' },
            { value: 'only_first_true', label: 'Csak az 1. állítás igaz' },
            { value: 'only_second_true', label: 'Csak a 2. állítás igaz' },
            { value: 'neither_true', label: 'Egyik állítás sem igaz' }
        ];
        return adminQuestion;
    }
}

module.exports = RelationAnalysisType;
