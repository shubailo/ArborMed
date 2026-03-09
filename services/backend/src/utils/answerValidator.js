/**
 * Utility for bilingual answer validation and normalization
 */

/**
 * Normalizes input (string, array, or JSON stringified array) into a flat array of lowercase trimmed strings.
 * This is crucial for ensuring case-insensitive and whitespace-agnostic comparisons.
 *
 * @param {any} input - The user's answer or the correct answer from the database.
 * @returns {string[]} An array of normalized strings.
 */
function normalize(input) {
    if (input === null || input === undefined) return [];

    let arr;
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
 * Validates a user's answer against the correct database answer, fully supporting bilingual (EN/HU) options.
 * It maps answers back to their option indices to ensure correctness regardless of the language the user is currently viewing.
 *
 * @param {any} userAnswer - The answer(s) provided by the user.
 * @param {any} dbCorrectAnswer - The correct answer(s) stored in the database (typically in English).
 * @param {object} options - An object containing arrays of localized options: { en: string[], hu: string[] }.
 * @returns {object} Result object containing `isCorrect` (boolean) and `normalizedCorrect` (the correct answer localized to the user's inferred language).
 */
function validateBilingual(userAnswer, dbCorrectAnswer, options) {
    const uNorms = normalize(userAnswer);
    const cNorms = normalize(dbCorrectAnswer);

    let isCorrect;
    let normalizedCorrect;

    if (options && options.en && options.hu) {
        // ⚡ Bolt: Cache localized options to prevent redundant map iterations
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
        // ⚡ Bolt: Use a Set for user indices to eliminate O(N) .includes() lookups inside .every()
        const userIndicesSet = new Set(userIndices);
        isCorrect = (correctIndices.length > 0 &&
            correctIndices.length === userIndices.length &&
            correctIndices.every(idx => userIndicesSet.has(idx)));

        // Detect if user is using Hungarian
        // ⚡ Bolt: Use a Set for huOptsLower to eliminate O(N) .includes() lookups inside .some()
        const huOptsLowerSet = new Set(huOptsLower);
        const isUserHu = uNorms.some(u => huOptsLowerSet.has(u));

        // Map normalizedCorrect to user's language (or fallback to English)
        if (correctIndices.length > 0) {
            const resultList = isUserHu ? options.hu : options.en;
            const fallbackList = isUserHu ? options.en : options.hu;
            // ⚡ Bolt: Provide strict fallback to prevent null lookups
            const mappedCorrect = correctIndices.map(idx => resultList[idx] || fallbackList[idx]);
            normalizedCorrect = mappedCorrect.length > 1 ? mappedCorrect : mappedCorrect[0];
        } else {
            // Fallback for types that don't match indices perfectly
            normalizedCorrect = cNorms.length > 1 ? cNorms : cNorms[0];
        }
    } else {
        // Simple fallback validation
        // ⚡ Bolt: Use a Set for uNorms to eliminate O(N) .includes() lookups inside .every()
        const uNormsSet = new Set(uNorms);
        isCorrect = (cNorms.length === uNorms.length && cNorms.every(c => uNormsSet.has(c)));
        normalizedCorrect = cNorms.length > 1 ? cNorms : cNorms[0];
    }

    return { isCorrect, normalizedCorrect };
}

module.exports = {
    normalize,
    validateBilingual
};
