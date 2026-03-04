const shopController = require('../../src/controllers/shopController');
const db = require('../../src/config/db');
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

    test('should prevent race condition by using atomic UPDATE with balance check', async () => {
        db.query.mockResolvedValueOnce({ rows: [{ id: 100, price: 50 }] }); // 1. Item

        withTransaction.mockImplementationOnce(async (fn) => {
            clientMock.query
                .mockResolvedValueOnce({ rows: [{ coins: 50 }], rowCount: 1 }) // UPDATE
                .mockResolvedValueOnce({ rows: [{ id: 1 }] });                 // INSERT
            return await fn(clientMock);
        });

        await shopController.buyItem(req, res, next);

        const updateCalls = clientMock.query.mock.calls.filter(call =>
            call[0] &&
            call[0].includes('UPDATE users') &&
            call[0].includes('coins >=')
        );

        if (updateCalls.length === 0) {
             const vulnerableUpdate = clientMock.query.mock.calls.find(call =>
                call[0] &&
                call[0].includes('UPDATE users') &&
                !call[0].includes('coins >=')
            );
            if (vulnerableUpdate) {
                throw new Error('Vulnerability detected: UPDATE without balance check!');
            }
            throw new Error('No UPDATE query found');
        }

        expect(updateCalls.length).toBe(1);
        expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
            message: 'Item purchased',
            newBalance: 50
        }));
    });

    test('should handle insufficient funds via atomic UPDATE result', async () => {
        db.query.mockResolvedValueOnce({ rows: [{ id: 100, price: 50 }] }); // 1. Item

        withTransaction.mockImplementationOnce(async (fn) => {
            clientMock.query
                .mockResolvedValueOnce({ rows: [], rowCount: 0 }); // UPDATE (Atomic Fail)
            return await fn(clientMock);
        });

        await shopController.buyItem(req, res, next);

        // Expect Error
        expect(next).toHaveBeenCalledWith(expect.any(AppError));
        expect(next.mock.calls[0][0].message).toBe('Insufficient coins');
    });
});
