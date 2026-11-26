const Ajv = require('ajv');

const string = { type: 'string' };
const visible = { type: 'string', pattern: '\\S' };
const identity = { anyOf: [visible, { type: 'number' }] };
const translated = ['en', 'hu'];
const labels = [...translated, 'label', 'text', 'value'];

function hasLabel(fields) {
  return fields.map(field => ({
    required: [field],
    properties: { [field]: field === 'value' ? identity : visible },
  }));
}

const localizedText = {
  anyOf: [visible, {
    type: 'object', properties: { en: string, hu: string }, anyOf: hasLabel(translated),
  }],
};
const option = {
  type: 'object',
  properties: { id: identity, value: identity, en: string, hu: string, label: string, text: string },
  anyOf: hasLabel(labels),
};
const entry = { anyOf: [visible, option] };
const list = { type: 'array', minItems: 2, items: entry };
// The editor keeps empty slots so translations stay aligned by row.
const slots = { type: 'array', minItems: 2, items: { anyOf: [string, option] } };
const empty = { type: 'array', maxItems: 0 };
const translatedLists = {
  type: 'object',
  anyOf: [
    { required: ['en'], properties: { en: list, hu: empty } },
    { required: ['hu'], properties: { hu: list, en: empty } },
    {
      required: ['en', 'hu'], properties: { en: slots, hu: slots },
      anyOf: translated.map(lang => ({ properties: { [lang]: { contains: entry } } })),
    },
  ],
};
const options = { anyOf: [list, translatedLists] };
const matchesSchema = new Ajv().compile(options);

function validOptions(source) {
  if (!matchesSchema(source)) return false;
  if (Array.isArray(source)) return true;
  const { en = [], hu = [] } = source;
  if (en.length && hu.length && en.length !== hu.length) return false;
  // Cross-language length and coverage are relationships between two arrays.
  const filled = item => item != null && (typeof item !== 'string' || item.trim() !== '');
  return (en.length ? en : hu).every((_, i) => filled(en[i]) || filled(hu[i]));
}

module.exports = { localizedText, options, validOptions };
