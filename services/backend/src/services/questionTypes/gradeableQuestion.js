const { choiceOptions, gradeChoices, resolveChoice } = require('./choiceOptions');
const { decodeStoredAnswer, scalarAnswer } = require('./storedAnswer');
const registry = require('./registry');

const splitPair = require('./splitPair');

function pairMap(pairs) {
  if (!Array.isArray(pairs) || pairs.length < 2 ||
      pairs.some(pair => !Array.isArray(pair) || pair.length !== 2 ||
        pair.some(value => typeof value !== 'string' || !value.trim()))) return null;
  const unique = side => new Set(pairs.map(pair => pair[side].trim().toLowerCase())).size === pairs.length;
  return unique(0) && unique(1) ? Object.fromEntries(pairs) : null;
}

function matchingAnswer(question) {
  const stored = decodeStoredAnswer(question.correct_answer);
  const explicit = question.content?.pairs;
  if (explicit != null && !Array.isArray(explicit)) return null;
  const displayed = explicit?.length ? pairMap(explicit.map(pair => [pair?.left?.en, pair?.right?.en])) : null;
  if (explicit?.length && !displayed) return null;
  if (stored && typeof stored === 'object' && !Array.isArray(stored) && Object.keys(stored).length) {
    const map = pairMap(Object.entries(stored));
    if (!map || (displayed && (Object.keys(map).length !== Object.keys(displayed).length ||
        Object.entries(map).some(([left, right]) => displayed[left] !== right)))) return null;
    return map;
  }
  if (stored != null && (typeof stored !== 'object' || Array.isArray(stored))) return null;
  if (displayed) return displayed;
  const options = decodeStoredAnswer(question.options);
  const lines = Array.isArray(options) ? options : options?.en;
  return Array.isArray(lines) ? pairMap(lines.map(splitPair)) : null;
}

// Some historical imports split every comma, including commas inside labels.
// Accept only a unique full partition of the recorded key into displayed options.
function recoverChoices(choices, input, multiple) {
  const parts = Array.isArray(input) ? input : [input];
  if (!parts.length || !parts.every(value => typeof value === 'string')) return null;
  const normalize = value => value.trim().toLowerCase().replace(/\s*[,;]\s*/g, ',').replace(/\s+/g, ' ');
  const source = normalize(parts.join(','));
  const labels = choices.flatMap(choice => [...new Set([normalize(choice.en), normalize(choice.hu)])]
    .filter(Boolean).map(label => ({ label, choice })));
  const memo = new Map();
  function partitions(start) {
    if (memo.has(start)) return memo.get(start);
    const matches = [];
    for (const { label, choice } of labels) {
      if (!source.startsWith(label, start)) continue;
      const end = start + label.length;
      if (end === source.length) matches.push([choice]);
      else if (multiple && source[end] === ',') {
        for (const suffix of partitions(end + 1)) matches.push([choice, ...suffix]);
      }
      if (matches.length > 1) break;
    }
    memo.set(start, matches);
    return matches;
  }
  const matches = partitions(0);
  if (matches.length !== 1 || new Set(matches[0].map(choice => choice.id)).size !== matches[0].length) return null;
  return multiple ? matches[0].map(choice => choice.en) : matches[0][0].en;
}

function fromType(question, declaredType) {
  if (!question || question.active === false) return null;
  let type = declaredType;
  if (type === 'relational_analysis') type = 'relation_analysis';
  const input = decodeStoredAnswer(question.correct_answer);
  if (type === 'case_study') type = 'single_choice';
  let key = input;
  if (type === 'matching') {
    key = matchingAnswer(question);
    if (!key) return null;
  } else if (type === 'single_choice' || type === 'multiple_choice') {
    const choices = choiceOptions(question);
    if (choices.length < 2) return null;
    const multiple = type === 'multiple_choice';
    if (!gradeChoices(question, input, multiple).correct) {
      key = recoverChoices(choices, input, multiple);
      if (key == null || !gradeChoices({...question, correct_answer: key}, key, multiple).correct) return null;
    }
    // A historical authoring ID (e.g. "a") is distinct from the stable
    // ID sent to the app. Use a visible label for the offline answer key.
    const visible = value => {
      const choice = resolveChoice(choices, value);
      const normalized = String(value).trim().toLowerCase();
      return [choice.id, choice.en.trim().toLowerCase(), choice.hu.trim().toLowerCase()].includes(normalized) ? value : choice.en;
    };
    key = Array.isArray(key) ? key.map(visible) : visible(key);
  } else {
    const handler = registry.getType(type);
    if (!handler || !handler.checkAnswer(question, scalarAnswer(input)).correct) return null;
  }
  return {...question, question_type: type, correct_answer: key};
}

function gradeableQuestion(question) {
  if (!question) return null;
  const primary = question.question_type || question.type || 'single_choice';
  const result = fromType(question, primary);
  if (result || !question.type || question.type === primary) return result;
  // Some seeders only populated the legacy type while the newer column
  // retained its default. Accept its declared type only if it actually grades.
  return fromType(question, question.type);
}

module.exports = gradeableQuestion;
