const SingleChoiceType = require('../../../../src/services/questionTypes/SingleChoiceType');
const MultipleChoiceType = require('../../../../src/services/questionTypes/MultipleChoiceType');

const question = {
  options: { en: ['red, bright', 'blue'], hu: ['piros', 'kék'] },
  correct_answer: '["red, bright"]',
};
const single = new SingleChoiceType();
const multi = new MultipleChoiceType();

test('grades the same option in either language and by its stable identifier', () => {
  const [red] = single.prepareForClient(question).choice_options;
  for (const answer of [red.id, 'red, bright', 'piros']) {
    expect(single.checkAnswer(question, answer).correct).toBe(true);
  }
  expect(single.checkAnswer(question, 'blue').correct).toBe(false);
});

test('multiple choice requires every correct option exactly once', () => {
  const q = { ...question, correct_answer: ['red, bright', 'blue'] };
  expect(multi.checkAnswer(q, ['kék', 'piros']).correct).toBe(true);
  expect(multi.checkAnswer(q, ['kék', 'kék']).correct).toBe(false);
  expect(multi.checkAnswer(q, ['piros', 'kék', 'unknown']).correct).toBe(false);
});

test('falls back to content options for malformed or empty legacy columns', () => {
  for (const options of [[], { en: 'malformed' }, 'bad json']) {
    const q = { ...question, options, content: { options: question.options } };
    expect(single.prepareForClient(q).choice_options).toHaveLength(2);
    expect(single.checkAnswer(q, 'piros').correct).toBe(true);
  }
});

test('grades historical JSON text stored by bilingual seeders', () => {
  const matching = new (require('../../../../src/services/questionTypes/MatchingType'))();
  const tf = new (require('../../../../src/services/questionTypes/TrueFalseType'))();
  const relation = new (require('../../../../src/services/questionTypes/RelationAnalysisType'))();
  expect(matching.checkAnswer({correct_answer: '{"a":"b","x":"y"}'}, {a:'b',x:'y'}).correct).toBe(true);
  expect(matching.checkAnswer({correct_answer: '{}'}, {}).correct).toBe(false);
  expect(matching.checkAnswer({correct_answer: '{"a":"b"}'}, {q:'b'}).correct).toBe(false);
  expect(tf.checkAnswer({correct_answer: '["false"]'}, 'hamis').correct).toBe(true);
  expect(relation.checkAnswer({correct_answer: '["A"]'}, 'A').correct).toBe(true);
});

test('prepares bilingual matching choices from the shipped legacy seed', () => {
  const questions = require('../../../../src/data/questions/haematology_questions.json');
  const q = questions.find(row => row.id === 'hd_005');
  const type = new (require('../../../../src/services/questionTypes/MatchingType'))();
  const { matching_data: choices } = type.prepareForClient(q);
  expect(choices.left).toContainEqual({ en:'Beta Globulin', hu:'Béta globulin' });
  expect(choices.right).toContainEqual({ en:'Transferrin', hu:'Transzferrin' });
});
