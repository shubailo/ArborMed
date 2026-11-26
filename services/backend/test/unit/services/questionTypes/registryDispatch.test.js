const registry = require('../../../../src/services/questionTypes/registry');
const gradeableQuestion = require('../../../../src/services/questionTypes/gradeableQuestion');

const base = {options:['A','B'], correct_answer:'B'};

test('explicit unsupported types fail consistently even when a legacy type is present', () => {
  for (const id of ['future_type', '', 0, false, {toString:0}]) {
    const q = {...base, question_type:id, type:'single_choice'};
    expect(registry.validate(id, q).valid).toBe(false);
    expect(gradeableQuestion(q)).toBeNull();
    for (const call of [() => registry.prepareForClient(q), () => registry.prepareForAdmin(q),
        () => registry.checkAnswer(q,'B')]) {
      expect(call).toThrow(expect.objectContaining({statusCode:422}));
    }
  }
});

test('missing types and known aliases select the same renderer and grader', () => {
  for (const fields of [{}, {type:'single_choice'}, {question_type:null,type:'case_study'},
      {question_type:'case_study'}]) {
    const q = {...base,...fields};
    expect(registry.prepareForClient(q).choice_options).toHaveLength(2);
    expect(registry.prepareForAdmin(q).correct_answer).toBe('B');
    expect(registry.checkAnswer(q,'B').correct).toBe(true);
  }
});

test('a JSON-looking submitted label keeps its own identity alongside legacy serialized inputs', () => {
  const q = {...base, question_type:'single_choice', options:['[42]', '42'], correct_answer:'42'};
  expect(registry.checkAnswer(q,'[42]').correct).toBe(false);
  expect(registry.checkAnswer(q,'42').correct).toBe(true);
  const first = gradeableQuestion({...q, correct_answer:'"[42]"'});
  expect(registry.checkAnswer(first,'[42]').correct).toBe(true);
  expect(registry.checkAnswer({...q,question_type:'multiple_choice',options:['A','B'],
    correct_answer:['A','B']},'["A","B"]').correct).toBe(true);
});

test('a label colliding with another authored ID cannot decide a stored key', () => {
  const q = {question_type:'single_choice', options:[{id:'left',en:'A',hu:'Első'},
    {id:'right',en:'B',hu:'left'}], correct_answer:'left'};
  expect(gradeableQuestion(q)).toBeNull();
  const [a,b] = registry.prepareForClient(q).choice_options;
  expect(registry.checkAnswer({...q,correct_answer:a.id},b.id).correct).toBe(false);
  expect(registry.checkAnswer({...q,correct_answer:a.id},a.id).correct).toBe(true);
});

test('a malformed historical identity cannot crash validation', () => {
  const q = {content:{question_text:'Pick one', options:[{id:{toString:0},en:'A'}, 'B']},
    correct_answer:'B'};
  expect(registry.validate('single_choice', q).valid).toBe(false);
});
