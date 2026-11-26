const MatchingType = require('../../../../src/services/questionTypes/MatchingType');
const gradeableQuestion = require('../../../../src/services/questionTypes/gradeableQuestion');

const matching = new MatchingType();
const pairs = [
  {left:{en:'A', hu:'Bal A'}, right:{en:'X', hu:'Jobb X'}},
  {left:{en:'B', hu:'Bal B'}, right:{en:'Y', hu:'Jobb Y'}},
];
const question = (items = pairs, answer = {A:'X', B:'Y'}) =>
  ({question_type:'matching', content:{pairs:items}, correct_answer:answer});

function expectRejected(q) {
  expect(matching.validate(q).valid).toBe(false);
  expect(gradeableQuestion(q)).toBeNull();
  expect(matching.prepareForClient(q).matching_data).toBeUndefined();
  expect(matching.checkAnswer(q, q.correct_answer).correct).toBe(false);
}

test('malformed localized sides are reported consistently without an exception', () => {
  for (const bad of [null, {left:{en:2},right:{en:'Y'}},
    {left:{en:'B'}, right:{en:'Y', hu:4}}]) {
    expectRejected(question([pairs[0], bad]));
  }
  expectRejected(question('invalid'));
});

test('a stored key cannot award points for pairs different from those displayed', () => {
  expectRejected(question(pairs, {A:'Y',B:'X'}));
  expectRejected(question(pairs, {A:'X'}));
  expectRejected(question(pairs, ['X','Y']));
});

test('each column has distinguishable English and effective Hungarian labels', () => {
  for (const second of [
    {...pairs[1], left:{en:' a ',hu:'másik'}},
    {...pairs[1], right:{en:'Y',hu:' JOBB X '}},
    {...pairs[1], left:{en:'Bal A',hu:' '}},
  ]) {
    expectRejected(question([pairs[0], second]));
  }
});

test('legacy left and right translations remain independent when the English term occurs on both sides', () => {
  const q = {question_type:'matching', options:{en:['A: X','X: Y'], hu:['Bal A: Jobb X','Bal X: Jobb Y']},
    correct_answer:'{"A":"X","X":"Y"}'};
  const client = matching.prepareForClient(q);
  expect(client.matching_data.left).toContainEqual({en:'X',hu:'Bal X'});
  expect(client.matching_data.right).toContainEqual({en:'X',hu:'Jobb X'});
  expect(matching.validate(q).valid).toBe(true);
  expect(matching.checkAnswer(q, {X:'Y',A:'X'}).correct).toBe(true);
});

test('legacy options with unequal lengths cannot attach another term’s translation', () => {
  const q = {question_type:'matching', options:{en:['extra: unused','A: X','B: Y'], hu:['Bal A: Jobb X','Bal B: Jobb Y']},
    correct_answer:{A:'X',B:'Y'}};
  expect(matching.prepareForClient(q).matching_data.right).toEqual(expect.arrayContaining([
    {en:'X', hu:'X'}, {en:'Y', hu:'Y'},
  ]));
  expect(gradeableQuestion(q).correct_answer).toEqual(q.correct_answer);
});

test('unambiguous pairs without a stored key can be displayed and graded, also from historical option lines', () => {
  const q = question([pairs[0], {left:{en:'B',hu:' '},right:{en:'Y'}}], {});
  const legacy = {question_type:'matching', options:JSON.stringify(['A → X','B: Y'])};
  for (const row of [q, legacy]) {
    expect(matching.validate(row).valid).toBe(true);
    const client = matching.prepareForClient(row);
    expect(client.matching_data.left).toContainEqual({en:'B', hu:'B'});
    expect(client.correct_answer).toEqual({A:'X', B:'Y'});
    expect(matching.checkAnswer(row, {A:'X',B:'Y'}).correct).toBe(true);
    expect(matching.checkAnswer(row, {A:'x',B:'Y'}).correct).toBe(false);
    expect(matching.checkAnswer(row, {A:'X',B:'Y',C:'Z'}).correct).toBe(false);
  }
});

test('advertised pair schema rejects empty English text and non-text solution values', () => {
  const accepts = new (require('ajv'))().compile(matching.getSchema());
  expect(accepts(question())).toBe(true);
  expect(accepts(question([{left:{en:'   '},right:{en:'X'}},pairs[1]]))).toBe(false);
  expect(accepts(question(pairs, {A:1,B:'Y'}))).toBe(false);
});
