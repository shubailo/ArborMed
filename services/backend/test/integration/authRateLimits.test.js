const { once } = require('node:events');
jest.mock('../../src/config/db', () => ({ query: jest.fn() }));
jest.mock('../../src/services/mailService', () => ({}));
const { app } = require('../../server');

test('sign-in, token refresh and ordinary profile traffic use distinct rate limits', async () => {
    const server = app.listen(0, '127.0.0.1');
    await once(server, 'listening');
    try {
        const base = 'http://127.0.0.1:' + server.address().port;
        const policy = async (path, method) => {
            const res = await fetch(base + path, {
                method, headers: { 'Content-Type': 'application/json' },
                body: method === 'POST' ? '{}' : undefined
            });
            await res.text();
            return res.headers.get('ratelimit-policy');
        };
        const login = await policy('/auth/login', 'POST');
        const refresh = await policy('/auth/refresh', 'POST');
        expect(login).toMatch(/^50;/);
        expect(refresh).toMatch(/^600;/);
        expect(await policy('/auth/me', 'GET')).toBeNull();
        expect(await policy('/api/translate', 'POST')).toBeNull();
    } finally {
        await new Promise(resolve => server.close(resolve));
    }
});
