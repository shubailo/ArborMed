const { Client } = require('pg');
const jwt = require('jsonwebtoken');
const { once } = require('node:events');

jest.mock('../../src/config/db', () => ({ query: jest.fn(), pool: { connect: jest.fn() } }));
jest.mock('../../src/services/mailService', () => ({}));
const db = require('../../src/config/db');
const { app } = require('../../server');

(process.env.TEST_DATABASE_URL ? describe : describe.skip)('subject editors over HTTP and PostgreSQL', () => {
    let pg, server, base;
    const previousSecret = process.env.JWT_SECRET;
    beforeAll(async () => {
        process.env.JWT_SECRET = 'admin-integration-fixture';
        pg = new Client({ connectionString: process.env.TEST_DATABASE_URL });
        await pg.connect();
        await pg.query(`
            CREATE TEMP TABLE users(id int primary key, email text, role text, coins int, xp int, level int,
                is_email_verified boolean, email_session_version uuid, assigned_subject_id int, last_activity_at timestamptz);
            CREATE TEMP TABLE topics(id serial primary key, parent_id int, name_en text, name_hu text, slug varchar(100) unique, description text, nexus_metadata jsonb);
            CREATE TEMP TABLE questions(id serial primary key, topic_id int, created_by int, question_text_en text,
                question_text_hu text, explanation_en text, explanation_hu text, options jsonb, correct_answer text,
                type text, question_type text, difficulty int, bloom_level int, content jsonb, metadata jsonb, active boolean DEFAULT true,
                updated_at timestamptz, created_at timestamptz DEFAULT now());
            CREATE TEMP TABLE user_topic_progress(topic_slug text);
            CREATE TEMP TABLE user_question_progress(question_id int);
            ALTER TABLE topics ADD FOREIGN KEY(parent_id) REFERENCES topics(id);
            ALTER TABLE questions ADD FOREIGN KEY(topic_id) REFERENCES topics(id);
            CREATE TEMP TABLE responses(id serial, question_id int, is_correct boolean, user_answer text, user_id int, session_id int);
            CREATE TEMP TABLE quiz_sessions(id int, user_id int);
            CREATE TEMP TABLE user_activity(user_id int);
            CREATE TEMP TABLE password_resets(email text);
            CREATE TEMP TABLE cohort_members(student_id int);
            CREATE TEMP TABLE admin_audit_log(admin_id int REFERENCES users(id), details jsonb);
            CREATE TEMP TABLE question_performance(question_id int, total_attempts int, success_rate numeric);
            CREATE TEMP TABLE question_reports(id serial primary key, question_id int, user_id int, status text, admin_notes text,
                created_at timestamptz DEFAULT now(), updated_at timestamptz);
            SET search_path TO pg_temp;
            INSERT INTO topics(id,parent_id,name_en) VALUES (1,NULL,'Core'),(2,1,'Core section'),(3,2,'Core subsection'),
                (4,NULL,'Other'),(5,4,'Other section');
            ALTER SEQUENCE topics_id_seq RESTART WITH 10;
            INSERT INTO users(id,email,role,assigned_subject_id) VALUES
                (11,'editor@example.org','admin',1),(12,'manager@example.org','admin',NULL),
                (13,'other@example.org','admin',4),(14,'student@example.org','student',NULL);
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
        if (previousSecret === undefined) delete process.env.JWT_SECRET; else process.env.JWT_SECRET = previousSecret;
    });
    const call = (id, path, method = 'GET', body) => fetch(base + path, {
        method, headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + jwt.sign({ id }, process.env.JWT_SECRET) },
        body: body ? JSON.stringify(body) : undefined,
    });
    const question = topic_id => ({ topic_id, question_type: 'single_choice', question_text_en: 'Question?',
        options_en: ['A','B'], correct_answer: 'A' });
    const path = '/quiz/admin/questions';
    test('the question bank filters nested topics by Bloom level and returns editor data and numeric metrics', async () => {
        const { rows: [q] } = await pg.query(`INSERT INTO questions
            (created_by,topic_id,bloom_level,difficulty,question_type,type,question_text_en,question_text_hu,content)
            VALUES (11,3,4,1,'single_choice','single_choice','Bank specimen','Szív & ér','{"image_url":"sample.png"}') RETURNING id`);
        await pg.query('INSERT INTO question_performance VALUES ($1,4,75.5)', [q.id]);
        for (const query of ['topic_id=1&bloom_level=4', 'search=' + encodeURIComponent('Szív & ér'),
            'search=' + encodeURIComponent('#' + q.id)]) {
            const response = await call(11, path + '?' + query);
            expect(response.status).toBe(200);
            expect((await response.json()).questions).toContainEqual(expect.objectContaining({
                id:q.id, attempts:4, success_rate:75.5, content:{image_url:'sample.png'}
            }));
        }
        expect((await (await call(11, path + '?search=' + encodeURIComponent('%_'))).json()).questions).toEqual([]);
    });
    test('a legacy case study can be listed alongside registered question formats', async () => {
        const { rows: [q] } = await pg.query(`INSERT INTO questions(created_by,topic_id,question_type,type,question_text_en)
            VALUES (11,1,'case_study','case_study','Legacy case') RETURNING id`);
        const response = await call(11, path + '?type=case_study');
        expect(response.status).toBe(200);
        expect((await response.json()).questions.map(row => row.id)).toContain(q.id);
    });
    test('creates and edits in assigned descendants, enforcing old and new subject on edits and bulk moves', async () => {
        const create = await call(11, path, 'POST', question(3));
        expect(create.status).toBe(201);
        const { id } = await create.json();
        const edit = await call(11, path + '/' + id, 'PUT', { ...question(2), question_type: 'multiple_choice', correct_answer: ['A'] });
        expect(edit.status).toBe(200);
        expect(await edit.json()).toMatchObject({ question_type: 'multiple_choice', type: 'multiple_choice', topic_id: 2 });
        expect((await call(11, path, 'POST', question(5))).status).toBe(403);
        expect((await call(11, path + '/' + id, 'PUT', question(5))).status).toBe(403);
        expect((await call(11, path + '/bulk', 'POST', { action: 'move', ids: [id], targetTopicId: 5 })).status).toBe(403);
        const other = await (await call(13, path, 'POST', question(5))).json();
        expect((await call(11, path + '/' + other.id)).status).toBe(404);
        expect((await call(11, path + '/bulk', 'POST', { action: 'delete', ids: [id, other.id] })).status).toBe(403);
        expect((await pg.query('SELECT topic_id FROM questions WHERE id = $1', [id])).rows[0].topic_id).toBe(2);
        expect((await call(11, path + '/' + id, 'DELETE')).status).toBe(200);
    });
    test('list, reports, hierarchy changes and CSV imports honor the assigned subject', async () => {
        const local = await (await call(11, path, 'POST', question(3))).json();
        const other = await (await call(13, path, 'POST', question(5))).json();
        const list = await (await call(11, path)).json();
        expect(list.questions.map(q => q.id)).toContain(local.id);
        expect(list.questions.map(q => q.id)).not.toContain(other.id);
        const report = (await pg.query(
            "INSERT INTO question_reports(question_id,user_id,status,admin_notes) VALUES ($1,14,'pending','Under review') RETURNING id", [other.id]
        )).rows[0];
        expect(await (await call(11, '/reports/question/' + other.id)).json()).toEqual([]);
        expect((await call(11, '/reports/' + report.id, 'PATCH', { status: 'resolved' })).status).toBe(404);
        const visible = await (await call(13, '/reports/question/' + other.id)).json();
        expect(visible).toEqual([expect.objectContaining({ id: report.id, status: 'pending' })]);
        const resolved = await (await call(13, '/reports/' + report.id, 'PATCH', { status: 'resolved' })).json();
        expect(resolved).toMatchObject({ id: report.id, status: 'resolved', admin_notes: 'Under review' });
        const topic = await call(11, '/quiz/admin/topics', 'POST', { name_en: 'New section', slug: 'new-section', parent_id: 1 });
        expect(topic.status).toBe(201);
        expect((await call(11, '/quiz/admin/topics/5', 'PUT', { name_en: 'Moved', slug: 'moved', parent_id: 1 })).status).toBe(403);
        const csv = 'en,hu,topic,bloom,type,correct,en_options\nQuestion?,,Core section,1,single_choice,A,A;B';
        const upload = content => {
            const form = new FormData();
            form.append('file', new Blob([content], { type: 'text/csv' }), 'questions.csv');
            return fetch(base + path + '/batch', { method: 'POST', body: form,
                headers: { Authorization: 'Bearer ' + jwt.sign({ id: 11 }, process.env.JWT_SECRET) } });
        };
        expect((await upload(csv)).status).toBe(200);
        expect((await upload(csv.replace('Core section', 'Other section'))).status).toBe(403);
    });
    test('batch import gives actionable file and form validation responses before parsing', async () => {
        const uploadForm = form => fetch(base + path+'/batch', {method:'POST',body:form,
            headers:{Authorization:'Bearer '+jwt.sign({id:11},process.env.JWT_SECRET)}});
        const wrongForm = new FormData();
        wrongForm.append('note','Draft list');
        expect((await uploadForm(wrongForm)).status).toBe(400);
        const workbook = new FormData();
        workbook.append('file',new Blob([new Uint8Array(5*1024*1024+1)]),'sample.csv');
        expect((await uploadForm(workbook)).status).toBe(413);
    });
    const topics = '/quiz/admin/topics';
    test('the dialog creates a named section without a slug and renames it without relocating it', async () => {
        const form = { name_en:'  Élettan  ', name_hu:'Élettan', parent_id:2 };
        const created = await call(11, topics, 'POST', form);
        expect(created.status).toBe(201);
        const row = await created.json();
        expect(row).toMatchObject({name_en:'Élettan', slug:'2-elettan', parent_id:2});
        await pg.query('UPDATE topics SET description=$1 WHERE id=$2',['Keep this',row.id]);
        const edit = await call(11, topics+'/'+row.id, 'PUT', {name_en:'Physiology', name_hu:'Tan'});
        expect(edit.status).toBe(200);
        expect(await edit.json()).toMatchObject({slug:row.slug, parent_id:2, description:'Keep this',name_en:'Physiology'});
        expect((await call(11, topics,'POST',form)).status).toBe(409);
        expect((await call(13, topics,'POST',{...form,parent_id:5})).status).toBe(201);
    });
    test('topic validation distinguishes malformed input, missing parents and unavailable destinations', async () => {
        expect((await call(12, topics+'/abc','PUT',{name_en:'New'})).status).toBe(400);
        for (const form of [{name_en:' '}, {name_en:'A'.repeat(101)}, {name_en:42}, {name_en:'Leaf',parent_id:0}]) {
            expect((await call(12,topics,'POST',form)).status).toBe(400);
        }
        expect((await call(12,topics,'POST',{name_en:'Leaf',parent_id:99999})).status).toBe(404);
        expect((await call(12,topics+'/2','PUT',{parent_id:3})).status).toBe(400);
        expect((await call(11,topics+'/2','PUT',{parent_id:4})).status).toBe(403);
        const cleared = await call(12,topics+'/3','PUT',{description:null,name_hu:null});
        expect(cleared.status).toBe(200);
        expect(await cleared.json()).toMatchObject({description:null,name_hu:'',parent_id:2});
    });
    test('an authenticated student catalog counts active questions through every level', async () => {
        const root = (await pg.query("INSERT INTO topics(name_en,slug) VALUES('Counts','counts') RETURNING id")).rows[0].id;
        const child = (await pg.query('INSERT INTO topics(parent_id) VALUES($1) RETURNING id',[root])).rows[0].id;
        const leaf = (await pg.query('INSERT INTO topics(parent_id) VALUES($1) RETURNING id',[child])).rows[0].id;
        await pg.query('INSERT INTO questions(topic_id,active,created_by) VALUES ($1,true,12),($2,true,12),($3,true,12),($3,false,12)',[root,child,leaf]);
        const res = await call(14,'/quiz/topics');
        expect(res.status).toBe(200);
        const rows = await res.json();
        expect([root,child,leaf].map(id => Number(rows.find(r => r.id===id).question_count))).toEqual([3,2,1]);
        expect((await call(14,topics,'POST',{name_en:'Read only'})).status).toBe(403);
    });
    test('deletion confirms the exact current set of questions and keeps the parent', async () => {
        const leaf = (await pg.query("INSERT INTO topics(parent_id,slug) VALUES(2,'delete-confirm') RETURNING id")).rows[0].id;
        const path = topics+'/'+leaf;
        const add = () => pg.query('INSERT INTO questions(topic_id,created_by) VALUES($1,12) RETURNING id',[leaf]);
        const first = (await add()).rows[0].id;
        const preview = await call(11,path,'DELETE');
        expect(preview.status).toBe(409);
        const ask = await preview.json();
        expect(ask).toMatchObject({code:'topic_questions_confirmation',count:1});
        await pg.query('DELETE FROM questions WHERE id=$1',[first]); await add();
        const confirmed = token => call(11,path+'?force=true&confirmation='+token,'DELETE');
        const changed = await confirmed(ask.confirmation);
        expect(changed.status).toBe(409);
        const again = await changed.json();
        expect(again.confirmation).not.toBe(ask.confirmation);
        expect((await confirmed(again.confirmation)).status).toBe(200);
        expect((await pg.query('SELECT FROM questions WHERE topic_id=$1',[leaf])).rowCount).toBe(0);
        expect((await pg.query('SELECT FROM topics WHERE id=2')).rowCount).toBe(1);
    });
    test('topic deletion protects assigned subjects, children, responses and spaced repetition history', async () => {
        expect((await call(12,topics+'/2','DELETE')).status).toBe(409);
        const {rows:[leaf]}=await pg.query("INSERT INTO topics(parent_id,slug) VALUES(2,'retained') RETURNING id");
        const path = topics+'/'+leaf.id;
        await pg.query('UPDATE users SET assigned_subject_id=$1 WHERE id=13',[leaf.id]);
        try {expect((await call(12,path,'DELETE')).status).toBe(409);}
        finally {await pg.query('UPDATE users SET assigned_subject_id=4 WHERE id=13');}
        const {rows:[q]}=await pg.query('INSERT INTO questions(topic_id,created_by) VALUES($1,12) RETURNING id',[leaf.id]);
        const {confirmation}=await (await call(12,path,'DELETE')).json();
        await pg.query('INSERT INTO responses(question_id) VALUES($1)',[q.id]);
        const confirmed = () => call(12,path+'?force=true&confirmation='+confirmation,'DELETE');
        expect((await confirmed()).status).toBe(409);
        await pg.query('DELETE FROM responses WHERE question_id=$1',[q.id]);
        await pg.query('INSERT INTO user_question_progress VALUES($1)',[q.id]);
        expect((await confirmed()).status).toBe(409);
        expect((await pg.query('SELECT FROM questions WHERE id=$1',[q.id])).rowCount).toBe(1);
    });
    test('external prerequisite links retain a section for both historical text and numeric IDs', async () => {
        const {rows:[leaf]} = await pg.query("INSERT INTO topics(parent_id,slug) VALUES(2,'prerequisite') RETURNING id");
        const {rows:[q]} = await pg.query('INSERT INTO questions(topic_id,created_by) VALUES($1,11) RETURNING id',[leaf.id]);
        const {rows:[ref]} = await pg.query('INSERT INTO questions(topic_id,created_by) VALUES(1,11) RETURNING id');
        for (const id of [q.id, ' 00'+q.id+' ']) {
            await pg.query('UPDATE questions SET metadata=$1 WHERE id=$2',[{prerequisite_ids:[id]},ref.id]);
            const response = await call(11,topics+'/'+leaf.id,'DELETE');
            expect(response.status).toBe(409);
            expect(await response.json()).toMatchObject({message:expect.stringMatching(/prerequisite/)});
        }
        await pg.query('UPDATE questions SET metadata=NULL WHERE id=$1',[ref.id]);
        const response = await call(11,topics+'/'+leaf.id,'DELETE');
        expect(await response.json()).toMatchObject({code:'topic_questions_confirmation'});
    });
    test('existing progress and Nexus links retain their topic identity across edits and deletes', async () => {
        const {rows:[row]}=await pg.query("INSERT INTO topics(slug) VALUES('tracked') RETURNING id");
        const path=topics+'/'+row.id;
        await pg.query("INSERT INTO user_topic_progress VALUES('tracked')");
        expect((await call(12,path,'PUT',{slug:'replacement'})).status).toBe(409);
        await pg.query("DELETE FROM user_topic_progress WHERE topic_slug='tracked'");
        await pg.query('UPDATE topics SET nexus_metadata=$1 WHERE id=5',[{nexus_links:[{topic_slug:'tracked'}]}]);
        expect((await call(12,path,'DELETE')).status).toBe(409);
        await pg.query('UPDATE topics SET nexus_metadata=NULL WHERE id=5');
        expect((await call(12,path,'PUT',{slug:'replacement'})).status).toBe(200);
        expect((await call(12,path,'DELETE')).status).toBe(200);
    });
    test('account removal works with the documented historical reset table and retains authored content', async () => {
        await pg.query(`INSERT INTO users(id,email,role) VALUES (15,'retired@example.org','student');
            INSERT INTO password_resets(email) VALUES ('retired@example.org');
            INSERT INTO questions(topic_id,created_by) VALUES (1,15);
            INSERT INTO admin_audit_log(admin_id) VALUES (15)`);
        const result = await call(12, '/admin/users/15', 'DELETE');
        expect(result.status).toBe(200);
        expect((await pg.query('SELECT FROM users WHERE id=15')).rowCount).toBe(0);
        expect((await pg.query('SELECT FROM password_resets')).rowCount).toBe(0);
        expect((await pg.query('SELECT FROM questions WHERE created_by IS NULL')).rowCount).toBe(1);
        expect((await pg.query('SELECT details FROM admin_audit_log')).rows[0].details.deleted_admin_id).toBe(15);
    });
    test('delegating a role cannot broaden the subject of the acting administrator', async () => {
        const grant = await call(11, '/admin/user-role', 'PUT', { userId: 14, newRole: 'admin' });
        expect(grant.status).toBe(200);
        const row = await pg.query('SELECT role, assigned_subject_id FROM users WHERE id=14');
        expect(row.rows[0]).toMatchObject({ role: 'admin', assigned_subject_id: 1 });
        expect((await call(11, '/admin/user-role', 'PUT', { userId: 13, newRole: 'student' })).status).toBe(403);
        expect((await call(11, '/admin/users/13', 'DELETE')).status).toBe(403);
    });
});
