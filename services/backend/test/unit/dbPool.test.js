const { EventEmitter } = require('node:events');
const { Pool } = require('pg');

jest.mock('pg', () => ({ Pool: jest.fn() }));
jest.mock('dotenv', () => ({ config: jest.fn() }));
jest.mock('../../src/config/databaseOptions', () => ({ databaseOptions: () => ({}) }));

test('idle pool diagnostics do not expose raw database messages', async () => {
    const pool = new EventEmitter();
    pool.query = jest.fn().mockResolvedValue({rows:[{ready:1}]});
    Pool.mockReturnValueOnce(pool);
    const errorLog = jest.spyOn(console, 'error').mockImplementation(() => {});
    try {
        const db = require('../../src/config/db');
        pool.emit('error', Object.assign(new Error('private diagnostic text'), {code:'57P01'}));
        expect(errorLog).toHaveBeenCalledWith('[DB] Unexpected error on idle client:', '57P01');
        expect(errorLog.mock.calls.flat().join(' ')).not.toContain('private diagnostic text');
        await expect(db.query('SELECT 1 AS ready')).resolves.toEqual({rows:[{ready:1}]});
    } finally {
        errorLog.mockRestore();
    }
});
