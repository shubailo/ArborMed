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
                role text, assigned_subject_id integer, coins integer, xp integer, level integer);
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

    async function call(handler, body) {
        const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
        const next = jest.fn();
        await handler({ body: { email, ...body } }, res, next);
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
        await reset(otp);
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
        const renewed = await call(auth.refreshToken, { userId: old.user.id, refreshToken: session.refreshToken });
        expect(jwt.verify(renewed.token, process.env.JWT_SECRET).emailVersion).toEqual(fresh.emailVersion);
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
});
