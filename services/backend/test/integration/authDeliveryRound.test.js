const { Client } = require('pg');
const fs = require('node:fs');
const path = require('node:path');

jest.mock('../../src/config/db', () => ({ query: jest.fn(), pool: { connect: jest.fn() } }));
jest.mock('../../src/services/mailService', () => ({ isConfigured: true, sendOTP: jest.fn() }));
const db = require('../../src/config/db');
const mail = require('../../src/services/mailService');
const challenges = require('../../src/services/authChallenges');

const postgres = process.env.TEST_DATABASE_URL ? describe : describe.skip;
postgres('mail delivery and the active verification challenge', () => {
    const client = new Client({ connectionString: process.env.TEST_DATABASE_URL });
    const email = 'student@example.test';
    const originalSecret = process.env.JWT_SECRET;
    beforeAll(async () => {
        process.env.JWT_SECRET = 'local-mail-round';
        await client.connect();
        await client.query('CREATE TEMP TABLE users (id int PRIMARY KEY, email text, password_hash text, is_email_verified boolean); SET search_path TO pg_temp');
        await client.query(fs.readFileSync(path.join(__dirname, '../../migrations/060_auth_challenges.sql'), 'utf8'));
        db.query.mockImplementation(client.query.bind(client));
        db.pool.connect.mockResolvedValue({ query: client.query.bind(client), release() {} });
    });
    afterAll(async () => {
        await client.end();
        if (originalSecret === undefined) delete process.env.JWT_SECRET;
        else process.env.JWT_SECRET = originalSecret;
    });
    beforeEach(async () => {
        mail.sendOTP.mockReset().mockResolvedValue({});
        await client.query('TRUNCATE auth_challenges, users');
    });
    async function eligibleRegistration() {
        const id = await challenges.register(email, 'student', 'Student', 'fixture');
        const code = mail.sendOTP.mock.lastCall[1];
        await client.query("UPDATE auth_challenges SET issued_at = now() - interval '2 minutes', attempts_left = 3");
        return { id, code };
    }
    const state = async () => (await client.query('SELECT otp_digest, expires_at, attempts_left FROM auth_challenges')).rows[0];
    test('a failed resend preserves the previous delivered code and its remaining budget', async () => {
        const { id, code } = await eligibleRegistration();
        const previous = await state();
        mail.sendOTP.mockRejectedValueOnce(new Error('fixture delivery failure'));
        await expect(challenges.resend(email, id)).rejects.toMatchObject({ statusCode: 503 });
        expect(await state()).toEqual(previous);
        await expect(challenges.resend(email, id)).rejects.toMatchObject({ statusCode: 429 });
        await expect(challenges.consume(email, 'registration', code, id, async () => true)).resolves.toBe(true);
    });
    test('successful delivery promotes the new code without reviving a consumed request', async () => {
        const { id, code } = await eligibleRegistration();
        let started, release;
        const sending = new Promise(resolve => { started = resolve; });
        mail.sendOTP.mockImplementationOnce(() => new Promise(resolve => { release = resolve; started(); }));
        const resend = challenges.resend(email, id);
        await sending;
        try {
            await expect(challenges.consume(email, 'registration', code, id, async () => true)).resolves.toBe(true);
        } finally {
            release();
            await Promise.allSettled([resend]);
        }
        await expect(resend).rejects.toMatchObject({ statusCode: 409 });
        expect(await state()).toBeUndefined();
    });
    test('a late delivery cannot replace a newer confirmed resend', async () => {
        const { id } = await eligibleRegistration();
        let started, release;
        const sending = new Promise(resolve => { started = resolve; });
        mail.sendOTP.mockImplementationOnce(() => new Promise(resolve => { release = resolve; started(); }));
        const older = challenges.resend(email, id);
        await sending;
        let latestCode;
        try {
            await client.query("UPDATE auth_challenges SET issued_at = now() - interval '2 minutes'");
            await challenges.resend(email, id);
            latestCode = mail.sendOTP.mock.lastCall[1];
        } finally {
            release();
            await Promise.allSettled([older]);
        }
        await expect(older).rejects.toMatchObject({ statusCode: 409 });
        await expect(challenges.consume(email, 'registration', latestCode, id, async () => true)).resolves.toBe(true);
    });

    test('a changed verification address is reported without creating an undeliverable challenge', async () => {
        await client.query('INSERT INTO users VALUES (1, $1, $2, false)', ['current@example.test', 'fixture']);
        await expect(challenges.beginEmailVerification({id: 1, email, password_hash: 'fixture'}))
            .rejects.toMatchObject({ statusCode: 409 });
        expect(mail.sendOTP).not.toHaveBeenCalled();
        expect(await state()).toBeUndefined();
    });
});
