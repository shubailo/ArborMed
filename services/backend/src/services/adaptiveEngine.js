/**
 * AdaptiveEngine adapter: Preserves legacy API interface delegating to unified PedagogicalEngine.
 */
const pedagogicalEngine = require('./pedagogicalEngine');

class AdaptiveEngineAdapter {
    async getNextQuestion(userId, topicSlug, excludedIds = [], levelOverride = null) {
        return pedagogicalEngine.getChallenge(userId, topicSlug, excludedIds, levelOverride);
    }

    async processAnswerResult(userId, topicSlug, isCorrect, questionId, bloomLevel = 1, quality = null) {
        const result = await pedagogicalEngine.resolveResponse(userId, topicSlug, questionId, isCorrect, quality);
        return {
            newLevel: result.newLevel,
            promotedTo: result.promotedTo,
            mastery_score: result.mastery_score,
            sm2: {
                easinessFactor: result.sm2.easinessFactor,
                interval: result.sm2.interval,
                repetitions: result.sm2.repetitions,
            },
            level_correct_count: result.level_correct_count,
            streakProgress: result.streakProgress,
        };
    }
}

module.exports = new AdaptiveEngineAdapter();
