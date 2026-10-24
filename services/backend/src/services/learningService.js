const pedagogicalEngine = require('./pedagogicalEngine');
const analyticsEngine = require('./analyticsEngine');

/**
 * LearningService facade delegating to PedagogicalEngine and AnalyticsEngine.
 */
class LearningService {
    calculateRetention(daysElapsed, stability) {
        return analyticsEngine.calculateRetention(daysElapsed, stability);
    }

    calculateReadiness(masteryScore, retention) {
        return analyticsEngine.calculateReadiness(masteryScore, retention);
    }

    async getChallenge(userId, topicSlug, excludedIds = []) {
        return pedagogicalEngine.getChallenge(userId, topicSlug, excludedIds);
    }

    async resolveResponse(userId, topicSlug, questionId, isCorrect, quality = null, responseTimeMs = null) {
        return pedagogicalEngine.resolveResponse(userId, topicSlug, questionId, isCorrect, quality, responseTimeMs);
    }
}

module.exports = new LearningService();
