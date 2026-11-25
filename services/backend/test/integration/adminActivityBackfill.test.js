const fs = require('node:fs');
const path = require('node:path');
const { randomUUID } = require('node:crypto');
const { Client } = require('pg');

const postgres = process.env.TEST_DATABASE_URL ? describe : describe.skip;
const sqlPath = path.join(__dirname, '../../migrations/068_admin_activity.sql');

postgres('historical admin last activity', () => {
    const schema = 'activity_test_' + randomUUID().replaceAll('-', '');
    let pg;
    const apply = () => pg.query(fs.readFileSync(sqlPath, 'utf8'));
    const read = async () => (await pg.query('SELECT id, last_activity_at FROM users ORDER BY id')).rows
        .map(row => row.last_activity_at?.toISOString() ?? null);
    const day = n => `2024-03-${String(n).padStart(2, '0')}T08:30:00.000Z`;

    beforeAll(async () => {
        pg = new Client({ connectionString: process.env.TEST_DATABASE_URL });
        await pg.connect();
        await pg.query(`CREATE SCHEMA ${schema}; SET search_path TO ${schema}; SET TIME ZONE 'Europe/Budapest';
            CREATE TABLE users(id int PRIMARY KEY, created_at timestamptz, last_active_date timestamptz, last_activity_at timestamptz);
            CREATE TABLE responses(user_id int, session_id int, created_at timestamptz);
            CREATE TABLE quiz_sessions(id int, user_id int, started_at timestamptz, completed_at timestamptz);
            CREATE TABLE refresh_tokens(user_id int, created_at timestamptz);
            CREATE TABLE security_audits(user_id int, action_type text, created_at timestamptz);
            CREATE TABLE user_activity(user_id int, action text, created_at timestamptz);
            CREATE TABLE user_topic_progress(user_id int, total_answered int, last_studied_at timestamptz);
            CREATE TABLE friendships(requester_id int, receiver_id int, status text, created_at timestamptz, updated_at timestamptz);
            CREATE TABLE consultation_notes(author_id int, target_user_id int, created_at timestamptz);
            CREATE TABLE question_reports(user_id int, created_at timestamptz, updated_at timestamptz);
            CREATE TABLE user_claimed_quests(user_id int, claimed_at timestamptz);
            CREATE TABLE room_likes(liker_id int, receiver_id int, created_at timestamp);
        `);
    });
    afterAll(async () => {
        try { await pg.query(`DROP SCHEMA ${schema} CASCADE`); } finally { await pg.end(); }
    });
    beforeEach(async () => {
        await pg.query(`TRUNCATE users, responses, quiz_sessions, refresh_tokens, security_audits, user_activity,
            user_topic_progress, friendships, consultation_notes, question_reports, user_claimed_quests, room_likes`);
    });

    test('uses the latest recorded action of its owner, including old session-only and offline answers', async () => {
        await pg.query(`INSERT INTO users(id,created_at) SELECT n, '2024-01-01Z' FROM generate_series(1,9) n;
            UPDATE users SET last_activity_at=created_at;
            INSERT INTO quiz_sessions VALUES(11,1,'2024-02-01Z','2024-02-03Z'),(22,2,'2024-03-02T08:30Z',NULL);
            INSERT INTO responses VALUES(NULL,11,'2024-03-01T09:30+01'),(3,22,'2024-03-03T08:30Z'),(4,NULL,'2024-03-04T08:30Z');
            INSERT INTO refresh_tokens VALUES(5,'2024-03-05T08:30Z');
            INSERT INTO security_audits VALUES(6,'LOGIN_SUCCESS','2024-03-06T08:30Z'),(9,'ROLE_UPDATE','2024-03-29T08:30Z');
            INSERT INTO user_activity VALUES(7,'quiz_answer','2024-03-07T08:30Z');
            UPDATE users SET last_active_date='2024-03-08T08:30Z' WHERE id=8;
            UPDATE users SET last_activity_at='2024-03-08T08:30Z' WHERE id=1;
            INSERT INTO refresh_tokens VALUES(9,'2023-01-01Z');`);
        await apply();
        expect(await read()).toEqual([day(8),day(2),day(3),day(4),day(5),day(6),day(7),day(8),null]);
        await pg.query('UPDATE users SET last_activity_at=NULL WHERE id=1');
        await apply();
        expect((await read())[0]).toBe(day(1));
        const versions = () => pg.query('SELECT xmin::text FROM users ORDER BY id').then(r => r.rows);
        const before = await versions();
        await apply();
        expect(await versions()).toEqual(before);
    });

    test('social, study and support evidence belongs to the actor; passive or undated events stay unknown', async () => {
        await pg.query(`INSERT INTO users(id,created_at) SELECT n, '2024-01-01Z' FROM generate_series(1,8) n;
            INSERT INTO consultation_notes VALUES(1,8,'2024-03-01T08:30Z');
            INSERT INTO friendships VALUES(2,8,'pending','2024-03-02T08:30Z','2024-03-02T08:30Z'),
                (2,3,'accepted','2024-02-01Z','2024-03-03T08:30Z');
            INSERT INTO question_reports VALUES(4,'2024-03-04T08:30Z','2024-05-01Z');
            INSERT INTO user_topic_progress VALUES(5,2,'2024-03-05T08:30Z'), (8,0,'2024-04-01Z');
            INSERT INTO user_claimed_quests VALUES(6,'2024-03-06T08:30Z');
            INSERT INTO room_likes VALUES(7,8,'2024-03-07 08:30:00');
            INSERT INTO security_audits VALUES(8,'LOGIN_FAILURE','2024-04-01Z');`);
        await apply();
        expect(await read()).toEqual([day(1),day(2),day(3),day(4),day(5),day(6),null,null]);
    });

    test('works with a partial historical schema and refuses to invent a timezone for old answers', async () => {
        await pg.query('BEGIN');
        try {
            await pg.query(`DROP TABLE user_activity, security_audits, consultation_notes;
                ALTER TABLE users DROP COLUMN last_activity_at;
                ALTER TABLE responses ALTER COLUMN created_at TYPE timestamp;
                INSERT INTO users (id, created_at) VALUES (1,'2024-01-01Z'),(2,'2024-01-01Z');
                INSERT INTO responses VALUES(1,NULL,'2024-03-01 09:30:00');
                INSERT INTO refresh_tokens VALUES(2,'2024-03-02T08:30Z');`);
            await apply();
            expect(await read()).toEqual([null, day(2)]);
        } finally {
            await pg.query('ROLLBACK');
        }
    });

    test('preserves a later activity write committed while the historical update waits for the user row', async () => {
        await pg.query(`INSERT INTO users VALUES(1,'2024-01-01Z',NULL,'2024-01-01Z');
            INSERT INTO refresh_tokens VALUES(1,'2024-03-01T08:30Z')`);
        const writer = new Client({connectionString: process.env.TEST_DATABASE_URL});
        await writer.connect();
        try {
            await writer.query(`BEGIN; UPDATE ${schema}.users SET last_activity_at='2024-03-31T08:30Z' WHERE id=1`);
            const backfill = apply();
            try {
                for (let n=0; n<200; n++) {
                    const { rows } = await writer.query('SELECT pg_backend_pid() = ANY(pg_blocking_pids($1)) AS waiting', [pg.processID]);
                    if (rows[0].waiting) break;
                    if (n===199) throw new Error('Backfill did not wait on the live activity write');
                    await new Promise(resolve => setTimeout(resolve, 10));
                }
            } finally {
                await writer.query('COMMIT');
                await backfill;
            }
        } finally { await writer.end(); }
        expect(await read()).toEqual([day(31)]);
    });
});
