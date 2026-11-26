const { Client } = require('pg');
const { once } = require('node:events');
const ExcelJS = require('exceljs');
const jwt = require('jsonwebtoken');

jest.mock('../../src/config/db', () => ({ query: jest.fn(), pool: { connect: jest.fn() } }));
jest.mock('../../src/services/mailService', () => ({}));
const db = require('../../src/config/db');
const { app } = require('../../server');

(process.env.TEST_DATABASE_URL ? describe : describe.skip)('administrator workbook and account management', () => {
    let pg, server, base;
    const secret = 'workbook-test';
    const original = [process.env.JWT_SECRET, process.env.SUPER_ADMIN_USER_ID];
    const questions = '/quiz/admin/questions';
    const auth = id => ({ Authorization: 'Bearer ' + jwt.sign({ id }, secret) });
    const request = (path, method = 'GET', body, actor = 10) => fetch(base + path, {
        method, headers: { ...auth(actor), 'Content-Type': 'application/json' },
        body: body === undefined ? undefined : JSON.stringify(body)
    });
    beforeAll(async () => {
        process.env.JWT_SECRET = secret;
        process.env.SUPER_ADMIN_USER_ID = '10';
        pg = new Client({ connectionString: process.env.TEST_DATABASE_URL });
        await pg.connect();
        await pg.query(`
            CREATE TEMP TABLE users(id int primary key, email text, role text, assigned_subject_id int,
                coins int, xp int, level int, is_email_verified boolean, email_session_version uuid, created_at timestamptz, last_activity_at timestamptz);
            CREATE TEMP TABLE topics(id int primary key, parent_id int, name_en text, name_hu text, slug text);
            CREATE TEMP TABLE questions(id serial primary key, topic_id int, created_by int, question_text_en text,
                question_text_hu text, explanation_en text, explanation_hu text, options jsonb, correct_answer text,
                type text, question_type text, difficulty int, bloom_level int, content jsonb, metadata jsonb,
                updated_at timestamptz, created_at timestamptz DEFAULT now());
            CREATE TEMP TABLE responses(id serial, question_id int, is_correct boolean, user_answer text);
            CREATE TEMP TABLE question_performance(question_id int, total_attempts int, success_rate numeric);
            CREATE TEMP TABLE question_reports(question_id int, status text);
            CREATE TEMP TABLE notifications(id serial primary key, user_id int, sender_id int, message text, type text);
            SET search_path TO pg_temp;
            INSERT INTO users(id,email,role,created_at) VALUES (10,'lead@example.org','admin','2026-01-01'),
                (11,'editor@example.org','admin','2026-01-02'),(12,'ana@example.org','student','2026-01-03'),
                (13,'ben@example.org','student','2026-01-04');
            INSERT INTO topics(id,parent_id,name_en) VALUES (1,NULL,'Core Skills'),(2,1,'Basics'),(3,1,'Advanced'),(4,NULL,'Empty');
        `);
        db.query.mockImplementation(pg.query.bind(pg));
        db.pool.connect.mockResolvedValue({ query: db.query, release() {} });
        server = app.listen(0, '127.0.0.1');
        await once(server, 'listening');
        base = 'http://127.0.0.1:' + server.address().port;
    });
    afterAll(async () => {
        if (server) await new Promise(resolve => server.close(resolve));
        if (pg) await pg.end();
        for (const [i, name] of ['JWT_SECRET', 'SUPER_ADMIN_USER_ID'].entries()) {
            if (original[i] === undefined) delete process.env[name];
            else process.env[name] = original[i];
        }
    });
    async function template() {
        const res = await request(questions + '/template');
        expect(res.status).toBe(200);
        expect(res.headers.get('content-disposition')).toContain('QUESTION_TEMPLATE.xlsx');
        const book = new ExcelJS.Workbook();
        await book.xlsx.load(await res.arrayBuffer());
        return book;
    }
    async function upload(book) {
        const form = new FormData();
        form.append('file', new Blob([await book.xlsx.writeBuffer()], {
            type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }), 'questions.xlsx');
        return fetch(base + questions + '/batch', {method: 'POST', headers: auth(10), body: form});
    }
    const listRow = (id, link, language, text, answer, topic = 'Basics') =>
        [id, link, language, 'Core Skills', topic, text, 2, 'single_choice', answer,
            language === 'en' ? 'Blue;Green' : 'Kek;Zold', language + ' explanation'];

    test('published template round-trips both entry sheets and retains bilingual content', async () => {
        const book = await template();
        expect(book.getWorksheet('Reference').getCell('A1').value).toBe('Core Skills');
        expect(book.definedNames.getRanges('SubjectsList').ranges).toEqual(['Reference!$A$1:$A$2']);
        expect(book.definedNames.getRanges('SubjectSections_1').ranges).toEqual(['Reference!$B$1:$B$2']);
        expect(book.definedNames.getRanges('SubjectSections_2').ranges).toEqual(['Reference!$C$1']);
        expect(book.getWorksheet('Reference').getCell('C1').value).toBe('Empty');
        const form = book.getWorksheet('Quick Entry Form');
        expect(form.getCell('B1').value).toBe('ENGLISH CONTENT');
        expect(form.getCell('C1').value).toBe('HUNGARIAN CONTENT');
        for (const [address, value] of Object.entries({
            B3: 'Core Skills', B4: 'Basics', B5: 1, B6: 'single_choice',
            B7: 'Form EN?', C7: 'Form HU?', B9: 'Blue', B10: 'Blue;Green', C10: 'Kek;Zold',
            B12: 'Form EN notes', C12: 'Form HU notes'
        })) form.getCell(address).value = value;
        const list = book.getWorksheet('Questions List');
        list.getRow(2).values = listRow(null, 'group-1', 'en', 'List EN?', 'Blue');
        list.getRow(3).values = listRow(null, 'group-1', 'hu', 'List HU?', null);
        const res = await upload(book);
        expect(res.status).toBe(200);
        expect(await res.json()).toMatchObject({ imported: 2, message: 'Successfully processed 2 questions', errors: null });
        const {rows} = await pg.query('SELECT question_text_en, question_text_hu, options, explanation_hu FROM questions ORDER BY question_text_en');
        expect(rows).toEqual([
            { question_text_en: 'Form EN?', question_text_hu: 'Form HU?', options: {en:['Blue','Green'],hu:['Kek','Zold']}, explanation_hu:'Form HU notes' },
            { question_text_en: 'List EN?', question_text_hu: 'List HU?', options: {en:['Blue','Green'],hu:['Kek','Zold']}, explanation_hu:'hu explanation' }
        ]);
    });

    test('workbook edits update one existing row and report the invalid row in a mixed import', async () => {
        const { rows: [original] } = await pg.query("INSERT INTO questions(topic_id,type,question_type,question_text_en) VALUES (2,'single_choice','single_choice','Original') RETURNING id");
        const book = new ExcelJS.Workbook();
        const list = book.addWorksheet('Questions List');
        list.addRow(['db_id','link_id','language','subject','topic','question_text','bloom_level','type','correct_answer','options','explanation']);
        list.addRow(listRow(original.id, null, 'en', 'Edited EN?', 'Blue', 'Advanced'));
        list.addRow(listRow(original.id, null, 'hu', 'Edited HU?', null, 'Advanced'));
        list.addRow(listRow(null, 'unknown', 'en', 'Unmapped?', 'Blue', 'No such topic'));
        const res = await upload(book);
        expect(res.status).toBe(200);
        expect(await res.json()).toMatchObject({ imported: 1, message: 'Successfully processed 1 questions', errors: [expect.stringMatching(/missing topic/i)] });
        const details = await (await request(questions + '/' + original.id)).json();
        expect(details).toMatchObject({ id: original.id, topic_id: 3, question_text_en: 'Edited EN?', question_text_hu: 'Edited HU?', correct_answer: 'Blue' });
        const page = await (await request(questions + '?search=Edited&type=single_choice&bloom_level=2&topic_id=1&sortBy=id&order=ASC&limit=1')).json();
        expect(page).toMatchObject({ total: 1, page: 1, limit: 1, questions: [{ id: original.id }] });
        expect((await request(questions + '?sortBy=unrecognized')).status).toBe(400);
        expect((await request(questions + '?order=unrecognized')).status).toBe(400);
        expect((await request(questions + '/batch', 'POST')).status).toBe(400);
        expect((await request(questions + '/bulk', 'POST', { action:'move', ids:[original.id], targetTopicId:2 })).status).toBe(200);
        await pg.query("INSERT INTO responses(question_id,is_correct,user_answer) VALUES ($1,false,'Green')", [original.id]);
        expect((await request(questions + '/bulk', 'POST', { action:'delete', ids:[original.id] })).status).toBe(400);
        expect((await request(questions + '/' + original.id, 'DELETE')).status).toBe(400);
        const analytics = await (await request(questions + '/' + original.id + '/analytics')).json();
        expect(analytics.wrongAnswers).toEqual([{answer:'Green',count:1}]);
    });

    async function sendFile(bytes, name = 'input.csv', mime = 'text/csv', actor = 10) {
        const form = new FormData();
        form.append('file', new Blob([bytes], { type: mime }), name);
        return fetch(base + questions + '/batch', { method: 'POST', headers: auth(actor), body: form });
    }
    const flatHeader =
        'db_id,link_id,language,subject,topic,question_text,bloom_level,type,correct_answer,options,explanation';
    function flat(overrides = {}) {
        return {
            db_id: '',
            link_id: '',
            language: 'en',
            subject: 'Core Skills',
            topic: 'Basics',
            question_text: 'Audit record?',
            bloom_level: '2',
            type: 'single_choice',
            correct_answer: 'Blue',
            options: 'Blue;Green',
            explanation: '',
            ...overrides
        };
    }
    const csv = rows =>
        [
            flatHeader,
            ...rows.map(r =>
                Object.values(r)
                    .map(v => '"' + String(v).replaceAll('"', '""') + '"')
                    .join(',')
            )
        ].join('\r\n');

    test('the template and importer resolve duplicate names and deep sections inside the selected subject', async () => {
        await pg.query(
            "INSERT INTO topics(id,parent_id,name_en) VALUES (20,4,'Basics'),(21,20,'Deep'),(22,4,'Other'),(23,22,'Deep')"
        );
        try {
            const book = await template(),
                ref = book.getWorksheet('Reference');
            expect(ref.state).toBe('hidden');
            const labels = ref.getColumn('C').values.filter(Boolean);
            expect(labels).toEqual(expect.arrayContaining(['Basics', 'Basics › Deep', 'Other › Deep']));
            const rows = [
                flat({ subject: 'Empty', topic: 'Basics › Deep', question_text: 'Deep selection' }),
                flat({ subject: 'Core Skills', topic: 'Basics', question_text: 'Scoped selection' }),
                flat({ subject: 'Empty', topic: 'Deep', question_text: 'Ambiguous selection' }),
                flat({ subject: 'Core Skills', topic: '21', question_text: 'Outside selected subject' }),
                flat({ subject: 'Core Skills', topic: '', question_text: 'Root selection' })
            ];
            const response = await sendFile(csv(rows));
            expect(response.status).toBe(200);
            expect(await response.json()).toMatchObject({
                imported: 3,
                errors: [expect.stringContaining('CSV 4'), expect.stringContaining('CSV 5')]
            });
            const saved = await pg.query(
                "SELECT topic_id FROM questions WHERE question_text_en IN ('Deep selection','Scoped selection','Root selection') ORDER BY topic_id"
            );
            expect(saved.rows.map(q => q.topic_id)).toEqual([1, 2, 21]);
        } finally {
            await pg.query('DELETE FROM questions WHERE topic_id>=20; DELETE FROM topics WHERE id>=20');
        }
    });

    test('template labels round-trip when translated subject names and numeric section names collide', async () => {
        await pg.query(
            "INSERT INTO topics(id,parent_id,name_en,name_hu) VALUES (25,NULL,'Cross','Core Skills'),(26,1,'2',NULL)"
        );
        try {
            const book = await template();
            const ref = book.getWorksheet('Reference');
            const subjects = ref.getColumn('A').values.filter(Boolean);
            expect(subjects).toContain('Core Skills [#1]');
            const topic = ref
                .getColumn('B')
                .values.filter(Boolean)
                .find(label => label === '2 [#26]');
            expect(topic).toBeDefined();
            const list = book.getWorksheet('Questions List');
            const values = listRow(null, null, 'en', 'Numeric named section?', 'Blue', topic);
            values[3] = 'Core Skills [#1]';
            list.getRow(2).values = values;
            list.getRow(3).values = values.map((v, i) => (i === 4 ? '2' : v));
            const response = await upload(book);
            expect(await response.json()).toMatchObject({
                imported: 1,
                errors: [expect.stringContaining('Questions List 3')]
            });
            expect(
                (
                    await pg.query(
                        "SELECT topic_id FROM questions WHERE question_text_en='Numeric named section?'"
                    )
                ).rows
            ).toEqual([{ topic_id: 26 }]);
        } finally {
            await pg.query('DELETE FROM questions WHERE topic_id=26; DELETE FROM topics WHERE id IN (25,26)');
        }
    });

    test('CSV with spreadsheet MIME preserves quoted commas, quotes and multiline explanations', async () => {
        const response = await sendFile(
            'en,hu,topic,bloom,type,correct,en_options,hu_options,explanation_en\r\n' +
                '"Pulse, ""resting""?",,Basics,2,single_choice,A,A;B,,"first line\r\nsecond line"',
            'quoted.csv',
            'application/vnd.ms-excel'
        );
        expect(response.status).toBe(200);
        const { rows } = await pg.query('SELECT explanation_en FROM questions WHERE question_text_en=$1', [
            'Pulse, "resting"?'
        ]);
        expect(rows).toEqual([{ explanation_en: 'first line\r\nsecond line' }]);
    });

    test('a one-language edit preserves its counterpart and an edit link identifies one persisted row', async () => {
        const book = await template();
        const list = book.getWorksheet('Questions List');
        list.getRow(2).values = listRow(null, 'new-a', 'en', 'Before language edit', 'Blue');
        const translated = listRow(null, 'new-a', 'hu', 'Eredeti', null);
        translated[9] = 'Kék;Zöld';
        translated[10] = 'Magyarázat';
        list.getRow(3).values = translated;
        expect((await upload(book)).status).toBe(200);
        const id = (await pg.query("SELECT id FROM questions WHERE question_text_en='Before language edit'"))
            .rows[0].id;
        const edit = await template();
        edit.getWorksheet('Questions List').getRow(2).values = listRow(id, null, 'en', 'Revised EN', 'Blue');
        const changed = await upload(edit);
        expect(changed.status).toBe(200);
        expect(
            (
                await pg.query('SELECT question_text_hu,explanation_hu,options FROM questions WHERE id=$1', [
                    id
                ])
            ).rows[0]
        ).toMatchObject({
            question_text_hu: 'Eredeti',
            explanation_hu: 'Magyarázat',
            options: { hu: ['Kék', 'Zöld'] }
        });
        const both = await sendFile(
            csv([
                flat({ db_id: id, link_id: 'edit-a', question_text: 'Linked EN' }),
                flat({
                    link_id: 'edit-a',
                    language: 'hu',
                    question_text: 'Kapcsolt HU',
                    correct_answer: '',
                    options: 'Kék;Zöld'
                })
            ])
        );
        expect(await both.json()).toMatchObject({ imported: 1, errors: null });
        expect(
            (await pg.query('SELECT question_text_en,question_text_hu FROM questions WHERE id=$1', [id]))
                .rows[0]
        ).toEqual({ question_text_en: 'Linked EN', question_text_hu: 'Kapcsolt HU' });
    });

    test('conflicting bilingual groups and invalid Bloom levels report their source without changing valid siblings', async () => {
        const response = await sendFile(
            csv([
                flat({ link_id: 'dup' }),
                flat({ link_id: 'dup', question_text: 'Repeated EN' }),
                flat({ bloom_level: '2-old' }),
                flat({ bloom_level: '5' }),
                flat({ language: 'de' }),
                flat({ link_id: 'key' }),
                flat({ link_id: 'key', language: 'hu', options: 'Kék;Zöld', correct_answer: 'Zöld' }),
                flat({ question_text: 'Kept valid sibling' })
            ])
        );
        expect(response.status).toBe(200);
        const data = await response.json();
        expect(data.imported).toBe(1);
        expect(data.errors).toHaveLength(5);
        expect(data.errors.join(' ')).toContain('CSV 3');
        const generated = await template();
        expect(generated.getWorksheet('Quick Entry Form').getCell('B5').dataValidation.formulae).toEqual([
            '"1,2,3,4"'
        ]);
    });

    test('empty, incorrect or unreadable workbook input receives a client error and zero writes', async () => {
        const count = async () => (await pg.query('SELECT COUNT(*)::int AS n FROM questions')).rows[0].n;
        const before = await count();
        for (const [body, name] of [
            ['en,hu,topic,bloom,type', 'empty.csv'],
            ['ordinary text', 'wrong.xlsx'],
            ['a,b\n1,2', 'bad.csv']
        ]) {
            expect((await sendFile(body, name)).status).toBe(400);
        }
        const ordinaryRow = flat();
        const overRecordLimit = csv(Array(5001).fill(ordinaryRow));
        expect((await sendFile(overRecordLimit)).status).toBe(413);
        const original = await template(),
            ExcelZip = require('jszip');
        const archive = await ExcelZip.loadAsync(await original.xlsx.writeBuffer());
        // Use a small synthetic budget to exercise the stream cap without allocating a large fixture.
        const limits = require('../../src/services/adminExcelService');
        const small = await archive.generateAsync({ type: 'nodebuffer' });
        await expect(limits.checkWorkbook(small, 128)).rejects.toMatchObject({ statusCode: 413 });
        expect(await count()).toBe(before);
    });

    test('worksheet translation edits keep authored choice IDs and reject conflicting form answers', async () => {
        const options = [
            { id: 'stable-blue', en: 'Blue', hu: 'Régi kék' },
            { id: 'stable-green', en: 'Green', hu: 'Régi zöld' }
        ];
        const {
            rows: [q]
        } = await pg.query(
            "INSERT INTO questions(topic_id,type,question_type,question_text_en,options,correct_answer) VALUES (2,'single_choice','single_choice','Structured choices',$1,'Blue') RETURNING id",
            [JSON.stringify(options)]
        );
        const result = await sendFile(
            csv([
                flat({
                    db_id: q.id,
                    language: 'hu',
                    question_text: 'Friss',
                    options: 'Kék;Zöld',
                    correct_answer: 'Kék'
                })
            ])
        );
        expect(await result.json()).toMatchObject({ imported: 1, errors: null });
        expect((await pg.query('SELECT options FROM questions WHERE id=$1', [q.id])).rows[0].options).toEqual(
            [
                { ...options[0], hu: 'Kék' },
                { ...options[1], hu: 'Zöld' }
            ]
        );
        const book = await template(),
            form = book.getWorksheet('Quick Entry Form');
        expect(form.getCell('C4').dataValidation.formulae[0]).toContain('IF(B3="",C3,B3)');
        for (const [addr, v] of Object.entries({
            B3: 'Core Skills',
            B4: 'Basics',
            B7: 'Bad form key?',
            B9: 'Blue',
            C9: 'Zöld',
            B10: 'Blue;Green',
            C10: 'Kék;Zöld'
        }))
            form.getCell(addr).value = v;
        const rejected = await upload(book);
        expect(rejected.status).toBe(400);
        expect(
            (
                await pg.query(
                    "SELECT count(*)::int AS n FROM questions WHERE question_text_en='Bad form key?'"
                )
            ).rows[0].n
        ).toBe(0);
    });

    test('directory filtering, role administration and direct notices use current account roles', async () => {
        const students = await (await request('/admin/students?page=2&limit=1')).json();
        expect(students).toMatchObject({ total:2, page:2, users:[{id:12,email:'ana@example.org'}] });
        expect(await (await request('/admin/students?search=ben')).json()).toMatchObject({ total:1, users:[{id:13}] });
        expect(await (await request('/admin/admins?search=editor')).json()).toMatchObject({ total:1, users:[{id:11}] });
        expect((await request('/admin/students?page=-1')).status).toBe(400);
        expect((await request('/admin/admins?limit=-1')).status).toBe(400);
        expect((await request('/admin/assign-subject', 'PUT', {adminId:11,subjectId:1}, 11)).status).toBe(403);
        expect((await request('/admin/assign-subject', 'PUT', {adminId:11,subjectId:1})).status).toBe(200);
        expect((await request('/admin/assign-subject', 'PUT', {adminId:12,subjectId:1})).status).toBe(404);
        expect((await request('/admin/user-role', 'PUT', {userId:11,newRole:'student'})).status).toBe(200);
        expect((await request('/admin/admins', 'GET', undefined, 11)).status).toBe(403);
        expect((await request('/admin/notify', 'POST', {userId:12,message:'Office hours moved'})).status).toBe(201);
        expect((await pg.query('SELECT user_id,sender_id,type FROM notifications')).rows).toEqual([{user_id:12,sender_id:10,type:'admin_alert'}]);
        expect((await request('/admin/notify', 'POST', {userId:12,message:' '})).status).toBe(400);
        expect((await request('/admin/users/10','DELETE')).status).toBe(400);
        expect((await request('/admin/user-role','PUT',{userId:'n/a',newRole:'student'})).status).toBe(400);
        expect((await request('/admin/user-role','PUT',{userId:100,newRole:'admin'})).status).toBe(404);
    });
});
