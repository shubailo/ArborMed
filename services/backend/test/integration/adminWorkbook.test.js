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
        expect(book.getWorksheet('Reference').getCell('C1').value).toBe('No Sections');
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
