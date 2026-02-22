/**
 * Analytics Engine - Smart Review & Retention Algorithm
 * Based on exponential forgetting curve (Spaced Repetition)
 */

/**
 * Calculates the new retention score based on time elapsed and stability.
 * Formula: R = e^(-t/S)
 * @param {number} daysElapsed - Days since last review
 * @param {number} stability - Stability factor (days until retention drops to 90%)
 * @returns {number} Retention score (0-100)
 */
exports.calculateRetention = (daysElapsed, stability) => {
    if (stability <= 0) return 0;
    // We use a simplified model where Retention = 100 * (0.9)^(days/stability)
    // If days == stability, retention is 90%.
    const retention = 100 * Math.pow(0.9, daysElapsed / stability);
    return Math.max(0, Math.min(100, Math.round(retention)));
};

/**
 * Updates stability based on performance.
 * @param {number} currentStability - Current stability (days)
 * @param {number} bloomLevel - Difficulty of the question (1-6)
 * @param {boolean} isCorrect - Did the student answer correctly?
 * @returns {number} New stability value
 */
exports.calculateNewStability = (currentStability, bloomLevel, isCorrect) => {
    let newStability = currentStability || 1.0; // Default starts at 1 day

    if (isCorrect) {
        // Boost factor depends on Bloom Level (Harder questions boost stability more if answered correctly)
        // Multiplier: 2.0 (base) + (0.1 * bloom)
        const boost = 2.0 + (0.1 * bloomLevel);
        newStability = newStability * boost;
    } else {
        // Decay on failure. Don't reset to 0, but cut significantly.
        // Harder questions punish less on failure? Or same?
        // Let's use a flat penalty for now.
        newStability = newStability * 0.5;
        if (newStability < 1.0) newStability = 1.0; // Floor at 1 day
    }

    return parseFloat(newStability.toFixed(2));
};

/**
 * Generates a Readiness Score for a topic.
 * Weighted: 70% Mastery (Accuracy) + 30% Retention
 */
exports.calculateReadiness = (mastery, retention) => {
    return Math.round((mastery * 0.7) + (retention * 0.3));
};

/**
 * Calculates SM-2 interval and EF.
 * @param {number} quality - Quality of the response (0-5).
 * @param {number} previousEF - Previous Easiness Factor (default 2.5).
 * @param {number} previousInterval - Previous interval in days (default 0).
 * @param {number} previousRepetitions - Previous number of successful repetitions (default 0).
 * @returns {object} { interval, easinessFactor, repetitions }
 */
exports.calculateSM2 = (quality, previousEF = 2.5, previousInterval = 0, previousRepetitions = 0) => {
    let interval, repetitions, easinessFactor;

    if (quality >= 3) {
        if (previousRepetitions === 0) {
            interval = 1;
            repetitions = 1;
        } else if (previousRepetitions === 1) {
            interval = 6;
            repetitions = 2;
        } else {
            interval = Math.round(previousInterval * previousEF);
            repetitions = previousRepetitions + 1;
        }

        easinessFactor = previousEF + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
        if (easinessFactor < 1.3) easinessFactor = 1.3;
    } else {
        repetitions = 0;
        interval = 1;
        // Decrease EF on failure (0-2)
        easinessFactor = Math.max(1.3, previousEF - 0.1);
    }

    return {
        interval,
        easinessFactor,
        repetitions
    };
};

/**
 * Calculates EF Modifier based on retention history.
 * @param {Array<boolean>} recentResults - Array of boolean (isCorrect) for last 50 questions.
 * @returns {number} Modifier (0.85, 1.0, or 1.15).
 */
exports.calculateRetentionModifier = (recentResults) => {
    if (!recentResults || recentResults.length < 10) return 1.0; // Not enough data

    const correct = recentResults.filter(r => r === true).length;
    const total = recentResults.length;
    const retentionRate = correct / total;

    if (retentionRate < 0.85) return 0.85; // Retention too low -> Decrease EF (more frequent reviews)
    if (retentionRate > 0.90) return 1.15; // Retention too high -> Increase EF (less frequent reviews) -> User said 85-90% target, so >90 is high?
    // User said: "EF modifier adjusts (0.85x/1.15x) based on 85%-90% retention target."
    // So if < 85%, modifier 0.85.
    // If > 90%, modifier 1.15.
    // Else 1.0.

    return 1.0;
};
