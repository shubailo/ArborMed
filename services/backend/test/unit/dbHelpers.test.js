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
