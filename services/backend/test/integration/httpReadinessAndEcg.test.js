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
            .mockResolvedValueOnce({ rows: [{ now: '2030-01-01T00:00:00Z', ready: false }] })
            .mockResolvedValueOnce({ rows: [{ now: '2030-01-01T00:00:00Z', ready: true }] });
        const unavailable = await fetch(base + '/health');
        expect(unavailable.status).toBe(503);
        expect(await unavailable.json()).toMatchObject({ status: 'degraded' });
        const alive = await fetch(base + '/ping');
        expect(alive.status).toBe(200);
        expect(await alive.json()).toMatchObject({ status: 'ok' });
        expect(db.query).toHaveBeenCalledTimes(1);
        const pending = await fetch(base + '/health');
        expect(pending.status).toBe(503);
        expect(await pending.json()).toMatchObject({ status: 'degraded' });
        const ready = await fetch(base + '/health');
        expect(ready.status).toBe(200);
        expect(await ready.json()).toMatchObject({ status: 'ok' });
    });

    (process.env.TEST_DATABASE_URL ? test : test.skip)('readiness follows the actual migration ledger', async () => {
        const { Client } = require('pg');
        const { baseline, forwardMigrations } = require('../../src/scripts/migrate');
        const pg = new Client({ connectionString: process.env.TEST_DATABASE_URL });
        await pg.connect();
        try {
            await pg.query('CREATE TEMP TABLE arbormed_schema_migrations(filename text PRIMARY KEY, checksum text NOT NULL)');
            db.query.mockImplementation((sql, args) => pg.query(sql, args));
            expect((await fetch(base + '/health')).status).toBe(503);
            const required = [baseline, ...forwardMigrations()];
            const fs = require('node:fs');
            const path = require('node:path');
            const { createHash } = require('node:crypto');
            const checksums = required.map(name => name === baseline ? 'operator-verified' : createHash('sha256')
                .update(fs.readFileSync(path.join(__dirname, '../../migrations', name), 'utf8').replace(/\r\n/g, '\n')).digest('hex'));
            await pg.query('INSERT INTO arbormed_schema_migrations SELECT * FROM unnest($1::text[], $2::text[])',
                [required.slice(0,-1), checksums.slice(0,-1)]);
            expect((await fetch(base + '/health')).status).toBe(503);
            await pg.query('INSERT INTO arbormed_schema_migrations VALUES ($1,$2)', [required.at(-1), 'different-file']);
            expect((await fetch(base + '/health')).status).toBe(503);
            await pg.query('UPDATE arbormed_schema_migrations SET checksum=$2 WHERE filename=$1', [required.at(-1),checksums.at(-1)]);
            await pg.query("INSERT INTO arbormed_schema_migrations VALUES ('999_future.sql','future-release')");
            expect((await fetch(base + '/health')).status).toBe(200);
        } finally { await pg.end(); }
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
