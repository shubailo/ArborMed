const shopController = require('../../src/controllers/shopController');
const AppError = require('../../src/utils/AppError');
const { withTransaction } = require('../../src/utils/dbHelpers');

// Mock dependencies
jest.mock('../../src/config/db', () => ({
    query: jest.fn(),
    pool: { on: jest.fn() }
}));

jest.mock('../../src/utils/catchAsync', () => (fn) => (req, res, next) => {
    return fn(req, res, next).catch(next);
});

jest.mock('../../src/utils/dbHelpers', () => ({
    withTransaction: jest.fn()
}));

describe('shopController.buyItem', () => {
    let req, res, next;
    let clientMock;

    beforeEach(() => {
        req = {
            user: { id: 1 },
            body: { itemId: 100 }
        };
        res = {
            json: jest.fn(),
            status: jest.fn().mockReturnThis()
        };
        next = jest.fn();
        clientMock = {
            query: jest.fn()
        };
        jest.clearAllMocks();
    });

    test.each([undefined, {}, {itemId: 0}, {itemId: 1.5}, {itemId: 2147483648},
        {itemId: 100, expectedPrice: '50'}])('rejects invalid purchase input before checkout (%p)', async body => {
        await shopController.buyItem({...req, body}, res, next);
        expect(next).toHaveBeenCalledWith(expect.objectContaining({statusCode:400}));
        expect(withTransaction).not.toHaveBeenCalled();
    });

    test('should prevent race condition by using atomic UPDATE with balance check', async () => {

        withTransaction.mockImplementationOnce(async (fn) => {
            clientMock.query
                .mockResolvedValueOnce({ rows: [{ coins: 100 }] })
                .mockResolvedValueOnce({ rows: [] })
                .mockResolvedValueOnce({ rows: [{ price: 50 }] })
                .mockResolvedValueOnce({ rows: [{ coins: 50 }], rowCount: 1 }) // UPDATE
                .mockResolvedValueOnce({ rows: [{ id: 1 }] });                 // INSERT
            return await fn(clientMock);
        });

        await shopController.buyItem(req, res, next);

        const updateCalls = clientMock.query.mock.calls.filter(([sql]) => sql.includes('UPDATE users'));
        expect(updateCalls).toHaveLength(1);
        expect(updateCalls[0][0]).toContain('COALESCE(coins, 0) >= $1');
        expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
            message: 'Item purchased',
            newBalance: 50
        }));
    });

    test('should handle insufficient funds via atomic UPDATE result', async () => {

        withTransaction.mockImplementationOnce(async (fn) => {
            clientMock.query
                .mockResolvedValueOnce({ rows: [{ coins: 100 }] })
                .mockResolvedValueOnce({ rows: [] })
                .mockResolvedValueOnce({ rows: [{ price: 50 }] })
                .mockResolvedValueOnce({ rows: [], rowCount: 0 }); // UPDATE (Atomic Fail)
            return await fn(clientMock);
        });

        await shopController.buyItem(req, res, next);

        // Expect Error
        expect(next).toHaveBeenCalledWith(expect.any(AppError));
        expect(next.mock.calls[0][0].message).toBe('Insufficient coins');
    });
});
