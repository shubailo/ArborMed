/**
 * Utility for bilingual answer validation and normalization
 */

/**
 * Normalizes input (string or array) into an array of lowercase trimmed strings
 * @param {any} input 
 * @returns {string[]}
 */
function normalize(input) {
    if (!input) return [];

    let arr = [];
    if (Array.isArray(input)) {
        arr = input;
    } else if (typeof input === 'string' && input.startsWith('[')) {
        try {
            arr = JSON.parse(input);
        } catch {
            arr = [input];
        }
    } else {
        arr = [input];
    }

    return arr.map(item => String(item).trim().toLowerCase());
}

/**
 * Validates user answer against correct answer with bilingual support
 * @param {any} userAnswer User provided answer(s)
 * @param {any} dbCorrectAnswer Correct answer(s) from DB
 * @param {object} options Bilingual options { en: [], hu: [] }
 * @returns {object} { isCorrect: boolean, normalizedCorrect: any }
 */
function validateBilingual(userAnswer, dbCorrectAnswer, options) {
    const uNorms = normalize(userAnswer);
    const cNorms = normalize(dbCorrectAnswer);

    let isCorrect = false;
    let normalizedCorrect = dbCorrectAnswer;

    if (options && options.en && options.hu) {
        const enOptsLower = options.en.map(o => String(o).trim().toLowerCase());
        const huOptsLower = options.hu.map(o => String(o).trim().toLowerCase());

        // Map DB correct to indices
        const correctIndices = cNorms.map(c => enOptsLower.indexOf(c)).filter(idx => idx !== -1);

        // Map User answers to indices (checking both lang lists)
        const userIndices = uNorms.map(u => {
            let idx = enOptsLower.indexOf(u);
            if (idx === -1) idx = huOptsLower.indexOf(u);
            return idx;
        }).filter(idx => idx !== -1);

        // Compare sets of indices
        isCorrect = (correctIndices.length > 0 &&
            correctIndices.length === userIndices.length &&
            correctIndices.every(idx => userIndices.includes(idx)));

        // Detect if user is using Hungarian
        const isUserHu = uNorms.some(u => huOptsLower.includes(u));

        // Map normalizedCorrect to user's language (or fallback to English)
        if (correctIndices.length > 0) {
            const resultList = isUserHu ? options.hu : options.en;
            const mappedCorrect = correctIndices.map(idx => resultList[idx] || (isUserHu ? options.en[idx] : options.hu[idx]));
            normalizedCorrect = mappedCorrect.length > 1 ? mappedCorrect : mappedCorrect[0];
        } else {
            // Fallback for types that don't match indices perfectly
            normalizedCorrect = cNorms.length > 1 ? cNorms : cNorms[0];
        }
    } else {
        // Simple fallback validation
        isCorrect = (cNorms.length === uNorms.length && cNorms.every(c => uNorms.includes(c)));
        normalizedCorrect = cNorms.length > 1 ? cNorms : cNorms[0];
    }

    return { isCorrect, normalizedCorrect };
}

module.exports = {
    normalize,
    validateBilingual
};
