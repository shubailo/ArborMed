const { once } = require('node:events');
const { Client } = require('pg');
const jwt = require('jsonwebtoken');
jest.mock('../../src/config/db', () => ({ query: jest.fn() }));
jest.mock('../../src/services/mailService', () => ({}));
const db = require('../../src/config/db');
const { app } = require('../../server');

const postgres = process.env.TEST_DATABASE_URL ? describe : describe.skip;
postgres('admin directories over authenticated HTTP', () => {
    let pg, server, base;
    const previousSecret = process.env.JWT_SECRET;
    async function get(path, id = 9, claims = {}) {
        const token = jwt.sign({ id, ...claims }, process.env.JWT_SECRET, { expiresIn: '15m' });
        return fetch(base + path, { headers: { authorization: 'Bearer ' + token } });
    }
    beforeAll(async () => {
        process.env.JWT_SECRET = 'admin-directory-test';
        pg = new Client({ connectionString: process.env.TEST_DATABASE_URL });
        await pg.connect();
        await pg.query(`CREATE TEMP TABLE users(id int PRIMARY KEY, email text, role text, assigned_subject_id int,
            coins int, xp int, level int, is_email_verified boolean DEFAULT true, email_session_version uuid,
            last_activity_at timestamptz, last_active_date timestamptz, created_at timestamptz DEFAULT now());
            SET search_path TO pg_temp;
            CREATE TEMP TABLE topics(id int PRIMARY KEY, parent_id int, slug text, name_en text, name_hu text);
            CREATE TEMP TABLE questions(id int PRIMARY KEY, topic_id int, created_by int, active boolean, question_text_en text, bloom_level int);
            CREATE TEMP TABLE responses(id int, user_id int, session_id int, question_id int, is_correct boolean, response_time_ms int,
                created_at timestamptz DEFAULT now());
            CREATE TEMP TABLE quiz_sessions(id int, user_id int);
            INSERT INTO topics VALUES (1,null,'pathology','Pathology','Patológia'), (2,1,'cells','Cells','Sejtek'),
                (3,null,'ecg','ECG','EKG'), (4,2,'microscopy','Microscopy','Mikroszkópia');
            INSERT INTO questions VALUES (10,4,9,true),(11,3,9,true);
            INSERT INTO users(id,email,role) VALUES (1,'one@example.test','student'),(2,'two@example.test','student'),
                (3,'unused@example.test','student'),(9,'admin@example.test','admin');
            UPDATE users SET assigned_subject_id=1 WHERE id=9;
            INSERT INTO quiz_sessions VALUES (11,1);
            INSERT INTO responses VALUES (1,null,11,10,true,200),(2,1,null,11,false,400),(3,2,null,10,false,50);`);
        db.query.mockImplementation((sql, values) => pg.query(sql, values));
        server = app.listen(0, '127.0.0.1');
        await once(server, 'listening');
        base = 'http://127.0.0.1:' + server.address().port;
    });
    afterAll(async () => {
        if (server) await new Promise(resolve => server.close(resolve));
        if (pg) await pg.end();
        if (previousSecret === undefined) delete process.env.JWT_SECRET;
        else process.env.JWT_SECRET = previousSecret;
    });

    test('ordinary browsing records its actor, throttles repeat requests and preserves unknown activity', async () => {
        await pg.query('UPDATE users SET last_activity_at = NULL');
        const since = (await pg.query('SELECT clock_timestamp() AS ts')).rows[0].ts;
        expect((await get('/quiz/question-types', 1)).status).toBe(200);
        expect((await get('/quiz/question-types', 3, { emailVersion: 'obsolete' })).status).toBe(401);
        const list = async () => (await get('/stats/admin/users-performance')).json();
        const first = await list();
        expect(first.users[0].id).toBe(1);
        const ts = first.users[0].last_activity;
        expect(Date.parse(ts)).toBeGreaterThanOrEqual(since.getTime());
        expect(first.users.find(u => u.id === 3).last_activity).toBeNull();
        await get('/quiz/question-types', 1);
        expect((await list()).users[0].last_activity).toBe(ts);
        await pg.query("UPDATE users SET last_activity_at = now() - interval '2 hours' WHERE id=1");
        await get('/quiz/question-types', 1);
        expect(Date.parse((await list()).users[0].last_activity)).toBeGreaterThanOrEqual(Date.parse(ts));
    });

    test('subject scores use their own attempts, and search and sorting run before pagination', async () => {
        const list = q => get('/stats/admin/users-performance?' + q).then(r => r.json());
        const search = await list('search=%23001');
        expect(search).toMatchObject({total:1,users:[{id:1,pathology_avg:100,pathology_total:1,ecg_avg:0,ecg_total:1}]});
        const history = await (await get('/stats/admin/users/1/history')).json();
        expect(history.find(row => row.id === 1)).toMatchObject({subject_slug:'pathology',section_name:'Microscopy'});
        expect((await list('sort=pathology&direction=asc&limit=1')).users[0].id).toBe(2);
        expect((await list('sort=pathology&direction=asc&limit=1&page=2')).users[0].id).toBe(1);
        expect((await list('sort=pathology&direction=asc&limit=1&page=3')).users[0].id).toBe(3);
    });

    test('admin directory exposes actual assignment, authorship and the last authenticated request', async () => {
        expect(await (await get('/admin/admins?search=%23009')).json()).toMatchObject({
            total:1,users:[{id:9, assigned_subject_name:'Pathology',questions_uploaded:2,last_activity:expect.any(String)}]
        });
        expect((await get('/admin/admins', 1)).status).toBe(403);
    });

    test('directory options reject invalid pages and treat search punctuation literally', async () => {
        for (const query of ['page=-1', 'limit=bad', 'sort=unknown', 'direction=unknown']) {
            expect((await get('/stats/admin/users-performance?' + query)).status).toBe(400);
        }
        expect(await (await get('/stats/admin/users-performance?search=%25')).json()).toMatchObject({ total:0, users:[] });
    });
});
