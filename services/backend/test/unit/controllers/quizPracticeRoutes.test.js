const quiz = require('../../../src/controllers/quizController');
const db = require('../../../src/config/db');
const engine = require('../../../src/services/pedagogicalEngine');
const translation = require('../../../src/services/translationService');

jest.mock('../../../src/config/db', () => ({query: jest.fn()}));
jest.mock('../../../src/services/pedagogicalEngine', () => ({getChallenge: jest.fn(), resolveResponse: jest.fn()}));
jest.mock('../../../src/services/translationService', () => ({translateText: jest.fn()}));
jest.mock('../../../src/utils/dbHelpers', () => ({
  withTransaction: action => action(require('../../../src/config/db')),
}));

const draft = {id: 5, question_type: 'multiple_choice', options:{en:['red','blue']}, correct_answer:'missing'};
let req, res, next;
beforeEach(() => {
  jest.resetAllMocks();
  req = {params:{id:5}, path:'/questions/5', user:{id:17}, body:{}, query:{}};
  res = {json:jest.fn(), status:jest.fn().mockReturnThis()};
  next = jest.fn();
});

test('creates a session for the authenticated student and returns its persisted identifier', async () => {
  const session = {id: 19, user_id: 17};
  db.query.mockResolvedValue({rows:[session]});
  await quiz.startSession(req, res, next);
  expect(db.query).toHaveBeenCalledWith(expect.stringContaining('INSERT INTO quiz_sessions'), [17]);
  expect(res.status).toHaveBeenCalledWith(201);
  expect(res.json).toHaveBeenCalledWith(session);
});

test('returns the topic catalog and its practice counts', async () => {
  const topics = [{id:2, slug:'renal', question_count:'5'}];
  db.query.mockResolvedValue({rows:topics});
  await quiz.getTopics(req, res, next);
  expect(db.query).toHaveBeenCalledWith(expect.stringContaining('q.active = TRUE'));
  expect(res.json).toHaveBeenCalledWith(topics);
});

test('a missing topic and an exhausted selection have distinct responses', async () => {
  await quiz.getNextQuestion(req, res, next);
  expect(next).toHaveBeenLastCalledWith(expect.objectContaining({statusCode:400}));
  expect(engine.getChallenge).not.toHaveBeenCalled();
  req.query = {topic:'renal', exclude:'1,invalid, 2'};
  engine.getChallenge.mockResolvedValue(null);
  await quiz.getNextQuestion(req, res, next);
  expect(engine.getChallenge).toHaveBeenCalledWith(17, 'renal', [1,2]);
  expect(next).toHaveBeenLastCalledWith(expect.objectContaining({statusCode:404}));
  expect(res.json).not.toHaveBeenCalled();
});

test('malformed keys remain available for an editor and unavailable in mistake review', async () => {
  db.query.mockResolvedValue({rows:[draft]});
  await quiz.getQuestionById(req, res, next);
  expect(next).toHaveBeenLastCalledWith(expect.objectContaining({statusCode:404}));
  expect(res.json).not.toHaveBeenCalled();
  req.path = '/admin/questions/5';
  await quiz.getQuestionById(req, res, next);
  expect(res.json).toHaveBeenCalledWith(draft);
});

test('presents bilingual options for a mistake and reports a deleted question', async () => {
  db.query.mockResolvedValueOnce({rows:[{...draft, correct_answer:['red'], options:{en:['red','blue'],hu:['piros','kék']}}]})
    .mockResolvedValueOnce({rows:[]});
  await quiz.getQuestionById(req, res, next);
  expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
    choice_options: expect.arrayContaining([expect.objectContaining({en:'red',hu:'piros'})]),
  }));
  await quiz.getQuestionById(req, res, next);
  expect(next).toHaveBeenLastCalledWith(expect.objectContaining({statusCode:404}));
});

test.each([
  [[],404],
  [[draft],422],
  [[{...draft, active:false, correct_answer:['red']}],422],
])('rejects an unavailable submission before saving a response or updating progress', async (rows, statusCode) => {
  req.body = {questionId:5, userAnswer:['red']};
  db.query.mockResolvedValueOnce({rows:[{id:17}]}).mockResolvedValueOnce({rows:[]}).mockResolvedValueOnce({rows});
  await quiz.submitAnswer(req, res, next);
  expect(next).toHaveBeenLastCalledWith(expect.objectContaining({statusCode}));
  expect(db.query).toHaveBeenCalledTimes(3);
  expect(engine.resolveResponse).not.toHaveBeenCalled();
  expect(res.json).not.toHaveBeenCalled();
});

test('an incomplete translation request makes no provider call and a complete request returns its result', async () => {
  req.body = {text:'blue', to:'hu'};
  await quiz.translate(req, res, next);
  expect(next).toHaveBeenLastCalledWith(expect.objectContaining({statusCode:400}));
  expect(translation.translateText).not.toHaveBeenCalled();
  req.body.from = 'en';
  translation.translateText.mockResolvedValue('kék');
  await quiz.translate(req, res, next);
  expect(translation.translateText).toHaveBeenCalledWith('blue', 'en', 'hu');
  expect(res.json).toHaveBeenCalledWith({translated:'kék'});
});
