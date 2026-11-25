const { once } = require('node:events');
const { Client } = require('pg');
const jwt = require('jsonwebtoken');
jest.mock('../../src/config/db', () => ({ query: jest.fn() }));
jest.mock('../../src/services/mailService', () => ({}));
const db = require('../../src/config/db');
const storage = require('../../src/services/uploadStorage');
const { app } = require('../../server');

const postgres = process.env.TEST_DATABASE_URL ? describe : describe.skip;
postgres('quote editor over authenticated HTTP', () => {
    let pg, server, base, token;
    const previousSecret = process.env.JWT_SECRET;
    const call = (path, method = 'GET', body) => fetch(base + '/quiz/' + path, {
        method,
        headers: { authorization: 'Bearer ' + token, 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
    });
    beforeAll(async () => {
        process.env.JWT_SECRET = 'local-test-quote-editor';
        pg = new Client({ connectionString: process.env.TEST_DATABASE_URL });
        await pg.connect();
        await pg.query(`CREATE TEMP TABLE users(id int PRIMARY KEY, role text, email text, assigned_subject_id int,
            is_email_verified boolean, email_session_version uuid, last_activity_at timestamptz,
            coins int, xp int, level int);
            SET search_path TO pg_temp;
            INSERT INTO users VALUES (1, 'admin', 'teacher@example.test', null, true, null, now());
            CREATE TEMP TABLE quotes(id serial PRIMARY KEY, text_en text NOT NULL, text_hu text DEFAULT '',
              author varchar(255) DEFAULT '', title_en varchar(100) DEFAULT 'Study Break',
              title_hu varchar(100) DEFAULT 'Tanulás', icon_name varchar(50) DEFAULT 'menu_book_rounded',
              custom_icon_url text, created_at timestamptz DEFAULT now());`);
        db.query.mockImplementation((sql, values) => pg.query(sql, values));
        server = app.listen(0, '127.0.0.1');
        await once(server, 'listening');
        base = 'http://127.0.0.1:' + server.address().port;
        token = jwt.sign({ id: 1 }, process.env.JWT_SECRET, { expiresIn:'15m' });
    });
    afterAll(async () => {
        if (server) await new Promise(resolve => server.close(resolve));
        if (pg) await pg.end();
        if (previousSecret === undefined) delete process.env.JWT_SECRET;
        else process.env.JWT_SECRET = previousSecret;
    });
    test('create, edit, reload, rotate and delete preserve the title and icon chosen in the editor', async () => {
        const original = { text_en:'Rest', text_hu:'Pihenj', author:'Ada', title_en:'A pause', title_hu:'Szünet',
            icon_name:'custom', custom_icon_url:'/uploads/stored/icons/one.png?scale=1.2&bg=true' };
        const created = await call('admin/quotes','POST',original);
        expect(created.status).toBe(201);
        const quote = await created.json();
        expect(quote).toMatchObject(original);
        const endpoint = 'admin/quotes/' + quote.id;
        const edited = { ...original, title_hu:'Új cím', icon_name:'random', custom_icon_url:'random_gallery' };
        expect(await (await call(endpoint,'PUT',edited)).json()).toMatchObject(edited);
        expect(await (await call('admin/quotes')).json()).toContainEqual(expect.objectContaining(edited));
        const gallery = jest.spyOn(storage, 'randomIcon').mockResolvedValue('/uploads/icons/leaf.png');
        try {
            const studentQuote = await (await call('quote')).json();
            expect(studentQuote).toMatchObject({...edited, icon_name:'custom', custom_icon_url:'/uploads/icons/leaf.png'});
            gallery.mockResolvedValueOnce(null);
            expect(await (await call('quote')).json()).toMatchObject({...edited,icon_name:'menu_book_rounded',custom_icon_url:null});
        } finally { gallery.mockRestore(); }
        const legacy = { text_en:'Legacy edit', text_hu:'', author:'' };
        expect(await (await call(endpoint,'PUT',legacy)).json()).toMatchObject({ ...edited, ...legacy });
        expect(await (await call(endpoint,'PUT',{...legacy, icon_name:'school', custom_icon_url:null})).json())
            .toMatchObject({icon_name:'school',custom_icon_url:null});
        expect((await call(endpoint,'DELETE')).status).toBe(200);
        expect(await (await call('admin/quotes')).json()).toEqual([]);
    });
    test('defaults allow older clients and invalid fields return a client error', async () => {
        const created = await call('admin/quotes','POST',{text_en:'Simple'});
        expect(created.status).toBe(201);
        expect(await created.json()).toMatchObject({title_en:'Study Break',icon_name:'menu_book_rounded'});
        for (const invalid of [{text_en:' '},{text_en:'Hi',title_en:'x'.repeat(101)},{text_en:'Hi',custom_icon_url:[]}]) {
            expect((await call('admin/quotes','POST',invalid)).status).toBe(400);
        }
    });
});
