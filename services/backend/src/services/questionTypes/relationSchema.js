const Ajv = require('ajv');

const string = {type:'string'};
const visible = {type:'string', pattern:'\\S'};
const translation = {type:['string','null']};
const optionalTerm = {anyOf:[string, {type:'object', properties:{en:translation, hu:translation}}, {type:'null'}]};
const localizedText = {anyOf:[visible, ...['en','hu'].map(lang => field(lang, visible))]};
const statements = [['statement1', 'statement_1'], ['statement2', 'statement_2']];

function field(name, schema) {
  return {type:'object', required:[name], properties:{[name]:schema}};
}

const sides = statements.map(names => ({anyOf:names.map(name => field(name, localizedText))}));
const pair = {allOf:sides};
const content = {
  type:['object','null'],
  // GET /quiz/question-types publishes this content fragment without the enclosing prompt fields.
  anyOf:[pair, {not:{anyOf:sides}}],
  properties:Object.fromEntries([...statements.flat(),'link_word','question_text'].map(name => [name, optionalTerm])),
};

const fullPrompt = {anyOf:[
  ...['question_text_en','question_text_hu','text'].map(name => field(name, visible)),
  field('content', field('question_text', localizedText)),
]};

// Rows written by the older editor can have two empty statement objects alongside the full prompt.
const presentation = {
  type:'object',
  properties:{content},
  anyOf:[field('content', pair), fullPrompt],
};
const hasPresentation = new Ajv().compile(presentation);
const schema = {
  ...presentation,
  required:['correct_answer'],
  properties:{
    content,
    correct_answer:{type:'string', pattern:'^\\s*[A-Ea-e]\\s*$'},
    explanation:{type:'string'},
  },
};

module.exports = {schema, hasPresentation};
