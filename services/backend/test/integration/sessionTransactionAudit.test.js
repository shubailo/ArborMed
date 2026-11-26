const { Pool, Client } = require('pg');
const { randomUUID } = require('node:crypto');
jest.mock('../../src/config/db', () => ({ query: jest.fn(), pool: { connect: jest.fn() } }));
const db = require('../../src/config/db');
const { withTransaction } = require('../../src/utils/dbHelpers');
const { findSessionUser } = require('../../src/services/sessionUser');
const run = process.env.TEST_DATABASE_URL ? describe : describe.skip;

run('session activity and transaction outcomes on PostgreSQL', () => {
    const schema = 'session_test_' + randomUUID().replaceAll('-', '');
    let admin, pool;
    beforeAll(async () => {
        const connectionString = process.env.TEST_DATABASE_URL;
        admin = new Client({ connectionString });
        await admin.connect();
        await admin.query('CREATE SCHEMA ' + schema);
        pool = new Pool({ connectionString, options: '-c search_path=' + schema });
        await pool.query(`CREATE TABLE users(id int PRIMARY KEY,email text,role text,assigned_subject_id int,
            coins int,xp int,level int,last_activity_at timestamptz,email_session_version uuid,is_email_verified boolean);
            INSERT INTO users(id,role,is_email_verified) VALUES(1,'student',true);
            CREATE TABLE marks(n int PRIMARY KEY)`);
        db.pool.connect.mockImplementation(() => pool.connect());
    });
    afterAll(async () => {
        await pool?.end();
        if (admin) {
            try {
                await admin.query('DROP SCHEMA IF EXISTS ' + schema + ' CASCADE');
            } finally {
                await admin.end();
            }
        }
    });
    test('a locked last-seen row does not block login or consume the statement timeout', async () => {
        const locker = await pool.connect(),
            reader = await pool.connect();
        // Bound a regression without using timing as the pass condition.
        await reader.query("SET statement_timeout='650ms'");
        let timedOut = false;
        db.query.mockImplementation(async (...args) => {
            try {
                return await reader.query(...args);
            } catch (error) {
                if (error.code === '57014') timedOut = true;
                throw error;
            }
        });
        try {
            await locker.query('BEGIN');
            await locker.query('SELECT id FROM users WHERE id=1 FOR UPDATE');
            expect(await findSessionUser({ id: 1 })).toMatchObject({ id: 1, role: 'student' });
            expect(timedOut).toBe(false);
            expect(
                (await reader.query('SELECT last_activity_at FROM users')).rows[0].last_activity_at
            ).toBeNull();
            await locker.query('ROLLBACK');
            await findSessionUser({ id: 1 });
            expect(
                (await reader.query('SELECT last_activity_at FROM users')).rows[0].last_activity_at
            ).toBeInstanceOf(Date);
        } finally {
            await locker.query('ROLLBACK');
            locker.release();
            await reader.query('RESET statement_timeout');
            reader.release();
        }
    });
    test('a versioned login only resolves the current verified owner and rejected sessions do not record activity', async () => {
        const version = randomUUID();
        db.query.mockImplementation((...args) => pool.query(...args));
        await pool.query("INSERT INTO users (id,role,is_email_verified,email_session_version) VALUES (2,'student',true,$1), (3,'student',false,$1)", [version]);
        expect(await findSessionUser({id: 2})).toBeNull();
        expect(await findSessionUser({id: 2, emailVersion: randomUUID()})).toBeNull();
        expect(await findSessionUser({id: 3, emailVersion: version})).toBeNull();
        expect((await pool.query('SELECT FROM users WHERE id IN (2,3) AND last_activity_at IS NOT NULL')).rowCount).toBe(0);
        expect(await findSessionUser({id: 2, emailVersion: version})).toMatchObject({id: 2});
    });

    test('an aborted transaction cannot return a successful callback value', async () => {
        await expect(
            withTransaction(async (client) => {
                await client.query('INSERT INTO marks VALUES (11)');
                try {
                    await client.query('INSERT INTO marks VALUES (11)');
                } catch (error) {
                    if (error.code !== '23505') throw error;
                }
                return 'saved';
            })
        ).rejects.toMatchObject({ code: 'TRANSACTION_ROLLED_BACK' });
        expect((await pool.query('SELECT FROM marks WHERE n=11')).rowCount).toBe(0);
    });
    test('a lost checkout before COMMIT reports the connection loss and rolls back the work', async () => {
        let interruption;
        const result = withTransaction(async client => {
            await client.query('INSERT INTO marks VALUES (41)');
            const interrupted = new Promise(resolve => client.once('error', resolve));
            await admin.query('SELECT pg_terminate_backend($1)', [client.processID]);
            interruption = await interrupted;
        });
        await expect(result).rejects.toMatchObject({code: '57P01'});
        await expect(result).rejects.toBe(interruption);
        expect((await pool.query('SELECT FROM marks WHERE n = 41')).rowCount).toBe(0);
    });

    test('a lost commit acknowledgement is distinguished from a known rollback', async () => {
        const client = await pool.connect(),
            lost = Object.assign(new Error('fixture connection lost'), { code: 'ECONNRESET' });
        const release = jest.fn((error) => client.release(error));
        db.pool.connect.mockResolvedValueOnce({
            release,
            query: async (sql, ...args) => {
                const result = await client.query(sql, ...args);
                if (sql === 'COMMIT') throw lost;
                return result;
            },
        });
        await expect(withTransaction((c) => c.query('INSERT INTO marks VALUES (21)'))).rejects.toMatchObject({
            code: 'TRANSACTION_OUTCOME_UNKNOWN',
            cause: lost,
        });
        expect(release).toHaveBeenCalledWith(lost);
        expect((await pool.query('SELECT FROM marks WHERE n=21')).rowCount).toBe(1);
    });

    test('a deferred constraint rejected at commit keeps its PostgreSQL error code', async () => {
        await expect(
            withTransaction(async (client) => {
                await client.query(
                    'CREATE TEMP TABLE deferred_mark (n int UNIQUE DEFERRABLE INITIALLY DEFERRED)'
                );
                await client.query('INSERT INTO deferred_mark VALUES (1), (1)');
            })
        ).rejects.toMatchObject({ code: '23505' });
        expect((await pool.query('SELECT 1 AS ok')).rows[0].ok).toBe(1);
    });

    test('a rollback error from a nested operation still rolls back the outer transaction', async () => {
        const nested = Object.assign(new Error('inner transaction failed'), { code: 'TRANSACTION_ROLLED_BACK' });
        await expect(withTransaction(async (client) => {
            await client.query('INSERT INTO marks VALUES (31)');
            throw nested;
        })).rejects.toBe(nested);
        const client = await pool.connect();
        try {
            expect((await client.query('SELECT FROM marks WHERE n = 31')).rowCount).toBe(0);
        } finally {
            client.release();
        }
    });

});
