const { once } = require('node:events');
const jwt = require('jsonwebtoken');

jest.mock('../../src/config/db', () => ({ query: jest.fn() }));
jest.mock('../../src/services/mailService', () => ({}));
const { app } = require('../../server');
const db = require('../../src/config/db');

describe('readiness and ECG practice over HTTP', () => {
    let server, base;
    const originalSecret = process.env.JWT_SECRET;
    const fullCase = {
        id: 31, diagnosis_id: 7, secondary_diagnoses_ids: [4, 6],
        diagnosis_code: 'correct-code', diagnosis_name: 'Correct diagnosis',
        description_en: 'Answer explanation', image_url: '/uploads/ecg/case_031.png',
        difficulty: 'intermediate', findings_json: { history: 'Case presentation', rhythm: 'answer key' },
    };
    const presentation = {
        id: 31, image_url: fullCase.image_url, difficulty: fullCase.difficulty,
        findings_json: { history: fullCase.findings_json.history },
    };
    beforeAll(async () => {
        process.env.JWT_SECRET = 'http-integration-fixture';
        server = app.listen(0, '127.0.0.1');
        await once(server, 'listening');
        base = 'http://127.0.0.1:' + server.address().port;
    });
    afterAll(async () => {
        await new Promise(resolve => server.close(resolve));
        if (originalSecret === undefined) delete process.env.JWT_SECRET;
        else process.env.JWT_SECRET = originalSecret;
    });
    beforeEach(() => db.query.mockReset());
    const auth = id => ({ Authorization: 'Bearer ' + jwt.sign({ id }, process.env.JWT_SECRET) });

    test('readiness reports database failures and liveness stays independent', async () => {
        db.query.mockRejectedValueOnce(new Error('database fixture unavailable'))
            .mockResolvedValueOnce({ rows: [{ now: '2030-01-01T00:00:00Z' }] });
        const unavailable = await fetch(base + '/health');
        expect(unavailable.status).toBe(503);
        expect(await unavailable.json()).toMatchObject({ status: 'degraded' });
        const alive = await fetch(base + '/ping');
        expect(alive.status).toBe(200);
        expect(await alive.json()).toMatchObject({ status: 'ok' });
        expect(db.query).toHaveBeenCalledTimes(1);
        const ready = await fetch(base + '/health');
        expect(ready.status).toBe(200);
        expect(await ready.json()).toMatchObject({ status: 'ok' });
    });

    test('student list and detail show presentation, and submission releases the rubric and grades both diagnoses', async () => {
        db.query.mockImplementation(async (sql, params) => {
            if (/\bFROM\s+users\s+WHERE\s+id\b/i.test(sql)) {
                return { rows: [{ id: params[0], role: params[0] === 2 ? 'admin' : 'student' }] };
            }
            return { rows: [fullCase] };
        });
        const headers = auth(1);
        const list = await fetch(base + '/ecg/cases', { headers });
        expect(await list.json()).toEqual([presentation]);
        const detail = await fetch(base + '/ecg/cases/31', { headers });
        expect(await detail.json()).toEqual(presentation);
        const admin = await fetch(base + '/ecg/cases/31', { headers: auth(2) });
        expect(await admin.json()).toMatchObject(fullCase);
        const submit = (diagnosisId, secondaryDiagnosisIds) => fetch(base + '/ecg/cases/31/interpretations', {
            method: 'POST', headers: { ...headers, 'Content-Type': 'application/json' },
            body: JSON.stringify({ diagnosisId, secondaryDiagnosisIds }),
        });
        const malformed = await submit(null, []);
        expect(malformed.status).toBe(400);
        expect(await malformed.json()).not.toHaveProperty('case');
        const correct = await submit(7, [6, 4]);
        expect(await correct.json()).toEqual({ case: fullCase, primaryCorrect: true, secondaryCorrect: true });
        const incorrect = await submit(3, [4]);
        expect(await incorrect.json()).toMatchObject({ primaryCorrect: false, secondaryCorrect: false });
    });

    test('the grading data are absent from the public static uploads path', async () => {
        const result = await fetch(base + '/uploads/ecg/cases_data.json');
        expect(result.status).toBe(404);
    });
});
