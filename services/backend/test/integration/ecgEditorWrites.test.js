const { once } = require('node:events');
const { Client } = require('pg');
const jwt = require('jsonwebtoken');
jest.mock('../../src/config/db', () => ({ query: jest.fn() }));
jest.mock('../../src/services/mailService', () => ({}));
const db = require('../../src/config/db');
const { app } = require('../../server');

(process.env.TEST_DATABASE_URL ? describe : describe.skip)('ECG editing over HTTP with PostgreSQL', () => {
    let pg, server, root;
    beforeAll(async () => {
        pg = new Client({ connectionString: process.env.TEST_DATABASE_URL });
        await pg.connect();
        await pg.query(`CREATE TEMP TABLE users(id int primary key, email text, role text, coins int, xp int, level int,
            is_email_verified boolean, email_session_version uuid, assigned_subject_id int, last_activity_at timestamptz);
            CREATE TEMP TABLE ecg_diagnoses(id serial PRIMARY KEY, code text UNIQUE NOT NULL, name_en text NOT NULL,
                name_hu text NOT NULL, description_en text, description_hu text, severity_level text, standard_findings_json jsonb);
            CREATE TEMP TABLE ecg_cases(id serial PRIMARY KEY, diagnosis_id int REFERENCES ecg_diagnoses(id), image_url text NOT NULL,
                difficulty text, findings_json jsonb NOT NULL, secondary_diagnoses_ids int[] DEFAULT '{}', created_at timestamptz DEFAULT now());
            INSERT INTO users(id,role) VALUES(1,'admin'),(2,'student');
            INSERT INTO ecg_diagnoses(code,name_en,name_hu) VALUES('D1','First','Első'),('D2','Second','Második');`);
        db.query.mockImplementation((sql, args) => pg.query(sql, args));
        server = app.listen(0, '127.0.0.1');
        await once(server, 'listening');
        root = 'http://127.0.0.1:' + server.address().port + '/ecg';
    });
    afterAll(async () => {
        if (server) await new Promise(resolve => server.close(resolve));
        if (pg) await pg.end();
    });
    const call = (path, method = 'GET', body, id = 1) => fetch(root + path, {
        method, body: body && JSON.stringify(body),
        headers: { authorization: 'Bearer ' + jwt.sign({id}, process.env.JWT_SECRET), 'content-type': 'application/json' },
    });
    const data = {
        diagnosis_id: 1, secondary_diagnoses_ids: [2], difficulty: 'intermediate', image_url: '/uploads/example.png',
        findings_json: { history: 'Synthetic case', rate: {target: 70, min: 65, max: 75}, extra: { text: 'Retained' } },
    };
    test('create, edit, list, reopen and delete the same case, preserving its grading data', async () => {
        expect((await call('/cases', 'POST', data, 2)).status).toBe(403);
        const response = await call('/cases', 'POST', data);
        expect(response.status).toBe(201);
        const created = await response.json();
        const path = '/cases/' + created.id;
        try {
            const changes = {...data, difficulty:'advanced', findings_json:{...data.findings_json, history:'Changed'}};
            expect((await call(path, 'PUT', changes)).status).toBe(200);
            expect(await (await call(path)).json()).toMatchObject(changes);
            expect(await (await call('/cases?difficulty=advanced')).json()).toContainEqual(expect.objectContaining({...changes, diagnosis_code:'D1'}));
        } finally { expect((await call(path, 'DELETE')).status).toBe(200); }
        expect((await call(path)).status).toBe(404);
    });
    test('bad or missing diagnosis IDs cannot create unlistable or inconsistent cases', async () => {
        for (const invalid of [
            { diagnosis_id: null }, { diagnosis_id: 999999 }, { secondary_diagnoses_ids: [999999] },
            { secondary_diagnoses_ids: [1] }, { secondary_diagnoses_ids: [2,2] },
            { findings_json: [] }, { image_url: '  ' },
        ]) {
            const res = await call('/cases','POST',{...data,...invalid});
            expect({status:res.status, invalid}).toEqual({status:400, invalid});
        }
        expect((await pg.query('SELECT 1 FROM ecg_cases')).rowCount).toBe(0);
    });
    test('an update from a client without the secondary field preserves existing selections', async () => {
        const created = await (await call('/cases', 'POST', data)).json();
        const {secondary_diagnoses_ids: expected, ...legacy} = data;
        const path = '/cases/' + created.id;
        try {
            expect((await call(path, 'PUT', {...legacy, difficulty:'advanced'})).status).toBe(200);
            expect((await (await call(path)).json()).secondary_diagnoses_ids).toEqual(expected);
            expect((await call(path,'PUT',{...data, diagnosis_id:2})).status).toBe(400);
            expect((await (await call(path)).json()).diagnosis_id).toBe(1);
        } finally { await call(path, 'DELETE'); }
    });
});
