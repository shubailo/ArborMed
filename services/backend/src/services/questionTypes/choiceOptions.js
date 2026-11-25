const { createHash } = require('node:crypto');
const { decodeStoredAnswer } = require('./storedAnswer');

function parseOptions(value) {
  if (typeof value !== 'string') return value;
  try { return JSON.parse(value); } catch { return value; }
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
    const hu = String(entry?.hu ?? options.hu?.[index] ?? en);
    // Keep the same key across translations, option shuffling and author reordering.
    const key = String(entry?.id ?? entry?.value ?? en);
    const id = 'opt_' + createHash('sha256').update(key).digest('hex').slice(0, 32);
    return { id, en, hu };
  }).filter(c => c.en.trim() || c.hu.trim());
}

function gradeChoices(question, answer, multiple = false) {
  const choices = choiceOptions(question);
  function key(value) {
    if (typeof value !== 'string' && typeof value !== 'number') return null;
    const label = String(value).trim().toLowerCase();
    if (!label) return null;
    if (!choices.length) return label;
    const match = choices.find(c => c.id === label || c.en.trim().toLowerCase() === label)
      ?? choices.find(c => c.hu.trim().toLowerCase() === label);
    return match?.id ?? null;
  }
  function keys(input) {
    const parsed = decodeStoredAnswer(input);
    return (Array.isArray(parsed) ? parsed : [parsed]).map(key);
  }
  const expected = keys(question.correct_answer);
  const actual = keys(answer);
  const actualSet = new Set(actual);
  const correct = expected.length > 0 && (multiple || expected.length === 1)
    && expected.length === actual.length && actualSet.size === actual.length
    && new Set(expected).size === expected.length
    && expected.every(id => id !== null && actualSet.has(id));
  function display(value) {
    return choices.find(choice => choice.id === value)?.en ?? value;
  }
  const displayAnswer = Array.isArray(answer) ? answer.map(display) : display(answer);
  return { correct, displayAnswer, score: correct ? 1 : 0, correctAnswer: question.correct_answer };
}

module.exports = { choiceOptions, gradeChoices };
