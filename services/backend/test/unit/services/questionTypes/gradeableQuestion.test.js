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
        if (!type || !type.checkAnswer(question, question.question_type === 'relation_analysis' ?
            [].concat(question.correct_answer)[0] : question.correct_answer).correct ||
            (question.question_type === 'matching' && !client.matching_data?.left?.length) ||
            JSON.stringify(q.correct_answer) !== JSON.stringify(question.correct_answer)) {
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
