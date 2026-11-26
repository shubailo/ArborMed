const Ajv = require('ajv');
const registry = require('../../../../src/services/questionTypes/registry');
const gradeableQuestion = require('../../../../src/services/questionTypes/gradeableQuestion');

const type = registry.getType('relation_analysis');
const accepts = new Ajv().compile(type.getSchema());
const make = content => ({question_type:'relational_analysis', content, correct_answer:'B'});
const split = {statement1:{en:'First'}, statement2:{hu:'Második'}};
const full = 'First statement because second statement';

test('a partial or malformed relation cannot be saved, offered, or awarded credit', () => {
  for (const content of [
    {statement1: 'Alone'}, {...split, statement1:{en:7,hu:'Első'}},
    {...split, statement2:[]}, {...split, link_word:{hu:true}}, ['not an object'],
  ]) {
    const q = {...make(content), question_text_en:full};
    expect(type.validate(q).valid).toBe(false);
    expect(accepts(q)).toBe(false);
    expect(gradeableQuestion(q)).toBeNull();
    expect(type.prepareForClient(q).correct_answer).toBeNull();
    expect(type.checkAnswer(q, 'B')).toMatchObject({correct:false, score:0});
  }
  expect(gradeableQuestion(make({}))).toBeNull();
});

test('both split spellings and historical full prompts remain playable in either language', () => {
  for (const q of [
    make(split), make({statement1:{hu:null,en:'First'}, statement2:{hu:'Második',en:null}}),
    make({statement_1:'First', statement_2:{en:'Second'}}),
    make({statement1:{en:''}, statement_1:'First', statement2:'Second'}),
    {...make({}), question_text_hu:full}, make({question_text:{hu:full}}),
    {...make({statement1:{en:' ',hu:''}, statement2:''}), question_text_en:full},
  ]) {
    expect(type.validate(q).valid).toBe(true);
    expect(accepts(q)).toBe(true);
    expect(gradeableQuestion(q)).toMatchObject({question_type:'relation_analysis', correct_answer:'B'});
    expect(type.checkAnswer(q, ' b ')).toMatchObject({correct:true, score:1});
  }
});

test('stored singleton or JSON keys become one scalar code; submitted values must already be strings', () => {
  for (const key of ['b', ' B ', ['b'], '[" b "]', '"b"']) {
    const q = {...make(split), correct_answer:key};
    expect(type.validate(q).valid).toBe(true);
    expect(gradeableQuestion(q)?.correct_answer).toBe('B');
    expect(type.prepareForClient(q).correct_answer).toBe('B');
    expect(type.checkAnswer(q, 'b')).toMatchObject({correct:true, correctAnswer:'B'});
    for (const user of [['B'], [['B']], {value:'B'}, true, 1, 'Z']) {
      expect(type.checkAnswer(q, user).correct).toBe(false);
    }
  }
  for (const key of [[['B']], [], ['A','B'], {value:'B'}, 'Z']) {
    const q = {...make(split), correct_answer:key};
    expect(gradeableQuestion(q)).toBeNull();
    expect(type.checkAnswer(q,'B')).toMatchObject({correct:false,score:0,correctAnswer:null});
  }
});

test('presentation exposes the ordered bilingual meaning of all five codes without sharing mutable options', () => {
  const q = make(split);
  const student = type.prepareForClient(q).options;
  const admin = type.prepareForAdmin(q).options;
  expect(type.shouldShuffleOptions).toBe(false);
  expect(student.map(({value}) => value)).toEqual(['A','B','C','D','E']);
  for (let i=0; i<student.length; i++) {
    expect(student[i]).toMatchObject({hu:expect.any(String),en:expect.any(String),label:student[i].hu});
    expect(admin[i]).toMatchObject({value:student[i].value, hu:student[i].hu, en:student[i].en});
  }
  student[0].label = 'edited';
  expect(type.prepareForClient(q).options[0].label).not.toBe('edited');
});

test('the content schema published by the type API rejects half a pair while permitting full-prompt mode', () => {
  const metadata = registry.getAllTypes().find(entry => entry.id === 'relation_analysis');
  const acceptsContent = new Ajv().compile(metadata.schema);
  expect(acceptsContent({statement1:'only the first statement'})).toBe(false);
  expect(acceptsContent({statement_1:'First',statement_2:'Second'})).toBe(true);
  expect(acceptsContent({})).toBe(true);
});
