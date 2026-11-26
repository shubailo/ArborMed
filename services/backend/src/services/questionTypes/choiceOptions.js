const { createHash } = require('node:crypto');
const { decodeStoredAnswer } = require('./storedAnswer');

function parseOptions(value) {
  if (typeof value !== 'string') return value;
  try { return JSON.parse(value); } catch { return value; }
}

function stableId(key) {
  return 'opt_' + createHash('sha256').update(String(key)).digest('hex').slice(0, 32);
}

function choiceOptions(question) {
  const sources = [parseOptions(question.options), parseOptions(question.content?.options),
    { en: parseOptions(question.options_en), hu: parseOptions(question.options_hu) }];
  const options = sources.find(value => [value, value?.en, value?.hu]
    .some(list => Array.isArray(list) && list.length));
  if (!options) return [];
  const entries = [options, options.en, options.hu].find(list => Array.isArray(list) && list.length);
  return entries.map((entry, index) => {
    const en = String(entry?.en ?? entry?.label ?? entry?.text ?? entry?.hu ?? entry?.value ?? (typeof entry === 'string' ? entry : ''));
    const translated = options.hu?.[index];
    const hu = String(entry?.hu ?? translated?.hu ?? translated?.text ?? translated?.label ??
      (typeof translated === 'string' ? translated : en));
    // Keep the same key across translations, option shuffling and author reordering.
    const key = String(entry?.id ?? entry?.value ?? en);
    const id = stableId(key);
    return { id, en, hu };
  }).filter(c => c.en.trim() || c.hu.trim());
}

function createChoiceResolver(choices) {
  const byId = new Map();
  const byLabel = new Map();
  for (const choice of choices) {
    byId.set(choice.id, choice);
    for (const text of [choice.en, choice.hu]) {
      const label = text.trim().toLowerCase();
      if (!byLabel.has(label)) byLabel.set(label, choice);
      else if (byLabel.get(label) !== choice) byLabel.set(label, null);
    }
  }
  return value => {
    const text = String(value).trim();
    const label = text.toLowerCase();
    if (byId.has(label)) return byId.get(label);
    const authored = byId.get(stableId(text));
    if (!byLabel.has(label)) return authored;
    const named = byLabel.get(label);
    return named && (!authored || authored === named) ? named : undefined;
  };
}

function gradeChoices(question, answer, multiple = false) {
  const choices = choiceOptions(question);
  const resolve = createChoiceResolver(choices);
  function key(value) {
    if (typeof value !== 'string' && typeof value !== 'number') return null;
    const label = String(value).trim().toLowerCase();
    if (!label) return null;
    if (!choices.length) return label;
    return resolve(value)?.id ?? null;
  }
  function keys(input) {
    const parsed = decodeStoredAnswer(input);
    return (Array.isArray(parsed) ? parsed : [parsed]).map(key);
  }
  const expected = keys(question.correct_answer);
  const actual = keys(answer);
  const actualSet = new Set(actual);
  const correct = expected.length > 0 && distinctChoices(choices) && (multiple || expected.length === 1)
    && expected.length === actual.length && actualSet.size === actual.length
    && new Set(expected).size === expected.length
    && expected.every(id => id !== null && actualSet.has(id));
  function display(value) {
    return choices.find(choice => choice.id === value)?.en ?? value;
  }
  const displayAnswer = Array.isArray(answer) ? answer.map(display) : display(answer);
  return { correct, displayAnswer, score: correct ? 1 : 0, correctAnswer: question.correct_answer };
}

function distinctChoices(choices) {
  return new Set(choices.map(choice => choice.id)).size === choices.length;
}

function resolveChoice(choices, value) {
  return createChoiceResolver(choices)(value);
}

module.exports = { choiceOptions, distinctChoices, gradeChoices, createChoiceResolver, resolveChoice };
