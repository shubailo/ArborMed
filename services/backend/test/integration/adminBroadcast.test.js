const { once } = require('node:events');
const { randomUUID } = require('node:crypto');
const { Pool } = require('pg');
const jwt = require('jsonwebtoken');

jest.mock('../../src/config/db', () => ({ query: jest.fn(), pool: { connect: jest.fn() } }));
jest.mock('../../src/services/mailService', () => ({}));
const db = require('../../src/config/db');
const { app } = require('../../server');

(process.env.TEST_DATABASE_URL ? describe : describe.skip)('admin notices and student inboxes', () => {
    const schema = 'notice_' + randomUUID().replaceAll('-', '');
    let pool, server, base;
    const send = (id, path, body) => fetch(base + path, {
        method: body ? 'POST' : 'GET',
        headers: { authorization: 'Bearer ' + jwt.sign({ id }, testSecret), 'content-type': 'application/json' },
        body: body && JSON.stringify(body),
    });
    const originalSecret = process.env.JWT_SECRET;
    const testSecret = 'jwt-fixture-' + require('node:crypto').randomUUID();
    beforeAll(async () => {
        process.env.JWT_SECRET = testSecret;
        pool = new Pool({ connectionString: process.env.TEST_DATABASE_URL, options: '-c search_path=' + schema });
        await pool.query(`CREATE SCHEMA ${schema};
            CREATE TABLE users(id int PRIMARY KEY, email text, username text, role text, assigned_subject_id int,
                coins int, xp int, level int, is_email_verified boolean, email_session_version uuid, last_activity_at timestamptz);
            CREATE TABLE notifications(id serial PRIMARY KEY, user_id int references users, sender_id int references users,
                type text, message text, is_read boolean DEFAULT false, created_at timestamptz DEFAULT now());
            CREATE TABLE admin_audit_log(admin_id int, action text, details jsonb);
            CREATE TABLE consultation_notes(id int, note text, created_at timestamptz, author_id int, target_user_id int);
            INSERT INTO users(id,role,email,username) VALUES (1,'admin','teacher@example.test','Teacher'),
                (2,'student','one@example.test','One'),(3,'student','two@example.test','Two'),
                (4,'student','endre@medbuddy.ai','Bot');`);
        db.query.mockImplementation(pool.query.bind(pool));
        db.pool.connect.mockImplementation(pool.connect.bind(pool));
        server = app.listen(0, '127.0.0.1');
        await once(server, 'listening');
        base = 'http://127.0.0.1:' + server.address().port;
    });
    afterAll(async () => {
        if (originalSecret === undefined) delete process.env.JWT_SECRET;
        else process.env.JWT_SECRET = originalSecret;

        if (server) await new Promise(resolve => server.close(resolve));
        if (pool) { await pool.query('DROP SCHEMA IF EXISTS ' + schema + ' CASCADE'); await pool.end(); }
    });
    const broadcast = '/admin/notify/broadcast';
    test('a retried broadcast is delivered once to each actual student inbox', async () => {
        const body = { title: ' Notice ', message: ' Office hours moved. ', requestId: randomUUID() };
        const replies = await Promise.all([send(1, broadcast, body), send(1, broadcast, body)]);
        expect(replies.map(r => r.status).sort()).toEqual([200, 201]);
        for (const reply of replies) expect(await reply.json()).toMatchObject({ delivered: 2 });
        for (const id of [2, 3]) {
            const inbox = await send(id, '/notifications/inbox');
            expect(await inbox.json()).toEqual([expect.objectContaining({
                message: 'Notice\n\nOffice hours moved.', sender_name: 'Teacher', is_read: false,
            })]);
        }
        for (const id of [1, 4]) expect(await (await send(id, '/notifications/inbox')).json()).toEqual([]);
        expect((await send(1, broadcast, { ...body, title: 'Different' })).status).toBe(409);
    });
    test('validates sender, title, body, and retry key before inserting messages', async () => {
        const body = { title: 'News', message: 'Message', requestId: randomUUID() };
        const before = (await pool.query('SELECT count(*) FROM notifications')).rows;
        expect((await send(2, broadcast, body)).status).toBe(403);
        for (const invalid of [{title:' '}, {message:4}, {requestId:'bad'}, {title:'a'.repeat(121)}, {message:'a'.repeat(4001)}]) {
            expect((await send(1, broadcast, { ...body, ...invalid })).status).toBe(400);
        }
        expect((await pool.query('SELECT count(*) FROM notifications')).rows).toEqual(before);
    });
    test('a direct message to a missing recipient produces a useful error', async () => {
        expect((await send(1, '/admin/notify', {userId:100, message:'Hello'})).status).toBe(404);
        expect((await send(1, '/admin/notify', {userId:2, message:{}})).status).toBe(400);
    });
    test('a failed receipt rolls back delivery, and a retry can complete', async () => {
        const body = {requestId: randomUUID(), title: 'New class', message: 'Monday'};
        const existing = (await pool.query('SELECT count(*) FROM notifications')).rows;
        await pool.query("ALTER TABLE admin_audit_log ADD CONSTRAINT reject_broadcast CHECK (action <> 'broadcast') NOT VALID");
        try {
            expect((await send(1, broadcast, body)).status).toBe(500);
            expect((await pool.query('SELECT count(*) FROM notifications')).rows).toEqual(existing);
        } finally {
            await pool.query('ALTER TABLE admin_audit_log DROP CONSTRAINT reject_broadcast');
        }
        expect((await send(1, broadcast, body)).status).toBe(201);
    });
});
