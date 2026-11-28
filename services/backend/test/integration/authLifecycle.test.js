const fs = require('node:fs');
const path = require('node:path');
const { Client } = require('pg');
const bcrypt = require('bcryptjs');

jest.mock('../../src/config/db', () => ({ query: jest.fn(), pool: { connect: jest.fn() } }));
jest.mock('../../src/controllers/auditController', () => ({ auditLog: jest.fn() }));
jest.mock('../../src/services/mailService', () => ({ isConfigured: true, sendOTP: jest.fn() }));

const db = require('../../src/config/db');
const mail = require('../../src/services/mailService');
const auth = require('../../src/controllers/authController');

// Uses only session-local temporary tables in the supplied test database.
const postgres = process.env.TEST_DATABASE_URL ? describe : describe.skip;
postgres('registration and password recovery on PostgreSQL', () => {
    const email = 'student@example.com';
    const client = new Client({ connectionString: process.env.TEST_DATABASE_URL });
    const originalSecret = process.env.JWT_SECRET;

    beforeAll(async () => {
        process.env.JWT_SECRET = 'test-only';
        await client.connect();
        await client.query(`
            CREATE TEMP TABLE users (id serial PRIMARY KEY, email text UNIQUE, username text UNIQUE,
                password_hash text NOT NULL, display_name text, is_email_verified boolean,
                role text, assigned_subject_id integer, coins integer, xp integer, level integer,
                streak_count int, longest_streak int, daily_coins_earned int, daily_coins_softcap_progress int,
                last_coin_reset_date date, rank text, malpractice_strikes int, last_rounds_date date, last_activity_at timestamptz);
            CREATE TEMP TABLE refresh_tokens (id serial PRIMARY KEY, user_id int REFERENCES users,
                token_hash text, revoked boolean DEFAULT false, expires_at timestamptz);
            SET search_path TO pg_temp;
        `);
        const migration = fs.readFileSync(path.join(__dirname, '../../migrations/060_auth_challenges.sql'), 'utf8');
        await client.query(migration);
        db.query.mockImplementation(client.query.bind(client));
        db.pool.connect.mockResolvedValue({ query: db.query, release() {} });
    });
    beforeEach(async () => {
        await client.query('TRUNCATE auth_challenges, refresh_tokens, users RESTART IDENTITY');
        mail.sendOTP.mockClear();
    });
    afterAll(async () => {
        await client.end();
        if (originalSecret === undefined) delete process.env.JWT_SECRET;
        else process.env.JWT_SECRET = originalSecret;
    });

    async function call(handler, body, user) {
        const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
        const next = jest.fn();
        await handler({ body: { email, ...body }, user }, res, next);
        const error = next.mock.calls[0]?.[0];
        if (error) throw error;
        return res.json.mock.calls[0][0];
    }
    async function permits(token) {
        const next = jest.fn();
        const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
        await require('../../src/middleware/authMiddleware').protect(
            { headers: { authorization: 'Bearer ' + token } }, res, next);
        return next.mock.calls.length === 1;
    }
    function deliveredCode() {
        return mail.sendOTP.mock.lastCall[1];
    }
    async function register() {
        return call(auth.register, { username: 'student', password: 'Original123!' });
    }
    async function verify(registrationId, otp) {
        return call(auth.verifyRegistration, { registrationId, otp });
    }
    async function reset(otp) {
        return call(auth.resetPassword, { otp, newPassword: 'Changed123!' });
    }
    test('session issuance records a verified registration and a later password sign-in without a quiz', async () => {
        const pending = await register();
        const { user } = await verify(pending.registrationId, deliveredCode());
        const activity = async () => (await client.query('SELECT last_activity_at FROM users WHERE id=$1', [user.id])).rows[0].last_activity_at;
        expect(await activity()).toBeInstanceOf(Date);
        await client.query('UPDATE users SET last_activity_at=NULL WHERE id=$1', [user.id]);
        await expect(call(auth.login, { password: 'wrong' })).rejects.toMatchObject({statusCode:401});
        expect(await activity()).toBeNull();
        await call(auth.login, { password: 'Original123!' });
        expect(await activity()).toBeInstanceOf(Date);
    });
    test('profile reload preserves the same clinical and economy fields as password login', async () => {
        const pending = await register();
        const { user } = await verify(pending.registrationId, deliveredCode());
        await client.query(`UPDATE users SET rank = 'resident', malpractice_strikes = 2,
            last_rounds_date = DATE '2026-03-29', daily_coins_earned = 7 WHERE id = $1`, [user.id]);
        const login = await call(auth.login, { password: 'Original123!' });
        const profile = await call(auth.getMe, {}, user);
        for (const response of [login, profile]) {
            expect(JSON.parse(JSON.stringify(response))).toMatchObject({
                rank: 'resident', malpractice_strikes: 2, daily_coins_earned: 7,
                last_rounds_date: '2026-03-29T00:00:00.000Z',
            });
            expect(response).not.toHaveProperty('password_hash');
        }
    });
    test('a normal password change retires both old tokens and permits a fresh login', async () => {
        const pending = await register();
        const old = await verify(pending.registrationId, deliveredCode());
        expect(await permits(old.token)).toBe(true);
        await call(auth.changePassword, { currentPassword: 'Original123!', newPassword: 'Changed123!' }, old.user);
        expect(await permits(old.token)).toBe(false);
        await expect(call(auth.refreshToken, { userId: old.user.id, refreshToken: old.refreshToken }))
            .rejects.toMatchObject({ statusCode: 401 });
        const fresh = await call(auth.login, { password: 'Changed123!' });
        expect(await permits(fresh.token)).toBe(true);
    });
    test('only the matching registration attempt and emailed code produce a session once', async () => {
        const pending = await register();
        expect(pending).not.toHaveProperty('token');
        expect(pending).not.toHaveProperty('otp');
        expect((await client.query('SELECT id FROM users')).rowCount).toBe(0);
        const otp = deliveredCode();
        await expect(verify('eb069f73-bbc6-469e-af7f-0ad7f2706b79', otp)).rejects.toMatchObject({ statusCode: 400 });
        const session = await verify(pending.registrationId, otp);
        expect(session.user.is_email_verified).toBe(true);
        expect(session.refreshToken).toBeTruthy();
        await expect(verify(pending.registrationId, otp)).rejects.toMatchObject({ statusCode: 400 });
        expect((await client.query('SELECT id FROM refresh_tokens')).rowCount).toBe(1);
    });

    test('password change, revocation and code consumption succeed or roll back together', async () => {
        const pending = await register();
        const session = await verify(pending.registrationId, deliveredCode());
        const response = await call(auth.requestOTP, {});
        expect(response).not.toHaveProperty('otp');
        expect(response).toEqual(await call(auth.requestOTP, { email: 'unknown@example.com' }));
        const otp = deliveredCode();
        await expect(call(auth.verifyEmail, { otp })).rejects.toMatchObject({ statusCode: 400 });
        await client.query('ALTER TABLE refresh_tokens ADD CHECK (NOT revoked)');
        await expect(reset(otp)).rejects.toMatchObject({ code: '23514' });
        const user = (await client.query('SELECT password_hash FROM users')).rows[0];
        expect(await bcrypt.compare('Original123!', user.password_hash)).toBe(true);
        await client.query('ALTER TABLE refresh_tokens DROP CONSTRAINT refresh_tokens_revoked_check');
        const previousVersion = (await client.query('SELECT email_session_version FROM users')).rows[0].email_session_version;
        await reset(otp);
        const recovered = (await client.query('SELECT email_session_version FROM users')).rows[0].email_session_version;
        expect(recovered).toBeTruthy();
        expect(recovered).not.toBe(previousVersion);
        await expect(reset(otp)).rejects.toMatchObject({ statusCode: 400 });
        await expect(call(auth.refreshToken, { userId: session.user.id, refreshToken: session.refreshToken }))
            .rejects.toMatchObject({ statusCode: 401 });
    });

    test('legacy accounts require both the password sign-in attempt and mailbox code', async () => {
        const pending = await register();
        const old = await verify(pending.registrationId, deliveredCode());
        await client.query('UPDATE users SET is_email_verified = FALSE');
        const refresh = () => call(auth.refreshToken, { userId: old.user.id, refreshToken: old.refreshToken });
        await expect(refresh()).rejects.toMatchObject({ statusCode: 401 });
        expect(await permits(old.token)).toBe(false);
        const login = password => call(auth.login, { email: undefined, username: 'student', password });
        await expect(login('wrong-password')).rejects.toMatchObject({ statusCode: 401 });
        expect(mail.sendOTP).toHaveBeenCalledTimes(1);
        const attempt = await login('Original123!');
        expect(attempt).toMatchObject({ code: 'email_not_verified', email, verificationId: expect.any(String) });
        expect(attempt).not.toHaveProperty('token');
        expect(mail.sendOTP.mock.lastCall).toEqual([email, expect.any(String), 'email-verification']);
        await expect(call(auth.requestOTP, { purpose: 'email-verification' })).rejects.toMatchObject({ statusCode: 400 });
        const otp = deliveredCode();
        await expect(call(auth.verifyEmail, { otp })).rejects.toMatchObject({ statusCode: 400 });
        await expect(call(auth.verifyEmail, { otp, verificationId: '11111111-1111-4111-8111-111111111111' }))
            .rejects.toMatchObject({ statusCode: 400 });
        await client.query("UPDATE auth_challenges SET issued_at = now() - interval '2 minutes'");
        await call(auth.requestOTP, { purpose: 'email-verification', verificationId: attempt.verificationId });
        const confirm = () => call(auth.verifyEmail, { otp: deliveredCode(), verificationId: attempt.verificationId });
        await confirm();
        await expect(confirm()).rejects.toMatchObject({ statusCode: 400 });
        await expect(refresh()).rejects.toMatchObject({ statusCode: 401 });
        const session = await login('Original123!');
        expect(await permits(old.token)).toBe(false);
        expect(await permits(session.token)).toBe(true);
        const jwt = require('jsonwebtoken');
        const fresh = jwt.verify(session.token, process.env.JWT_SECRET);
        expect(fresh.emailVersion).toBeTruthy();
        expect(jwt.verify(old.token, process.env.JWT_SECRET).emailVersion).toBeUndefined();
        const renewed = await call(auth.refreshToken, { userId: String(old.user.id), refreshToken: session.refreshToken });
        expect(jwt.verify(renewed.token, process.env.JWT_SECRET)).toMatchObject({
            id: old.user.id, emailVersion: fresh.emailVersion,
        });
    });

    test('a previously issued email challenge cannot verify a changed password', async () => {
        const pending = await register();
        await verify(pending.registrationId, deliveredCode());
        await client.query('UPDATE users SET is_email_verified = FALSE');
        const attempt = await call(auth.login, { password: 'Original123!' });
        await client.query('UPDATE users SET password_hash = $1', [await bcrypt.hash('Changed123!', 4)]);
        await expect(call(auth.verifyEmail, { verificationId: attempt.verificationId, otp: deliveredCode() }))
            .rejects.toMatchObject({ statusCode: 400 });
        expect((await client.query('SELECT is_email_verified FROM users')).rows[0].is_email_verified).toBe(false);
    });

    test('expired and exhausted challenges cannot be completed', async () => {
        const pending = await register();
        const otp = deliveredCode();
        const wrongCode = otp === '000000' ? '999999' : '000000';
        for (let attempt = 0; attempt < 5; attempt++) {
            await expect(verify(pending.registrationId, wrongCode)).rejects.toMatchObject({ statusCode: 400 });
        }
        await expect(verify(pending.registrationId, otp)).rejects.toMatchObject({ statusCode: 400 });

        await client.query("UPDATE auth_challenges SET issued_at = now() - interval '1 hour'");
        await call(auth.resendRegistrationOTP, { registrationId: pending.registrationId });
        await client.query("UPDATE auth_challenges SET expires_at = now() - interval '1 hour'");
        await expect(verify(pending.registrationId, deliveredCode())).rejects.toMatchObject({ statusCode: 400 });
    });

    test('login returns the profile and session version at grant issuance', async () => {
        const pending = await register();
        const { user } = await verify(pending.registrationId, deliveredCode());
        // Represent a concurrent profile change after credential lookup, before issuance.
        db.query.mockImplementationOnce(async (...args) => {
            const old = await client.query(...args);
            await client.query(
                "UPDATE users SET display_name='New display',email_session_version=gen_random_uuid() WHERE id=$1",
                [user.id]
            );
            return old;
        });
        const session = await call(auth.login, { password: 'Original123!' });
        expect(session.display_name).toBe('New display');
        expect(await permits(session.token)).toBe(true);
        expect(
            await permits(
                (await call(auth.refreshToken, { userId: user.id, refreshToken: session.refreshToken })).token
            )
        ).toBe(true);
    });

    test('refresh transfers at most one grant and logout revokes only that grant', async () => {
        const pending = await register();
        const a = await verify(pending.registrationId, deliveredCode());
        const b = await call(auth.login, { password: 'Original123!' });
        await client.query(
            "INSERT INTO refresh_tokens(user_id,token_hash,expires_at) SELECT $1,md5(i::text),now()+interval '1 day' FROM generate_series(1,64) i",
            [a.user.id]
        );
        let rowsRead;
        db.query.mockImplementationOnce(async (...args) => {
            const result = await client.query(...args);
            rowsRead = result.rowCount;
            return result;
        });
        await call(auth.refreshToken, { userId: a.user.id, refreshToken: a.refreshToken });
        expect(rowsRead).toBe(1);
        await call(auth.logout, { refreshToken: a.refreshToken }, a.user);
        await call(auth.logout, { refreshToken: a.refreshToken }, a.user);
        await expect(
            call(auth.refreshToken, { userId: a.user.id, refreshToken: a.refreshToken })
        ).rejects.toMatchObject({ statusCode: 401 });
        expect(
            (await call(auth.refreshToken, { userId: a.user.id, refreshToken: b.refreshToken })).token
        ).toBeTruthy();
    });

    test('a malformed logout value has a client error and preserves the active session', async () => {
        const pending = await register();
        const s = await verify(pending.registrationId, deliveredCode());
        await expect(call(auth.logout, { refreshToken: {} }, s.user)).rejects.toMatchObject({ statusCode: 400 });
        expect(
            (await call(auth.refreshToken, { userId: s.user.id, refreshToken: s.refreshToken })).token
        ).toBeTruthy();
    });

    test('logout retires access tokens issued before and during renewal for only that login', async () => {
        const pending = await register();
        const first = await verify(pending.registrationId, deliveredCode());
        const other = await call(auth.login, { password: 'Original123!' });
        const refresh = () => call(auth.refreshToken, {
            userId: first.user.id, refreshToken: first.refreshToken,
        });
        const { protect } = require('../../src/middleware/authMiddleware');
        const req = { headers: { authorization: 'Bearer ' + first.token } };
        const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
        await protect(req, res, error => { if (error) throw error; });
        expect(req.authSessionId).toEqual(expect.any(Number));
        let markGrantRead, releaseRenewal;
        const grantRead = new Promise(resolve => { markGrantRead = resolve; });
        const finishRenewal = new Promise(resolve => { releaseRenewal = resolve; });
        db.query.mockImplementationOnce(async (...args) => {
            const grant = await client.query(...args);
            markGrantRead();
            await finishRenewal;
            return grant;
        });
        const inFlight = refresh();
        try {
            await Promise.race([grantRead, inFlight]);
            await auth.logout(req, res, error => { throw error; });
        } finally {
            releaseRenewal();
        }
        const renewed = await inFlight;
        expect(await permits(first.token)).toBe(false);
        expect(await permits(renewed.token)).toBe(false);
        await expect(refresh()).rejects.toMatchObject({ statusCode: 401 });
        expect(await permits(other.token)).toBe(true);
    });

    test('profile rejects invalid names, preserves omitted fields and reports a missing account', async () => {
        const pending = await register();
        const { user } = await verify(pending.registrationId, deliveredCode());
        for (const value of ['  ', {}, 'x'.repeat(256)]) {
            await expect(call(auth.updateProfile, { username: value }, user)).rejects.toMatchObject({
                statusCode: 400,
            });
        }
        expect((await call(auth.updateProfile, { display_name: 'Hallgató' }, user)).username).toBe('student');
        await expect(call(auth.updateProfile, { display_name: 'X' }, { id: 99999 })).rejects.toMatchObject({
            statusCode: 404,
        });
    });

    test('a collision at the profile write is returned as an application conflict', async () => {
        const pending = await register();
        const { user } = await verify(pending.registrationId, deliveredCode());
        db.query.mockImplementation(async (sql, params) => {
            // The other profile claims the name after any preflight check.
            if (/UPDATE users SET username/.test(sql)) {
                await client.query(
                    "INSERT INTO users(email,username,password_hash) VALUES ('other@example.test','taken','fixture')"
                );
            }
            return client.query(sql, params);
        });
        try {
            await expect(call(auth.updateProfile, { username: 'taken' }, user)).rejects.toMatchObject({
                statusCode: 400,
            });
            expect(
                (await client.query('SELECT username FROM users WHERE id=$1', [user.id])).rows[0].username
            ).toBe('student');
        } finally {
            db.query.mockImplementation(client.query.bind(client));
        }
    });

    test('sign-in does not retain an undisclosed refresh grant when access-token issuance fails', async () => {
        const pending = await register();
        const { user } = await verify(pending.registrationId, deliveredCode());
        const count = async () =>
            (await client.query('SELECT FROM refresh_tokens WHERE user_id=$1', [user.id])).rowCount;
        const previous = await count();
        const sign = jest.spyOn(require('jsonwebtoken'), 'sign').mockImplementationOnce(() => {
            throw new Error('fixture signing failure');
        });
        try {
            await expect(call(auth.login, { password: 'Original123!' })).rejects.toThrow(
                'fixture signing failure'
            );
            expect(await count()).toBe(previous);
        } finally {
            sign.mockRestore();
        }
    });
    test('email sign-in resolves an exact email even with a historical overlapping username', async () => {
        const hashes = await Promise.all(['Original123!', 'Student123!'].map((value) => bcrypt.hash(value, 4)));
        await client.query(
            "INSERT INTO users(email,username,password_hash,is_email_verified) VALUES ('alpha@example.test','beta@example.test',$1,true),('beta@example.test','beta',$2,true)",
            hashes
        );
        const session = await call(auth.login, { identifier: 'beta@example.test', password: 'Student123!' });
        expect(session.email).toBe('beta@example.test');
        expect(
            (await call(auth.login, { identifier: 'alpha@example.test', password: 'Original123!' })).email
        ).toBe('alpha@example.test');
    });

    test('an issued access token is accepted just before its 15 minute limit and rejected at the limit', async () => {
        const pending = await register();
        const { token } = await verify(pending.registrationId, deliveredCode());
        const issuedAt = require('jsonwebtoken').decode(token).iat;
        const clock = jest.spyOn(Date, 'now');
        try {
            clock.mockReturnValue((issuedAt + 899) * 1000);
            expect(await permits(token)).toBe(true);
            clock.mockReturnValue((issuedAt + 900) * 1000);
            expect(await permits(token)).toBe(false);
        } finally {
            clock.mockRestore();
        }
    });
});
