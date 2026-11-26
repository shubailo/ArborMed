const express = require('express');
const { once } = require('node:events');

jest.mock('../../src/controllers/authController', () => {
    const ok = (_req, res) => res.sendStatus(200);
    return {
        register: ok, verifyRegistration: ok, resendRegistrationOTP: ok, refreshToken: ok,
        login: (_req, res) => res.sendStatus(401), googleLogin: (_req, res) => res.sendStatus(503),
        verifyEmail: ok, requestOTP: ok, resetPassword: ok, logout: ok, claimReward: ok,
        changePassword: ok, updateProfile: ok, getMe: ok,
    };
});
jest.mock('../../src/middleware/authMiddleware', () => ({ protect: (_req, _res, next) => next() }));
jest.mock('express-rate-limit', () => {
    const { rateLimit } = jest.requireActual('express-rate-limit');
    // The same middleware, with a two-request budget for deterministic boundary tests.
    return { rateLimit: options => rateLimit({ ...options, limit: 2 }) };
});

describe('auth router request budgets', () => {
    let server;
    beforeEach(async () => {
        const app = express();
        jest.isolateModules(() => app.use('/auth', require('../../src/routes/authRoutes')));
        server = app.listen(0, '127.0.0.1');
        await once(server, 'listening');
    });
    afterEach(() => new Promise(resolve => server.close(resolve)));
    async function request(path, method = 'POST') {
        const res = await fetch('http://127.0.0.1:' + server.address().port + '/auth/' + path, { method });
        const body = await res.text();
        return { status: res.status, remaining: res.headers.get('ratelimit-remaining'),
            body, type: res.headers.get('content-type'), retry: res.headers.get('retry-after') };
    }
    test('issuing a code leaves room in the separate confirmation budget', async () => {
        expect((await request('register')).remaining).toBe('1');
        expect((await request('verify-registration')).remaining).toBe('1');
        expect((await request('resend-registration-otp')).remaining).toBe('0');
        expect((await request('verify-email')).remaining).toBe('0');
    });
    test('a method with no sign-in handler does not spend a sign-in attempt', async () => {
        const other = await request('login', 'GET');
        expect(other.status).toBe(404);
        expect(other.remaining).toBeNull();
        expect((await request('login')).remaining).toBe('1');
    });
    test('upstream unavailability leaves the failed sign-in budget intact', async () => {
        expect((await request('google')).status).toBe(503);
        expect((await request('login')).remaining).toBe('1');
        expect((await request('login')).remaining).toBe('0');
    });
    test('a capped request provides the JSON message consumed by the app and a retry time', async () => {
        await request('request-otp');
        await request('request-otp');
        const capped = await request('request-otp');
        expect(capped.status).toBe(429);
        expect(capped.type).toMatch(/application\/json/);
        expect(JSON.parse(capped.body).message).toEqual(expect.any(String));
        expect(Number(capped.retry)).toBeGreaterThan(0);
    });
});
