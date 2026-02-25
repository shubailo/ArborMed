const shopController = require('../../src/controllers/shopController');
const db = require('../../src/config/db');
const AppError = require('../../src/utils/AppError');

// Mock dependencies
jest.mock('../../src/config/db', () => ({
    query: jest.fn(),
    pool: { on: jest.fn() }
}));

jest.mock('../../src/utils/catchAsync', () => (fn) => (req, res, next) => {
    return fn(req, res, next).catch(next);
});

describe('shopController.buyItem', () => {
    let req, res, next;

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
        jest.clearAllMocks();
    });

    test('should prevent race condition by using atomic UPDATE with balance check', async () => {
        // Mocks for Atomic Implementation
        db.query
            .mockResolvedValueOnce({ rows: [{ id: 100, price: 50 }] }) // 1. Item
            .mockResolvedValueOnce({})                                 // 2. BEGIN
            .mockResolvedValueOnce({ rows: [{ coins: 50 }], rowCount: 1 }) // 3. UPDATE (Success)
            .mockResolvedValueOnce({ rows: [{ id: 1 }] })              // 4. INSERT
            .mockResolvedValueOnce({});                                // 5. COMMIT

        await shopController.buyItem(req, res, next);

        // Assert that an atomic UPDATE was executed
        const updateCalls = db.query.mock.calls.filter(call =>
            call[0] &&
            call[0].includes('UPDATE users') &&
            call[0].includes('coins >=')
        );

        if (updateCalls.length === 0) {
             const vulnerableUpdate = db.query.mock.calls.find(call =>
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
        // Mocks for Atomic Failure
        db.query
            .mockResolvedValueOnce({ rows: [{ id: 100, price: 50 }] }) // 1. Item
            .mockResolvedValueOnce({})                                 // 2. BEGIN
            .mockResolvedValueOnce({ rows: [], rowCount: 0 })          // 3. UPDATE (Atomic Fail)
            .mockResolvedValueOnce({});                                // 4. ROLLBACK

        await shopController.buyItem(req, res, next);

        // Expect Error
        expect(next).toHaveBeenCalledWith(expect.any(AppError));
        expect(next.mock.calls[0][0].message).toBe('Insufficient coins');

        // Ensure ROLLBACK was called
        expect(db.query).toHaveBeenCalledWith('ROLLBACK');
    });
});
