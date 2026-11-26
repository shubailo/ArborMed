const text = { type: 'string', minLength: 1 };
const localized = {
  type: 'object', properties: { en: text, hu: text },
  anyOf: [{ required: ['en'] }, { required: ['hu'] }],
};
const option = {
  type: 'object', properties: { en: text, hu: text, label: text, text, value: text },
  anyOf: ['en', 'hu', 'label', 'text', 'value'].map(field => ({ required: [field] })),
};
const list = { type: 'array', items: { anyOf: [text, option] }, minItems: 2 };
const translatedLists = {
  type: 'object', properties: { en: list, hu: list },
  anyOf: [{ required: ['en'] }, { required: ['hu'] }],
};

module.exports = {
  localizedText: { anyOf: [text, localized] },
  options: { anyOf: [list, translatedLists] },
};
