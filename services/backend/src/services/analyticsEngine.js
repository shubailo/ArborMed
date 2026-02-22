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
