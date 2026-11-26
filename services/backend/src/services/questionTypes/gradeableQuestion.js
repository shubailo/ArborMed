const { choiceOptions, distinctChoices, gradeChoices, createChoiceResolver } = require('./choiceOptions');
const { decodeStoredAnswer, scalarAnswer } = require('./storedAnswer');
const registry = require('./registry');

const matchingDefinition = require('./matchingDefinition');

// Some historical imports split every comma, including commas inside labels.
// Accept only a unique full partition of the recorded key into displayed options.
function recoverChoices(choices, resolve, input, multiple) {
  const parts = Array.isArray(input) ? input : [input];
  if (!parts.length || !parts.every(value => typeof value === 'string')) return null;
  const normalize = value => value.trim().toLowerCase().replace(/\s*[,;]\s*/g, ',').replace(/\s+/g, ' ');
  const source = normalize(parts.join(','));
  const labels = choices.flatMap(choice => {
    const aliases = [choice.en, choice.hu].filter(value => resolve(value)?.id === choice.id);
    return [...new Set(aliases.map(normalize))].filter(Boolean).map(label => ({ label, choice }));
  });
  if (!source) return null;
  // Count complete paths at each token boundary. Two paths already mean ambiguity.
  const paths = new Map([[0, { count: 1 }]]);
  for (let start = 0; start < source.length; start++) {
    const prefix = paths.get(start);
    if (!prefix) continue;
    for (const { label, choice } of labels) {
      if (!source.startsWith(label, start)) continue;
      const end = start + label.length;
      if (end !== source.length && (!multiple || source[end] !== ',' || end + 1 === source.length)) continue;
      const next = end === source.length ? end : end + 1;
      const existing = paths.get(next);
      paths.set(next, { count: Math.min(2, (existing?.count || 0) + prefix.count), start, choice });
    }
  }
  if (paths.get(source.length)?.count !== 1) return null;
  const recovered = [];
  for (let pos = source.length; pos > 0;) {
    const step = paths.get(pos);
    recovered.push(step.choice);
    pos = step.start;
  }
  if (!distinctChoices(recovered)) return null;
  const keys = recovered.reverse().map(choice => visibleKey(resolve, choice));
  return multiple ? keys : keys[0];
}

function visibleKey(resolve, choice) {
  const label = choice.en;
  return decodeStoredAnswer(label) === label && resolve(label)?.id === choice.id ? label : choice.id;
}

function fromType(question, declaredType) {
  if (!question || question.active === false) return null;
  let type = declaredType;
  if (type === 'relational_analysis') type = 'relation_analysis';
  if (type === 'case_study') type = 'single_choice';
  let key;
  if (type === 'matching') {
    key = matchingDefinition(question).answer;
    if (!key) return null;
  } else if (type === 'relation_analysis') {
    key = registry.getType(type).solutionFor(question);
    if (!key) return null;
  } else if (type === 'single_choice' || type === 'multiple_choice') {
    const input = decodeStoredAnswer(question.correct_answer);
    key = input;
    const choices = choiceOptions(question);
    if (choices.length < 2 || !distinctChoices(choices)) return null;
    const multiple = type === 'multiple_choice';
    const resolve = createChoiceResolver(choices);
    if (!gradeChoices(question, input, multiple).correct) {
      key = recoverChoices(choices, resolve, input, multiple);
      if (key == null || !gradeChoices({...question, correct_answer: key}, key, multiple).correct) return null;
    }
    // A historical authoring ID (e.g. "a") is distinct from the stable
    // ID sent to the app. Use a visible label for the offline answer key.
    const visible = value => {
      const choice = resolve(value);
      if (!multiple && decodeStoredAnswer(value) !== value) return choice.id;
      const normalized = String(value).trim().toLowerCase();
      return [choice.id, choice.en.trim().toLowerCase(), choice.hu.trim().toLowerCase()].includes(normalized) ? value : visibleKey(resolve, choice);
    };
    key = Array.isArray(key) ? key.map(visible) : visible(key);
  } else {
    const handler = registry.getType(type);
    key = decodeStoredAnswer(question.correct_answer);
    if (!handler || !handler.checkAnswer(question, scalarAnswer(key)).correct) return null;
  }
  return {...question, question_type: type, correct_answer: key};
}

function gradeableQuestion(question) {
  if (!question) return null;
  const primary = question.question_type ?? question.type ?? 'single_choice';
  const result = fromType(question, primary);
  if (result || primary !== 'single_choice' || !question.type || question.type === primary) return result;
  // Some seeders only populated the legacy type while the newer column
  // retained its default. Accept its declared type only if it actually grades.
  return fromType(question, question.type);
}

module.exports = gradeableQuestion;
