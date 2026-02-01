const SingleChoiceType = require('./SingleChoiceType');
const MultipleChoiceType = require('./MultipleChoiceType');
const RelationAnalysisType = require('./RelationAnalysisType');
const TrueFalseType = require('./TrueFalseType');
const MatchingType = require('./MatchingType');

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
            schema: type.getSchema()
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
                errors: [`Unknown question type: ${typeId}`]
            };
        }
        return type.validate(questionData);
    }

    /**
     * Check if a user's answer is correct
     * @param {Object} question - The question object
     * @param {*} userAnswer - The user's answer
     * @returns {Object} { correct: boolean, score: number, feedback: string }
     */
    checkAnswer(question, userAnswer) {
        const type = this.getType(question.question_type);
        if (!type) {
            throw new Error(`Unknown question type: ${question.question_type}`);
        }
        return type.checkAnswer(question, userAnswer);
    }

    /**
     * Prepare question for client (hide answers)
     * @param {Object} question - The full question object
     * @returns {Object} Client-safe question object
     */
    prepareForClient(question) {
        const type = this.getType(question.question_type);
        if (!type) {
            throw new Error(`Unknown question type: ${question.question_type}`);
        }
        return type.prepareForClient(question);
    }

    /**
     * Prepare question for admin (keep answers)
     * @param {Object} question - The full question object
     * @returns {Object} Admin-friendly question object
     */
    prepareForAdmin(question) {
        const type = this.getType(question.question_type);
        if (!type) {
            throw new Error(`Unknown question type: ${question.question_type}`);
        }
        return type.prepareForAdmin(question);
    }
}

// Export singleton instance
module.exports = new QuestionTypeRegistry();
