const { Client } = require('pg');
const db = require('../../src/config/db');
const stats = require('../../src/controllers/statsController');

jest.mock('../../src/config/db', () => ({ query: jest.fn() }));

const postgres = process.env.TEST_DATABASE_URL ? describe : describe.skip;
postgres('study statistics from recorded answers', () => {
    let pg;
    beforeAll(async () => {
        pg = new Client({ connectionString: process.env.TEST_DATABASE_URL });
        await pg.connect();
        await pg.query(`
            CREATE TEMP TABLE topics (id int PRIMARY KEY, parent_id int, slug text, name_en text, name_hu text);
            CREATE TEMP TABLE questions (id int PRIMARY KEY, topic_id int, question_text_en text, bloom_level int, difficulty int);
            CREATE TEMP TABLE quiz_sessions (id int, user_id int, started_at timestamp, completed_at timestamp);
            CREATE TEMP TABLE users (id int, email text, role text, last_activity_at timestamptz, created_at timestamp default now());
            INSERT INTO users(id,email,role) VALUES (1,'student-one@example.test','student'), (2,'another@example.test','student');
            CREATE TEMP TABLE responses (id int, user_id int, question_id int, session_id int,
                response_time_ms int, is_correct boolean, created_at timestamp default now());
            CREATE TEMP TABLE user_topic_progress (user_id int, topic_slug text, current_bloom_level int,
                mastery_score float, total_answered int, last_studied_at timestamp);
            INSERT INTO topics VALUES (1, null, 'pathophysiology', 'Subject', 'Tárgy'), (2, 1, 'section', 'Section', 'Téma');
            INSERT INTO questions VALUES (3, 2, 'Practice question', 2, 1);
            INSERT INTO quiz_sessions VALUES (10, 1, now()-interval '10 minutes', null), (11, 2, now()-interval '20 minutes', now());
            INSERT INTO responses (id,user_id,question_id,session_id,response_time_ms) VALUES
                (1,null,3,10,200), (2,1,3,10,100), (3,1,3,null,300), (4,2,3,11,900);
            UPDATE responses SET is_correct = id=1;
            UPDATE responses SET created_at=now()-interval '2 days' WHERE id=1;
            INSERT INTO user_topic_progress VALUES (1,'section',2,75,3,now()-interval '10 days');
            ALTER TABLE user_topic_progress ADD COLUMN correct_answered int default 1,
                ADD COLUMN stability float default 1, ADD COLUMN retention_score float default 0;
        `);
        db.query.mockImplementation((sql, args) => pg.query(sql, args));
    });
    afterAll(async () => { await pg.end(); });

    test('counts distinct recorded sessions and includes offline answers in subject timing', async () => {
        const res = { json: jest.fn() };
        await stats.getSubjectDetail({ user: { id: 1 }, params: { subjectSlug: 'pathophysiology' } }, res, e => { throw e; });
        expect(res.json).toHaveBeenCalledWith([expect.objectContaining({ attempts: 3, sessions_count: 1, avg_time_ms: 200 })]);
    });

    test('history includes both legacy sessions and independently synchronized answers', async () => {
        const res = { json: jest.fn() };
        await stats.getUserHistory({ params: { userId: 1 }, query: {} }, res, e => { throw e; });
        expect(res.json.mock.calls[0][0].map(row => row.id).sort()).toEqual([1, 2, 3]);
    });

    async function read(handler, req = {}) {
        const res = { json: jest.fn() };
        await handler({ user: { id: 1 }, query: {}, params: {}, ...req }, res, e => { throw e; });
        return res.json.mock.calls[0][0];
    }

    test('student summary, smart review and instructor analytics agree for the same learner', async () => {
        expect(await read(stats.getSummary)).toEqual([expect.objectContaining({ total_answered: 3, correct_answered: 1, mastery_percent: 75 })]);
        const readiness = await read(stats.getReadiness);
        const review = await read(stats.getSmartReview);
        expect(readiness).toMatchObject({ overallReadiness: 45, breakdown: [{ slug: 'section', score: 45 }] });
        expect(review).toMatchObject({ count: 1, recommendations: [{ slug: 'section', mastery: 75 }] });
        expect(await read(stats.getAdminUserAnalytics, {params: {userId: 1}})).toEqual({readiness, smartReview: review.recommendations});
        expect(await read(stats.getReadiness, {user: {id: 2}})).toEqual({overallReadiness: 0, breakdown: []});
    });

    test('the class dashboard includes sessions without an end signal and reports zero-percent days', async () => {
        const actor = { id: 9, role: 'admin', assigned_subject_id: null };
        const dashboard = await read(stats.getQuestionStats, {user: actor, query: {topicId: '1'}});
        expect(dashboard.questionStats).toEqual([expect.objectContaining({total_attempts: 4, correct_percentage: 25})]);
        expect(dashboard.userStats).toMatchObject({total_users: 2, avg_session_mins: 15, class_avg_trend: '-25.0'});
        expect(await read(stats.getAdminSummary, {user: actor})).toEqual([expect.objectContaining({slug:'pathophysiology', attempts:4, proficiency:25})]);
        expect(await read(stats.getInventorySummary)).toEqual([expect.objectContaining({total:1,sections:[expect.objectContaining({total:1})]})]);
    });

    test('the class average and its daily trend weight recorded answers in the selected subject', async () => {
        await pg.query('BEGIN');
        try {
            await pg.query(`
                INSERT INTO questions VALUES (4,2,'One attempt',2,1),(5,2,'Still unused',1,1);
                INSERT INTO responses(id,user_id,question_id,is_correct) VALUES (5,1,4,true);
                INSERT INTO users(id,email,role) VALUES (8,'test_reset@example.com','student');
                INSERT INTO quiz_sessions(id,user_id,started_at) VALUES (12,8,now());
                INSERT INTO responses(id,session_id,question_id,is_correct) VALUES (6,12,4,true);
            `);
            const dashboard = await read(stats.getQuestionStats, {
                user: {id:9,role:'admin',assigned_subject_id:null}, query:{topicId:'1'},
            });
            expect(dashboard.userStats).toMatchObject({class_avg:40, class_avg_trend:'-15.0'});
            expect(dashboard.questionStats.find(q => q.question_id === '4')).toMatchObject({total_attempts:1,correct_count:1});
            expect(dashboard.questionStats.find(q => q.question_id === '5')).toMatchObject({total_attempts:0});
        } finally {
            await pg.query('ROLLBACK');
        }
    });

    test('subject charts summarize student answers by section and respect the instructor question scope', async () => {
        await pg.query('BEGIN');
        try {
            await pg.query(`
                ALTER TABLE questions ADD COLUMN created_by int;
                INSERT INTO topics VALUES (5,null,'new-subject','Other subject','Más tárgy'),(6,5,'other-section','Other section','Más téma');
                INSERT INTO topics VALUES (10,2,'unit','Unit','Egység');
                INSERT INTO questions(id,topic_id) VALUES (7,6),(10,10);
                INSERT INTO users(id,email,role) VALUES (9,'teacher@example.test','admin'),(8,'test_reset@example.com','student');
                INSERT INTO responses(id,user_id,question_id,is_correct) VALUES (5,9,3,true),(6,8,3,true),(7,2,10,true),(8,2,7,true);
            `);
            const actor = { id:9, role:'admin', assigned_subject_id:1 };
            const selected = await read(stats.getAdminSummary, {user:actor, query:{topicId:'1'}});
            expect(selected).toEqual([expect.objectContaining({slug:'section', section:'Section', name_hu:'Téma', attempts:5, proficiency:40, avg_time_ms:375})]);
            expect(await read(stats.getAdminSummary, {user:actor, query:{topicId:'5'}})).toEqual([]);
            expect(await read(stats.getAdminSummary, {user:actor})).toEqual([expect.objectContaining({slug:'pathophysiology', attempts:5, proficiency:40})]);
            const global = await read(stats.getAdminSummary, {user:{...actor, assigned_subject_id:null}});
            expect(global).toHaveLength(2);
            expect(global).toContainEqual(expect.objectContaining({slug:'new-subject', attempts:1, proficiency:100}));
            const dashboard = await read(stats.getQuestionStats, {user:actor, query:{topicId:'1'}});
            expect(dashboard.userStats).toMatchObject({class_avg:40, class_avg_trend:'-15.0'});
            await expect(read(stats.getAdminSummary, {user:actor, query:{topicId:'bad'}})).rejects.toMatchObject({statusCode:400});
        } finally {
            await pg.query('ROLLBACK');
        }
    });

    test('instructor search returns the matching student and counts their offline answer', async () => {
        for (const search of ['student-one', '1']) {
            const result = await read(stats.getUsersPerformance, {query:{search, limit:'1'}});
            expect(result).toMatchObject({total:1, page:1, users:[{id:1, pathophysiology_total:3, pathophysiology_correct:1}]});
        }
        const empty = await read(stats.getUsersPerformance, {query:{page:'5',limit:'1'}});
        expect(empty).toMatchObject({total:2, users:[]});
    });
});
