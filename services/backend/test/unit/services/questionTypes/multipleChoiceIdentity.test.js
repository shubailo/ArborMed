const registry = require('../../../../src/services/questionTypes/registry');
const gradeableQuestion = require('../../../../src/services/questionTypes/gradeableQuestion');

const type = 'multiple_choice';
const handler = registry.getType(type);
const question = (options, correct_answer) => ({ question_type: type, content: { options }, correct_answer });

test('authoring, the practice selector and direct grading reject duplicate option identities', () => {
  const duplicate = question([{ id: 'a', text: 'First' }, { id: 'a', text: 'Second' }], ['First']);
  expect(handler.validate(duplicate).valid).toBe(false);
  expect(gradeableQuestion(duplicate)).toBeNull();
  expect(handler.checkAnswer(duplicate, ['Second']).correct).toBe(false);
});

test('a translated key resolves to one distinct option per selection', () => {
  const q = question({ en: ['First', 'Second'], hu: ['Első', 'Második'] }, ['Második']);
  const second = handler.prepareForClient(q).choice_options[1].id;
  expect(handler.validate(q).valid).toBe(true);
  expect(handler.validate({ ...q, correct_answer: [second] }).valid).toBe(true);
  expect(handler.checkAnswer(q, [second]).correct).toBe(true);
  expect(handler.validate({ ...q, correct_answer: ['Második', 'Second'] }).valid).toBe(false);
});

test('authoring IDs survive preparation when two choices share a display label', () => {
  const q = question([{ id: 'a', en: 'Same', hu: 'Első' }, { id: 'b', en: 'Same', hu: 'Második' }], ['b']);
  const [first, second] = handler.prepareForClient(q).choice_options;
  expect(handler.validate(q).valid).toBe(true);
  const prepared = gradeableQuestion(q);
  expect(prepared.correct_answer).toEqual([second.id]);
  expect(handler.checkAnswer(prepared, [second.id]).correct).toBe(true);
  expect(handler.checkAnswer(prepared, [first.id]).correct).toBe(false);
  expect(gradeableQuestion({ ...q, correct_answer: ['Same'] })).toBeNull();
});

test('legacy key repair preserves option identity across translated comma-separated labels', () => {
  const q = question([{ id: 'a', en: 'Same', hu: 'másik' }, { id: 'b', en: 'Same', hu: 'második, elem' }], ['második', 'elem']);
  const [first, second] = handler.prepareForClient(q).choice_options;
  const prepared = gradeableQuestion(q);
  expect(handler.checkAnswer(prepared, [first.id]).correct).toBe(false);
  expect(handler.checkAnswer(prepared, [second.id]).correct).toBe(true);
});

test('a trailing separator cannot complete a partial historical key', () => {
  expect(gradeableQuestion(question(['First', 'Second'], ['First', '']))).toBeNull();
});

test('an author ID shadowed by another visible label requires an explicit stable key', () => {
  const q = question([{ id: 'old', en: 'First' }, { id: 'next', en: 'old' }], ['old']);
  expect(handler.validate(q).valid).toBe(false);
  expect(gradeableQuestion(q)).toBeNull();
  const second = handler.prepareForClient(q).choice_options[1].id;
  expect(handler.validate({ ...q, correct_answer: [second] }).valid).toBe(true);
});
