const fs = require('node:fs/promises');
const os = require('node:os');
const path = require('node:path');
const { randomUUID } = require('node:crypto');
const storage = require('../../src/services/uploadStorage');

describe('persistent upload storage', () => {
    let directory, source, savedEnv;
    const keys = ['NODE_ENV', 'SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY', 'SUPABASE_UPLOAD_BUCKET'];
    const object = 'bdc1c240-00ae-4643-9fef-18fadfec55c9.png';
    const bytes = Buffer.from('fixture');
    const base = 'https://storage.example.test/storage/v1/';

    beforeEach(async () => {
        savedEnv = Object.fromEntries(keys.map(key => [key, process.env[key]]));
        Object.assign(process.env, { NODE_ENV: 'production', SUPABASE_URL: 'https://storage.example.test',
            SUPABASE_SERVICE_ROLE_KEY: 'test-role-key', SUPABASE_UPLOAD_BUCKET: 'assets' });
        directory = await fs.mkdtemp(path.join(os.tmpdir(), 'arbormed-upload-'));
        source = path.join(directory, 'source');
        await fs.writeFile(source, bytes);
        jest.spyOn(global, 'fetch').mockRejectedValue(new Error('Unexpected object storage call'));
    });
    afterEach(async () => {
        jest.restoreAllMocks();
        for (const key of keys) {
            if (savedEnv[key] === undefined) delete process.env[key];
            else process.env[key] = savedEnv[key];
        }
        await fs.unlink(source);
        await fs.rmdir(directory);
    });

    test('stores bytes remotely and produces a stable link with no credential in the public URL', async () => {
        fetch.mockResolvedValueOnce(new Response('{}', { status: 200 }));
        expect(await storage.save('icons', object, source, 'image/png')).toBe('/uploads/stored/icons/' + object);
        expect(fetch).toHaveBeenCalledWith(base + 'object/assets/icons/' + object, expect.objectContaining({
            method: 'POST', body: bytes, redirect: 'error',
            headers: expect.objectContaining({ Authorization: 'Bearer test-role-key', 'Content-Type': 'image/png' }),
        }));
        expect(storage.publicUrl('icons', object)).toBe(base + 'object/public/assets/icons/' + object);
        expect(storage.publicUrl('other', object)).toBeNull();
        expect(storage.publicUrl('images', 'legacy.svg')).toBeNull();
    });

    test('combines legacy local images with all remote pages and excludes unrelated files', async () => {
        jest.spyOn(fs, 'readdir').mockResolvedValue([
            { isFile: () => true, name: 'legacy.png' }, { isFile: () => true, name: 'notes.txt' },
            { isFile: () => false, name: 'directory.png' },
        ]);
        const firstPage = Array.from({ length: 98 }, () => ({ id: randomUUID(), name: randomUUID() + '.png' }));
        fetch.mockResolvedValueOnce(Response.json([...firstPage, { name: 'not-an-image' }, { id: null, name: randomUUID() + '.png' }]))
            .mockResolvedValueOnce(Response.json([{ id: randomUUID(), name: object }]));
        expect(await storage.list('icons')).toEqual([
            '/uploads/icons/legacy.png', ...firstPage.map(entry => '/uploads/stored/icons/' + entry.name),
            '/uploads/stored/icons/' + object,
        ]);
        const requests = fetch.mock.calls.map(([url, opts]) => [url, JSON.parse(opts.body)]);
        expect(requests).toEqual([0, 100].map(offset => [
            base + 'object/list/assets', expect.objectContaining({ offset, limit: 100, prefix: expect.stringMatching(/^icons\/?$/) }),
        ]));
    });

    test('refuses ephemeral production writes and propagates remote write failures', async () => {
        const copy = jest.spyOn(fs, 'copyFile');
        fetch.mockResolvedValueOnce(new Response('{}', { status: 503 }));
        await expect(storage.save('images', object, source, 'image/png')).rejects.toThrow();
        delete process.env.SUPABASE_SERVICE_ROLE_KEY;
        await expect(storage.save('images', object, source, 'image/png')).rejects.toThrow();
        expect(copy).not.toHaveBeenCalled();
        expect(fetch).toHaveBeenCalledTimes(1);
    });

    test('deletes only the requested remote object', async () => {
        expect(await storage.remove('icons', '../invalid.png', true)).toBe(false);
        fetch.mockResolvedValueOnce(Response.json([{ name: 'icons/' + object }]));
        expect(await storage.remove('icons', object, true)).toBe(true);
        expect(fetch).toHaveBeenCalledTimes(1);
        expect(fetch).toHaveBeenCalledWith(base + 'object/assets', expect.objectContaining({
            method: 'DELETE', body: JSON.stringify({ prefixes: ['icons/' + object] }),
        }));
        fetch.mockResolvedValueOnce(Response.json([]));
        expect(await storage.remove('icons', object, true)).toBe(false);
    });
});
