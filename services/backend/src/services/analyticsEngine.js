/**
 * Pedagogical Analytics & Math Engine
 * Handles SM-2 calculations, Bloom weights, and stability math
 */

class AnalyticsEngine {
    /**
     * SM-2 Algorithm Implementation
     * @param {number} quality - Response quality (0-5)
     * @param {number} previousEF - Last Easiness Factor
     * @param {number} previousInterval - Last interval in days
     * @param {number} repetitions - Number of consecutive correct answers
     */
    calculateSM2(quality, previousEF, previousInterval, repetitions) {
        let ef = previousEF;
        let interval = 0;
        let n = repetitions;

        if (quality >= 3) {
            // Correct response
            if (n === 0) {
                interval = 1;
            } else if (n === 1) {
                interval = 6;
            } else {
                interval = Math.round(previousInterval * ef);
            }
            n++;

            // EF calculation: EF' := f(EF, q)
            ef = ef + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
        } else {
            // Incorrect response
            n = 0;
            interval = 1;
        }

        if (ef < 1.3) ef = 1.3;

        return {
            easinessFactor: ef,
            interval: interval,
            repetitions: n
        };
    }

    /**
     * Retention-Based Modifier
     * Adjusts difficulty based on overall user performance vs target (85-90%)
     */
    calculateRetentionModifier(recentResults) {
        if (recentResults.length < 10) return 1.0;

        const correctCount = recentResults.filter(r => r === true).length;
        const retention = correctCount / recentResults.length;

        // Target: 85% - 90%
        if (retention < 0.85) {
            return 0.85; // Faster easing, harder interval growth
        } else if (retention > 0.90) {
            return 1.15; // Slow easing, faster interval growth
        }

        return 1.0;
    }

    /**
     * SSR Stability Calculation (Simplified FSRS-like approach)
     */
    calculateNewStability(currentStability, bloomLevel, isCorrect) {
        const s = currentStability || 1.0;
        const levelWeight = bloomLevel / 4.0;

        if (isCorrect) {
            // Stability increases more for higher bloom levels
            return s * (1 + (2.0 * levelWeight));
        } else {
            // Stability drops significantly on failure
            return s * 0.4;
        }
    }
}

module.exports = new AnalyticsEngine();
