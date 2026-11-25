const { once } = require('node:events');
const fs = require('node:fs/promises');
const path = require('node:path');
const jwt = require('jsonwebtoken');
jest.mock('../../src/config/db', () => ({ query: jest.fn() }));
jest.mock('../../src/services/mailService', () => ({}));
const db = require('../../src/config/db');
const { app } = require('../../server');

describe('admin image upload, browser display and deletion', () => {
    const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+yDp8AAAAASUVORK5CYII=', 'base64');
    const origin = 'https://arbor-med.netlify.app';
    let server, base, headers;
    const env = ['NODE_ENV','SUPABASE_URL','SUPABASE_SERVICE_ROLE_KEY','SUPABASE_UPLOAD_BUCKET','JWT_SECRET'];
    const previous = Object.fromEntries(env.map(k => [k, process.env[k]]));
    const createdFiles = [];
    beforeAll(async () => {
        process.env.NODE_ENV = 'test';
        delete process.env.SUPABASE_URL; delete process.env.SUPABASE_SERVICE_ROLE_KEY; delete process.env.SUPABASE_UPLOAD_BUCKET;
        process.env.JWT_SECRET = 'local-upload-transport-test';
        db.query.mockResolvedValue({ rows:[{ id:1, role:'admin' }] });
        server = app.listen(0,'127.0.0.1');
        await once(server,'listening');
        base = 'http://127.0.0.1:' + server.address().port;
        headers = { Authorization: 'Bearer ' + jwt.sign({id:1},process.env.JWT_SECRET), Origin: origin };
    });
    afterAll(async () => {
        if (server) await new Promise(resolve => server.close(resolve));
        for (const file of createdFiles) await fs.rm(file,{force:true});
        for (const key of env) {
            if (previous[key] === undefined) delete process.env[key]; else process.env[key] = previous[key];
        }
    });
    async function upload(data, type = 'image/png', name = 'figure.png') {
        const form = new FormData();
        form.append('image', new Blob([data], {type}), name);
        return fetch(base + '/api/upload', {method:'POST',headers,body:form});
    }
    test('reopens saved bytes from a separate frontend origin and allows inline image display', async () => {
        const result = await upload(png);
        expect(result.status).toBe(200);
        const { imageUrl } = await result.json();
        expect(imageUrl).toMatch(/^\/uploads\/[a-f0-9-]+\.png$/);
        const name = path.basename(imageUrl);
        createdFiles.push(path.join(__dirname,'../../uploads',name));
        const image = await fetch(base + imageUrl, {headers:{ Origin:origin }});
        expect(image.headers.get('content-type')).toMatch(/^image\/png/);
        expect(Buffer.from(await image.arrayBuffer())).toEqual(png);
        expect(image.headers.get('access-control-allow-origin')).toBe(origin);
        expect(image.headers.get('cross-origin-resource-policy')).toBe('cross-origin');
        expect((await fetch(base + '/api/upload/' + name,{method:'DELETE',headers})).status).toBe(200);
        expect((await fetch(base + imageUrl)).status).toBe(404);
    });
    test('returns a client error for files larger than 20 MiB', async () => {
        const result = await upload(Buffer.alloc(20 * 1024 * 1024 + 1));
        expect(result.status).toBe(413);
    });
});
