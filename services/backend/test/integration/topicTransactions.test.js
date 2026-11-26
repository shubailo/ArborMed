const { randomUUID } = require('node:crypto');
const { Pool } = require('pg');
const topics = require('../../src/controllers/topicController');
const db = require('../../src/config/db');

jest.mock('../../src/config/db', () => ({ pool: { connect: jest.fn() } }));
(process.env.TEST_DATABASE_URL ? describe : describe.skip)('topic write transactions in PostgreSQL', () => {
    const schema = 'topics_' + randomUUID().replaceAll('-', '');
    let pool;
    beforeAll(async () => {
        pool = new Pool({ connectionString: process.env.TEST_DATABASE_URL, options: '-c search_path=' + schema });
        await pool.query('CREATE SCHEMA ' + schema);
        db.pool.connect.mockImplementation(() => pool.connect());
        await pool.query(`
            CREATE TABLE topics (id serial PRIMARY KEY, parent_id int REFERENCES topics(id), name_en varchar(100) NOT NULL,
                name_hu varchar(100), slug varchar(100) UNIQUE NOT NULL, description text, nexus_metadata jsonb);
            CREATE TABLE users (id int PRIMARY KEY, role text, email text, assigned_subject_id int REFERENCES topics(id));
            CREATE TABLE questions (id serial PRIMARY KEY, topic_id int REFERENCES topics(id), metadata jsonb);
            CREATE TABLE responses (question_id int REFERENCES questions(id));
            CREATE TABLE user_question_progress (question_id int REFERENCES questions(id));
            CREATE TABLE user_topic_progress (topic_slug text);
            CREATE TABLE other_reference (topic_id int REFERENCES topics(id));
            INSERT INTO topics(name_en,slug) VALUES ('Root','root');
            INSERT INTO users VALUES (1,'admin','editor@example.org',1);`);
    });
    afterAll(async () => {
        if (pool) {
            try { await pool.query('DROP SCHEMA IF EXISTS ' + schema + ' CASCADE'); }
            finally { await pool.end(); }
        }
    });
    const call = async (handler, req) => {
        const res = {statusCode:200, status(code) { this.statusCode=code; return this; }, json(body) { this.body=body; }};
        await handler({user:{id:1},query:{}, ...req}, res, e => { throw e; });
        return res;
    };

    test('parallel creates commit one row and independent partial edits preserve both fields', async () => {
        const body = {name_en:'Same section',parent_id:1};
        const writes = await Promise.allSettled([call(topics.createTopic,{body}),call(topics.createTopic,{body})]);
        const created = writes.filter(r => r.status === 'fulfilled');
        expect(created).toHaveLength(1);
        expect(writes.find(r => r.status === 'rejected').reason.statusCode).toBe(409);
        const id = created[0].value.body.id;
        await Promise.all([{name_en:'New'}, {description:'Other editor'}].map(change =>
            call(topics.updateTopic,{params:{id},body:change})));
        expect((await pool.query('SELECT * FROM topics WHERE id=$1',[id])).rows[0])
            .toMatchObject({name_en:'New',description:'Other editor',parent_id:1});
    });

    test('a final restrictive foreign key rolls back every confirmed question deletion', async () => {
        const {rows:[leaf]} = await pool.query("INSERT INTO topics(name_en,slug,parent_id) VALUES ('Used','used',1) RETURNING id");
        await pool.query('INSERT INTO questions(topic_id) VALUES($1),($1)',[leaf.id]);
        await pool.query('INSERT INTO other_reference VALUES($1)',[leaf.id]);
        const params = {id:leaf.id};
        const preview = await call(topics.deleteTopic,{params});
        expect(preview.body.count).toBe(2);
        await expect(call(topics.deleteTopic,{params,query:{force:'true',confirmation:preview.body.confirmation}}))
            .rejects.toMatchObject({statusCode:409});
        expect((await pool.query('SELECT FROM questions WHERE topic_id=$1',[leaf.id])).rowCount).toBe(2);
        expect((await pool.query('SELECT FROM topics WHERE id=$1',[leaf.id])).rowCount).toBe(1);
    });
});
