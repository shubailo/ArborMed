const fs = require('node:fs');
const ecg = require('../../../src/controllers/ecgController');
const db = require('../../../src/config/db');

jest.mock('../../../src/config/db', () => ({query: jest.fn()}));

const fixture = {
  diagnoses: [{code:'D1', name_en:'First'}, {code:'D2', name_en:'Second'}],
  cases: [
    {case_number:13, difficulty:'advanced', diagnosis_code:'D2', image_url:'/fixture/13',
      findings_json:{history:'history', rhythm:'hidden'}, secondary_diagnoses_ids:[1]},
    {case_number:14, difficulty:'beginner', diagnosis_code:'D1', image_url:'/fixture/14', findings_json:{}},
  ],
};

let req, res, next, failure;

beforeEach(() => {
  jest.replaceProperty(process, 'env', {...process.env, NODE_ENV:'development'});
  jest.spyOn(fs, 'existsSync').mockReturnValue(true);
  // Mock only case-data reads so unrelated module loading keeps working.
  const read = fs.readFileSync.bind(fs);
  jest.spyOn(fs, 'readFileSync').mockImplementation((filename, ...args) =>
    String(filename).endsWith('ecg_cases.json') ? JSON.stringify(fixture) : read(filename, ...args));
  jest.spyOn(fs.promises, 'readFile').mockResolvedValue(JSON.stringify(fixture));
  failure = new Error('test database unavailable');
  db.query.mockReset().mockRejectedValue(failure);
  req = {query:{difficulty:'advanced'}, params:{id:13}, user:{role:'student'}, body:{}};
  res = {json:jest.fn()};
  next = jest.fn();
});

afterEach(() => jest.restoreAllMocks());

test('development fixtures retain diagnosis identifiers, difficulty filters and the pre-answer view', async () => {
  await ecg.getDiagnoses(req, res, next);
  expect(res.json).toHaveBeenLastCalledWith([{id:1,...fixture.diagnoses[0]}, {id:2,...fixture.diagnoses[1]}]);
  const preview = {id:13, difficulty:'advanced', image_url:'/fixture/13', findings_json:{history:'history'}};
  await ecg.getCases(req, res, next);
  expect(res.json).toHaveBeenLastCalledWith([preview]);
  await ecg.getCaseById(req, res, next);
  expect(res.json).toHaveBeenLastCalledWith(preview);
  req.body = {diagnosisId:2, secondaryDiagnosisIds:[1]};
  await ecg.submitInterpretation(req, res, next);
  expect(res.json).toHaveBeenLastCalledWith({
    primaryCorrect:true, secondaryCorrect:true,
    case:{...fixture.cases[0],id:13,diagnosis_id:2},
  });
});

test('a missing fixture case returns 404 without a grading result', async () => {
  req.params.id = 1000;
  req.body = {diagnosisId:1};
  await ecg.submitInterpretation(req, res, next);
  expect(next).toHaveBeenLastCalledWith(expect.objectContaining({statusCode:404}));
  expect(res.json).not.toHaveBeenCalled();
});

test('outside development, a database error is propagated without reading local case data', async () => {
  process.env.NODE_ENV = 'test';
  for (const handler of [ecg.getDiagnoses, ecg.getCases, ecg.getCaseById]) {
    await handler(req, res, next);
    expect(next).toHaveBeenLastCalledWith(failure);
  }
  expect(fs.promises.readFile).not.toHaveBeenCalled();
  expect(res.json).not.toHaveBeenCalled();
});
