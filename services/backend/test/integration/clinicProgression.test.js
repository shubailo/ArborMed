const { randomUUID } = require('node:crypto');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const { Client, Pool } = require('pg');
jest.mock('../../src/config/db', () => ({ query: jest.fn(), pool: { connect: jest.fn() } }));
const db = require('../../src/config/db');
const social = require('../../src/controllers/socialController');
const residency = require('../../src/controllers/gamificationController');

const run = process.env.TEST_DATABASE_URL ? describe : describe.skip;
run('colleagues, clinics and residency rounds', () => {
    const schema = 'clinic_test_' + randomUUID().replaceAll('-', '');
    const today = "(CURRENT_TIMESTAMP AT TIME ZONE 'UTC')::date";
    let admin, pool, created;

    beforeAll(async () => {
        const connectionString = process.env.TEST_DATABASE_URL;
        admin = new Client({ connectionString });
        await admin.connect();
        await admin.query(`CREATE SCHEMA ${schema}`);
        created = true;
        // UTC accounting must be independent of the database session timezone.
        pool = new Pool({ connectionString, options: `-c search_path=${schema} -c timezone=Pacific/Kiritimati` });
        await pool.query(`CREATE TABLE users(id int PRIMARY KEY, username text, display_name text,
                streak_count int DEFAULT 0, xp int DEFAULT 0, level int DEFAULT 1, coins int DEFAULT 0);
            CREATE TABLE quiz_sessions(id int PRIMARY KEY, user_id int REFERENCES users);
            CREATE TABLE responses(id serial PRIMARY KEY, session_id int REFERENCES quiz_sessions, user_id int REFERENCES users,
                is_correct boolean NOT NULL, created_at timestamptz DEFAULT now());
            CREATE TABLE room_likes(liker_id int REFERENCES users, receiver_id int REFERENCES users, UNIQUE(liker_id,receiver_id))`);
        for (const file of ['008_friendships.sql', '051_residency_progression.sql']) {
            await pool.query(readFileSync(join(__dirname, '../../migrations', file), 'utf8'));
        }
        db.query.mockImplementation((...args) => pool.query(...args));
        db.pool.connect.mockImplementation(() => pool.connect());
    });

    afterAll(async () => {
        await pool?.end();
        try {
            if (created) await admin.query(`DROP SCHEMA ${schema} CASCADE`);
        } finally {
            await admin?.end();
        }
    });

    beforeEach(async () => {
        await pool.query(`TRUNCATE users, friendships, consultation_notes, responses, quiz_sessions, room_likes;
            INSERT INTO users(id,username) VALUES(1,'student-one'),(2,'student-two'),(3,'student-three'),(999,'hemmy')`);
    });

    async function call(handler, userId, fields = {}, role = 'student') {
        const req = { user: {id:userId, role}, body:{}, query:{}, params:{}, ...fields };
        let payload;
        const res = { status() {return this;}, json(value) { payload = value; } };
        await handler(req, res, error => { throw error; });
        return payload;
    }
    const request = (from, to) => call(social.sendRequest, from, { body: { receiverId: to } });
    const respond = (receiver, requesterId, action) =>
        call(social.respondToRequest, receiver, { body: { requesterId, action } });
    const search = (id, query) => call(social.searchUsers, id, { query: { query } });
    const note = (from, to, message) => call(social.leaveNote, from, { body: { targetUserId: to, note: message } });
    const notes = (id, owner, role) => call(social.getNotes, id, { params: {userId: String(owner)} }, role);
    const profileIds = rows => rows.map(profile => profile.id).sort((a,b) => a-b);

    it('reflects incoming, outgoing and accepted invitations in search and the correct clinics', async () => {
        await expect(search(1, '')).rejects.toMatchObject({statusCode:400});
        const initial = await search(1, 'student');
        expect(profileIds(initial)).toEqual([2,3]);
        expect(initial.every(student => student.friendshipStatus === 'none')).toBe(true);
        await expect(request(1,1)).rejects.toMatchObject({statusCode:400});
        await request(1,2);
        await expect(request(2,1)).rejects.toMatchObject({statusCode:400});
        expect((await search(1,'2'))[0]).toMatchObject({id:2,friendshipStatus:'request_sent'});
        expect((await search(2,'1'))[0]).toMatchObject({id:1,friendshipStatus:'request_received'});
        expect(profileIds((await call(social.getNetwork,2)).pending)).toEqual([1]);
        await expect(respond(3,1,'accept')).rejects.toMatchObject({statusCode:404});
        await respond(2,1,'decline');
        expect((await call(social.getNetwork,2)).pending).toEqual([]);
        await request(2,1);
        await respond(1,2,'accept');
        expect((await search(1,'2'))[0].friendshipStatus).toBe('colleague');
        expect(profileIds((await call(social.getNetwork,1)).colleagues)).toEqual([2,999]);
        expect((await call(social.getNetwork,999)).colleagues).toEqual([]);
        await call(social.removeColleague,1,{params:{targetUserId:'2'}});
        expect(profileIds((await call(social.getNetwork,2)).colleagues)).toEqual([999]);
    });

    it('keeps consultation notes private and returns only recent notes in the target clinic', async () => {
        await expect(note(1,2,'')).rejects.toMatchObject({statusCode:400});
        await expect(note(1,2,'Consultation')).rejects.toMatchObject({statusCode:403});
        await request(1,2);
        await expect(note(1,2,'Pending')).rejects.toMatchObject({statusCode:403});
        await respond(2,1,'accept');
        await note(1,2,'Recent note');
        await note(3,999,'System clinic');
        await pool.query("INSERT INTO consultation_notes(author_id,target_user_id,note,created_at) VALUES(1,2,'Old',now()-interval '8 days')");
        expect((await notes(2,2)).map(row => [row.username, row.note])).toEqual([['student-one','Recent note']]);
        await expect(notes(1,2)).rejects.toMatchObject({statusCode:403});
        expect((await notes(3,999,'admin')).map(row=>row.note)).toEqual(['System clinic']);
    });

    it('credits a room owner once when two requests for the same like overlap', async () => {
        const like = targetUserId => call(social.likeRoom,1,{body:{targetUserId}});
        await expect(like(1)).rejects.toMatchObject({statusCode:400});
        await expect(like(-1)).rejects.toMatchObject({statusCode:400});
        const results = await Promise.allSettled([like(2),like(2)]);
        expect(results.filter(r=>r.status==='fulfilled')).toHaveLength(1);
        expect(results.find(r=>r.status==='rejected').reason.statusCode).toBe(400);
        expect((await pool.query('SELECT coins FROM users WHERE id IN(1,2) ORDER BY id')).rows).toEqual([{coins:0},{coins:5}]);
    });

    it.each([['chief','attending',3],['attending','resident',3],['resident','intern',3],
        ['intern','unmatched',3],['unmatched','unmatched',5]])(
        'demotes %s only one rank after the fifth strike and applies the missed day once', async (rank, expected, strikes) => {
            await pool.query(`UPDATE users SET rank=$1, malpractice_strikes=4, last_rounds_date=${today}-2 WHERE id=1`, [rank]);
            const first = await call(residency.getStatus,1);
            expect(first.data).toMatchObject({rank:expected,malpracticeStrikes:strikes,isOnProbation:true});
            expect(await call(residency.getStatus,1)).toEqual(first);
        });

    it('initializes a new resident without a strike and records a single missed shift below probation', async () => {
        const {data} = await call(residency.getStatus,1);
        expect(data).toMatchObject({rank:'unmatched',malpracticeStrikes:0,isOnProbation:false});
        expect(data.lastRoundsDate.toISOString()).toMatch(/T00:00:00\.000Z$/);
        await pool.query(`UPDATE users SET rank='resident',malpractice_strikes=0,last_rounds_date=${today}-2 WHERE id=1`);
        expect((await call(residency.getStatus,1)).data).toMatchObject({rank:'resident',malpracticeStrikes:1,isOnProbation:false});
    });

    it('requires ten qualifying answers on the UTC study day and pardons at most one strike on retries', async () => {
        await pool.query(`UPDATE users SET last_rounds_date=${today}-1,malpractice_strikes=3 WHERE id=1;
            INSERT INTO quiz_sessions VALUES(21,1),(22,2);
            INSERT INTO responses(user_id,is_correct,created_at)
                SELECT 1,true, (${today}::timestamp AT TIME ZONE 'UTC') FROM generate_series(1,8);
            INSERT INTO responses(session_id,user_id,is_correct) VALUES(21,NULL,true),(22,NULL,true),(21,2,true),(21,1,false);
            INSERT INTO responses(user_id,is_correct,created_at) VALUES(1,true,(${today}::timestamp AT TIME ZONE 'UTC')-interval '1 second')`);
        expect((await call(residency.syncRounds,1)).data.malpracticeStrikes).toBe(3);
        await pool.query('INSERT INTO responses(user_id,is_correct) VALUES(1,true)');
        const [first, retry] = await Promise.all([call(residency.syncRounds,1),call(residency.syncRounds,1)]);
        expect(first).toEqual(retry);
        expect(first.data).toMatchObject({malpracticeStrikes:2,isOnProbation:false});
        const day = await pool.query(`SELECT ${today}::text AS day`);
        expect(first.data.lastRoundsDate.toISOString()).toBe(day.rows[0].day+'T00:00:00.000Z');
    });
});
