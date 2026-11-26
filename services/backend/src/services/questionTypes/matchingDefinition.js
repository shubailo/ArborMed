const { decodeStoredAnswer } = require('./storedAnswer');
const splitPair = require('./splitPair');

const isMap = value => value !== null && typeof value === 'object' && !Array.isArray(value);
const hasText = value => typeof value === 'string' && value.trim().length > 0;

function legacyPairs(question, stored) {
  const options = decodeStoredAnswer(question.options);
  const english = Array.isArray(options) ? options : options?.en;
  const parsed = Array.isArray(english) ? english.map(splitPair) : [];
  const entries = stored?.length ? stored : parsed;
  if (!entries.length || entries.some(pair => !pair)) return [];
  const translations = [new Map(), new Map()];
  if (Array.isArray(options?.hu) && options.hu.length === parsed.length) {
    parsed.forEach((en, index) => {
      const hu = splitPair(options.hu[index]);
      if (!en || !hu) return;
      en.forEach((term, side) => {
        const labels = translations[side];
        const value = labels.has(term) && labels.get(term) !== hu[side] ? null : hu[side];
        labels.set(term, value);
      });
    });
  }
  return entries.map(([left, right]) => ({
    left: {en:left, hu:translations[0].get(left) ?? left},
    right: {en:right, hu:translations[1].get(right) ?? right},
  }));
}

// The wire identity is the original English text. Whitespace and case folding
// are used only to detect indistinguishable labels within each column.
function matchingDefinition(question) {
  const key = decodeStoredAnswer(question?.correct_answer);
  const stored = isMap(key) ? Object.entries(key) : [];
  const content = decodeStoredAnswer(question?.content);
  const explicit = content?.pairs;
  const errors = [];
  if (key != null && !isMap(key)) errors.push('correct_answer must be a mapping');
  if (explicit != null && !Array.isArray(explicit)) return {errors:['pairs must be an array']};
  const source = explicit?.length ? explicit : legacyPairs(question ?? {}, stored);
  if (source.length < 2) return {errors:['pairs must be an array with at least 2 items']};

  const seen = {left:{en:new Set(), hu:new Set()}, right:{en:new Set(), hu:new Set()}};
  const pairs = source.map((row, i) => {
    const pair = {};
    for (const side of ['left', 'right']) {
      const term = row?.[side];
      if (!hasText(term?.en)) {
        errors.push('Pair ' + (i + 1) + ' is missing English "' + side + '" value');
        continue;
      }
      if (term.hu != null && typeof term.hu !== 'string') {
        errors.push('Pair ' + (i + 1) + ' has an invalid Hungarian "' + side + '" value');
        continue;
      }
      pair[side] = {en:term.en, hu:hasText(term.hu) ? term.hu : term.en};
      for (const lang of ['en','hu']) {
        const normalized = pair[side][lang].trim().toLowerCase();
        if (seen[side][lang].has(normalized)) {
          errors.push('Pair ' + (i + 1) + ' repeats a ' + side + ' label (' + lang + ')');
        }
        seen[side][lang].add(normalized);
      }
    }
    return pair;
  });

  if (errors.length) {
    if (key == null) errors.push('correct_answer is required');
    return {errors};
  }
  const answer = Object.fromEntries(pairs.map(pair => [pair.left.en, pair.right.en]));
  if (stored.length && (stored.length !== pairs.length || stored.some(([left, right]) =>
    !Object.hasOwn(answer, left) || answer[left] !== right))) {
    return {errors:['correct_answer must agree with the displayed pairs']};
  }
  return {pairs, answer, errors};
}

module.exports = matchingDefinition;
