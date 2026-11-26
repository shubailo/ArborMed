const SingleChoiceType = require('./SingleChoiceType');
const MultipleChoiceType = require('./MultipleChoiceType');
const RelationAnalysisType = require('./RelationAnalysisType');
const TrueFalseType = require('./TrueFalseType');
const MatchingType = require('./MatchingType');
const AppError = require('../../utils/AppError');

function unknownTypeMessage(id) {
    return typeof id === 'string' ? `Unknown question type: ${id}` : 'Unknown question type';
}

/**
 * Question Type Registry
 * Central registry for all question types
 */
class QuestionTypeRegistry {
    constructor() {
        this.types = new Map();
        this._registerDefaultTypes();
    }

    /**
     * Register default question types
     * @private
     */
    _registerDefaultTypes() {
        this.register(new SingleChoiceType());
        this.register(new MultipleChoiceType());
        this.register(new RelationAnalysisType());
        this.register(new TrueFalseType());
        this.register(new MatchingType());
        // Add more types here as they're implemented
    }

    /**
     * Register a new question type
     * @param {QuestionType} questionType - The question type to register
     */
    register(questionType) {
        if (!questionType.id) {
            throw new Error('Question type must have an id');
        }
        this.types.set(questionType.id, questionType);
    }

    /**
     * Get a question type by ID
     * @param {string} typeId - The question type ID
     * @returns {QuestionType|null}
     */
    getType(typeId) {
        if (typeId === 'case_study') typeId = 'single_choice';
        if (typeId === 'relational_analysis') typeId = 'relation_analysis';
        return this.types.get(typeId) || null;
    }

    /**
     * Get all registered question types
     * @returns {Array<Object>} Array of type metadata
     */
    getAllTypes() {
        return Array.from(this.types.values()).map(type => ({
            id: type.id,
            name: type.name,
            description: type.description,
            schema: type.getSchema().properties.content
        }));
    }

    /**
     * Validate question data based on its type
     * @param {string} typeId - The question type ID
     * @param {Object} questionData - The question data to validate
     * @returns {Object} { valid: boolean, errors: string[] }
     */
    validate(typeId, questionData) {
        const type = this.getType(typeId);
        if (!type) {
            return {
                valid: false,
                errors: [unknownTypeMessage(typeId)]
            };
        }
        return type.validate(questionData);
    }

    typeForQuestion(question) {
        const id = question.question_type ?? question.type ?? 'single_choice';
        const type = this.getType(id);
        if (!type) throw new AppError(unknownTypeMessage(id), 422);
        return type;
    }

    /**
     * Check if a user's answer is correct
     * @param {Object} question - The question object
     * @param {*} userAnswer - The user's answer
     * @returns {Object} { correct: boolean, score: number, feedback: string }
     */
    checkAnswer(question, userAnswer) {
        return this.typeForQuestion(question).checkAnswer(question, userAnswer);
    }

    /**
     * Prepare a question for practice, including offline grading data
     * @param {Object} question - The full question object
     * @returns {Object} Client-safe question object
     */
    prepareForClient(question) {
        return this.typeForQuestion(question).prepareForClient(question);
    }

    /**
     * Prepare question for admin (keep answers)
     * @param {Object} question - The full question object
     * @returns {Object} Admin-friendly question object
     */
    prepareForAdmin(question) {
        return this.typeForQuestion(question).prepareForAdmin(question);
    }
}

// Export singleton instance
module.exports = new QuestionTypeRegistry();
