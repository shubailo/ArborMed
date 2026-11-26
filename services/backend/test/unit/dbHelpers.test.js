jest.mock('../../src/config/db', () => ({
    pool: {
        connect: jest.fn(),
    },
}));

const db = require('../../src/config/db');
const { withTransaction } = require('../../src/utils/dbHelpers');

describe('dbHelpers', () => {
    describe('withTransaction', () => {
        let mockClient;

        beforeEach(() => {
            mockClient = {
                query: jest.fn(),
                release: jest.fn(),
            };
            db.pool.connect.mockResolvedValue(mockClient);
        });

        afterEach(() => jest.clearAllMocks());

        test('a connection error during application work evicts the checkout without starting COMMIT', async () => {
            const { EventEmitter } = require('node:events');
            const client = Object.assign(new EventEmitter(), mockClient);
            db.pool.connect.mockResolvedValueOnce(client);
            const lost = new Error('connection lost while acquiring another resource');
            let callbackResumed = false;
            await expect(withTransaction(async () => {
                client.emit('error', lost);
                callbackResumed = true;
            })).rejects.toBe(lost);
            expect(callbackResumed).toBe(true);
            expect(client.query.mock.calls).toEqual([['BEGIN']]);
            expect(client.release).toHaveBeenCalledWith(lost);
            expect(client.listenerCount('error')).toBe(0);
        });

        test('commits on success', async () => {
            const callback = jest.fn().mockResolvedValue('result');

            const result = await withTransaction(callback);

            expect(mockClient.query).toHaveBeenCalledWith('BEGIN');
            expect(callback).toHaveBeenCalledWith(mockClient);
            expect(mockClient.query).toHaveBeenCalledWith('COMMIT');
            expect(mockClient.release).toHaveBeenCalled();
            expect(result).toBe('result');
        });

        test('rolls back on error', async () => {
            const error = new Error('DB failure');
            const callback = jest.fn().mockRejectedValue(error);

            await expect(withTransaction(callback)).rejects.toThrow('DB failure');

            expect(mockClient.query).toHaveBeenCalledWith('BEGIN');
            expect(mockClient.query).toHaveBeenCalledWith('ROLLBACK');
            expect(mockClient.release).toHaveBeenCalled();
        });

        test('always releases client even on unexpected error', async () => {
            const callback = jest.fn().mockRejectedValue(new Error('crash'));

            try { await withTransaction(callback); } catch { /* expected */ }

            expect(mockClient.release).toHaveBeenCalledTimes(1);
        });

        test('discards a connection when rollback fails and preserves the original error', async () => {
            const original = new Error('operation failed');
            const rollbackError = new Error('connection closed');
            mockClient.query.mockResolvedValueOnce({}).mockRejectedValueOnce(rollbackError);
            await expect(withTransaction(async () => { throw original; })).rejects.toBe(original);
            expect(mockClient.release).toHaveBeenCalledWith(rollbackError);
            expect(mockClient.release).toHaveBeenCalledTimes(1);
        });

        test('passes client to callback for query execution', async () => {
            await withTransaction(async (client) => {
                await client.query('INSERT INTO test VALUES ($1)', [1]);
                await client.query('INSERT INTO test VALUES ($1)', [2]);
            });

            expect(mockClient.query).toHaveBeenCalledWith('BEGIN');
            expect(mockClient.query).toHaveBeenCalledWith('INSERT INTO test VALUES ($1)', [1]);
            expect(mockClient.query).toHaveBeenCalledWith('INSERT INTO test VALUES ($1)', [2]);
            expect(mockClient.query).toHaveBeenCalledWith('COMMIT');
        });
    });
});
