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
  [{content: {options:{en:['one']}}, correct_answer:['one']}, 'At least 2 options'],
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
  const question = {question_type:'relational_analysis', question_text_en:'First because second', correct_answer:'b'};
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

describe.each(['single_choice', 'multiple_choice'])('%s editor and student choice contract', type => {
  const ajv = new (require('ajv'))();
  const handler = registry.getType(type);
  const schema = ajv.compile(handler.getSchema().properties.content);

  test('empty alternate language and placeholders keep both choices visible and gradeable', () => {
    for (const options of [
      { en: ['One', 'Two'], hu: [] },
      { en: ['One', 'Two'], hu: ['', '  '] },
      { en: [], hu: [{ id: 4, hu: 'Egy' }, { id: 5, hu: 'Kettő' }] },
      { en: ['', '  '], hu: ['Egy', 'Kettő'] },
    ]) {
      const expected = options.en.some(v => v.trim()) ? ['One', 'Two'] : ['Egy', 'Kettő'];
      const key = expected[1];
      const content = { question_text: { en: 'Choose', hu: '' }, options };
      expect(schema(content)).toBe(true);
      const question = { question_type: type, content, correct_answer: type === 'single_choice' ? key : [key] };
      expect(registry.validate(type, question).valid).toBe(true);
      const choices = handler.prepareForClient(question).choice_options;
      expect(choices.map(c => c.hu)).toEqual(expected);
      expect(choices.map(c => c.en)).toEqual(expected);
      expect(handler.checkAnswer(question, type === 'single_choice' ? choices[1].id : [choices[1].id]).correct).toBe(true);
    }
  });

  test('structured translated slots preserve the same canonical ID as the editor', () => {
    const options = {en:['', ''], hu:[{id:42, label:'Egy'}, {id:5, hu:'Kettő'}]};
    const question = {content:{question_text:'Choose', options}, correct_answer:type === 'single_choice' ? '42' : ['42']};
    const [first] = handler.prepareForClient(question).choice_options;
    expect(first).toEqual({en:'Egy', hu:'Egy', id:'opt_73475cb40a568e8da8a045ced110137e'});
    expect(handler.checkAnswer(question, type === 'single_choice' ? first.id : [first.id]).correct).toBe(true);
  });

  test('a historical blank-label hash is usable only when its row is unique', () => {
    const old = 'opt_e3b0c44298fc1c149afbf4c8996fb924';
    const question = en => ({options:{en, hu:['Első','Második']}, correct_answer:type === 'single_choice' ? old : [old]});
    const actual = type === 'single_choice' ? 'Első' : ['Első'];
    expect(handler.checkAnswer(question(['','Second']), actual).correct).toBe(true);
    expect(handler.checkAnswer(question(['','']), actual).correct).toBe(false);
  });

  test('invalid structured identity and labels are rejected by the advertised and runtime contracts', () => {
    for (const bad of [{id: {}, en:'One'}, {en: {text:'One'}}, {en:'   '}]) {
      const content = {question_text: 'Choose', options: [bad, 'Two']};
      expect(schema(content)).toBe(false);
      expect(registry.validate(type, {content, correct_answer: type === 'single_choice' ? 'Two' : ['Two']}).valid).toBe(false);
    }
  });
});

test('a quoted JSON-looking single answer still grades its original row after storage normalization', () => {
  const gradeableQuestion = require('../../../../src/services/questionTypes/gradeableQuestion');
  const q = {question_type:'single_choice', options:['[42]', '42'], correct_answer:'"[42]"'};
  const prepared = gradeableQuestion(q);
  const [first, second] = registry.prepareForClient(q).choice_options;
  expect(prepared.correct_answer).toBe(first.id);
  expect(registry.checkAnswer(prepared, first.id).correct).toBe(true);
  expect(registry.checkAnswer(prepared, second.id).correct).toBe(false);
});
