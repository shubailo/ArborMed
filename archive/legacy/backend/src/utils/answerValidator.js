/**
 * Utility for bilingual answer validation and normalization
 */

/**
 * Normalizes input (string or array) into an array of lowercase trimmed strings
 * @param {any} input 
 * @returns {string[]}
 */
function normalize(input) {
    if (input === null || input === undefined) return [];

    let arr = [];
    if (Array.isArray(input)) {
        arr = input;
    } else if (typeof input === 'string') {
        const trimmed = input.trim();
        if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
            try {
                arr = JSON.parse(trimmed);
            } catch {
                arr = [trimmed];
            }
        } else if (trimmed.includes(',') && !trimmed.includes('{') && !trimmed.includes('"')) {
            // Likely a comma-separated list: "Option A, Option B"
            arr = trimmed.split(',').map(s => s.trim());
        } else {
            arr = [trimmed];
        }
    } else {
        arr = [String(input)];
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
        const correctIndices = cNorms.map(c => {
            let idx = enOptsLower.indexOf(c);
            if (idx === -1) idx = huOptsLower.indexOf(c);
            // Handle explicit boolean labels if options are English but DB has Hungarian Correct
            if (idx === -1) {
                if (c === 'igaz') idx = enOptsLower.indexOf('true');
                if (c === 'hamis') idx = enOptsLower.indexOf('false');
            }
            return idx;
        }).filter(idx => idx !== -1);

        // Map User answers to indices (checking both lang lists)
        const userIndices = uNorms.map(u => {
            let idx = enOptsLower.indexOf(u);
            if (idx === -1) idx = huOptsLower.indexOf(u);
            // Handle explicit boolean labels mapping
            if (idx === -1) {
                if (u === 'igaz') idx = enOptsLower.indexOf('true');
                if (u === 'hamis') idx = enOptsLower.indexOf('false');
            }
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
