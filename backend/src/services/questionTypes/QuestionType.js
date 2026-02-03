/**
 * Base Question Type Interface
 * All question types must implement this interface
 */
class QuestionType {
    constructor(id, name, description) {
        this.id = id;
        this.name = name;
        this.description = description;
    }

    /**
     * Whether options should be shuffled for this question type
     * @returns {boolean}
     */
    get shouldShuffleOptions() {
        return true;
    }

    /**
     * Validate question data structure
     * @param {Object} questionData - The question data to validate
     * @returns {Object} { valid: boolean, errors: string[] }
     */
    validate(questionData) {
        throw new Error('validate() must be implemented');
    }

    /**
     * Check if user's answer is correct
     * @param {Object} question - The question object
     * @param {*} userAnswer - The user's answer
     * @returns {Object} { correct: boolean, score: number, feedback: string }
     */
    checkAnswer(question, userAnswer) {
        throw new Error('checkAnswer() must be implemented');
    }

    /**
     * Get JSON schema for this question type (for frontend form generation)
     * @returns {Object} JSON Schema
     */
    getSchema() {
        throw new Error('getSchema() must be implemented');
    }

    /**
     * Transform question data for client (hide answers, etc.)
     * @param {Object} question - The full question object
     * @returns {Object} Client-safe question object
     */
    prepareForClient(question) {
        // Return full question including correct_answer and explanation for instant feedback
        return { ...question };
    }

    /**
     * Transform question data for admin (keep answers, add metadata)
     * @param {Object} question - The full question object
     * @returns {Object} Admin-friendly question object
     */
    prepareForAdmin(question) {
        return { ...question };
    }
}

module.exports = QuestionType;
