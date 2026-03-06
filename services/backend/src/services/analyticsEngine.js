/**
 * Pedagogical Analytics & Math Engine
 * Handles SM-2 calculations, Bloom weights, and stability math
 */

class AnalyticsEngine {
    /**
     * SM-2 Algorithm Implementation for Spaced Repetition (SRS).
     * Calculates the new Easiness Factor (EF), next review interval, and repetition count
     * based on the user's performance quality on a question.
     *
     * @param {number} quality - Response quality (0-5 scale, where >=3 is correct).
     * @param {number} previousEF - Last Easiness Factor (starts at 2.5).
     * @param {number} previousInterval - Last interval in days.
     * @param {number} repetitions - Number of consecutive correct answers.
     * @returns {Object} An object containing the new easinessFactor, interval, and repetitions.
     */
    calculateSM2(quality, previousEF, previousInterval, repetitions) {
        let ef = previousEF;
        let interval;
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
     * Retention-Based Modifier.
     * Adjusts the difficulty interval growth based on overall user performance against a target retention rate of 85-90%.
     *
     * @param {Array<boolean>} recentResults - An array of recent answer correctness (true for correct, false for incorrect).
     * @returns {number} A modifier value (e.g., 0.85 for faster easing, 1.15 for slower easing, or 1.0 for normal).
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
     * SSR Stability Calculation (Simplified FSRS-like approach).
     * Calculates the new stability of a memory trace based on correctness and Bloom level.
     * Higher Bloom levels increase stability more significantly when correct.
     *
     * @param {number} currentStability - The current stability value of the memory trace (defaults to 1.0).
     * @param {number} bloomLevel - The Bloom's Taxonomy level of the question (1-4).
     * @param {boolean} isCorrect - Whether the user answered the question correctly.
     * @returns {number} The newly calculated stability value.
     */
    calculateNewStability(currentStability, bloomLevel, isCorrect) {
        const s = currentStability || 1.0;
        const levelWeight = (bloomLevel || 1) / 4.0;

        if (isCorrect) {
            // Stability increases more for higher bloom levels
            return s * (1 + (2.0 * levelWeight));
        } else {
            // Stability drops significantly on failure
            return s * 0.4;
        }
    }

    /**
     * Calculates the retention percentage based on stability and time elapsed.
     * Uses the forgetting curve formula: R = e^(-t/S).
     *
     * @param {number} daysElapsed - The number of days elapsed since the last review.
     * @param {number} stability - The current stability of the memory trace.
     * @returns {number} The calculated retention percentage (0-100).
     */
    calculateRetention(daysElapsed, stability) {
        const s = stability || 1.0;
        const retention = Math.exp(-daysElapsed / s);
        return Math.round(retention * 100);
    }

    /**
     * Calculates the Exam Readiness Score.
     * A combined metric weighing Mastery (Long-term understanding) at 60% and Retention (Current state) at 40%.
     *
     * @param {number} masteryScore - The user's mastery score (0-100).
     * @param {number} retention - The calculated retention percentage (0-100).
     * @returns {number} The overall Exam Readiness Score (0-100).
     */
    calculateReadiness(masteryScore, retention) {
        // Simple balance: 60% Mastery, 40% current retention
        const readiness = (masteryScore * 0.6) + (retention * 0.4);
        return Math.round(Math.min(100, readiness));
    }
}

module.exports = new AnalyticsEngine();
