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
        const priorFactor = Number(previousEF);
        let ef = Number.isFinite(priorFactor) && priorFactor > 0 ? Math.max(1.3, priorFactor) : 2.5;
        let interval;
        let n = Number(repetitions);
        if (!Number.isSafeInteger(n) || n < 0) n = 0;

        if (quality >= 3) {
            // Correct response
            if (n === 0) {
                interval = 1;
            } else if (n === 1) {
                interval = 6;
            } else {
                const days = Number(previousInterval);
                interval = Number.isFinite(days) && days > 0 ? Math.max(1, Math.round(days * ef)) : 1;
            }
            n = Math.min(n + 1, 2147483647); // user_question_progress.repetition_count is int4

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
        if (!Number.isFinite(daysElapsed)) return 0;
        const value = Number(stability);
        const s = Number.isFinite(value) && value > 0 ? value : 1;
        const retention = Math.exp(-Math.max(0, daysElapsed) / s);
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
        const percent = value => {
            const numeric = Number(value);
            return Number.isFinite(numeric) ? Math.max(0, Math.min(100, numeric)) : 0;
        };
        return Math.round(percent(masteryScore) * 0.6 + percent(retention) * 0.4);
    }
}

module.exports = new AnalyticsEngine();
