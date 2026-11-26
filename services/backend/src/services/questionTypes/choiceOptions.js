const { createHash } = require('node:crypto');
const { decodeStoredAnswer } = require('./storedAnswer');

function parseOptions(value) {
  if (typeof value !== 'string') return value;
  try { return JSON.parse(value); } catch { return value; }
}

function stableId(key) {
  return 'opt_' + createHash('sha256').update(String(key)).digest('hex').slice(0, 32);
}

function optionSource(question) {
  const sources = [parseOptions(question.options), parseOptions(question.content?.options),
    { en: parseOptions(question.options_en), hu: parseOptions(question.options_hu) }];
  return sources.find(value => [value, value?.en, value?.hu]
    .some(list => Array.isArray(list) && list.length));
}

function firstText(...values) {
  return values.find(value => typeof value === 'string' && value.trim()) ?? '';
}

function keyText(value) {
  return typeof value === 'number' ? String(value) : firstText(value);
}

// Historical IDs are accepted on read without exposing additional student-facing fields.
const historicalIds = new WeakMap();

function choiceOptions(question) {
  const options = optionSource(question);
  if (!options) return [];
  const enRows = Array.isArray(options) ? options : Array.isArray(options.en) ? options.en : [];
  const huRows = Array.isArray(options.hu) ? options.hu : [];
  const entries = enRows.length ? enRows : huRows;
  const choices = [];
  entries.forEach((raw, index) => {
    const translated = huRows[index];
    const hasPrimary = enRows.length > 0;
    const entry = typeof raw === 'string' && !raw.trim() && translated && typeof translated === 'object'
      ? translated : raw;
    const hu = firstText(entry?.hu, translated?.hu, translated?.text, translated?.label,
      keyText(translated?.value), translated);
    const en = firstText(entry?.en, hasPrimary && entry === raw && entry?.label,
      hasPrimary && entry === raw && entry?.text, hasPrimary && raw,
      hasPrimary && entry === raw && !firstText(entry?.hu) && keyText(entry?.value));
    if (!en && !hu) return;
    const key = keyText(entry?.id) || keyText(entry?.value) || en || hu;
    const choice = { id: stableId(key), en: en || hu, hu: hu || en };
    const previousKey = raw?.id ?? raw?.value ?? raw?.en ?? raw?.label ?? raw?.text ??
      raw?.hu ?? (typeof raw === 'string' ? raw : '');
    if ((typeof previousKey === 'string' || typeof previousKey === 'number') && String(previousKey) !== key) {
      historicalIds.set(choice, stableId(previousKey));
    }
    choices.push(choice);
  });
  return choices;
}

function createChoiceResolver(choices) {
  const byId = new Map();
  const byLabel = new Map();
  const byPreviousId = new Map();
  for (const choice of choices) {
    byId.set(choice.id, choice);
    const previous = historicalIds.get(choice);
    if (previous) byPreviousId.set(previous, byPreviousId.has(previous) ? null : choice);
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
    if (byPreviousId.has(label)) return byPreviousId.get(label);
    const authored = byId.get(stableId(text));
    if (!byLabel.has(label)) return authored;
    const named = byLabel.get(label);
    return named && (!authored || authored === named) ? named : undefined;
  };
}

function gradeChoices(question, answer, multiple = false, choices = choiceOptions(question)) {
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
  // A displayed label can itself look like a JSON array. Only unwrap the
  // legacy wire encoding when the submitted text isn't an option label.
  const literal = typeof answer === 'string' && ['[', '{', '"'].includes(answer.trim()[0])
    && choices.some(choice => [choice.en, choice.hu].some(text =>
      text.trim().toLowerCase() === answer.trim().toLowerCase()));
  const actual = literal ? [key(answer)] : keys(answer);
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

module.exports = { optionSource, choiceOptions, distinctChoices, gradeChoices, createChoiceResolver, resolveChoice };
