const gradeableQuestion = require('../../../../src/services/questionTypes/gradeableQuestion');

describe('practice content contracts', () => {
  const choice = {question_type: 'multiple_choice', options: {en: ['a, b', 'c', 'x'], hu: ['ab', 'c', 'x']}};
  test('recovers exactly one lossless partition into original options', () => {
    expect(gradeableQuestion({...choice, correct_answer: ['a', 'b','c']}).correct_answer).toEqual(['a, b','c']);
    expect(gradeableQuestion({...choice, correct_answer: ['a, b, c']}).correct_answer).toEqual(['a, b','c']);
    expect(gradeableQuestion({...choice, correct_answer: ['obsolete answer']})).toBeNull();
  });
  test('keeps a gradeable translated answer', () => {
    expect(gradeableQuestion({...choice, correct_answer: '["ab","c"]'})).toBeTruthy();
  });
  test('withholds ambiguous repairs', () => {
    expect(gradeableQuestion({question_type:'multiple_choice',
      options: ['a', 'b, c', 'a, b', 'c'], correct_answer: ['a, b, c']})).toBeNull();
  });
  test('recovers explicitly paired definitions', () => {
    const raw = {question_type:'matching', correct_answer: {}, options:{en:['A: X','B: Y'],hu:['Bal: Első','Jobb: Második']}};
    expect(gradeableQuestion(raw).correct_answer).toEqual({A:'X',B:'Y'});
    expect(gradeableQuestion({...raw, options:{en:['A','B']}})).toBeNull();
  });
});

test('tracked practice content can be rendered and graded through the public type', () => {
  const fs = require('node:fs');
  const path = require('node:path');
  const registry = require('../../../../src/services/questionTypes/registry');
  const dir = path.resolve(__dirname, '../../../../src/data/questions');
  const failures = [];
  function check(directory) {
    for (const entry of fs.readdirSync(directory, {withFileTypes: true})) {
      const filename = path.join(directory, entry.name);
      if (entry.isDirectory()) { if (entry.name !== 'legacy_backup') check(filename); continue; }
      if (!entry.name.endsWith('.json')) continue;
      const document = JSON.parse(fs.readFileSync(filename, 'utf8'));
      const rows = Array.isArray(document) ? document : document.questions;
      rows.forEach((q, index) => {
        if (q.active === false) return;
        const question = gradeableQuestion(q);
        const type = question && registry.getType(question.question_type);
        const client = type && type.prepareForClient(question);
        const expectedKey = question?.question_type === 'relation_analysis'
          ? [].concat(q.correct_answer)[0] : q.correct_answer;
        if (!type || !type.checkAnswer(question, question.correct_answer).correct ||
            (question.question_type === 'matching' && !client.matching_data?.left?.length) ||
            JSON.stringify(expectedKey) !== JSON.stringify(question.correct_answer)) {
          failures.push(path.relative(dir, filename) + ' ' + (q.id ?? index));
        }
      });
    }
  }
  check(dir);
  expect(failures).toEqual([]);
});

test('preserves older authoring IDs and the legacy type column', () => {
  const question = {question_type: 'single_choice', type: 'multiple_choice',
    options: {en: [{id: 'a', text:'Red'}, {id:'b', text:'Blue'}], hu: [{text:'Piros'},{text:'Kék'}]},
    correct_answer: ['a','b']};
  expect(gradeableQuestion(question)).toMatchObject({question_type:'multiple_choice', correct_answer:['Red','Blue']});
});


test('a broken explicit type cannot be graded as a different legacy type', () => {
  const row = {type: 'single_choice', options: ['Red', 'Blue'], correct_answer: 'Red'};
  expect(gradeableQuestion({...row, question_type: 'matching'})).toBeNull();
  expect(gradeableQuestion({...row, question_type: 'retired_type'})).toBeNull();
  expect(gradeableQuestion(row)).toMatchObject({question_type: 'single_choice'});
});

test('scalar keys accept one historical wrapper and reject remaining containers', () => {
  const {scalarAnswer, decodeStoredAnswer} = require('../../../../src/services/questionTypes/storedAnswer');
  for (const key of ['["A"]', ['A'], '"A"', 'A']) expect(scalarAnswer(key)).toBe('A');
  expect(scalarAnswer('[false]')).toBe(false);
  expect(scalarAnswer('[0]')).toBe(0);
  for (const value of [{toString: 'not a method'}, '[{"a":1}]', '[[1]]', ['a','b']]) {
    expect(scalarAnswer(value)).toBeNull();
  }
  expect(decodeStoredAnswer('{"left":"right"}')).toEqual({left:'right'});
});

test('structured keys produce a validation result for a single-choice question', () => {
  const registry = require('../../../../src/services/questionTypes/registry');
  const q = {content: {question_text: 'Pick one', options: ['A','B']},
    correct_answer: '{"toString":0}'};
  expect(registry.validate('single_choice', q).valid).toBe(false);
});
