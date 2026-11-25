const registry = require('../../../../src/services/questionTypes/registry');

const options = {en: ['red', 'green', 'blue'], hu: ['piros', 'zöld', 'kék']};
const multi = {question_type: 'multiple_choice', content: {options}, correct_answer: '["red","blue"]'};

test('bilingual multiple-choice options retain gradeable identities in the student presentation', () => {
  expect(registry.validate(multi.question_type, multi)).toEqual({valid: true, errors: []});
  const rendered = registry.prepareForClient(multi);
  expect(rendered.is_multiple).toBe(true);
  const [red, green, blue] = rendered.choice_options;
  expect([red.hu, green.hu, blue.hu]).toEqual(options.hu);
  expect(registry.checkAnswer(multi, [blue.id, 'piros'])).toMatchObject({correct: true, score: 1});
  expect(registry.checkAnswer(multi, [red.id, green.id])).toMatchObject({correct: false, score: 0});
});

test.each([
  [{}, 'content is required'],
  [{content: {options:{en:['one']}}, correct_answer:['one']}, 'At least 2 English options'],
  [{content:{options}}, 'correct_answer is required'],
  [{content:{options}, correct_answer:[]}, 'non-empty array'],
  [{content:{options}, correct_answer:'malformed'}, 'valid JSON array'],
  [{content:{options}, correct_answer:['red', 'missing']}, 'not in the options list: missing'],
])('reports the authoring error for an invalid multiple-choice definition', (question, message) => {
  const result = registry.validate('multiple_choice', question);
  expect(result.valid).toBe(false);
  expect(result.errors).toContainEqual(expect.stringContaining(message));
});

test('single-choice validation reports missing statements, options and absent keys', () => {
  expect(registry.validate('single_choice', {}).valid).toBe(false);
  expect(registry.validate('single_choice', {content: {}}).errors).toHaveLength(3);
  const content = {question_text: 'Pick a colour', options:['red','blue']};
  expect(registry.validate('single_choice', {content, correct_answer:'absent'}).valid).toBe(false);
  expect(registry.validate('single_choice', {content, correct_answer:'red'}).valid).toBe(true);
});

test('matching authoring requires both sides and presents each bilingual pair exactly once', () => {
  const pairs = [
    {left:{en:'A', hu:'a'}, right:{en:'X', hu:'x'}},
    {left:{en:'B', hu:'b'}, right:{en:'Y', hu:'y'}},
  ];
  const question = {question_type:'matching', content:{pairs}, correct_answer:{A:'X', B:'Y'}};
  expect(registry.validate('matching', {}).valid).toBe(false);
  expect(registry.validate('matching', {content: {pairs: []}}).errors).toHaveLength(1);
  const broken = registry.validate('matching', {content: {pairs:[{left:pairs[0].left},{right:pairs[1].right}]}});
  expect(broken.errors).toEqual([
    'Pair 1 is missing English "right" value', 'Pair 2 is missing English "left" value', 'correct_answer is required',
  ]);
  expect(registry.validate('matching', question).valid).toBe(true);
  const {left, right} = registry.prepareForClient(question).matching_data;
  expect(left).toHaveLength(2);
  expect(right).toHaveLength(2);
  expect(left).toEqual(expect.arrayContaining(pairs.map(pair => pair.left)));
  expect(right).toEqual(expect.arrayContaining(pairs.map(pair => pair.right)));
  expect(registry.prepareForAdmin(question)).toEqual(question);
  expect(registry.checkAnswer(question, {A:'Y', B:'X'}).correct).toBe(false);
});

test('relation-analysis aliases share their authoring codes, presentation order and grading', () => {
  const question = {question_type:'relational_analysis', correct_answer:'b'};
  const student = registry.prepareForClient(question).options;
  const author = registry.prepareForAdmin(question).options;
  expect(student.map(row => row.value)).toEqual(['A','B','C','D','E']);
  expect(author.map(row => row.value)).toEqual(student.map(row => row.value));
  expect(registry.validate('relation_analysis', {}).valid).toBe(false);
  expect(registry.validate('relation_analysis', {correct_answer:'Z'}).valid).toBe(false);
  expect(registry.validate('relation_analysis', question).valid).toBe(true);
  expect(registry.checkAnswer(question, 'B')).toMatchObject({correct:true, correctAnswer:'B'});
  expect(registry.checkAnswer(question, 'A')).toMatchObject({correct:false, correctAnswer:'B'});
});

test('true/false authoring accepts Hungarian keys and preserves the available answers in the editor', () => {
  const question = {question_type:'true_false', content:{statement:{en:'A'}}, correct_answer:'Hamis'};
  expect(registry.validate('true_false', {}).valid).toBe(false);
  expect(registry.validate('true_false', {content:{}}).errors).toHaveLength(2);
  expect(registry.validate('true_false', {...question, correct_answer:'invalid'}).valid).toBe(false);
  expect(registry.validate('true_false', question).valid).toBe(true);
  expect(registry.prepareForAdmin(question).options).toEqual(registry.prepareForClient(question).options);
  expect(registry.checkAnswer(question, false)).toMatchObject({correct:true, correctAnswer:'Hamis'});
});
